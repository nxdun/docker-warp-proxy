#!/bin/sh
set -eu

warp-svc &
warp_svc_pid=$!


max_retries=30
retries=0 

while ! warp-cli --accept-tos registration new; do
	sleep 1
	>&2 echo "Awaiting warp-svc become online..."
	retries=$((retries + 1))
	if [ "$retries" -ge "$max_retries" ]; then
		>&2 echo "Timeout waiting for warp-svc to become online"
		exit 1
	fi
done

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
