#!/usr/bin/env bash
# rolling_update.sh <container_name> <new_image> <health_url> [timeout_seconds]
# Starts new container without host port bindings, waits for health,
# then stops old container and recreates new one with original host ports.
set -euo pipefail

CONTAINER="${1:?container name required}"
NEW_IMAGE="${2:?new image required}"
HEALTH_URL="${3:?health URL required}"
TIMEOUT="${4:-60}"
NEW_CONTAINER="${CONTAINER}-new"

# Capture old container's config
NETWORK=$(docker inspect "${CONTAINER}" \
  --format '{{range $k, $_ := .NetworkSettings.Networks}}{{$k}}{{end}}')
ENV_ARGS=$(docker inspect "${CONTAINER}" \
  --format '{{range .Config.Env}}-e "{{.}}" {{end}}')
PORT_ARGS=$(docker inspect "${CONTAINER}" \
  --format '{{range $p, $b := .HostConfig.PortBindings}}{{range $b}}-p {{.HostPort}}:{{$p}} {{end}}{{end}}' \
  | sed 's|/tcp||g')
SERVICE_PORT=$(docker inspect "${CONTAINER}" \
  --format '{{range $p, $_ := .HostConfig.PortBindings}}{{$p}}{{end}}' \
  | sed 's|/tcp||g')
HEALTH_PATH="/${HEALTH_URL#*://*/}"

echo "==> Starting ${NEW_CONTAINER} from ${NEW_IMAGE} (no host ports)"
# shellcheck disable=SC2086
docker run -d \
  --name "${NEW_CONTAINER}" \
  --network "${NETWORK}" \
  ${ENV_ARGS} \
  "${NEW_IMAGE}"

echo "==> Waiting up to ${TIMEOUT}s for ${NEW_CONTAINER} to be healthy"
DEADLINE=$(( $(date +%s) + TIMEOUT ))
sleep 2

until docker exec "${NEW_CONTAINER}" \
  python -c "import urllib.request; urllib.request.urlopen('http://localhost:${SERVICE_PORT}${HEALTH_PATH}')" \
  >/dev/null 2>&1; do
  if (( $(date +%s) >= DEADLINE )); then
    echo "ERROR: health check timed out — aborting, old container left running."
    docker logs "${NEW_CONTAINER}" || true
    docker rm -f "${NEW_CONTAINER}" || true
    exit 1
  fi
  sleep 2
done

echo "==> Healthy. Swapping ${NEW_CONTAINER} -> ${CONTAINER}"
docker stop "${CONTAINER}"
docker rm   "${CONTAINER}"
docker rm   "${NEW_CONTAINER}"

# shellcheck disable=SC2086
docker run -d \
  --name "${CONTAINER}" \
  --network "${NETWORK}" \
  ${ENV_ARGS} \
  ${PORT_ARGS} \
  "${NEW_IMAGE}"

echo "==> Done."
