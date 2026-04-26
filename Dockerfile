FROM ghcr.io/home-assistant/amd64-base:latest

# Install coturn and dig (for external IP detection)
RUN apk add --no-cache coturn bind-tools

# Bundle the detect-external-ip helper
COPY detect-external-ip.sh /usr/local/bin/detect-external-ip
RUN chmod +x /usr/local/bin/detect-external-ip

# Copy the entrypoint script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
