# onvif-server

This project provides a lightweight Docker image that proxies RTSP streams from Eufy cameras to **ONVIF** so that platforms such as UniFi Protect can adopt them as regular cameras.

The container bundles the [go2rtc](https://github.com/AlexxIT/go2rtc) application which exposes RTSP and ONVIF endpoints. You can publish one or many streams from a single container by providing a stream list via the `STREAMS` environment variable. Running separate containers per camera is still possible and may simplify networking.

## Features

- Pulls a remote RTSP stream and exposes it via ONVIF
- Minimal configuration via environment variables
- Small image size built from `alpine`

## Quick start

```bash
# Example environment for single stream
CAM_NAME=front
RTSP_URL=rtsp://user:pass@eufy-camera.local/live0

# build image
docker build -t onvif-server .

# create a macvlan network (only once)
docker network create -d macvlan \
  --subnet=192.168.50.0/24 \
  --gateway=192.168.50.1 \
  -o parent=eth0 cams

# run container with a unique MAC address on the macvlan network
docker run -d \
  --name $CAM_NAME \
  --network cams \
  --ip 192.168.50.10 \
  --mac-address 02:42:c0:a8:32:0a \
  --env CAM_NAME=$CAM_NAME \
  --env RTSP_URL=$RTSP_URL \
  onvif-server
```

To expose multiple cameras from a single container use the `STREAMS` variable to
provide a semicolon-separated list of `name=url` pairs:

```bash
# Example for two cameras
STREAMS="front=rtsp://user:pass@eufy-front.local/live0;back=rtsp://user:pass@eufy-back.local/live0"

docker run -d \
  --name cameras \
  --network host \
  --env STREAMS="$STREAMS" \
  onvif-server
```

Point UniFi Protect at the container's ONVIF service (default port `1984`) and it will detect a camera named after `CAM_NAME`.

## Multiple cameras

Run additional containers with different names and MAC addresses or define several streams in one container. The example below uses a `macvlan` network so each container appears as a unique device on the LAN. Create the network once and then start your containers:

```bash
docker network create -d macvlan \
  --subnet=192.168.50.0/24 \
  --gateway=192.168.50.1 \
  -o parent=eth0 cams
```

```yaml
version: '3'
services:
  front:
    build: .
    networks:
      cams:
        ipv4_address: 192.168.50.10
    mac_address: "02:42:c0:a8:32:0a"
    environment:
      - CAM_NAME=front
      - RTSP_URL=rtsp://user:pass@eufy-front.local/live0
  back:
    build: .
    networks:
      cams:
        ipv4_address: 192.168.50.11
    mac_address: "02:42:c0:a8:32:0b"
    environment:
      - CAM_NAME=back
      - RTSP_URL=rtsp://user:pass@eufy-back.local/live0

networks:
  cams:
    external: true
```

Each service exposes its own ONVIF device that UniFi Protect can adopt separately.

## Configuration options

* `CAM_NAME` – Name for a single stream (defaults to `camera`)
* `RTSP_URL` – Full RTSP URL to the Eufy camera (single stream mode)
* `STREAMS` – Semicolon-separated list of `name=url` pairs for multi-stream mode
* `ONVIF_PORT` – Optional, default `1984`

## How it works

`go2rtc` automatically publishes an ONVIF service alongside the configured stream. The container entrypoint generates a simple `go2rtc.yaml` file from the environment variables and then launches `go2rtc`.

