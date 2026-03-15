#!/bin/bash
set -euo pipefail

required_bins=(warp-cli warp-svc socat)
for bin in "${required_bins[@]}"; do
	if ! command -v "$bin" >/dev/null 2>&1; then
		>&2 echo "Missing required binary: $bin"
		exit 1
	fi
done

warp-svc &
warp_svc_pid=$!

while ! warp-cli --accept-tos registration new; do
	sleep 1
	>&2 echo "Awaiting warp-svc become online..."
done
warp-cli --accept-tos mode proxy
warp-cli --accept-tos proxy port 40001

if [ -n "${LICENSE:-}" ]; then
	warp-cli --accept-tos registration license "$LICENSE"
fi

warp-cli --accept-tos connect

# Fail fast if either process exits unexpectedly.
socat TCP-LISTEN:40000,fork TCP:localhost:40001 &
socat_pid=$!
wait -n "$warp_svc_pid" "$socat_pid"
exit 1


