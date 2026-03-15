```JSON
{
  "docker"{
    "image": "nxdun/cloudflare-warp-proxy:latest",
    "size": "34 MB",
    "description": "Docker image to run Cloudflare Warp in proxy mode.",
    "features": [
      "Multi step build to reduce image size. approx 120MB.",
      "uses busybox as base image.",
    ]
  }
}
```
Docker image to run Cloudflare Warp in proxy mode.

- Multi step build to reduce image size. approx 33MB.
- uses busybox as base image.
- Recreate Trigger

## Usage

### docker hub image
```
docker run -d -p 40000:40000 --restart unless-stopped nxdun/cloudflare-warp-proxy
```

SOCKS5 proxy server will be listening at port 40000.

### docker-compose

```yaml
services:
  cloudflare-warp-proxy:
    image: nxdun/cloudflare-warp-proxy
    network_mode: bridge
    ports:
      - 40000:40000
    restart: unless-stopped
    environment:
      - LICENSE='cute-license-key' # use your own key, for example zero trust or warp+

```

## test

```bash
curl https://www.cloudflare.com/cdn-cgi/trace/ -x socks5h://127.1:40000  # remote dns mode

# or

curl https://www.cloudflare.com/cdn-cgi/trace/ -x socks5://127.1:40000  # local dns mode

# or

curl https://www.cloudflare.com/cdn-cgi/trace/ -x http://127.1:40000  # http mode

```

```bash
...
sni=plaintext
warp=on
# 👆 warp is on !!!
gateway=off
...
```
