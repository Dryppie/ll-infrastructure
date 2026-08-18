# Central logging rollout

This environment contains the GitOps definitions for private, single-replica
Loki storage, a node-level Grafana Alloy log collector, and a staged private
Grafana operator UI. Cloudflare resources and credentials remain external
prerequisites and are never created by these charts.

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
- Argo CD deploys pinned Grafana Alloy chart `1.11.1` as one DaemonSet pod per
  node. Alloy reads `/var/log/pods` read-only, persists offsets beneath the
  dedicated `/var/lib/alloy-logs` host directory, and writes only to the
  cluster-local Loki endpoint.
- Alloy collects the `ll` namespace, `default/cloudflared`,
  `kube-system/traefik`, and selected Argo CD controller/server workloads. It
  excludes the `observability` namespace and all other kube-system workloads.
- Alloy has pod-only read discovery permission and no Secret permission. Its
  container runs as UID 0 so the node log and checkpoint host paths work
  consistently, but privilege escalation is disabled, all Linux capabilities
  are dropped, its root filesystem is read-only, and the host log mount is
  read-only.
- The pinned Grafana Community chart `12.11.0` is staged disabled. When enabled,
  it runs one non-root replica with a retained 5 GiB `local-path` PVC, a
  Git-provisioned Loki datasource and logging dashboard, and local administrator
  authentication backed by a SealedSecret.
- A short-lived UID 0 init container assigns the node-local volume to Grafana's
  UID 472. It cannot escalate privileges, has a read-only root filesystem, and
  retains only `CHOWN` and `DAC_OVERRIDE`; the Grafana application container
  remains non-root with all capabilities dropped.
- Grafana has a ClusterIP Service. Its only ingress is the dedicated Traefik
  hostname, and NetworkPolicy admits only the Traefik pod. Grafana can egress
  only to Loki and cluster DNS. Cloudflare Access is the mandatory external
  authentication layer in front of that hostname.

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

## Alloy rollout and verification

1. Publish the platform chart and wait for `ll-alloy-logs` to become
   `Synced Healthy` in Argo CD.
2. Confirm the DaemonSet has one ready pod per schedulable node:

   ```bash
   kubectl -n observability get daemonset,pod -l app.kubernetes.io/instance=alloy-logs -o wide
   ```

3. Confirm Alloy reports no configuration, permission, file-tail, DNS, or Loki
   write errors:

   ```bash
   kubectl -n observability logs daemonset/alloy-logs -c alloy --since=10m
   ```

4. Generate a non-sensitive marker in one application pod, then query Loki for
   `{cluster="legends-legacy-dev",namespace="ll"}` and that marker. The first
   rollout intentionally starts newly discovered files at their end rather
   than backfilling all rotated node logs.
5. Restart the selected application pod after emitting another marker. Confirm
   the marker remains queryable and that Alloy resumes from its checkpoint
   after an Alloy pod restart without replaying the complete file.
6. Inspect Loki series and confirm indexed labels are limited to bounded source
   dimensions. `pod`, `node`, and `version` must appear as structured metadata,
   not indexed labels. Request, trace, account, and character identifiers must
   remain JSON fields, never labels.
7. Confirm frontend 2xx/3xx access records, Traefik 2xx/3xx access records,
   routine Argo CD info/debug records, the observability namespace, and
   unrelated kube-system workloads are absent.

The Development API, Worker, and Chat keep `ASPNETCORE_ENVIRONMENT=Development`
but receive explicit JSON console formatter overrides through `ll-app`. LiveOps
already loads its Production JSON formatter. Updating `ll-app` values rolls the
affected application pods; it does not require new application binaries.

## Grafana prerequisites and sealed secret

Grafana is deliberately disabled until all of these prerequisites exist:

1. In Cloudflare Zero Trust, create an Access application for
   `grafana.legends-legacy.com`. Allow only the intended operator email or
   existing identity-provider group, require MFA, use a bounded session, and
   verify an unauthorised identity is denied.
2. In the remotely managed tunnel, route `grafana.legends-legacy.com` to the
   cluster's Traefik HTTP service. Do not create routes for Loki or Alloy.
   Confirm the VPS firewall does not expose the Traefik origin directly. A
   request sent to the public node address with
   `Host: grafana.legends-legacy.com` must not bypass Cloudflare Access. Do not
   enable Grafana until that origin-bypass test fails closed.
3. Create an item in the `legends-legacy-dev` 1Password vault with tags
   `sealedsecret` and `env:dev`. Set its metadata fields to:

   ```text
   name=grafana-admin
   namespace=observability
   ```

4. Add these fields without placing their values in Git:

   | Field | Initial value |
   | --- | --- |
   | `admin-user` | A non-email administrator username |
   | `admin-password` | A unique randomly generated password of at least 32 characters |
   | `secret-key` | A separate randomly generated value of at least 64 characters |

5. Generate the SealedSecret using the existing workflow:

   ```powershell
   ./src/secrets/generate-secrets.ps1
   ```

   Review and commit only the generated
   `templates/secrets/observability.grafana-admin.sealed.yaml`. Confirm the
   generator's actual filename before staging it. Never commit or print the
   unsealed Secret or any field value.

The `secret-key` protects Grafana sessions and encrypted data stored in its
database. Losing or changing it can invalidate sessions and make encrypted
settings unreadable. Back it up in 1Password. The initial administrator values
bootstrap a new Grafana database; changing only the Kubernetes Secret does not
change an administrator password already stored in an existing database.

## Grafana rollout and verification

1. Keep `observability.grafana.enabled: false` until the SealedSecret, tunnel
   route, Access application, and policy are verified.
2. Set `observability.grafana.enabled: true` and
   `observability.grafana.replicas: 0`, then publish and reconcile. Confirm the
   `ll-grafana` Application is `Synced Healthy`, its Service is `ClusterIP`, its
   Ingress has only the intended hostname, and no Grafana pod starts yet.
3. Confirm the rendered PVC is 5 GiB, uses `local-path`, and carries both the
   Helm keep annotation and Argo CD `Prune=false` sync option. The claim remains
   `Pending` until the first pod is scheduled because the StorageClass uses
   `WaitForFirstConsumer`.
4. Set `observability.grafana.replicas: 1`, publish, and reconcile. Confirm the
   PVC binds, one pod becomes ready, and the node retains safe disk headroom:

   ```bash
   kubectl -n observability get deploy,pod,svc,ingress,pvc -l app.kubernetes.io/instance=grafana -o wide
   kubectl -n observability logs deployment/grafana --since=10m
   ```

5. Open `https://grafana.legends-legacy.com` in a private browser session.
   Confirm Cloudflare Access authenticates first and Grafana's own login form
   appears second. Confirm an unauthorized identity cannot reach that form and
   anonymous requests never reach a dashboard.
6. Sign in with the administrator credentials, open **Connections > Data
   sources > Loki**, and run **Save & test**. Open the provisioned **Legends
   Legacy / Legends Legacy Logs** dashboard and verify its environment,
   namespace, service, workload, and level variables return current streams.
7. Find a known error, narrow by service and time, expand its JSON fields, and
   correlate it using `TraceId` or `RequestId`. Confirm account, character,
   trace, request, pod, node, and version values are not offered as indexed
   dashboard variables.
8. Recreate the Grafana pod and confirm the datasource and dashboard are
   reprovisioned while login state and Grafana database content survive on the
   same PVC.

The Grafana PVC is node-local, non-expandable, and not an independent backup.
Important datasources and dashboards are provisioned from Git so they can be
recreated. Grafana users, sessions, and UI-only changes live only in the PVC;
avoid relying on unprovisioned UI edits as durable configuration.

## Rollback and recovery

- **Emergency stop:** set `observability.loki.replicas: 0` and reconcile. The
  StatefulSet PVC is explicitly retained and R2 objects are untouched.
- **Stop collection:** set `observability.alloy.enabled: false` and reconcile
  the parent chart. Before removing the child Application, choose the intended
  Argo cascade behavior. The node checkpoint directory is deliberately not
  deleted automatically.
- **Alloy failure or noisy stream:** disable Alloy, correct its allowlist or
  processing rule, render the pinned chart locally, then re-enable it. Do not
  delete Loki data as a collector rollback step.
- **Stop Grafana non-destructively:** set `observability.grafana.replicas: 0`
  and reconcile. Keep the child Application and PVC. Loki and Alloy continue
  operating and no retained logs are deleted.
- **Grafana release/configuration failure:** pin the last known-good Grafana
  chart/configuration and reconcile while replicas remain zero. Restore one
  replica only after local rendering succeeds. Do not delete the PVC as a
  rollback step.
- **Grafana credential recovery:** use the supported Grafana administrator
  reset procedure against the retained database, then update the 1Password item
  and regenerate the SealedSecret so disaster-recovery credentials match. Do
  not expose credentials in commands saved to shell history.
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

Grafana requires no application release or schema migration. After the Grafana
rollout has been verified, the next phase is at least one week of ingestion,
storage, query, and resource measurement followed by retention and noise tuning.
Metrics, alerts, and traces remain separate follow-up work. Loki and Alloy must
remain unexposed.
