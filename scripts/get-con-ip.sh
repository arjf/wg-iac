#!/bin/bash
set -xeuo pipefail

PROXMOX_HOST="$1"
SSH_PORT="$2"
SSH_USER="$3"
SSH_KEY="$4"
CONTAINER_ID="$5"

CMD="sudo pct exec ${CONTAINER_ID} -- ip -4 -o addr show dev eth0 | awk '{print \$4}' | cut -d/ -f1"

IP=$(ssh -i "${SSH_KEY}" -p "${SSH_PORT}" -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PROXMOX_HOST}" $CMD)

echo "${IP}"
