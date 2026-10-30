#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-groupos-system}"
POD="${2:-}"
BACKUP_NAME="${3:-groupos-storage-test}"
MOUNT_PATH="${4:-/data}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/Documents/LOCAL_PROJECT/GroupOS/infrastructure/.local/backups/storage}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

if [[ -z "$POD" ]]; then
  echo "Usage: $0 <namespace> <pod-name> [backup-name] [mount-path]"
  exit 1
fi

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE="$BACKUP_DIR/${BACKUP_NAME}_${TIMESTAMP}.tar.gz"
TEMP_ARCHIVE="${ARCHIVE}.partial"

trap 'rm -f "$TEMP_ARCHIVE"' EXIT

echo "Backing up $NAMESPACE/$POD:$MOUNT_PATH"

kubectl exec -n "$NAMESPACE" "$POD" -- \
  tar -czf - -C "$MOUNT_PATH" . > "$TEMP_ARCHIVE"

tar -tzf "$TEMP_ARCHIVE" >/dev/null
mv "$TEMP_ARCHIVE" "$ARCHIVE"
chmod 600 "$ARCHIVE"

shasum -a 256 "$ARCHIVE" > "${ARCHIVE}.sha256"
chmod 600 "${ARCHIVE}.sha256"

echo "PASS: backup created: $ARCHIVE"

# Retensi hanya berlaku pada arsip dengan nama backup ini.
find "$BACKUP_DIR" -type f \
  -name "${BACKUP_NAME}_*.tar.gz" \
  -mtime +"$RETENTION_DAYS" \
  -delete

find "$BACKUP_DIR" -type f \
  -name "${BACKUP_NAME}_*.tar.gz.sha256" \
  -mtime +"$RETENTION_DAYS" \
  -delete

echo "Backup completed."
