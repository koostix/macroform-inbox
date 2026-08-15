# Macroform Inbox

Name a dump. File it. Two minutes.

This is the processor for unnamed piles — recorder dumps (`EX000_*.WAV`), Logic `Untitled` projects, and anything dropped on `_Inbox`. It does **not** replace `_Music Projects`. It feeds `_Start`.

## Daily use

1. Drop a session folder (or an SD-card dump folder) into:

   `~/Desktop/_Music Projects/_Inbox`

2. Open **Macroform Inbox** from Applications (or Spotlight). No Terminal needed.

3. Listen to the likely mix. Type a description and a BPM (20–300). Hit Return.

4. Finder now has:

   `~/Desktop/_Music Projects/_Start/YYMMDD_description_BPM/`

   The original dump is **moved**, not copied.

Unnamed folders already sitting in `_Start` or `2_Revise` show up automatically. Logic `Untitled*.logicx` packages in `~/Music/Logic` do too. Those already in `_Start` / `2_Revise` are **renamed in place**. Inbox and Logic dumps move into `_Start`.

To rebuild the double-clickable app after a code change:

```bash
cd ~/Desktop/MacroformInbox
./scripts/package-app.sh
cp -R "dist/Macroform Inbox.app" ~/Applications/
```

## Keys

| Key | Action |
|---|---|
| Space | Play / pause the preview |
| Return | File it (when the name is valid) |
| ⌘↩ | File it |
| ⌘. | Skip this pile |
| ⌘R | Reveal the pile in Finder |
| ⇧⌘R | Reveal `_Start` |
| ⌘L | Reload the queue |

## Naming

```
YYMMDD_description_BPM
260323_underwater guitar_92
```

Date defaults to the date already on the folder, or the oldest file in the pile. Spaces in the description are fine. BPM is required.

## What it will not do (yet)

- Copy across volumes (SD card → laptop). Same volume only.
- Split one dump into several songs.
- Touch named project folders.
- Talk to DistroKid, Bandcamp, or the external drive.

Close a Logic project before filing it if the pile contains a `.logicx`.
