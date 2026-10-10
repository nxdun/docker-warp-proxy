```json
{
  "docker": {
    "image": "nxdun/cloudflare-warp-proxy:latest",
    "size": "40 MB",
    "description": "Docker image to run Cloudflare Warp in proxy mode.",
    "features": [
      "Multi step build to reduce image size.",
      "uses busybox as base image."
    ]
  }
}
```
Docker image to run Cloudflare Warp in proxy mode.

- Multi step build to reduce image size. approx 40MB.
- uses busybox as base image.
- Recreate Trigger

## Usage

### docker hub image
```bash
docker run -d --cap-add=NET_ADMIN -p 40000:40000 --restart unless-stopped nxdun/cloudflare-warp-proxy
```

> [!NOTE]
> `--cap-add=NET_ADMIN` is required for Cloudflare WARP to manage its network routing policies inside the container.

SOCKS5 proxy server will be listening at port 40000.

### docker-compose

```yaml
services:
  cloudflare-warp-proxy:
    image: nxdun/cloudflare-warp-proxy
    network_mode: bridge
    cap_add:
      - NET_ADMIN
    ports:
      - 40000:40000
    restart: unless-stopped
    environment:
      - LICENSE='cute-license-key' # use your own key, for example zero trust or warp+
```

## test

```bash
curl https://www.cloudflare.com/cdn-cgi/trace -x socks5h://127.1:40000  # remote dns mode

# or

curl https://www.cloudflare.com/cdn-cgi/trace -x socks5://127.1:40000  # local dns mode

# or

curl https://www.cloudflare.com/cdn-cgi/trace -x http://127.1:40000  # http mode

```

```bash
...
sni=plaintext
warp=on
# 👆 warp is on !!!
gateway=off
...
```
