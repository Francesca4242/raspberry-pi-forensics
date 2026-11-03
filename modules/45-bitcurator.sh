# about: More BitCurator tools: libyal suite, plaso timelines, RegRipper, HFSExplorer, read-only mounting
# Image and container formats (libyal): shadow copies, BitLocker, FileVault,
# LUKS, VMDK/VHD/QCOW virtual disks, APFS/NTFS/ext/HFS without the kernel.
apt_install \
    libvshadow-utils libbde-utils libfvde-utils libluksde-utils \
    libvmdk-utils libvhdi-utils libqcow-utils \
    libfsapfs-utils libfsntfs-utils libfsext-utils libfshfs-utils \
    xmount libguestfs-tools

# Filesystems and encrypted volumes: mount (read-only!) or undelete
apt_install \
    ntfs-3g exfatprogs dislocker squashfs-tools \
    ext4magic extundelete

# Windows artefacts: registry, event logs, shortcuts, prefetch, Recycle Bin,
# Thumbs.db, Internet Explorer history, Outlook/ESE databases
apt_install \
    regripper reglookup chntpw \
    libregf-utils libevtx-utils libevt-utils liblnk-utils libscca-utils \
    libmsiecf-utils libolecf-utils libesedb-utils \
    rifiuti2 vinetto galleta pasco

# Timelines, fuzzy hashing, duplicates, carving, PDFs
apt_install \
    plaso \
    ssdeep \
    fdupes rdfind \
    recoverjpeg magicrescue \
    pdfresurrect \
    gtkhash geany

# HFSExplorer + unhfs: classic Mac HFS/HFS+ images (Java). Not packaged.
url=$(github_latest_asset unsound/hfsexplorer 'hfsexplorer-.*-bin\.zip$' || true)
if [[ -n ${url:-} ]]; then
    tmp=$(mktemp -d)
    if curl -fsSL -o "$tmp/hfsx.zip" "$url"; then
        rm -rf /opt/hfsexplorer && mkdir -p /opt/hfsexplorer
        unzip -q "$tmp/hfsx.zip" -d /opt/hfsexplorer
        for tool in hfsexplorer unhfs; do
            script=$(find /opt/hfsexplorer -type f \( -name "$tool" -o -name "$tool.sh" \) -print -quit)
            if [[ -n $script ]]; then
                chmod +x "$script"
                printf '#!/bin/sh\nexec %s "$@"\n' "$script" > "/usr/local/bin/$tool"
                chmod 0755 "/usr/local/bin/$tool"
            else
                warn "HFSExplorer: '$tool' launcher not found in the release zip"
            fi
        done
        [[ -x /usr/local/bin/hfsexplorer ]] && desktop_entry hfsexplorer "HFSExplorer" hfsexplorer false \
            "Browse and extract classic Mac HFS/HFS+ disk images"
    else
        warn "HFSExplorer download failed (non-fatal)"
    fi
    rm -rf "$tmp"
else
    warn "couldn't find an HFSExplorer release; see github.com/unsound/hfsexplorer"
fi

# ro-mount needs a place to mount evidence
install -d -m 0755 /mnt/evidence
