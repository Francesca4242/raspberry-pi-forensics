# Shared helpers for setup.sh and the modules. Sourced, not executed.
# shellcheck shell=bash

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }

# Install whichever of the given packages this Debian release actually has,
# so one missing package doesn't abort the whole run.
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

# pip_tool NAME "pip spec..." -- CMD [CMD...]
# Installs Python tools into their own venv under /opt/NAME (Raspberry Pi OS
# blocks system-wide pip, PEP 668) and links the listed commands onto PATH.
# Failures are warnings, never fatal.
pip_tool() {
    local name=$1; shift
    local specs=()
    while (($#)) && [[ $1 != -- ]]; do specs+=("$1"); shift; done
    shift || true
    local venv="/opt/$name" cmd
    [[ -d $venv ]] || python3 -m venv "$venv" || { warn "venv $name failed"; return 0; }
    if ! "$venv/bin/pip" install --quiet --upgrade pip wheel "${specs[@]}"; then
        warn "pip install of ${specs[*]} failed (non-fatal)"
        return 0
    fi
    for cmd in "$@"; do
        if [[ -x $venv/bin/$cmd ]]; then
            ln -sf "$venv/bin/$cmd" "/usr/local/bin/$cmd"
        else
            warn "$name: command '$cmd' not found in venv"
        fi
    done
}

# github_latest_asset OWNER/REPO REGEX -> prints download URL of the newest
# release asset whose name matches REGEX.
github_latest_asset() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
        | jq -r '.assets[].browser_download_url' \
        | grep -E "$2" | head -n1
}

# Desktop launcher for terminal or GUI programs.
desktop_entry() {   # desktop_entry ID "Name" "Exec" terminal(true|false) "Comment"
    install -d /usr/local/share/applications
    cat > "/usr/local/share/applications/$1.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$2
Exec=$3
Terminal=$4
Comment=$5
Icon=utilities-terminal
Categories=Utility;Archiving;
EOF
}
