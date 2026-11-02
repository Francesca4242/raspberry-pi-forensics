# about: Greaseweazle flux capture and vintage filesystem tools (FAT, HFS, CP/M, Amiga)
pip_tool greaseweazle "git+https://github.com/keirf/greaseweazle@latest" -- gw
apt_install \
    mtools dosfstools \
    hfsutils hfsprogs hfsplus \
    cpmtools \
    fatcat \
    disktype
# unadf/ADFlib for Amiga disk images
apt_install unadf || true
