# about: Unix essentials, Python, Java runtime, shells and file managers
apt_install \
    git curl wget ca-certificates build-essential pkg-config jq \
    python3 python3-venv python3-pip python3-dev pipx \
    default-jre-headless \
    tmux screen htop btop vim nano mc ranger tree ncdu less \
    whiptail dialog file xxd hexedit rsync sqlite3 \
    man-db manpages parallel pv lsof smartmontools
usermod -aG dialout,plugdev,cdrom "$TARGET_USER"
