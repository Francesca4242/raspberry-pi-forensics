# about: Analysis: Sleuth Kit, fiwalk/DFXML, bulk_extractor, carving, malware scanning
apt_install \
    sleuthkit \
    bulk-extractor \
    foremost scalpel \
    testdisk \
    binwalk \
    yara \
    clamav clamav-freshclam \
    libimage-exiftool-perl \
    hashdeep rhash
pip_tool forensics-py dfxml oletools -- oleid olevba rtfobj

# bulk_extractor isn't packaged on every release: build it from source if so.
if ! command -v bulk_extractor >/dev/null; then
    say "Building bulk_extractor from source (slow on a Pi: 20-40 min)"
    apt_install flex libexpat1-dev libssl-dev zlib1g-dev libewf-dev libre2-dev libsqlite3-dev
    url=$(github_latest_asset simsong/bulk_extractor 'bulk_extractor-.*\.tar\.gz$' || true)
    if [[ -n ${url:-} ]]; then
        tmp=$(mktemp -d)
        if curl -fsSL "$url" | tar -xz -C "$tmp" --strip-components=1 \
                && (cd "$tmp" && ./configure --quiet && make -j"$(nproc)" && make install); then
            echo "bulk_extractor installed"
        else
            warn "bulk_extractor build failed (non-fatal)"
        fi
        rm -rf "$tmp"
    else
        warn "couldn't find a bulk_extractor release (non-fatal)"
    fi
fi
