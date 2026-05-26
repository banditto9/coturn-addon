# Pull coturn 4.12 binaries
FROM ghcr.io/coturn/coturn:4.12-alpine3.23 AS coturn

# Home Assistant Add-on base image
FROM ghcr.io/home-assistant/amd64-base:3.23

# Copy coturn binaries from official image
COPY --from=coturn /usr/bin/turnserver /usr/bin/turnserver
COPY --from=coturn /usr/bin/turnadmin /usr/bin/turnadmin
COPY --from=coturn /usr/lib/coturn /usr/lib/coturn

# Install DNS utilities (bind-tools still from apk)
RUN apk add --no-cache bind-tools

# Optional: show installed Coturn version during build
RUN turnserver --version

# Bundle external IP detection helper
COPY detect-external-ip.sh /usr/local/bin/detect-external-ip
RUN chmod +x /usr/local/bin/detect-external-ip

# Copy entrypoint script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
