# Coturn TURN Server — Home Assistant Add-on

A Home Assistant add-on wrapping [coturn](https://github.com/coturn/coturn), a production-grade TURN/STUN server for NAT traversal.

## What is TURN/STUN?

TURN (Traversal Using Relays around NAT) and STUN (Session Traversal Utilities for NAT) are protocols used by WebRTC to establish peer-to-peer connections through firewalls and NAT routers.

**Common use cases in Home Assistant:**
- WebRTC camera streams (go2rtc, Frigate, HA WebRTC integration)
- Voice assistants with peer-to-peer audio
- Any WebRTC-based communication

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. Click the three-dot menu (⋮) → **Repositories**.
3. Add your repository URL (where this add-on lives).
4. Find **Coturn TURN Server** and click **Install**.

## Configuration

| Option | Default | Description |
|---|---|---|
| `listening_port` | `3478` | TURN/STUN listening port (TCP + UDP) |
| `tls_port` | `5349` | TLS/DTLS listening port |
| `min_port` | `49152` | Start of relay UDP port range |
| `max_port` | `65535` | End of relay UDP port range |
| `realm` | `homeassistant.local` | Your domain or hostname |
| `username` | `homeassistant` | TURN credential username |
| `password` | `changeme` | TURN credential password — **change this!** |
| `external_ip` | _(empty)_ | Your public IP. Leave empty to auto-detect. |
| `detect_external_ip` | `true` | Auto-detect public IP at startup |
| `no_tls` | `true` | Disable TLS (set false if you have certs) |
| `no_dtls` | `true` | Disable DTLS |
| `cli_disabled` | `true` | Disable Coturn CLI interface |

Please note that `use-auth-secret` (Nextcloud/REST) and `lt-cred-mech` (username/password) are mutually exclusive — coturn does not support both at the same time:
- static_auth_secret is set → uses --use-auth-secret only (Nextcloud mode). The username/password fields are ignored.
- static_auth_secret is empty → uses --lt-cred-mech with username/password (HA WebRTC mode).

## Networking

This add-on uses **host networking** (required for TURN servers — Docker NAT performs poorly across the large relay port range).

Make sure the following are open in your router/firewall:

| Port | Protocol | Purpose |
|---|---|---|
| `3478` | TCP + UDP | STUN/TURN |
| `5349` | TCP + UDP | TURNS (TLS) |
| `49152–65535` | UDP | Media relay |

## Using with Home Assistant WebRTC

In your `configuration.yaml` or go2rtc config, point your ICE servers to this add-on:

```yaml
# Example for go2rtc
webrtc:
  ice_servers:
    - urls: turn:<YOUR_HA_IP>:3478
      username: homeassistant
      credential: changeme
```

## Reducing the Relay Port Range

If you want to open fewer firewall ports, reduce the range in the add-on config:

```yaml
min_port: 49152
max_port: 49300
```

This limits relay connections but uses far fewer ports.

## Security Notes

- Always change the default `password`.
- If exposing to the internet, consider enabling TLS (`no_tls: false`) with a valid certificate.
- The `realm` should match your domain for TLS setups.


## Before testing with a real domain, checklist:

- Open your router firewall for ports 3478 TCP+UDP and 5349 TCP+UDP inbound to `local IP`, plus UDP 49152–49300
- Enable TLS with a Let's Encrypt cert for your domain for CoTURN (port 5349)
- Change the default password in the add-on config from changeme to something strong
- Set your realm to your actual domain name (e.g. turn.yourdomain.com) and point an A record at `external IP`
- For proper external testing, use the Trickle ICE page with `turn:external IP (or internal IP):3478` or `turn:yourdomain.com:3478` — you should see relay candidates coming from your public IP (this is for turn, for turn(s) which stands for secure use port :5349)