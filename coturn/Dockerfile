ARG BUILD_FROM=ghcr.io/home-assistant/base:3.24
FROM $BUILD_FROM
ARG BUILD_FROM
ENV BASE_IMAGE=$BUILD_FROM

LABEL \
  io.hass.version="1.0.1" \
  io.hass.type="app" \
  io.hass.arch="amd64"

RUN apk add --no-cache \
    coturn \
    bind-tools

COPY detect-external-ip.sh /usr/local/bin/detect-external-ip
RUN chmod +x /usr/local/bin/detect-external-ip

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
