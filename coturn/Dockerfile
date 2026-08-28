FROM ghcr.io/coturn/coturn:4.17.2-trixie

LABEL \
  io.hass.version="1.0.5" \
  io.hass.type="app" \
  io.hass.arch="amd64"

RUN apk add --no-cache \
    coturn \
    bind-tools

RUN turnserver --version

COPY detect-external-ip.sh /usr/local/bin/detect-external-ip
RUN chmod +x /usr/local/bin/detect-external-ip

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
