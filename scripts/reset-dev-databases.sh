#!/usr/bin/env bash
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"

namespace="ll"
platform_name="ll-platform-dev"
template_name="reset-dev-databases"
expected_confirmation="RESET ${platform_name}"
writer_deployments=(
  "ll-app-ll-backend"
  "ll-app-ll-backend-worker"
  "ll-app-ll-chat"
)

kubectl --namespace "$namespace" get cronjob "$template_name" >/dev/null

active_reset_jobs="$(
  kubectl --namespace "$namespace" get jobs \
    --selector='app.kubernetes.io/name=reset-dev-databases' \
    --output=go-template='{{range .items}}{{if not .status.completionTime}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}'
)"

if [[ -n "$active_reset_jobs" ]]; then
  echo "Refusing to start while another reset Job has not completed:" >&2
  printf '  - %s\n' "$active_reset_jobs" >&2
  exit 1
fi

if kubectl --namespace "$namespace" get job init-myseconddb >/dev/null 2>&1; then
  initializer_completion="$(
    kubectl --namespace "$namespace" get job init-myseconddb --output=jsonpath='{.status.completionTime}'
  )"
  if [[ -z "$initializer_completion" ]]; then
    echo "Refusing to reset while the chat database initializer is unfinished." >&2
    exit 1
  fi
fi

unsafe_deployments=()
for deployment in "${writer_deployments[@]}"; do
  if ! kubectl --namespace "$namespace" get deployment "$deployment" >/dev/null 2>&1; then
    continue
  fi

  desired_replicas="$(kubectl --namespace "$namespace" get deployment "$deployment" --output=jsonpath='{.spec.replicas}')"
  current_replicas="$(kubectl --namespace "$namespace" get deployment "$deployment" --output=jsonpath='{.status.replicas}')"
  desired_replicas="${desired_replicas:-0}"
  current_replicas="${current_replicas:-0}"

  if (( desired_replicas != 0 || current_replicas != 0 )); then
    unsafe_deployments+=("${deployment} (desired=${desired_replicas}, current=${current_replicas})")
  fi
done

if (( ${#unsafe_deployments[@]} > 0 )); then
  echo "Refusing to reset while database-writing deployments are running." >&2
  printf '  - %s\n' "${unsafe_deployments[@]}" >&2
  echo "Run 'bash scripts/maintenance.sh enter', wait for it to finish, and try again." >&2
  exit 1
fi

echo "WARNING: This permanently deletes all game and chat data in ${platform_name}."
read -r -p "Type '${expected_confirmation}' to continue: " confirmation

if [[ "$confirmation" != "$expected_confirmation" ]]; then
  echo "Confirmation did not match. Nothing was changed."
  exit 1
fi

job_name="reset-dev-databases-$(date -u +%Y%m%d%H%M%S)"

kubectl --namespace "$namespace" create job "$job_name" --from="cronjob/${template_name}"
echo "Created job ${job_name}."

if kubectl --namespace "$namespace" wait --for=condition=complete "job/${job_name}" --timeout=10m; then
  kubectl --namespace "$namespace" logs "job/${job_name}"
  echo "Database reset completed. Run 'bash scripts/maintenance.sh leave' when ready."
else
  kubectl --namespace "$namespace" logs "job/${job_name}" --all-containers=true || true
  kubectl --namespace "$namespace" describe job "$job_name" || true
  echo "Database reset failed. Keep maintenance mode enabled until the failure is understood." >&2
  exit 1
fi
