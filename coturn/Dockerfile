# Home Assistant Add-on base image
FROM ghcr.io/home-assistant/amd64-base:4.11.0-r0-alpine

# Install Coturn and DNS utilities
RUN apk add --no-cache \
    coturn \
    bind-tools

# Optional: show installed Coturn version during build
RUN turnserver --version

# Bundle external IP detection helper
COPY detect-external-ip.sh /usr/local/bin/detect-external-ip
RUN chmod +x /usr/local/bin/detect-external-ip

# Copy entrypoint script
COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
