#!/bin/bash

set -eu

ENV_FILE="cloudflared/cloudflared.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Env file not found: $ENV_FILE" >&2
  exit 1
fi

# Argument Parsing
dry_run=false
debug=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        -d|--dry-run)
            dry_run=true
            shift
            ;;
        -e|--debug)
            debug=true
            shift
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

if [ -z "${CF_USE-}" ] || [ "$CF_USE" != "true" ]; then
  echo "Warn: Cloudflared is not enabled. Set CF_USE=true in cloudflared.env to enable." >&2
  exit 0
fi

if [ "$dry_run" = true ]; then
    echo "INFO: Dry run, skipping cloudflared start"
    exit 0
fi

LOG_LEVEL="info"
if [ "$debug" = true ]; then
    set -x
    LOG_LEVEL="debug"
fi

if ! curl -s -o /dev/null -w "%{http_code}" \
     -H "CF-Access-Client-Id: $CF_SRV_ID" \
     -H "CF-Access-Client-Secret: $CF_SRV_SECRET" \
     -I "$CF_REMOTE_HOST" | grep -qE "^2[0-9][0-9]$"; then
    echo "Warn: CF Access check failed. Credentials or host may be invalid." >&2
fi

start_tunn(){
    nohup cloudflared access tcp \
        --hostname "$CF_REMOTE_HOST" \
        --service-token-id "$CF_SRV_ID" \
        --service-token-secret "$CF_SRV_SECRET" \
        --loglevel $LOG_LEVEL --logfile ./cfd.log \
        --url "localhost:${CF_LOCAL_PORT:-1080}" > cf.log 2>&1 &

    echo $! > cf.pid

    for i in $(seq 1 30); do
        if ss -ltn | grep -q ":${CF_LOCAL_PORT:-1080}\b"; then
            echo "INFO: cloudflared listening on ${CF_LOCAL_PORT:-1080}"
            break
        fi
        sleep 1
    done

    if ! ss -ltn | grep -q ":${CF_LOCAL_PORT:-1080}\b"; then
        echo "ERROR: cloudflared failed to start on port ${CF_LOCAL_PORT:-1080}" >&2
        exit 1
    fi
}

start_tunn