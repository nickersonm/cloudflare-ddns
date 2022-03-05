# cloudflare-ddns
Dynamic DNS with Cloudflare


## Description

POSIX shell script (also using `sed`); acquires current host's IP and updates specified Cloudflare DNS entries with the [Cloudflare API](https://api.cloudflare.com/#dns-records-for-a-zone-list-dns-records). Does not modify TTL or Proxy status.

## Install

Clone this repository or just download [`cloudflare-ddns.sh`](https://github.com/nickersonm/cloudflare-ddns/raw/main/cloudflare-ddns.sh) and configure.

Example:

```bash
wget https://raw.githubusercontent.com/nickersonm/cloudflare-ddns/main/cloudflare-ddns.sh
nano cloudflare-ddns.sh
```

## Configuration

Review and modify variable definitions in the **Definitions** section - minimal required changes are AUTH_KEY, DNS_ZONE, and DNS_RECORDS

```bash
# Definitions
## Account settings (required)
AUTH_EMAIL=""             # Cloudflare email; only required for Global API key usage
AUTH_TYPE="token"         # 'token' or 'global' https://dash.cloudflare.com/profile/api-tokens
AUTH_KEY="<apikey>"       # Relevant Cloudflare API key

## DNS record settings (required)
DNS_ZONE="<domainzone>"   # Cloudflare zone ID; retreive from the "Overview" tab of the domain dashboard
DNS_RECORDS="<[sub.]domain.tld>"            # Record(s) to point to this IP, in the form of `[sub.]domain.tld`

## Connection settings (defaults)
IP_V="4"                  # IP version to check and update: (4 | 6)
IP_QUERY="https://icanhazip.com https://api.ip.sb/ip https://api64.ipify.org https://ip.seeip.org/ https://api.my-ip.io/ip"
```


## Usage

Use `cron`, `/etc/periodic/`, or similar to run regularly. For example:

```bash
doas mv cloudflare-ddns.sh /etc/periodic/15m
doas chown root:root /etc/periodic/15m/cloudflare-ddns.sh
doas chmod 770 /etc/periodic/15m/cloudflare-ddns.sh         # Contains API key
```

Errors are output to `stderr`, information is output to `stdout`.

