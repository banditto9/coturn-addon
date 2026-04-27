# Coturn TURN Server — Home Assistant Add-on

A Home Assistant add-on wrapping [coturn](https://github.com/coturn/coturn), TURN/STUN server for NAT traversal.

## What is TURN/STUN?

TURN (Traversal Using Relays around NAT) and STUN (Session Traversal Utilities for NAT) are protocols used by WebRTC to establish peer-to-peer connections through firewalls and NAT routers. STUN/TURN may be useful for SIP VOIP calls as well and STUN can be used in Asterisk setup as well.

STUN is a very simple protocol:

1) Client sends a binding request to your server
2) Server replies with the client's public IP and port
3) No authentication, no encryption, no TLS needed
4) Works on plain UDP port 3478

So for STUN only you need just one port open: 3478 UDP
The only time you need TLS/SSL for STUN is if you use stuns: (STUN over TLS) — but virtually nobody uses that. Plain stun: on UDP 3478 is the universal standard and works everywhere including from HTTPS pages, because STUN is not HTTP traffic so browser mixed-content rules don't apply to it.

Summary of what needs SSL and what doesn't:


| Protocol | Port | SSL required or not |
|---|---|---|
|stun:|3478 UDP|❌|
|turn:|3478 TCP/UDP|❌ (unencrypted)|
|turns:|5349 TCP|✅|
|stuns:|5349|✅ (rare)|

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
| `max_port` | `49300` | End of relay UDP port range |
| `realm` | `homeassistant.local` | Your domain or hostname |
| `username` | `homeassistant` | TURN credential username |
| `password` | `changeme` | TURN credential password — **change this!** |
| `external_ip` | _(empty)_ | Your public IP. Leave empty to auto-detect. |
| `detect_external_ip` | `true` | Auto-detect public IP at startup |
| `no_tls` | `true` | Disable TLS (set false if you have certs) |
| `no_dtls` | `true` | Disable DTLS |
| `cli_disabled` | `true` | Disable Coturn CLI interface |

Please note that `use-auth-secret` (Nextcloud/REST) and `lt-cred-mech` (username/password) are mutually exclusive — coturn does not support both at the same time:
- `static_auth_secret` is set → uses `--use-auth-secret` only (Nextcloud mode). The username/password fields are ignored.
- `static_auth_secret` is empty → uses `--lt-cred-mech` with username/password (HA WebRTC mode).

## Networking

This add-on uses **host networking** (required for TURN servers — Docker NAT performs poorly across the large relay port range).

Make sure the following ports are opened/duly forwarded in your router:

| Port | Protocol | Purpose |
|---|---|---|
| `3478` | TCP + UDP | STUN/TURN |
| `5349` | TCP + UDP | TURNS (TLS) |
| `49152–49300` | UDP | Media relay |

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

## Security Notes

- Always change the default `password`.
- If exposing to the internet, consider enabling TLS (`no_tls: false`) with a valid certificate.
- The `realm` should match your domain for TLS setups.

## Certificate Setup

This add-on reads TLS certificates from `/ssl/coturn/` on your HA host. You are responsible for keeping this folder populated with valid certificates.

### Tip: rclone sync from Nginx Proxy Manager

If you use the NPM add-on for Let's Encrypt certificates, set up rclone to sync them hourly (for example):

**Source path (NPM stores certs here):**
```
/addon_configs/a0d7b954_nginxproxymanager/letsencrypt/live/npm-1/
```
> Note: `npm-1` is the certificate ID in NPM. Check your actual path — it stays stable across renewals as long as you don't delete and recreate the certificate.

**Destination path (where coturn reads from):**
```
/ssl/coturn/fullchain.pem
/ssl/coturn/privkey.pem
```

**HA Automation to restart coturn after cert sync** (add to `automations.yaml`):
```yaml
alias: "Restart Coturn after cert sync"
trigger:
  - platform: time_pattern
    hours: "/1"
    minutes: "10"
action:
  - service: hassio.addon_restart
    data:
      addon: local_coturn
```

## Before testing with a real domain, checklist:

- Open your router firewall for ports 3478 TCP+UDP and 5349 TCP+UDP inbound to `local IP`, plus UDP 49152–49300
- Enable TLS with a Let's Encrypt cert for your domain for CoTURN (port 5349)
- Change the default password in the add-on config from changeme to something strong
- Set your realm to your actual domain name (e.g. turn.yourdomain.com) and point an A record at `external IP`
- For proper external testing, use the Trickle ICE page with `turn:external IP (or internal IP):3478` or `turn:yourdomain.com:3478` — you should see relay candidates coming from your public IP (this is for turn, for turn(s) which stands for secure use port :5349)
