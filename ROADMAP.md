# Roadmap: things you might want or need later

Ideas for growing the workstation, roughly in priority order within each
section. ★ marks the ones most worth doing first.

## Before relying on it for real work

- ★ **A battery for the Pi 5's real-time clock.** Offline, a Pi without one
  boots with the wrong date, and every timestamp in `metadata.txt`, the
  logs and your BagIt bags inherits the error. The Pi 5 has an RTC header:
  fit the official battery, set the time once while online, and log the
  clock source in each case.
- ★ **Test it against known disk images.** Run `image-analyse` on reference
  images from [Digital Corpora](https://digitalcorpora.org) and compare the
  results with what's published for them. Keep a few test floppies whose
  contents you already know.
- ★ **Backups (3-2-1).** Keep cases on the SSD, sync them to an external
  drive with `rsync`, and keep a third copy off-site or on a NAS. A
  `case-backup` script could verify hashes after copying.
- ★ **Full-disk encryption (LUKS)** if the laptop carries donor or sensitive
  material and travels.
- **A UPS HAT or battery pack**, so a power cut doesn't interrupt a
  multi-hour hard drive image.
- **Shellcheck in GitHub Actions**, plus a test that runs `image-analyse` on
  a generated image, so changes to the scripts get checked automatically.

## Capture hardware

| Media | What you'd need | Notes |
|---|---|---|
| Apple II, Mac 400K/800K with copy protection | [Applesauce](https://wiki.reactivemicro.com/Applesauce) | Better than Greaseweazle for Apple GCR. Its software is macOS only |
| 8" floppies | 50-pin adapter for the Greaseweazle, plus an 8" drive and its PSU | |
| Zip / Jaz / LS-120 / SyQuest | USB or SCSI drives, then `disk-capture` | Often failing mechanically: image them early |
| Magneto-optical (MO) | USB or SCSI MO drive | |
| Data tapes (QIC, DAT/DDS, DLT, LTO) | SCSI drive + USB-SCSI adapter, then `mt` and `dd` | Needs a `tape-capture` script that reads tape files until end-of-data |
| IDE / SATA / SCSI hard drives | A **hardware write-blocker** (Tableau, WiebeTech) | Safer than software write-blocking for drives you can't replace |
| CompactFlash, SmartMedia, xD, Memory Stick | Multi-format USB card reader | `disk-capture` already handles these |
| Audio cassette, reel-to-reel, DAT audio | USB audio interface plus Audacity/SoX | Workflow notes, a BWF MetaEdit build, and checksums for WAVs |
| Video tape (VHS, U-matic, Betacam) | Capture card + TBC; [vrecord](https://github.com/amiaopensource/vrecord) | Realistically x86 only. Note it here, do it elsewhere |
| Phones and PDAs (Palm, early Nokia/BlackBerry) | Varies a lot | Plan per device |
| Photographing the media | USB webcam or document camera | A `photo-media` step in the capture scripts: label photos saved into the case |

## Software

### BitCurator tools still missing

| Tool | Why it isn't here yet | How it could be added |
|---|---|---|
| **Autopsy 4** | Java + Sleuth Kit JNI bindings, aimed at x86 | Try the Linux zip with a source-built `sleuthkit-java` on arm64 |
| **Disk Image Processor** (CCA) | Expects a BitCurator environment | pip install into a venv with its dependencies (`unhfs`, brunnhilde and tsk are already here) |
| **Bulk Reviewer** | Electron app, no arm64 release | Build from source with Node, or run it on another machine against `bulk_extractor/` output |
| **BEViewer** | Dropped from bulk_extractor 2.x | Use an old Java release, or read the feature files directly |
| **BitCurator Access Webtools** | Web app for browsing images | Docker on the Pi |
| **apfs-fuse** | Not packaged | Build from GitHub. The libfsapfs tools already cover read-only APFS |
| **NSRL hash sets** | Many GB; filters out known OS files | Download the NSRL RDS "minimal" set onto the SSD and add a filter step |

### Preservation tools

- ★ **veraPDF**: scripted install from its IzPack installer with an
  auto-install XML file.
- **Apache Tika**: download `tika-app.jar` and add a `tika` wrapper for
  full-text and metadata extraction.
- **Exactly** or another accession-transfer tool, if donors send you files.
- **RAWcooked + FFV1/MKV normalisation** for audio/video preservation
  masters, with MediaConch policies to check them.
- **PREMIS / METS generation**: write events (capture, hashing, virus scan)
  as PREMIS XML alongside `metadata.txt`, so cases can go straight into
  Archivematica or a repository.
- **Archivematica / AtoM**: too heavy for a Pi. Instead, a script that packs
  each case into a transfer-ready BagIt bag with a standard folder layout.
- **Emulation as a Service (EaaSI)** or a curated set of emulator
  configurations, so common disk types open with one click.
- **Kiwix (offline Wikipedia) and Zeal (offline docs)** for working with no
  network.

### Format work with the PRONOM editor

- ★ Run the [PRONOM editor](https://github.com/francesca4242/pronom_editor)
  on the Pi with a local PRONOM clone, so you can draft a signature when you
  find an unidentified format.
- A `roy build` step that compiles a siegfried signature file from your local
  PRONOM edits, so you can re-identify a case against them straight away.
- A report of "unknown" files across all cases: candidates for new PRONOM
  signatures, with sample files ready to submit.

## Workflow

- ★ **An accession register**: a small SQLite database (or CSV) of every
  piece of media. It would record ID, donor, media type, label, condition,
  capture date, result and location. The capture scripts would add rows to it
  automatically.
- ★ **Scheduled fixity checks**: a systemd timer that re-verifies
  `hashes.txt` and `files-manifest.txt` monthly and warns about changes.
- **An HTML case report** that turns each case folder into one page: photos,
  hashes, the file tree, format breakdown, timeline highlights and
  bulk_extractor hits. Useful for donors and appraisal.
- **Redaction / PII review**: triage `bulk_extractor` hits (card numbers,
  emails, national ID numbers) into a checklist before material is opened to
  researchers.
- **Batch mode**: `floppy-capture --batch` asks for the next disk and
  auto-increments the ID, for working through boxes of floppies.
- **Label printing** for media and case IDs (USB label printer + `lpr`).
- **Quarantine policy**: keep new captures in a holding area for 30 days
  (or until the virus definitions update), then rescan before release.
- **Sync to a work server** over SSH/rsync when back on the network.

## Nice to have

- A proper desktop theme and launcher panel for the preservation tools
- A Greaseweazle drive-health check (`gw rpm`, alignment test disks) logged
  before each session
- A setting for the Greaseweazle bus type (IBM PC vs Shugart) when using
  two drives
- More games: Infocom story files (legal free ones), Brogue,
  OpenTTD, and a DOS shareware collection for DOSBox
