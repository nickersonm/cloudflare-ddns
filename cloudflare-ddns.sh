#!/bin/sh
# 
# Update specified Cloudflare DNS entries
#   Uses `sed`
# 
# Copyright (c) Michael Nickerson 2022
# 
set -eu


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


# Process definitions
AUTH_TYPE=$(echo "$AUTH_TYPE" | sed "s/global/X-Auth-Key:/i; /X-Auth-Key/b; c Authorization: Bearer")
[ "$IP_V" = "6" ] && DNS_TYPE="AAAA" || DNS_TYPE="A"


# Execution
## Get public IP
IP_PUB=""
for IPQ in ${IP_QUERY}; do
  IP_PUB=$(curl -s -$IP_V "$IPQ")
  [ -z "$IP_PUB" ] || break
done

[ -n "$IP_PUB" ] || {
  >&2 echo "cloudflare-ddns: Unable to get public IP; aborting"
  exit 1
}

## Get Cloudflare DNS entry for each DNS_RECORD
for DNS_REC in ${DNS_RECORDS}; do
  # Get Cloudflare record
  CF_REC=$( curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${DNS_ZONE}/dns_records?type=${DNS_TYPE}&name=${DNS_REC}" \
                 -H "X-Auth-Email: ${AUTH_EMAIL}" \
                 -H "${AUTH_TYPE} ${AUTH_KEY}" \
                 -H "Content-Type: application/json" )
  
  # Verify record exists
  [ "${CF_REC#*\"count\":0}" = "$CF_REC" ] || {
    >&2 echo "cloudflare-ddns: No Cloudflare DNS entry for '$DNS_REC'"
    exit 1
  }
  
  # Extract existing IP
  [ "$IP_V" = "4" ] && CF_IP=$(echo "$CF_REC" | sed -n 's/.*"content":"\([0-9\.]*\)".*/\1/p')
  [ "$IP_V" = "6" ] && CF_IP=$(echo "$CF_REC" | sed -n 's/.*"content":"\([0-9\.a-zA-Z:]*\)".*/\1/p')
  
  # Continue if already correct
  [ "$IP_PUB" = "$CF_IP" ] && {
    echo "cloudflare-ddns: '$DNS_REC' already correct."
    continue
  }
  
  # Extract IP identifier
  CF_ID=$(echo "$CF_REC" | sed -n 's/.*"id":"\(\w*\)".*/\1/p')
  [ -z "$CF_ID" ] && {
    >&2 echo "cloudflare-ddns: Unable to extract ID for '$DNS_REC'; response: '$CF_REC'"
    exit 1
  }
  
  # Update Cloudflare DNS to correct IP
  CF_REC=$( curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${DNS_ZONE}/dns_records/${CF_ID}/" \
                 -H "X-Auth-Email: ${AUTH_EMAIL}" \
                 -H "${AUTH_TYPE} ${AUTH_KEY}" \
                 -H "Content-Type: application/json" \
                 --data '{"type":"'"$DNS_TYPE"'","content":"'"$IP_PUB"'"}' )
  
  # Check for success
  [ "${CF_REC#*\"success\":true}" = "$CF_REC" ] && {
    >&2 echo "cloudflare-ddns: Failed to update '$DNS_REC'; response: '$CF_REC'"
    exit 1
  } || {
    echo "cloudflare-ddns: Updated '$DNS_REC' to '$IP_PUB'"
  }
done

# Exit with success
exit 0
