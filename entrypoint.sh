#!/bin/sh
set -eu

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

# Fail fast
socat TCP-LISTEN:40000,fork TCP:localhost:40001 &
socat_pid=$!
wait -n "$warp_svc_pid" "$socat_pid"

# alias
alias warp-cli='warp-cli --accept-tos'
alias wc='warp-cli --accept-tos'
exit 1

