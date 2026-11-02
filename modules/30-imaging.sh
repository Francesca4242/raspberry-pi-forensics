# about: Disk and optical imaging: ddrescue, Guymager, ewf (E01), CD/DVD, write-blocking
apt_install \
    gddrescue dc3dd \
    ewf-tools afflib-tools \
    guymager \
    hdparm smartmontools \
    cdrdao cdparanoia whipper \
    dvdisaster \
    xorriso genisoimage libcdio-utils udftools \
    dmg2img \
    qemu-utils

if ((WANT_WRITEBLOCK)); then
    say "Software write-blocking for USB block devices"
    cat > /etc/udev/rules.d/90-forensic-writeblock.rules <<'RULES'
# Mark newly attached USB disks read-only and stop the desktop auto-mounting
# them. write-block skips whatever disk holds the root filesystem, so a Pi
# that boots from USB keeps working.
ACTION=="add", SUBSYSTEM=="block", ENV{ID_BUS}=="usb", ENV{DEVTYPE}=="disk", RUN+="/usr/local/bin/write-block auto %k"
ACTION=="add", SUBSYSTEM=="block", ENV{ID_BUS}=="usb", ENV{UDISKS_AUTO}="0"
RULES
    install -m 0755 "$HERE/bin/write-block" /usr/local/bin/write-block
    udevadm control --reload-rules
fi
