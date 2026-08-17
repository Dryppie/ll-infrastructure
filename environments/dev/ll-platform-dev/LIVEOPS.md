# LiveOps dashboard rollout

This environment contains the deployment wiring for the private Legends Legacy
LiveOps dashboard. The workload is disabled by default so that Argo CD cannot
start it before its image, Helm chart, credentials, and external hostname are
ready.

## Architecture

- `ll-liveops` runs as one non-root pod behind the existing Traefik ingress.
- `liveops.legends-legacy.com` has its own ingress rule and does not share the
  public game host.
- The browser uses server-side Google OIDC. Google tokens and the client secret
  are never exposed to the Angular application.
- LiveOps reads and writes the Game database through the existing
  `postgres-ll-connection` Secret.
- LiveOps calls Chat over the cluster-only `ll-chat` Service. Both workloads
  receive the same dedicated moderation secret.
- Readiness requires the Game database and reports Chat outages as degraded.
  Liveness checks only the LiveOps process.

The single replica and `Recreate` update strategy are intentional. OIDC state
and cookie encryption keys are pod-local, so a restart signs the operator out
instead of requiring shared key storage for a one-person dashboard.

## Prerequisites

1. Publish an application version containing `API.LiveOps`, the
   `ll-liveops` image, and the `ll-liveops` Helm chart. The first application
   workflow bootstraps chart version `0.0.1`; publish this before publishing the
   aggregate infrastructure chart that references it.
2. Confirm that the Game `AddLiveOpsAdministration` migration and Chat
   `AddChatModeration` migration have completed through the normal service
   rollout. The LiveOps pod does not apply migrations.
3. In Google Cloud, configure the OAuth web client with:

   ```text
   Redirect URI: https://liveops.legends-legacy.com/signin-oidc
   Scopes: openid, profile, email
   ```

   An Authorized JavaScript Origin is not needed for this server-side flow. If
   Google requires one, use `https://liveops.legends-legacy.com`.
4. In the remotely managed Cloudflare tunnel, route
   `liveops.legends-legacy.com` to the cluster's Traefik HTTP service. Adding a
   Cloudflare Access owner policy is optional defense in depth; the application
   itself still enforces the immutable Google owner identity.
5. Confirm the k3s pod CIDR before enabling LiveOps:

   ```bash
   kubectl get nodes -o jsonpath='{range .items[*]}{.spec.podCIDR}{"\n"}{end}'
   ```

   Update `liveOps.trustedProxyNetworks` if the result is not within the
   configured `10.42.0.0/16`. Only these networks may supply forwarded host and
   HTTPS headers to the application.

## Create the sealed secret

Create an item in the `legends-legacy-dev` 1Password vault with the tags
`sealedsecret` and `env:dev`. Set its custom metadata fields to:

```text
name=ll-liveops
namespace=ll
```

Add these fields without placing their values in Git:

| Field | Initial value |
| --- | --- |
| `google-client-id` | The Google OAuth web client ID |
| `google-client-secret` | The Google OAuth client secret |
| `bootstrap-owner-email` | The exact Google email allowed for the first login |
| `chat-moderation-secret` | A new random service-to-service secret |
| `owner-subject` | Omit for the first login |

Generate the SealedSecret with the existing workflow:

```powershell
./src/secrets/generate-secrets.ps1
```

Review and commit only the generated
`templates/secrets/ll.ll-liveops.sealed.yaml`. Never commit the unsealed Secret
or any of the field values.

## Enable and bootstrap the owner

After the component chart, external hostname, and SealedSecret exist, change:

```yaml
liveOps:
  enabled: true
```

Publish the updated platform and aggregate charts and let Argo CD reconcile
them. Verify `/healthz/live` and `/healthz/ready`, then sign in at:

```text
https://liveops.legends-legacy.com
```

Open `/auth/session` and copy the returned `subject`. Replace the
`bootstrap-owner-email` field in 1Password with an `owner-subject` field that
contains this value, regenerate the SealedSecret, and restart the LiveOps pod.
When `owner-subject` exists it takes precedence over email, even if the
bootstrap email was accidentally left in the Secret.

## Rollback

For an authentication, ingress, or application problem, set
`liveOps.enabled: false` and reconcile the platform and aggregate applications.
This removes the LiveOps workload and its ingress rule without affecting Game,
Chat, or their databases.

For a bad component release, pin `deploy/versions/ll-liveops.version` to the
previous published chart version and republish `ll-app`. LiveOps schema changes
are additive and shared with the normal Game and Chat services; do not run a
down migration merely to roll back the dashboard.

Rotating either Google or Chat credentials requires regenerating the
SealedSecret and restarting the LiveOps pod. Rotating the Chat moderation
secret also restarts Chat so both sides switch to the same value.
