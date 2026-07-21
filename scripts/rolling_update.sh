#!/usr/bin/env bash
# rolling_update.sh <container_name> <new_image> <health_url> [timeout_seconds]
# Starts new container alongside old one, waits for health check,
# then stops old. Aborts and leaves old running if health check times out.
set -euo pipefail

CONTAINER="${1:?container name required}"
NEW_IMAGE="${2:?new image required}"
HEALTH_URL="${3:?health URL required}"
TIMEOUT="${4:-60}"
NEW_CONTAINER="${CONTAINER}-new"

# Capture old container's network and env so new container is identical
NETWORK=$(docker inspect "${CONTAINER}" \
  --format '{{range $k, $_ := .NetworkSettings.Networks}}{{$k}}{{end}}')
ENV_ARGS=$(docker inspect "${CONTAINER}" \
  --format '{{range .Config.Env}}-e "{{.}}" {{end}}')
PORT_ARGS=$(docker inspect "${CONTAINER}" \
  --format '{{range $p, $b := .HostConfig.PortBindings}}{{range $b}}-p {{.HostPort}}:{{$p}} {{end}}{{end}}' \
  | sed 's|/tcp||g')

echo "==> Starting ${NEW_CONTAINER} from ${NEW_IMAGE}"
# shellcheck disable=SC2086
docker run -d \
  --name "${NEW_CONTAINER}" \
  --network "${NETWORK}" \
  ${ENV_ARGS} \
  ${PORT_ARGS} \
  "${NEW_IMAGE}"

echo "==> Waiting up to ${TIMEOUT}s for ${HEALTH_URL}"
DEADLINE=$(( $(date +%s) + TIMEOUT ))
until curl -sf "${HEALTH_URL}" >/dev/null 2>&1; do
  if (( $(date +%s) >= DEADLINE )); then
    echo "ERROR: health check timed out — aborting, old container left running."
    docker rm -f "${NEW_CONTAINER}" || true
    exit 1
  fi
  sleep 2
done

echo "==> Healthy. Swapping ${NEW_CONTAINER} -> ${CONTAINER}"
docker stop "${CONTAINER}"
docker rm   "${CONTAINER}"
docker rename "${NEW_CONTAINER}" "${CONTAINER}"
echo "==> Done."
