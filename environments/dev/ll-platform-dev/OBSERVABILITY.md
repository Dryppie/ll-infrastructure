# Loki object-storage rollout

This environment contains the GitOps definition for a private, single-replica
Loki deployment. It is deliberately disabled and staged at zero replicas. The
checked-in change does not create Cloudflare resources, credentials, or a Loki
workload.

## Architecture and boundaries

- Argo CD deploys pinned Grafana Community Loki chart `18.9.0` into the
  `observability` namespace.
- Loki runs in monolithic mode and has no Ingress, Gateway, or public Service.
- A 10 GiB ReadWriteOnce PVC retains the WAL, active index, and compactor state.
- The observed k3s `local-path` StorageClass is used explicitly. It is
  node-local, binds only after a pod is scheduled, cannot expand in place, and
  has a `Delete` reclaim policy.
- A dedicated private Cloudflare R2 bucket stores retained TSDB index and chunk
  objects through the S3-compatible API.
- NetworkPolicy permits same-namespace clients, DNS, and outbound HTTPS for R2.
  Confirm that the installed k3s network-policy implementation enforces these
  policies before treating them as a security boundary.
- Application logs are not collected in this phase. Grafana Alloy and Grafana
  are separate follow-up deployments.

The Loki chart disables authentication because the Service is cluster-only and
policy-constrained. Do not add an Ingress or Cloudflare route for Loki.

## Prerequisites

1. The cluster was confirmed on Kubernetes `v1.36.3+k3s1`, which satisfies the
   chart's Kubernetes 1.25 or later requirement.
2. The cluster's default StorageClass was confirmed as `local-path` with
   `WaitForFirstConsumer`, `Delete` reclaim, and volume expansion disabled. The
   class is pinned explicitly in `values.yaml`. Confirm the node has at least
   10 GiB plus operating headroom before starting Loki.
3. Create one dedicated private R2 bucket. Do not make the bucket public and do
   not reuse a bucket containing unrelated data.
4. Create an R2 token with Object Read & Write permission scoped only to that
   bucket. Do not use a global Cloudflare API token.
5. Do not configure a blanket R2 object-expiration rule. Loki Compactor owns
   retention and also stores deletion state. Any future lifecycle safety net
   must target verified chunk prefixes and exceed the longest 30-day retention
   plus deletion delay.

## Create the sealed secret

Create an item in the `legends-legacy-dev` 1Password vault with tags
`sealedsecret` and `env:dev`. Set its metadata fields to:

```text
name=loki-r2
namespace=observability
```

Add these fields without placing their values in Git:

| Field | Value |
| --- | --- |
| `AWS_ACCESS_KEY_ID` | Bucket-scoped R2 Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | Bucket-scoped R2 Secret Access Key |
| `LOKI_S3_ENDPOINT` | `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` |
| `LOKI_S3_REGION` | `auto` |
| `LOKI_S3_BUCKET` | The dedicated private bucket name |

Generate the SealedSecret using the existing workflow:

```powershell
./src/secrets/generate-secrets.ps1
```

Review and commit only
`environments/dev/ll-platform-dev/templates/secrets/observability.loki-r2.sealed.yaml`.
Never commit the unsealed Secret or any field value. Confirm the generator's
actual filename before staging it.

## Staged rollout

No command in this section should be run from an unreviewed workstation or
against an unexpected kube-context.

1. Validate the parent chart and the rendered Loki chart locally.
2. Commit the generated SealedSecret while `observability.enabled` remains
   `false` and `observability.loki.replicas` remains `0`.
3. Publish/reconcile the platform chart. Confirm the `observability` namespace
   and unsealed `loki-r2` Secret exist; inspect only the Secret key names, never
   their values.
4. Set `observability.enabled: true` while keeping replicas at `0`. Publish and
   reconcile. Confirm the `ll-loki` Argo CD Application is healthy and its
   rendered resources contain no Ingress, LoadBalancer, or NodePort.
5. Confirm the rendered StatefulSet claim template names `local-path` and that
   NetworkPolicy enforcement is active. A PVC will not bind yet because
   `local-path` uses `WaitForFirstConsumer` and Loki still has zero replicas.
6. Set `observability.loki.replicas: 1`, publish, and reconcile. Confirm the PVC
   is `Bound`, the pod is scheduled on the expected node, and the node retains
   safe free-disk headroom.
7. Push one synthetic, non-sensitive test record through a local port-forward,
   query it back, restart the Loki pod, and query it again.
8. Confirm objects appear in the dedicated R2 bucket and that the Compactor
   reports retention as enabled. Do not print object payloads or credentials.
9. Confirm Loki is unreachable from outside the cluster and from an unrelated
   namespace.

The initial default retention is 14 days. Production warning, error, and
critical streams retain 30 days; production debug/trace retain 3 days; staging
and Kubernetes Events retain 7 days; development retains 3 days. These stream
rules take effect once Alloy supplies the documented bounded labels.

## Rollback and recovery

- **Emergency stop:** set `observability.loki.replicas: 0` and reconcile. The
  StatefulSet PVC is explicitly retained and R2 objects are untouched.
- **Bad chart/configuration:** pin `observability.loki.chartVersion` to the last
  known-good version and reconcile. Keep replicas at zero until rendering and
  configuration checks pass.
- **R2 outage:** stop ingestion if the local PVC is growing, restore R2 access,
  and then restart Loki. Do not delete the PVC or bucket as a recovery step.
- **PVC capacity:** `local-path` cannot expand the existing claim. Treat a size
  increase as a planned data-migration/recreation operation and rely on R2 as
  the durable retained-log copy. Never delete the claim merely to make the
  StatefulSet start.
- **Full removal:** first scale to zero and decide explicitly whether retained
  logs, the PVC, Secret, and R2 bucket must remain. The parent Argo application
  does not prune removed child `Application` manifests automatically, so an
  operator must deliberately delete `ll-loki` with the intended cascade policy
  before setting `observability.enabled: false`.

Removing an Argo CD Application, PVC, or R2 data is destructive and is not part
of this rollout. The chart retains the StatefulSet claim, but manually deleting
that claim allows the StorageClass's `Delete` policy to remove its local volume.
The R2 bucket is the durable log copy; the local PVC is retained restart state,
not a substitute backup.

## Compatibility and next phase

This phase does not require an application release and does not ingest current
workload logs. The next compatible step is the pinned Grafana Alloy DaemonSet,
which will write to the cluster-only Loki service and attach the label schema
documented in `LOGGING_SYSTEM_PLAN.md` in the application repository.
