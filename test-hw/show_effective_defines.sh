#!/usr/bin/env bash
set -euo pipefail

CONFIG="../src/project_config.v"

if [[ $# -gt 0 && "$1" != -* ]]; then
    CONFIG="$1"
    shift
fi

if [[ ! -f "$CONFIG" ]]; then
    echo "error: config file not found: $CONFIG" >&2
    exit 1
fi

if ! command -v iverilog >/dev/null 2>&1; then
    echo "error: iverilog is required for Verilog preprocessing" >&2
    echo "install with: sudo apt install iverilog" >&2
    exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

CONFIG_DIR="$(cd "$(dirname "$CONFIG")" && pwd)"
CONFIG_FILE="$(basename "$CONFIG")"

NAMES_FILE="$TMPDIR/define_names.txt"
PROBE_FILE="$TMPDIR/show_effective_defines_probe.v"
OUT_FILE="$TMPDIR/preprocessed.txt"

perl -0777 -ne '
    s{/\*.*?\*/}{}gs;
    s{//.*$}{}mg;
    while (/^\s*`(?:define|ifdef|ifndef)\s+([A-Za-z_][A-Za-z0-9_\$]*)/mg) {
        print "$1\n";
    }
' "$CONFIG" | sort -u > "$NAMES_FILE"

for arg in "$@"; do
    case "$arg" in
        -D*)
            name="${arg#-D}"
            name="${name%%=*}"
            if [[ -n "$name" ]]; then
                echo "$name" >> "$NAMES_FILE"
            fi
            ;;
    esac
done

sort -u "$NAMES_FILE" -o "$NAMES_FILE"

{
    echo '`default_nettype none'
    printf '`include "%s"\n' "$CONFIG_FILE"
    echo '__EFFECTIVE_DEFINES_BEGIN__'

    while IFS= read -r name; do
        [[ -n "$name" ]] || continue

        printf '`ifdef %s\n' "$name"
        printf '%s=`%s\n' "$name" "$name"
        printf '`else\n'
        printf '%s=<undefined>\n' "$name"
        printf '`endif\n'
    done < "$NAMES_FILE"

    echo '__EFFECTIVE_DEFINES_END__'
    echo '`default_nettype wire'
} > "$PROBE_FILE"

iverilog -E -g2012 -I "$CONFIG_DIR" "$@" "$PROBE_FILE" -o "$OUT_FILE"

awk '
    /^__EFFECTIVE_DEFINES_BEGIN__/ { show = 1; next }
    /^__EFFECTIVE_DEFINES_END__/   { show = 0; next }

    show {
        sub(/^[[:space:]]+/, "")
        sub(/[[:space:]]+$/, "")

        if ($0 == "") {
            next
        }

        if ($0 ~ /<undefined>$/) {
            next
        }

        if ($0 ~ /^[A-Za-z_][A-Za-z0-9_\$]*=$/) {
            print $0 " (defined)"
        } else {
            print
        }
    }
' "$OUT_FILE" | sort