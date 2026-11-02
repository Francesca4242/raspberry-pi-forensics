# about: Packaging, email, web archives, legacy documents, archives and conversion tools
# Packaging and fixity
pip_tool bagit bagit -- bagit.py
apt_install hashdeep rhash

# Email
apt_install pst-utils pff-tools libemail-outlook-message-perl mpack

# Web archives
apt_install wget httrack
pip_tool warc warcio pywb -- warcio wb-manager wayback

# Legacy documents and conversion
apt_install \
    antiword catdoc unrtf wv \
    pandoc \
    imagemagick graphicsmagick ghostscript \
    ffmpeg sox \
    poppler-utils qpdf \
    tesseract-ocr ocrmypdf \
    libreoffice-core

# Archive formats old and new
apt_install \
    zip unzip p7zip-full unar cabextract lhasa arj zoo \
    unrar-free lzip zstd xz-utils bzip2 cpio rpm2cpio \
    unace
