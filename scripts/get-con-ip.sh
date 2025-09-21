#!/bin/bash
set -xeuo pipefail

PROXMOX_HOST="$1"
SSH_PORT="$2"
SSH_USER="$3"
SSH_KEY="$4"
CONTAINER_ID="$5"

IP=$(ssh -i "${SSH_KEY}" -p "${SSH_PORT}" -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null "${SSH_USER}@${PROXMOX_HOST}" \
    "sudo pct exec ${CONTAINER_ID} -- hostname -I | awk '{print $1}'" | tr -d '\r\n')

jq -n --arg ip "${IP}" '{ ip: $ip }'