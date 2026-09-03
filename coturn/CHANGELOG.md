# Changelog

## v1.0~1.0.5

- Added 'environment versions' in the log output for further reference if any required
- Alpine 3.24 based
- Detection of external IP via `detect-external-ip`
- Full config can be done in `/config/turnserver.conf` (https://github.com/coturn/coturn/blob/master/examples/etc/turnserver.conf)
- SSL certs are read from `/ssl/coturn` (for TLS setup)
