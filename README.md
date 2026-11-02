# Raspberry Pi floppy forensics station

Turns a Raspberry Pi into a Linux floppy-disk forensics workstation. It uses a
[Greaseweazle](https://github.com/keirf/greaseweazle) for flux-level capture,
installs a BitCurator-style toolkit, and adds some games and emulators.

## Hardware

| Part | Notes |
|---|---|
| Raspberry Pi 4 or 5 (4 GB+) | A Pi 3 works but analysis is slow |
| 32 GB+ microSD or USB SSD | Raspberry Pi OS **64-bit** (Lite or Desktop) |
| Greaseweazle (V4.x or F7) | Connects over USB |
| 34-pin floppy drive(s) | 3.5" PC drive for PC/Amiga/Atari/Mac 800K. Add a 5.25" drive for older disks |
| Drive power | 3.5" drives need 5 V. 5.25" drives need 5 V **and** 12 V. Check your Greaseweazle model's docs before powering a drive from it |
| Powered USB hub (optional) | Helps when the drive draws power over USB |

**Why not install BitCurator itself?** BitCurator is an Ubuntu x86-64 distro
built with SaltStack, and it doesn't support the Pi's ARM CPU. This setup
installs the same core tools from Debian/Raspberry Pi OS instead.

## Install

Flash Raspberry Pi OS 64-bit, boot it, connect it to the internet, then:

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

Options:

- `--no-games`: skip the games and emulators
- `--no-siegfried`: skip building siegfried (needs Go; fido is installed anyway)
- `--write-block-usb`: automatically set newly plugged USB disks read-only (see below)

## Use

```bash
gw info
```

```bash
floppy-menu
```

Or skip the menu:

```bash
floppy-capture -f ibm.1440 -n "Label: tax returns 1994" ACC-2026-001
```

Each case gets its own folder under `~/cases/<ID>/`:

| File | What |
|---|---|
| `flux.scp` | Raw flux. This is the preservation master; you can re-decode it later in a different format |
| `disk.img` / `.adf` / `.st` / `.d64` | Decoded sector image |
| `decode-report.txt` | Greaseweazle's report of good and bad sectors |
| `hashes.txt` | MD5, SHA-1 and SHA-256 of the images |
| `metadata.txt`, `capture.log` | Who, when, which tool versions, full log |
| `disktype.txt`, `fsstat.txt` | Filesystem detection |
| `fls.txt` | Full file listing; deleted entries are marked with `*` |
| `disk.dfxml.xml` | Digital Forensics XML (fiwalk) |
| `files/` | Extracted allocated files |
| `recovered/` | Allocated **and deleted** files |
| `files-manifest.txt` | Per-file hashes (hashdeep) |
| `formats.csv` | PRONOM format IDs (siegfried, or fido if siegfried isn't installed) |
| `exif.csv` | Embedded metadata (exiftool) |
| `bulk_extractor/` | Emails, URLs, phone numbers and other features found in the image |

The script won't overwrite an existing case. Once a capture finishes, it makes
the images read-only.

### Common formats (`-f`)

`ibm.1440`, `ibm.720`, `ibm.1200`, `ibm.360`, `amiga.amigados`,
`atari.st.720`, `mac.800`, `mac.400`, `commodore.1541`, or `flux` if you don't
know the format. `gw convert --help` lists all of them.

To read 40-track 5.25" disks in an 80-track drive, add
`-x "--tracks=c=0-39:step=2"`.

To re-decode an existing flux capture in a different format:

```bash
gw convert --format=amiga.amigados flux.scp disk.adf
```

Sleuth Kit reads FAT, so it handles PC and Atari ST disks. For other
filesystems:

- Amiga: open the `.adf` in FS-UAE.
- Classic Mac: use `hls`/`hcopy` from hfsutils.
- Commodore 64: open the `.d64` in VICE.

## Write protection

1. **Physical write-protect first.** On 3.5" disks, slide the tab open. On
   5.25" disks, cover the notch.
2. Greaseweazle `gw read` never writes. Never run `gw write` or `gw erase` on
   evidence.
3. For USB floppy drives and card readers, use `write-block on /dev/sdX`. You
   can also install with `--write-block-usb`, which sets every new USB disk
   read-only and disables automount. It always skips the disk that holds the
   root filesystem. Check with `write-block status`.

## Unix and games

The menu has a shell (`tmux`, `mc`, `ranger`, `vim`, `htop`). Games include:

- bsdgames (`adventure`, `tetris-bsd`, `robots`, ...)
- NetHack, Angband, Dungeon Crawl
- frotz, for Infocom-style text adventures
- ninvaders, moon-buggy and others

Emulators let you run software straight off the disks you've imaged:

- **DOSBox**: mount a PC image with `imgmount a disk.img -t floppy`
- **FS-UAE**: Amiga
- **Hatari**: Atari ST
- **VICE**: C64

Amiga, Atari and C64 emulators need their system ROMs. These aren't
included, so supply your own legally obtained ROMs.

## Tie-in with the PRONOM editor

siegfried and fido both identify files with PRONOM signatures. If you add or
fix a signature using the
[PRONOM editor](https://github.com/francesca4242/pronom_editor), you can rebuild a
custom signature file with siegfried's `roy` tool and check it against the
files in your floppy captures.
