#!/bin/sh
set -eu

warp-svc &
warp_svc_pid=$!

cleanup() {
	>&2 echo "Received termination signal, shutting down..."
	kill -TERM "${socat_pid:-}" "$warp_svc_pid" 2>/dev/null || true
	wait "$warp_svc_pid" 2>/dev/null || true
	exit 0
}
trap cleanup TERM INT

max_retries=30
retries=0

while ! warp-cli --accept-tos status >/dev/null 2>&1; do
	sleep 1
	>&2 echo "Awaiting warp-svc become online..."
	retries=$((retries + 1))
	if [ "$retries" -ge "$max_retries" ]; then
		>&2 echo "Timeout waiting for warp-svc to become online."
		>&2 echo "Ensure container has '--cap-add=NET_ADMIN' capability."
		exit 1
	fi
done

if ! warp-cli --accept-tos registration show >/dev/null 2>&1; then
	warp-cli --accept-tos registration new
fi

warp-cli --accept-tos mode proxy
warp-cli --accept-tos proxy port 40001

if [ -n "${LICENSE:-}" ]; then
	warp-cli --accept-tos registration license "$LICENSE"
fi

warp-cli --accept-tos connect

# Fail fast
socat TCP-LISTEN:40000,fork TCP:127.0.0.1:40001 &
socat_pid=$!
wait -n "$warp_svc_pid" "$socat_pid"

exit 1
