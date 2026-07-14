#!/bin/bash
set -euo pipefail

: "${MACKEREL_APIKEY:?MACKEREL_APIKEY is not set}"

MACKEREL_SERVICE="wifi"
MACKEREL_API="https://api.mackerelio.com/api/v0/services/${MACKEREL_SERVICE}/tsdb"

CLOUDFLARE_SPEED_CLI="/opt/homebrew/bin/cloudflare-speed-cli"
JQ="/opt/homebrew/bin/jq"

result=$("$CLOUDFLARE_SPEED_CLI" --json --auto-save false 2>/dev/null)

epoch=$(date +%s)

payload=$("$JQ" -n --argjson epoch "$epoch" --argjson result "$result" '
  [
    { name: "wifi.speedtest.download.mbps",      time: $epoch, value: $result.download.median_mbps },
    { name: "wifi.speedtest.upload.mbps",         time: $epoch, value: $result.upload.median_mbps },
    { name: "wifi.speedtest.latency.idle_ms",     time: $epoch, value: $result.idle_latency.median_ms },
    { name: "wifi.speedtest.latency.jitter_ms",   time: $epoch, value: $result.idle_latency.jitter_ms },
    { name: "wifi.speedtest.packet_loss.percent",  time: $epoch, value: $result.experimental_udp.latency.loss }
  ]
')

curl -s -X POST "$MACKEREL_API" \
  -H "X-Api-Key: ${MACKEREL_APIKEY}" \
  -H "Content-Type: application/json" \
  -d "$payload"
