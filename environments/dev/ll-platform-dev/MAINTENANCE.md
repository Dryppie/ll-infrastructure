# Maintenance and development database reset

This runbook describes the implemented maintenance workflow for the Legends
Legacy development platform. It keeps a themed frontend maintenance page
available while preventing game and chat traffic and stopping every workload
that can write to PostgreSQL.

## Implemented architecture

The workflow has three independent controls:

| Setting | Effect |
| --- | --- |
| `maintenance.pageEnabled` | Shows only the login-themed maintenance panel, redirects protected/signup/unknown routes to `/login`, and suppresses frontend API, time-sync, and realtime startup calls. |
| `maintenance.rejectTraffic` | Makes the game API and chat service return HTTP 503 with `Retry-After`, while preserving `/healthz/ready` and `/healthz/live`. |
| `maintenance.stopServices` | Scales the game API, chat service, and worker Deployments to zero. The frontend remains running. |

Additional runtime values control the visible message:

```yaml
maintenance:
  pageEnabled: false
  rejectTraffic: false
  stopServices: false
  message: "Legend's Legacy is undergoing maintenance."
  expectedBack: ""
  retryAfterSeconds: 300
```

The Angular frontend receives these values through its existing runtime
`env.js` generation. Changing maintenance state does not require rebuilding an
already compatible frontend image.

## Previously implemented database reset

The platform chart includes a permanently suspended `reset-dev-databases`
CronJob that is used only as a template for manually created Jobs. It never runs
from its schedule.

The reset implementation:

- Requires the exact confirmation phrase `RESET ll-platform-dev`.
- Refuses to run while backend, chat, worker, the database initializer, or
  another reset is active.
- Verifies the namespace and exact development database names inside the Pod.
- Drops and recreates both the game and chat development databases.
- Reinstalls the Quartz PostgreSQL schema in the game database.
- Uses the existing Kubernetes Secret for PostgreSQL credentials.
- Sets `backoffLimit: 0`, so Kubernetes does not automatically retry a failed
  destructive Job.
- Retains the completed Job for 24 hours for log inspection.

The game API and chat service apply their EF Core migrations when they start.
The game API also applies its normal seed data.

## Initial rollout

The maintenance feature must be deployed once before it can be controlled with
Argo CD overrides:

1. Publish compatible frontend, backend, and chat images/charts.
2. Update the `ll-app` dependency versions in the infrastructure repository.
3. Publish the updated `ll-app` chart.
4. Publish the updated `ll-platform-dev` chart.
5. Let Argo CD sync both `ll-platform-dev` and `ll-app`.
6. Verify that the reset template exists and is suspended:

   ```bash
   kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml \
     --namespace ll get cronjob reset-dev-databases
   ```

No database reset is performed during this rollout. All maintenance defaults
are false.

## Enter maintenance

Run from a checkout of the infrastructure repository on the server:

```bash
bash scripts/maintenance.sh enter \
  "Deploying a game update." \
  "Expected back around 21:00 CET"
```

The script requires `ENTER MAINTENANCE` and then performs three staged Argo CD
reconciliations:

1. Roll out the frontend maintenance page and wait for `ll-app` health.
2. Reject game API and chat traffic while leaving health checks available.
3. Scale backend, chat, and worker to zero and wait for reconciliation.

If any step fails, stop and investigate. The script deliberately does not
attempt to roll forward after a failed step.

## Reset both development databases

Only after maintenance entry completes, run:

```bash
bash scripts/reset-dev-databases.sh
```

Type `RESET ll-platform-dev` exactly. Review the Job output before continuing.
If the reset fails, keep maintenance active. Do not start services against a
partially reset database until the failure is understood.

The reset is irreversible and does not currently create a backup.

## Leave maintenance

After maintenance or database work succeeds:

```bash
bash scripts/maintenance.sh leave
```

The script requires `LEAVE MAINTENANCE` and then:

1. Restores backend, chat, and worker replicas while non-health traffic remains
   rejected.
2. Waits for Argo CD to report `ll-app` synced and healthy. Readiness health
   checks remain available during startup and migrations.
3. Removes the temporary Helm overrides, returning to chart defaults and
   restoring both API traffic and normal frontend routing.

If service startup or health verification fails, the frontend maintenance page
remains enabled.

## Manual Argo CD equivalent

The operator script uses temporary Helm parameter overrides on
`ll-platform-dev`. It does not publish a new chart for each maintenance window.
The underlying operations are `argocd app set`, `argocd app sync`,
`argocd app wait`, and finally `argocd app unset`.

Both Argo CD applications must be visible to the authenticated CLI user:

- `ll-platform-dev`
- `ll-app`

The user must have permission to update, sync, and read both applications.

## Failure recovery

- **Frontend maintenance rollout fails:** backend remains available; fix the
  frontend/Argo issue before continuing.
- **Traffic rejection fails:** maintenance page remains visible; do not stop
  services until both APIs reject non-health traffic.
- **Workload shutdown fails:** the database reset script refuses to run while
  writer replicas remain.
- **Database reset fails:** keep all services stopped and inspect the retained
  Job logs.
- **Service startup fails:** keep the maintenance page visible. The leave script
  exits before removing the page override when health does not recover.
- **Argo CD permission denied:** authenticate with an account permitted to
  update and sync both Applications; root access on the VPS does not grant Argo
  CD permissions.

## Security and operational notes

- Frontend route restriction is a user-experience measure, not an authorization
  boundary. The API/chat traffic gate and stopped workloads provide the actual
  maintenance enforcement.
- The reset credentials must remain in Kubernetes Secrets and must never be
  added to scripts, ConfigMaps, or logs.
- Existing plaintext PostgreSQL credentials in the platform manifest should be
  rotated and migrated into the sealed-secret workflow separately.
- Consider adding persistent `pg_dump` storage before using the reset process
  for any environment whose data cannot be recreated.
