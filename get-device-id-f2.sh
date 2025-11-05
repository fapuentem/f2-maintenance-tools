#!/usr/bin/env bash
set -euo pipefail

for IF in eth1 eth2 eth0; do
  addr_file="/sys/class/net/$IF/address"
  if [[ -r "$addr_file" ]]; then
    mac=$(<"$addr_file")
    # Validate MAC format like xx:xx:xx:xx:xx:xx
    if [[ "$mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
      mac_nocolon=${mac//:/}
      # Lowercase (bash 4+), just in case the MAC comes uppercase
      printf 'f2_%s\n' "${mac_nocolon,,}"
      exit 0
    fi
  fi
done

echo "Error: no valid MAC found on eth1, eth2, or eth0." >&2
exit 1
