FROM ghcr.io/home-assistant/amd64-base:3.24

RUN apk add --no-cache \
    coturn \
    bind-tools

RUN turnserver --version

COPY detect-external-ip.sh /usr/local/bin/detect-external-ip
RUN chmod +x /usr/local/bin/detect-external-ip

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
