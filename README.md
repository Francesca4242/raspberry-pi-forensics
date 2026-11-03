# Raspberry Pi digital preservation workstation

Turns a Raspberry Pi into a standalone Linux laptop for digital preservation
and forensic extraction work. It can:

- capture floppy disks at the flux level with a
  [Greaseweazle](https://github.com/keirf/greaseweazle);
- image USB sticks, memory cards, hard drives and CDs/DVDs;
- identify, validate and characterise file formats (PRONOM, via siegfried,
  DROID and fido);
- package material as BagIt bags;
- open, render and convert legacy files;
- run the original software in emulators.

All of the software is open source. It also has a Unix toolset and some
games.

## Hardware

| Part | Notes |
|---|---|
| Raspberry Pi 5 (8 GB) or Pi 4 (4 GB+) | A Pi 500 keyboard computer, or a Pi in a laptop shell, makes a tidy portable unit |
| Storage: USB SSD or NVMe (256 GB+) | Disk images add up fast. Boot from SSD rather than microSD |
| Raspberry Pi OS **64-bit with desktop** | Lite works too: use `--skip desktop` |
| Greaseweazle (V4.x or F7) + 34-pin drives | 3.5" drive for PC/Amiga/Atari/Mac 800K. Add a 5.25" drive for older disks. 5.25" drives need a 5 V + 12 V supply |
| USB CD/DVD drive | For optical media |
| USB-SATA/IDE adapter (and ideally a hardware write-blocker) | For hard drives |
| Powered USB hub | Drives draw more power than the Pi's ports supply |

**Why not BitCurator?** BitCurator is an Ubuntu x86-64 distro and doesn't
support the Pi's ARM CPU. This setup installs the same core tools, plus a lot
more, on Raspberry Pi OS.

## Install

```bash
git clone https://github.com/francesca4242/raspberry-pi-forensics.git
```

```bash
cd raspberry-pi-forensics
```

```bash
sudo ./setup.sh
```

```bash
sudo reboot
```

The full install pulls several GB and takes an hour or more on a Pi. Most of
that time is LibreOffice, the emulators, and building siegfried and
bulk_extractor. You can re-run it at any time; it continues and updates where
it left off.

| Option | |
|---|---|
| `--list` | Show the modules |
| `--only floppy,identification` | Install just some modules |
| `--skip desktop,games` | Install everything except some modules |
| `--write-block-usb` | Make every newly plugged USB disk read-only (never the boot disk) |

### Modules

| Module | What it installs |
|---|---|
| `base` | Unix essentials (tmux, vim, mc, ranger, htop), Python, Java runtime |
| `desktop` | LibreOffice, GIMP, Inkscape, VLC, Audacity, Okular, Thunderbird, Calibre, DB Browser for SQLite, GHex, Meld, GParted |
| `floppy` | Greaseweazle `gw`; mtools, hfsutils/hfsprogs (Mac), cpmtools (CP/M), unadf (Amiga), disktype |
| `imaging` | GNU ddrescue, dc3dd, Guymager, ewf-tools (E01), AFF tools, cdparanoia, whipper (audio CDs), cdrdao, dvdisaster, xorriso, dmg2img, qemu-img, smartmontools |
| `forensics` | Sleuth Kit, fiwalk/DFXML, bulk_extractor, foremost, scalpel, PhotoRec/TestDisk, binwalk, YARA, ClamAV, exiftool, hashdeep, oletools |
| `bitcurator` | The rest of the BitCurator toolset that runs on ARM: libyal tools (shadow copies, BitLocker, FileVault, LUKS, VMDK/VHD/QCOW, APFS/NTFS/HFS), plaso timelines, RegRipper and Windows artefact parsers (event logs, LNK, prefetch, Recycle Bin, Thumbs.db), ssdeep, fdupes, xmount, dislocker, HFSExplorer/unhfs, GtkHash |
| `identification` | siegfried and roy, DROID, fido, JHOVE, MediaInfo, MediaConch, Brunnhilde, poppler/qpdf |
| `preservation` | BagIt; email tools (readpst, pff-tools, msgconvert); web archives (wget WARC, HTTrack, warcio, pywb); legacy documents (antiword, catdoc, unrtf, wv); pandoc, ImageMagick, Ghostscript, FFmpeg, SoX, Tesseract OCR, OCRmyPDF; archive formats (7z, unar, cabextract, lha, arj, zoo, unace, ...) |
| `emulation` | DOSBox, DOSBox-X, FS-UAE (Amiga), Hatari (Atari ST), VICE (C64), Basilisk II (68k Mac), QEMU (x86/PPC/68k), MAME |
| `games` | bsdgames, NetHack, Angband, Dungeon Crawl, frotz, ninvaders, moon-buggy and others |

The installer skips any package your OS release doesn't have and tells you
which ones. A module that fails doesn't stop the others; the end of the run
lists the failed modules and the command to retry them.

## Everyday use

```bash
preservation-menu
```

The menu (also under the desktop's Accessories menu) covers everything
below. Every capture goes into its own case folder, `~/cases/<ID>/`. The tools
won't overwrite an existing case, and they make images read-only once
they're written.

### Floppy disks

```bash
floppy-capture -f ibm.1440 -n "Label: tax returns 1994" ACC-2026-001
```

This saves the raw flux (`flux.scp`, the preservation master) and the
decoded image, then runs the analysis below.

Formats include `ibm.1440`, `ibm.720`, `ibm.1200`, `ibm.360`,
`amiga.amigados`, `atari.st.720`, `mac.800`, `mac.400` and `commodore.1541`.
Use `flux` if you don't know the format; `gw convert --help` lists them all.
To read 40-track disks in an 80-track drive, add
`-x "--tracks=c=0-39:step=2"`.

You can re-decode a flux capture later:

```bash
gw convert --format=amiga.amigados flux.scp disk.adf
```

### USB sticks, memory cards, hard drives, CDs and DVDs

```bash
lsblk
```

```bash
disk-capture -n "Blue USB stick, box 4" /dev/sda ACC-2026-002
```

`disk-capture` does the following:

1. Refuses the boot disk and mounted devices.
2. Sets the device read-only.
3. Records the model, serial number and SMART identity.
4. Images the device with ddrescue: a fast first pass, then retries bad
   areas. The `ddrescue.map` file shows exactly what was readable.
5. Hashes the image and runs the analysis.

CDs and DVDs (`/dev/sr0`) are imaged to `disc.iso`. Audio CDs have no data
track to image, so rip them with `whipper cd rip`.

### Analysing an image you already have

```bash
image-analyse received/stick.E01
```

This works on `.img`, `.iso`, `.E01`, `.aff`, floppy images, and partitioned
disks. It writes:

| Output | |
|---|---|
| `disktype.txt`, `mmls.txt`, `fsstat.txt` | Partitions and filesystems |
| `fls.txt` | Every file, including deleted ones (marked `*`) |
| `timeline.csv` | Every created/modified/accessed timestamp, in date order |
| `*.dfxml.xml` | Digital Forensics XML |
| `files/`, `recovered/` | Extracted files; `recovered/` also has deleted files |
| `files-manifest.txt` | Per-file MD5 and SHA-256 |
| `files-ssdeep.txt`, `duplicates.txt` | Fuzzy hashes (spot near-identical files) and exact duplicates |
| `formats.csv`, `brunnhilde/` | PRONOM format identification and an HTML report |
| `exif.csv` | Embedded metadata |
| `clamav.txt` | Virus scan |
| `bulk_extractor/` | Email addresses, URLs, phone numbers, card numbers and so on |

### Browsing an image read-only

```bash
ro-mount disk.img
```

This mounts every filesystem on an image, E01 or device under
`/mnt/evidence/<name>/`, so you can open it in a file manager. The loop
device is read-only, and so are the mounts. They also block running programs
from the image, and ext3/ext4 journals are never replayed, because replaying
one would change the disk. `ro-mount -l` lists what's mounted;
`ro-mount -u all` unmounts everything.

For classic Mac disks, use `hfsexplorer` (GUI) or `unhfs` instead.

### Identifying, validating and packaging

| Task | Command |
|---|---|
| PRONOM identification | `sf folder/` or `fido -recurse folder/` |
| DROID (GUI) | `droid` |
| Validate PDF/TIFF/JPEG/XML/WAV | `jhove file` |
| Audio/video technical metadata and policy checks | `mediainfo`, `mediaconch` |
| Package as BagIt (in place) | `bagit.py --sha256 folder/` |
| Validate a bag | `bagit.py --validate folder/` |
| Open an Outlook PST | `readpst -r -o out/ mail.pst` |
| Convert `.msg` to `.eml` | `msgconvert` |
| Capture a website to WARC | `wget --mirror --warc-file=site https://example.org/` |
| Replay a WARC | `wb-manager init coll && wb-manager add coll site.warc.gz && wayback`, then open <http://localhost:8080/coll/> |
| Make a scanned PDF searchable | `ocrmypdf in.pdf out.pdf` |
| Super-timeline of a whole disk (file system, browser, registry, logs) | `psteal.py --source disk.img -o dynamic -w timeline.csv` |
| Windows registry report | `regripper -r path/to/NTUSER.DAT -a` |
| BitLocker volume (with the recovery key) | `bdemount -r KEY disk.img /mnt/bde` |
| Old Windows Recycle Bin / Thumbs.db | `rifiuti-vista $Recycle.Bin/S-.../`, `vinetto Thumbs.db` |

## Keeping it working offline

When you're online, run:

```bash
preservation-update
```

This refreshes siegfried's PRONOM signatures, the ClamAV virus definitions
and the Greaseweazle tools. `preservation-update --all` also upgrades the OS
and re-runs the setup.

DROID updates its own signatures: in DROID, use Tools > Check for updates.

## Write protection

1. **Physical write-protect first.** On 3.5" floppies, open the tab. On 5.25"
   floppies, cover the notch. For SD cards, use the lock switch. For hard
   drives, use a hardware write-blocker if you have one.
2. `gw read` never writes. Never run `gw write` or `gw erase` on evidence.
3. `disk-capture` sets the device read-only before reading. You can also use
   `write-block on /dev/sdX` or `write-block status` yourself, or install
   with `--write-block-usb` to make every new USB disk read-only and disable
   desktop auto-mount.

If you handle sensitive collections on a laptop that travels, consider full
disk encryption on the Pi's SSD.

## Emulators and games

Emulators let you run the software you've imaged. For example, in DOSBox:
`imgmount a disk.img -t floppy`.

The Amiga (Kickstart), classic Mac and C64 emulators need system ROMs, which
aren't included; supply your own legally obtained ROMs. The Atari ST
emulator can use EmuTOS, which is free.

The menu's **Games** entry lists every installed game. The terminal ones are
also on the command line, e.g. `nethack`, `adventure`, `tetris-bsd`.

## Not included (install by hand if you need them)

- **veraPDF** (PDF/A validation): download the installer from
  <https://verapdf.org>.
- **Apache Tika**: download the app jar from <https://tika.apache.org>, then
  run `java -jar tika-app.jar`.
- **KryoFlux**: its software is proprietary. Greaseweazle covers the same
  ground.
- **JHOVE**: if your OS release doesn't package it, get it from
  <https://jhove.openpreservation.org>.

## Roadmap

[ROADMAP.md](ROADMAP.md) lists things you might want later: more capture
hardware, more software, and workflow improvements.

## Related

The [PRONOM editor](https://github.com/francesca4242/pronom_editor) edits a
local clone of the PRONOM registry. siegfried's `roy` tool builds custom
signature files, which you can use to test new or fixed signatures against
the files you've extracted here.
