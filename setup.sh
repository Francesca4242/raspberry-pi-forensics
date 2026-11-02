#!/usr/bin/env bash
# Turn a Raspberry Pi running Raspberry Pi OS (Debian based, 64-bit
# recommended) into a floppy-disk forensics workstation:
#
#   * Greaseweazle host tools (gw) for flux-level floppy capture
#   * a BitCurator-style toolkit (Sleuth Kit, fiwalk/DFXML, bulk_extractor,
#     hashdeep, disktype, ddrescue, exiftool, siegfried, fido, ...)
#   * classic Unix command-line comforts
#   * games: terminal classics plus DOS / Amiga / Atari ST emulators,
#     so you can actually run what comes off the disks
#
# Usage:  sudo ./setup.sh [--no-games] [--no-siegfried] [--write-block-usb]
#
# Safe to re-run: every step is idempotent.

set -euo pipefail

WANT_GAMES=1
WANT_SF=1
WANT_WRITEBLOCK=0
for arg in "$@"; do
    case "$arg" in
        --no-games)        WANT_GAMES=0 ;;
        --no-siegfried)    WANT_SF=0 ;;
        --write-block-usb) WANT_WRITEBLOCK=1 ;;
        -h|--help)         sed -n '2,16p' "$0"; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    echo "Run me with sudo: sudo $0 $*" >&2
    exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-pi}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
export DEBIAN_FRONTEND=noninteractive

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }

# Install whichever of the given packages this Debian release actually
# has, so one missing package doesn't abort the whole run.
apt_install() {
    local have=() pkg
    for pkg in "$@"; do
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            have+=("$pkg")
        else
            warn "package '$pkg' not available on this release, skipping"
        fi
    done
    if ((${#have[@]})); then
        apt-get install -y --no-install-recommends "${have[@]}"
    fi
}

# ---------------------------------------------------------------------------
say "Updating package lists"
apt-get update

say "Base system, build tools and Unix comforts"
apt_install \
    git curl wget ca-certificates build-essential pkg-config \
    python3 python3-venv python3-pip python3-dev pipx \
    tmux screen htop btop vim nano mc ranger tree ncdu less \
    whiptail dialog zip unzip p7zip-full unar file xxd hexedit \
    rsync jq sqlite3 man-db manpages

# ---------------------------------------------------------------------------
say "Forensics toolkit (BitCurator-style)"
apt_install \
    sleuthkit \
    disktype \
    gddrescue \
    dc3dd \
    hashdeep \
    libimage-exiftool-perl \
    bulk-extractor \
    foremost \
    testdisk \
    ewf-tools \
    binwalk \
    mtools dosfstools \
    hfsutils hfsprogs hfsplus \
    fatcat \
    guymager \
    ghex \
    clamav \
    python3-magic

# ---------------------------------------------------------------------------
say "Greaseweazle host tools"
# Installed in its own venv: Raspberry Pi OS blocks system-wide pip (PEP 668).
GW_VENV=/opt/greaseweazle
[[ -d $GW_VENV ]] || python3 -m venv "$GW_VENV"
"$GW_VENV/bin/pip" install --upgrade pip wheel
"$GW_VENV/bin/pip" install --upgrade \
    "git+https://github.com/keirf/greaseweazle@latest"
ln -sf "$GW_VENV/bin/gw" /usr/local/bin/gw

# The Greaseweazle shows up as /dev/ttyACM*; dialout grants access.
usermod -aG dialout,plugdev "$TARGET_USER"

# ---------------------------------------------------------------------------
say "Fido (PRONOM format identification, Python)"
FIDO_VENV=/opt/fido
[[ -d $FIDO_VENV ]] || python3 -m venv "$FIDO_VENV"
"$FIDO_VENV/bin/pip" install --upgrade opf-fido \
    && ln -sf "$FIDO_VENV/bin/fido" /usr/local/bin/fido \
    || warn "fido install failed (non-fatal)"

if ((WANT_SF)); then
    say "Siegfried (PRONOM format identification, Go)"
    apt_install golang-go
    if GOBIN=/usr/local/bin GOTOOLCHAIN=auto GOPATH=/opt/go \
            go install github.com/richardlehane/siegfried/cmd/sf@latest; then
        # Signature file lives in the user's home (~/siegfried)
        sudo -u "$TARGET_USER" -H /usr/local/bin/sf -update \
            || warn "sf -update failed; run 'sf -update' later when online"
    else
        warn "siegfried build failed (Go may be too old on this release)."
        warn "Install a newer Go from go.dev and re-run, or use 'fido'."
    fi
fi

# ---------------------------------------------------------------------------
if ((WANT_GAMES)); then
    say "Games"
    apt_install \
        bsdgames bsdgames-nonfree \
        nethack-console angband crawl \
        frotz \
        ninvaders moon-buggy greed pacman4console nsnake \
        cmatrix sl fortune-mod cowsay \
        dosbox \
        fs-uae fs-uae-launcher \
        hatari \
        vice
    # bsdgames installs into /usr/games, which isn't on PATH for every shell
    grep -qs '/usr/games' /etc/profile.d/games-path.sh || \
        echo 'case ":$PATH:" in *:/usr/games:*) ;; *) PATH="$PATH:/usr/games";; esac' \
            > /etc/profile.d/games-path.sh
fi

# ---------------------------------------------------------------------------
say "Installing floppy tools into /usr/local/bin"
install -m 0755 "$HERE/bin/floppy-capture" /usr/local/bin/floppy-capture
install -m 0755 "$HERE/bin/floppy-menu"    /usr/local/bin/floppy-menu
install -m 0755 "$HERE/bin/write-block"    /usr/local/sbin/write-block

CASES="$TARGET_HOME/cases"
install -d -o "$TARGET_USER" -g "$TARGET_USER" "$CASES"

if ((WANT_WRITEBLOCK)); then
    say "Software write-blocking for USB block devices"
    cat > /etc/udev/rules.d/90-forensic-writeblock.rules <<'EOF'
# Mark newly attached USB disks (USB floppy drives, card readers, sticks)
# read-only and stop the desktop from auto-mounting them. The helper skips
# whatever disk holds the root filesystem, so USB-booted Pis keep working.
ACTION=="add", SUBSYSTEM=="block", ENV{ID_BUS}=="usb", ENV{DEVTYPE}=="disk", RUN+="/usr/local/sbin/write-block auto %N"
ACTION=="add", SUBSYSTEM=="block", ENV{ID_BUS}=="usb", ENV{UDISKS_AUTO}="0"
EOF
    udevadm control --reload-rules
fi

# Friendly login banner
cat > /etc/profile.d/floppy-forensics.sh <<'EOF'
if [ -t 1 ] && [ -z "$FLOPPY_BANNER_SHOWN" ]; then
    export FLOPPY_BANNER_SHOWN=1
    echo
    echo "  Floppy forensics station:  floppy-menu    (menu)"
    echo "                             floppy-capture (imaging, see --help)"
    echo "                             gw info        (check the Greaseweazle)"
    echo
fi
EOF

say "Done."
cat <<EOF

Log out and back in (or reboot) so '$TARGET_USER' picks up the dialout group.
Then plug in the Greaseweazle and run:

    gw info
    floppy-menu

Cases are saved under $CASES
EOF
