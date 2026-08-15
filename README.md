# Music Projects Organizer

A Mac app for musicians who dump sessions into folders and need them named, previewed, and filed — fast.

Point it at a recorder dump, a Logic `Untitled` project, an SD card, or a whole library. Inspect the files, hear the likely mix, tap a tempo, and file it as:

```
YYMMDD_description_BPM
260323_underwater guitar_92
```

The original folder is **moved**, not copied.

**macOS 14+ · Apple Silicon / Intel**

[Getting started](docs/GETTING_STARTED.md) · [Keys](#keys) · [Build](#build-from-source)

## Install

```bash
git clone https://github.com/koostix/music-projects-organizer.git
cd music-projects-organizer
./scripts/package-app.sh
cp -R "dist/Music Projects Organizer.app" ~/Applications/
```

Open **Music Projects Organizer** from Applications or Spotlight. No Terminal after that.

## What it does

- Opens your inbox, or **any folder** (`⌘O`)
- Lists dumps, named projects, Logic packages, and leftover loose files
- Click a file to preview it on a scrubbable waveform
- Tap tempo (Space) when the session never wrote a BPM, or file as `000`
- Renames in place, moves to `_Start`, or files into a folder you choose
- Wraps loose audio into a new named project folder

It does not replace your library. It feeds the start of one.

## Suggested library

A simple layout that works well with Inbox mode:

```
~/Desktop/_Music Projects/
  _Inbox/     ← drop unnamed dumps here
  _Start/     ← filed projects land here
  2_Revise/   ← unnamed folders here are offered for rename
```

Inbox mode also watches `~/Music/Logic` for `Untitled*.logicx`.

Any other folder works. Open it and organize what is there.

## Keys

| Key | Action |
|---|---|
| Space | Tap tempo |
| Click a file | Play / pause that preview |
| Return | File it |
| ⌘O | Open any folder |
| ⇧⌘I | Back to Inbox |
| ⌘↩ | File it |
| ⌘. | Skip |
| ⌘R | Reveal the pile |
| ⌥⌘R | Reveal the opened folder |
| ⇧⌘R | Reveal `_Start` |
| ⌘L | Reload |

## Build from source

```bash
swift test
./scripts/package-app.sh
```

To regenerate the app icon:

```bash
python3 scripts/generate-icon.py
iconutil -c icns Assets/AppIcon.iconset -o Assets/AppIcon.icns
```

## Limits

- Same volume only. No SD-card → laptop copy yet.
- Does not split one dump into several songs.
- Close Logic before filing a pile that contains a `.logicx`.

## License

Personal / studio tool. Use and adapt as you like.
