#!/usr/bin/env bash
set -euo pipefail

ETH_IF="eth2" # This network iface depends on the f2 carrier board version
CELL_IF="wwan0"
QUECTEL_SERVICE="quectel-cm.service"

CHECK_TARGETS=("1.1.1.1" "8.8.8.8" "9.9.9.9")
FAIL_THRESHOLD=3
RECOVER_THRESHOLD=5
CELL_RESTART_THRESHOLD=6

ETH_PRIMARY_METRIC=205
CELL_BACKUP_METRIC=2357
CELL_PRIMARY_METRIC=105
ETH_BACKUP_METRIC=2500

STATE_DIR="/run/f2-failover"
STATE_FILE="$STATE_DIR/state"
ETH_FAIL_FILE="$STATE_DIR/eth_fail"
ETH_OK_FILE="$STATE_DIR/eth_ok"
CELL_FAIL_FILE="$STATE_DIR/cell_fail"

mkdir -p "$STATE_DIR"

log() {
    logger -t f2-failover "$*"
    echo "$(date '+%F %T') $*"
}

read_count() {
    local f="$1"
    [[ -f "$f" ]] && cat "$f" || echo 0
}

write_count() {
    echo "$2" > "$1"
}

get_state() {
    [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo "UNKNOWN"
}

set_state() {
    echo "$1" > "$STATE_FILE"
}

iface_has_carrier() {
    [[ -f "/sys/class/net/$1/carrier" ]] && [[ "$(cat /sys/class/net/$1/carrier)" == "1" ]]
}

iface_has_ipv4() {
    ip -4 addr show dev "$1" | grep -q "inet "
}

iface_default_gw() {
    ip route show default dev "$1" | awk '/default/ {for(i=1;i<=NF;i++) if($i=="via") {print $(i+1); exit}}'
}

set_route_metric() {
    local iface="$1"
    local metric="$2"
    local gw

    gw="$(iface_default_gw "$iface" || true)"
    [[ -n "$gw" ]] || return 0

    ip route replace default via "$gw" dev "$iface" metric "$metric"
}

ping_via_iface() {
    local iface="$1"
    local target="$2"
    ping -I "$iface" -c 1 -W 2 "$target" >/dev/null 2>&1
}

health_check_iface() {
    local iface="$1"
    local ok=0

    iface_has_ipv4 "$iface" || return 1

    for target in "${CHECK_TARGETS[@]}"; do
        if ping_via_iface "$iface" "$target"; then
            ok=$((ok + 1))
        fi
    done

    [[ "$ok" -ge 2 ]]
}

quectel_active() {
    systemctl is-active --quiet "$QUECTEL_SERVICE"
}

restart_quectel() {
    log "Restarting $QUECTEL_SERVICE"
    systemctl restart "$QUECTEL_SERVICE"
}

prefer_eth() {
    set_route_metric "$ETH_IF" "$ETH_PRIMARY_METRIC"
    set_route_metric "$CELL_IF" "$CELL_BACKUP_METRIC"
    set_state "ETH_ACTIVE"
    log "Preferred uplink: Ethernet ($ETH_IF)"
}

prefer_cell() {
    set_route_metric "$CELL_IF" "$CELL_PRIMARY_METRIC"
    set_route_metric "$ETH_IF" "$ETH_BACKUP_METRIC"
    set_state "CELL_ACTIVE"
    log "Preferred uplink: Cellular ($CELL_IF)"
}

main() {
    local state eth_fail eth_ok cell_fail
    local eth_healthy="no"
    local cell_healthy="no"
    local eth_carrier="no"

    state="$(get_state)"
    eth_fail="$(read_count "$ETH_FAIL_FILE")"
    eth_ok="$(read_count "$ETH_OK_FILE")"
    cell_fail="$(read_count "$CELL_FAIL_FILE")"

    if iface_has_carrier "$ETH_IF"; then
        eth_carrier="yes"
        if health_check_iface "$ETH_IF"; then
            eth_healthy="yes"
        fi
    fi

    if health_check_iface "$CELL_IF"; then
        cell_healthy="yes"
        write_count "$CELL_FAIL_FILE" 0
    else
        cell_fail=$((cell_fail + 1))
        write_count "$CELL_FAIL_FILE" "$cell_fail"
    fi

    if ! quectel_active; then
        log "$QUECTEL_SERVICE is not active"
        restart_quectel
        exit 0
    fi

    if [[ "$cell_fail" -ge "$CELL_RESTART_THRESHOLD" ]]; then
        restart_quectel
        write_count "$CELL_FAIL_FILE" 0
        exit 0
    fi

    case "$state" in
        UNKNOWN)
            if [[ "$eth_healthy" == "yes" ]]; then
                prefer_eth
            elif [[ "$cell_healthy" == "yes" ]]; then
                prefer_cell
            else
                log "No healthy uplink detected"
            fi
            ;;
        ETH_ACTIVE)
            if [[ "$eth_healthy" == "yes" ]]; then
                write_count "$ETH_FAIL_FILE" 0
            else
                eth_fail=$((eth_fail + 1))
                write_count "$ETH_FAIL_FILE" "$eth_fail"
                log "Ethernet unhealthy ($eth_fail/$FAIL_THRESHOLD), carrier=$eth_carrier"

                if [[ "$eth_fail" -ge "$FAIL_THRESHOLD" ]]; then
                    if [[ "$cell_healthy" == "yes" ]]; then
                        prefer_cell
                        write_count "$ETH_FAIL_FILE" 0
                        write_count "$ETH_OK_FILE" 0
                    else
                        log "Ethernet failed and cellular is not healthy"
                    fi
                fi
            fi
            ;;
        CELL_ACTIVE)
            if [[ "$eth_healthy" == "yes" ]]; then
                eth_ok=$((eth_ok + 1))
                write_count "$ETH_OK_FILE" "$eth_ok"
                log "Ethernet recovery check passed ($eth_ok/$RECOVER_THRESHOLD)"

                if [[ "$eth_ok" -ge "$RECOVER_THRESHOLD" ]]; then
                    prefer_eth
                    write_count "$ETH_FAIL_FILE" 0
                    write_count "$ETH_OK_FILE" 0
                fi
            else
                write_count "$ETH_OK_FILE" 0
            fi
            ;;
        *)
            log "Invalid state '$state', resetting"
            set_state "UNKNOWN"
            ;;
    esac
}

main
