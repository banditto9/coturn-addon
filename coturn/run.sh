#!/usr/bin/with-contenv bashio

# Read config values from Home Assistant add-on options
LISTENING_PORT=$(bashio::config 'listening_port')
TLS_PORT=$(bashio::config 'tls_port')
MIN_PORT=$(bashio::config 'min_port')
MAX_PORT=$(bashio::config 'max_port')
REALM=$(bashio::config 'realm')
USERNAME=$(bashio::config 'username')
PASSWORD=$(bashio::config 'password')
STATIC_AUTH_SECRET=$(bashio::config 'static_auth_secret')
EXTERNAL_IP=$(bashio::config 'external_ip')
DETECT_EXTERNAL_IP=$(bashio::config 'detect_external_ip')
LOG_FILE=$(bashio::config 'log_file')
NO_TLS=$(bashio::config 'no_tls')
NO_DTLS=$(bashio::config 'no_dtls')
CERTFILE=$(bashio::config 'certfile')
KEYFILE=$(bashio::config 'keyfile')
CLI_DISABLED=$(bashio::config 'cli_disabled')

CUSTOM_CONF="/homeassistant/turnserver.conf"

# If a custom config file exists, use it directly and skip option-building
if [ -f "${CUSTOM_CONF}" ]; then
    bashio::log.info "Found custom config at ${CUSTOM_CONF} — using it directly."
    exec turnserver -c "${CUSTOM_CONF}"
fi

bashio::log.info "Starting Coturn TURN Server..."
bashio::log.info "Listening on port: ${LISTENING_PORT} (TCP/UDP)"
bashio::log.info "Relay ports: ${MIN_PORT}-${MAX_PORT}"

# Build the turnserver command
CMD="turnserver"
CMD="${CMD} --listening-port=${LISTENING_PORT}"
CMD="${CMD} --tls-listening-port=${TLS_PORT}"
CMD="${CMD} --min-port=${MIN_PORT}"
CMD="${CMD} --max-port=${MAX_PORT}"
CMD="${CMD} --realm=${REALM}"
CMD="${CMD} --fingerprint"
CMD="${CMD} --no-multicast-peers"
CMD="${CMD} --log-file=${LOG_FILE}"

# Auth: use-auth-secret (Nextcloud/REST) and lt-cred-mech (username/password)
# are mutually exclusive — coturn does not support both at the same time.
if [ -n "${STATIC_AUTH_SECRET}" ]; then
    bashio::log.info "Auth mode: shared secret (Nextcloud / REST API compatible)"
    CMD="${CMD} --use-auth-secret"
    CMD="${CMD} --static-auth-secret=${STATIC_AUTH_SECRET}"
else
    bashio::log.info "Auth mode: long-term credentials (username/password)"
    CMD="${CMD} --lt-cred-mech"
    CMD="${CMD} --user=${USERNAME}:${PASSWORD}"
fi

# TLS configuration — certs synced by rclone to /ssl/coturn/
if bashio::var.true "${NO_TLS}"; then
    bashio::log.info "TLS disabled"
    CMD="${CMD} --no-tls"
else
    CERT_PATH="/ssl/${CERTFILE}"
    KEY_PATH="/ssl/${KEYFILE}"
    if [ -f "${CERT_PATH}" ] && [ -f "${KEY_PATH}" ]; then
        bashio::log.info "TLS enabled using: ${CERT_PATH}"
        CMD="${CMD} --cert=${CERT_PATH}"
        CMD="${CMD} --pkey=${KEY_PATH}"
    else
        bashio::log.warning "TLS cert not found at ${CERT_PATH}"
        bashio::log.warning "Make sure rclone has synced certs to /ssl/coturn/ before starting."
        CMD="${CMD} --no-tls"
    fi
fi

# DTLS uses the same certs as TLS
if bashio::var.true "${NO_DTLS}"; then
    CMD="${CMD} --no-dtls"
else
    CERT_PATH="/ssl/${CERTFILE}"
    KEY_PATH="/ssl/${KEYFILE}"
    if [ -f "${CERT_PATH}" ] && [ -f "${KEY_PATH}" ]; then
        bashio::log.info "DTLS enabled"
    else
        CMD="${CMD} --no-dtls"
    fi
fi

if bashio::var.true "${CLI_DISABLED}"; then
    CMD="${CMD} --no-cli"
    CMD="${CMD} --cli-password=disabled"
fi

# External IP handling
if bashio::var.true "${DETECT_EXTERNAL_IP}"; then
    bashio::log.info "Auto-detecting external IP..."
    DETECTED_IP=$(detect-external-ip 2>/dev/null | head -1 | tr -d '[:space:]' || true)
    if [ -n "${DETECTED_IP}" ]; then
        bashio::log.info "Detected external IP: ${DETECTED_IP}"
        CMD="${CMD} --external-ip=${DETECTED_IP}"
    else
        bashio::log.warning "Could not auto-detect external IP. You may need to set it manually."
    fi
elif [ -n "${EXTERNAL_IP}" ]; then
    CMD="${CMD} --external-ip=${EXTERNAL_IP}"
fi

bashio::log.info "Running: ${CMD}"
exec ${CMD}
