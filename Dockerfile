ARG DEBIAN_RELEASE=bookworm
ARG LICENSE=

FROM docker.io/debian:$DEBIAN_RELEASE-slim AS builder
ARG DEBIAN_RELEASE
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg ca-certificates curl binutils socat && \
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    ARCH="$(dpkg --print-architecture)" && \
    echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $DEBIAN_RELEASE main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends cloudflare-warp

RUN set -eu && \
    mkdir -p /out/bin && \
    for bin in /usr/bin/warp-cli /usr/bin/warp-svc /usr/bin/socat; do \
    strip --strip-unneeded "$bin" || true; \
    cp -v --parents "$bin" /out/; \
    ldd "$bin" 2>/dev/null | awk '/=>/ {print $3} /^[[:space:]]*\// {print $1}' | grep -E '^/' | xargs -r -I{} cp -vn --parents "{}" /out/ || true; \
    done && \
    ln -sf /usr/bin/warp-cli /out/bin/warp-cli && \
    ln -sf /usr/bin/warp-svc /out/bin/warp-svc && \
    find /out/lib /out/usr/lib -type f -name '*.so*' -exec strip --strip-unneeded {} + 2>/dev/null || true && \
    if [ -d /usr/lib/cloudflare-warp ]; then cp -a --parents /usr/lib/cloudflare-warp /out/; fi && \
    mkdir -p /out/etc/ssl/certs && \
    cp -v /etc/ssl/certs/ca-certificates.crt /out/etc/ssl/certs/ && \
    for arch_dir in /lib/*-linux-gnu; do \
        if [ -d "$arch_dir" ]; then \
            mkdir -p "/out${arch_dir}" && \
            cp -vn "$arch_dir"/libnss_dns.so.* "/out${arch_dir}/" || true && \
            cp -vn "$arch_dir"/libresolv.so.* "/out${arch_dir}/" || true; \
        fi; \
    done

FROM docker.io/busybox:1.36.1-uclibc
ARG LICENSE
ENV LICENSE=${LICENSE}

COPY entrypoint.sh /
COPY --from=builder /out/ /
RUN chmod +x /entrypoint.sh

EXPOSE 40000/tcp

HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
    CMD warp-cli --accept-tos status | grep -q 'Connected' && nc -z -w 2 127.0.0.1 40000 || exit 1

ENTRYPOINT [ "/entrypoint.sh" ]