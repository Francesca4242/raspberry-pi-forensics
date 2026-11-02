#!/usr/bin/env bash
# Turn a Raspberry Pi running Raspberry Pi OS (64-bit) into a standalone
# digital preservation / forensic extraction workstation.
#
# Usage:  sudo ./setup.sh [options]
#
#   --list              show the available modules and exit
#   --only a,b,...      install only these modules
#   --skip a,b,...      install everything except these modules
#   --write-block-usb   set every newly attached USB disk read-only
#                       (never the disk the Pi boots from)
#
# Safe to re-run: every module is idempotent. Re-running also updates tools.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$HERE/lib/common.sh"

module_name() { basename "$1" .sh | cut -d- -f2-; }

ONLY=""
SKIP=""
export WANT_WRITEBLOCK=0
while (($#)); do
    case "$1" in
        --list)
            for m in "$HERE"/modules/*.sh; do
                printf '  %-14s %s\n' "$(module_name "$m")" "$(sed -n 's/^# about: //p' "$m")"
            done
            exit 0 ;;
        --only) ONLY=",${2:?--only needs a list},"; shift ;;
        --skip) SKIP=",${2:?--skip needs a list},"; shift ;;
        --write-block-usb) WANT_WRITEBLOCK=1 ;;
        -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
    esac
    shift
done

if [[ $EUID -ne 0 ]]; then
    echo "Run me with sudo: sudo $0" >&2
    exit 1
fi

export HERE
export TARGET_USER="${SUDO_USER:-pi}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
export TARGET_HOME
export DEBIAN_FRONTEND=noninteractive

say "Updating package lists"
apt-get update

FAILED=()
for m in "$HERE"/modules/*.sh; do
    name=$(module_name "$m")
    [[ -n $ONLY && $ONLY != *",$name,"* ]] && continue
    [[ $SKIP == *",$name,"* ]] && continue
    say "Module: $name"
    # A separate bash process per module: errexit stays active inside it,
    # and one failing module doesn't stop the others.
    if ! bash -c 'set -euo pipefail; source "$1"; source "$2"' _ \
            "$HERE/lib/common.sh" "$m"; then
        warn "module '$name' failed"
        FAILED+=("$name")
    fi
done

say "Installing workstation commands into /usr/local/bin"
for f in "$HERE"/bin/*; do
    install -m 0755 "$f" "/usr/local/bin/$(basename "$f")"
done
install -d -o "$TARGET_USER" -g "$TARGET_USER" "$TARGET_HOME/cases"
echo "REPO=$HERE" > /etc/preservation-station.conf

desktop_entry preservation-menu "Preservation Menu" preservation-menu true \
    "Capture, identify and package digital media"

cat > /etc/profile.d/preservation-station.sh <<'EOF'
if [ -t 1 ] && [ -z "$PRESERVATION_BANNER_SHOWN" ]; then
    export PRESERVATION_BANNER_SHOWN=1
    echo
    echo "  Digital preservation station:  preservation-menu"
    echo "  floppy-capture | disk-capture | image-analyse | preservation-update"
    echo
fi
EOF

say "Done."
if ((${#FAILED[@]})); then
    list="${FAILED[*]}"
    warn "modules with errors: $list  (fix, then: sudo ./setup.sh --only ${list// /,})"
fi
cat <<EOF

Reboot so '$TARGET_USER' picks up its new groups, then run:  preservation-menu
Cases are saved under $TARGET_HOME/cases
EOF
