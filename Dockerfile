ARG DEBIAN_RELEASE=bullseye
ARG LICENSE=

FROM docker.io/debian:$DEBIAN_RELEASE-slim AS builder
ARG DEBIAN_RELEASE
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg ca-certificates curl binutils && \
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    ARCH="$(dpkg --print-architecture)" && \
    echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $DEBIAN_RELEASE main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends cloudflare-warp

RUN set -eu && \
    mkdir -p /out && \
    for bin in /bin/warp-cli /bin/warp-svc; do \
        real_bin="$(readlink -f "$bin")"; \
        strip --strip-unneeded "$real_bin" || true; \
        cp -v --parents "$bin" "$real_bin" /out/; \
        ldd "$real_bin" 2>/dev/null | awk '/=>/ {print $3} /^[[:space:]]*\// {print $1}' | grep -E '^/' | xargs -r -I{} cp -vn --parents "{}" /out/ || true; \
    done && \
    find /out/lib /out/usr/lib -type f -name '*.so*' -exec strip --strip-unneeded {} + 2>/dev/null || true && \
    if [ -d /usr/lib/cloudflare-warp ]; then cp -a --parents /usr/lib/cloudflare-warp /out/; fi && \
    mkdir -p /out/etc/ssl/certs && \
    cp -v /etc/ssl/certs/ca-certificates.crt /out/etc/ssl/certs/ && \
    mkdir -p /out/lib/x86_64-linux-gnu && \
    cp -vn /lib/x86_64-linux-gnu/libnss_dns.so.* /out/lib/x86_64-linux-gnu/ || true && \
    cp -vn /lib/x86_64-linux-gnu/libresolv.so.* /out/lib/x86_64-linux-gnu/ || true

FROM docker.io/busybox:1.36.1-uclibc
ARG LICENSE
ENV LICENSE=${LICENSE}

COPY entrypoint.sh /
COPY --from=builder /out/ /
RUN chmod +x /entrypoint.sh

EXPOSE 40000/tcp
ENTRYPOINT [ "/entrypoint.sh" ]
