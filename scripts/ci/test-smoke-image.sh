#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-localhost/groupos-infra-smoke:ci-test}"
CONTAINER_NAME="groupos-smoke-ci-$$"
HOST_PORT="18081"

cleanup() {
  podman rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "=== Starting smoke container ==="

podman run -d \
  --name "$CONTAINER_NAME" \
  -p "127.0.0.1:${HOST_PORT}:8080" \
  "$IMAGE"

echo "=== Testing HTTP endpoint ==="

SUCCESS=0

for i in $(seq 1 30); do
  if curl --fail --silent \
    "http://127.0.0.1:${HOST_PORT}/" \
    | grep -q "GroupOS Infrastructure Ready"; then
    SUCCESS=1
    break
  fi

  sleep 1
done

if [[ "$SUCCESS" -ne 1 ]]; then
  podman logs "$CONTAINER_NAME"
  echo "FAIL: HTTP smoke test failed"
  exit 1
fi

echo "PASS: HTTP smoke test successful"
