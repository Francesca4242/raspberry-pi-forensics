# about: Format ID and validation: siegfried, DROID, fido, JHOVE, MediaInfo/MediaConch, Brunnhilde
apt_install \
    golang-go \
    mediainfo mediaconch \
    jhove \
    libimage-exiftool-perl \
    python3-magic \
    poppler-utils qpdf

# fido (Python, PRONOM)
pip_tool fido opf-fido -- fido

# siegfried (Go, PRONOM). GOTOOLCHAIN=auto lets older Go fetch a newer one.
if GOBIN=/usr/local/bin GOTOOLCHAIN=auto GOPATH=/opt/go GOCACHE=/opt/go/cache \
        go install github.com/richardlehane/siegfried/cmd/sf@latest; then
    GOBIN=/usr/local/bin GOTOOLCHAIN=auto GOPATH=/opt/go GOCACHE=/opt/go/cache \
        go install github.com/richardlehane/siegfried/cmd/roy@latest || true
    sudo -u "$TARGET_USER" -H /usr/local/bin/sf -update \
        || warn "sf -update failed; run 'preservation-update' later when online"
else
    warn "siegfried build failed; install a newer Go from go.dev and re-run this module"
fi

# Brunnhilde: HTML reports on top of siegfried
pip_tool brunnhilde brunnhilde -- brunnhilde.py

# DROID (The National Archives, Java). Pulled from the latest GitHub release.
url=$(github_latest_asset digital-preservation/droid 'droid-binary-.*-bin\.zip$' || true)
if [[ -n ${url:-} ]]; then
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/droid.zip" "$url"
    rm -rf /opt/droid && mkdir -p /opt/droid
    unzip -q "$tmp/droid.zip" -d /opt/droid
    rm -rf "$tmp"
    droid_sh=$(find /opt/droid -name droid.sh -print -quit)
    chmod +x "$droid_sh"
    printf '#!/bin/sh\nexec %s "$@"\n' "$droid_sh" > /usr/local/bin/droid
    chmod 0755 /usr/local/bin/droid
    desktop_entry droid "DROID" droid false "PRONOM file format identification (The National Archives)"
else
    warn "couldn't find a DROID release; download it from github.com/digital-preservation/droid"
fi

command -v jhove >/dev/null || warn "JHOVE isn't packaged on this release; get it from jhove.openpreservation.org"
