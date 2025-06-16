FROM alpine:3.20

RUN apk add --no-cache curl

# install go2rtc
RUN set -eux; \
    arch=$(uname -m); \
    case "$arch" in \
      x86_64)  bin="go2rtc_linux_amd64" ;; \
      aarch64) bin="go2rtc_linux_arm64" ;; \
      arm*)    bin="go2rtc_linux_arm" ;; \
      *) echo "unsupported arch $arch" && exit 1 ;; \
    esac; \
    curl -L -o /usr/local/bin/go2rtc "https://github.com/AlexxIT/go2rtc/releases/latest/download/${bin}"; \
    chmod +x /usr/local/bin/go2rtc

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV CAM_NAME=camera
ENV RTSP_URL=
ENV STREAMS=
ENV ONVIF_PORT=1984

EXPOSE 1984 8554 8555

ENTRYPOINT ["/entrypoint.sh"]
CMD ["go2rtc"]
