#!/usr/bin/env bash
set -euo pipefail

# Optional: override the order via IF_ORDER="eth1 eth2 eth0" ./script.sh
IFS_DEFAULT=("eth1" "eth2" "eth0")
read -r -a IF_ORDER <<< "${IF_ORDER:-${IFS_DEFAULT[*]}}"

is_valid_mac() {
  local mac="$1"
  # must look like xx:xx:xx:xx:xx:xx
  [[ "$mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]] || return 1
  # normalize to lowercase
  mac="${mac,,}"
  # reject all-zero and common dummy values
  [[ "$mac" != "00:00:00:00:00:00" ]] || return 1
  [[ "$mac" != "00:00:00:00:00:01" ]] || return 1
  [[ "$mac" != "ff:ff:ff:ff:ff:ff" ]] || return 1
  # if interface is virtual (no 'device' link), optionally skip it
  # caller passes iface as $2; when provided, skip virtuals
  if [[ -n "${2:-}" ]] && [[ ! -e "/sys/class/net/$2/device" ]]; then
    return 1
  fi
  return 0
}

for IF in "${IF_ORDER[@]}"; do
  addr_file="/sys/class/net/$IF/address"
  [[ -r "$addr_file" ]] || continue
  mac=$(<"$addr_file")
  if is_valid_mac "$mac" "$IF"; then
    mac_no_colon=${mac//:/}
    printf 'f2_%s\n' "${mac_no_colon,,}"
    exit 0
  fi
done

echo "Error: no valid MAC found on ${IF_ORDER[*]}." >&2
exit 1
