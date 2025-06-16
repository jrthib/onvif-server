#!/bin/sh
set -e

CONFIG=/config/go2rtc.yaml
mkdir -p /config


# Generate go2rtc config
echo "streams:" > "$CONFIG"
if [ -n "$STREAMS" ]; then
  # STREAMS should be semicolon-separated list of name=url pairs
  echo "$STREAMS" | tr ';' '\n' | while IFS='=' read -r name url; do
    echo "  $name: $url" >> "$CONFIG"
  done
else
  echo "  ${CAM_NAME:-camera}: ${RTSP_URL}" >> "$CONFIG"
fi

cat >> "$CONFIG" <<CFG
api:
  listen: ":$ONVIF_PORT"
CFG

exec "$@" -config "$CONFIG"
