ARG DEBIAN_RELEASE=bullseye
ARG LICENSE=

FROM docker.io/debian:$DEBIAN_RELEASE-slim AS builder
ARG DEBIAN_RELEASE
ENV DEBIAN_FRONTEND=noninteractive

RUN true && \
	apt update && \
	apt install -y gnupg ca-certificates curl socat

RUN	curl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
	ARCH="$(dpkg --print-architecture)" && \
	echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/  $DEBIAN_RELEASE main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
	apt update && \
	apt install cloudflare-warp -y --no-install-recommends

RUN	set -euo pipefail && \
	mkdir -p /out && \
	for bin in /usr/bin/warp-cli /usr/bin/warp-svc /usr/bin/socat; do \
		cp -v --parents "$bin" /out/; \
		ldd "$bin" | awk '/=>/ {print $3} /^[[:space:]]*\// {print $1}' | grep -E '^/' | xargs -r -I{} cp -v --parents "{}" /out/; \
	done && \
	mkdir -p /out/etc/ssl/certs && \
	cp -v /etc/ssl/certs/ca-certificates.crt /out/etc/ssl/certs/

FROM docker.io/debian:$DEBIAN_RELEASE-slim
ARG LICENSE
ENV LICENSE=${LICENSE}

COPY entrypoint.sh /
COPY --from=builder /out/ /
RUN chmod +x /entrypoint.sh

EXPOSE 40000/tcp
ENTRYPOINT [ "/entrypoint.sh" ]
