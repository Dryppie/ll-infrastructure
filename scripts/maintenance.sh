#!/usr/bin/env bash
set -euo pipefail

platform_app="${PLATFORM_APP:-ll-platform-dev}"
workload_app="${WORKLOAD_APP:-ll-app}"
wait_timeout="${ARGOCD_WAIT_TIMEOUT:-600}"
default_message="Legend's Legacy is undergoing maintenance."

usage() {
  cat <<'EOF'
Usage:
  bash scripts/maintenance.sh enter [message] [expected-back]
  bash scripts/maintenance.sh leave

Examples:
  bash scripts/maintenance.sh enter
  bash scripts/maintenance.sh enter "Deploying a game update." "Expected back around 21:00 CET"
  bash scripts/maintenance.sh leave
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command '$1' was not found." >&2
    exit 1
  fi
}

escape_helm_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//,/\\,}"
  printf '%s' "$value"
}

validate_text() {
  local name="$1"
  local value="$2"
  if [[ "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
    echo "$name must be a single line." >&2
    exit 1
  fi
}

wait_for_auto_sync() {
  local app_name="$1"
  shift

  # Setting a Helm parameter starts an operation because these Applications
  # use automated sync. Refresh and wait for that operation instead of racing
  # it with a second explicit sync request.
  argocd app get "$app_name" --refresh >/dev/null
  argocd app wait "$app_name" --operation --sync "$@" --timeout "$wait_timeout"
}

sync_apps() {
  wait_for_auto_sync "$platform_app"
  wait_for_auto_sync "$workload_app" --health
}

preflight() {
  require_command argocd
  argocd app get "$platform_app" >/dev/null
  argocd app get "$workload_app" >/dev/null
}

enter_maintenance() {
  local message="${1:-$default_message}"
  local expected_back="${2:-}"
  local confirmation

  validate_text "Maintenance message" "$message"
  validate_text "Expected-back text" "$expected_back"

  echo "This will show the maintenance page, reject API/chat traffic, and stop game services."
  read -r -p "Type 'MAINTENANCE' to continue: " confirmation
  if [[ "$confirmation" != "MAINTENANCE" ]]; then
    echo "Confirmation did not match. Nothing was changed."
    exit 1
  fi

  echo "Step 1/3: enabling the frontend maintenance page."
  argocd app set "$platform_app" \
    --helm-set maintenance.pageEnabled=true \
    --helm-set-string "maintenance.message=$(escape_helm_string "$message")" \
    --helm-set-string "maintenance.expectedBack=$(escape_helm_string "$expected_back")"
  sync_apps

  echo "Step 2/3: rejecting public backend and chat traffic while retaining health checks."
  argocd app set "$platform_app" --helm-set maintenance.rejectTraffic=true
  sync_apps

  echo "Step 3/3: stopping backend, chat, LiveOps, and worker workloads."
  argocd app set "$platform_app" --helm-set maintenance.stopServices=true
  sync_apps

  echo "Maintenance mode is active. Database maintenance can now begin."
}

leave_maintenance() {
  local confirmation

  echo "This will start game services, wait for health, and then restore the login page."
  read -r -p "Type 'MAINTENANCE' to continue: " confirmation
  if [[ "$confirmation" != "MAINTENANCE" ]]; then
    echo "Confirmation did not match. Nothing was changed."
    exit 1
  fi

  echo "Step 1/2: starting backend, chat, LiveOps, and worker workloads while traffic remains rejected."
  argocd app set "$platform_app" --helm-set maintenance.stopServices=false
  sync_apps

  echo "Step 2/2: restoring traffic and normal frontend routing by removing temporary overrides."
  argocd app unset "$platform_app" \
    -p maintenance.pageEnabled \
    -p maintenance.rejectTraffic \
    -p maintenance.stopServices \
    -p maintenance.message \
    -p maintenance.expectedBack
  sync_apps

  echo "Maintenance mode is disabled and game services are healthy."
}

if (( $# < 1 )); then
  usage
  exit 1
fi

action="$1"
shift

preflight

case "$action" in
  enter)
    if (( $# > 2 )); then
      usage
      exit 1
    fi
    enter_maintenance "${1:-}" "${2:-}"
    ;;
  leave)
    if (( $# != 0 )); then
      usage
      exit 1
    fi
    leave_maintenance
    ;;
  *)
    usage
    exit 1
    ;;
esac
