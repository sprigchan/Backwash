# Backwash

Reverse reverb and creative effects for REAPER (JSFX).

Backwash captures incoming audio, renders a reversed reverb tail and lets you
shape it with a chain of effects. Useful for swells, risers, transitions and
other reverse-reverb tricks.
![Backwash](backwash.png)
## Features

- Reverse reverb with five types: Plate, Hall, Room, Chamber, Cathedral
- Length in milliseconds or synced to the project tempo (1/16 bar to 2 bars)
- Shape, width, output level, high-pass and low-pass filters, filter bell
- Effects chain with reorderable order: Pitch Riser, Saturation (Soft, Tube,
  Hard, Fuzz), Sweep, Modulation (Chorus, Flanger, Phaser), Tremolo, Auto Pan,
  Bitcrusher
- Loop mode and MIDI note trigger
- Send the rendered result to a REAPER track (needs the Lua receiver script)

## Installation (ReaPack)

1. In REAPER open **Extensions > ReaPack > Import repositories...**
2. Paste this URL:

   ```
   https://github.com/sprigchan/Backwash/raw/master/index.xml
   ```

3. Open **Extensions > ReaPack > Browse packages**, find **Backwash** and install it.
4. Install **Backwash Receiver (SEND TO TRACK)** from the same repository. It is a
   separate package (the Lua script) and is only needed for the SEND TO TRACK button.
5. Add the plugin to a track: **FX > JS: Backwash (vislov)**.

### SEND TO TRACK

Run the receiver once: **Actions > Show action list**, find
*Script: Backwash_Receiver.lua* and run it. On first launch it offers to start
automatically with REAPER. After that, the SEND TO TRACK button in the plugin
writes a WAV into the project folder and places it on the selected track
(or on a new track if none is selected).

## Manual installation

Open your REAPER resource path (**Options > Show REAPER resource path in explorer**)
and copy two files from this repository:

1. `Backwash/Backwash.jsfx` into `Effects/vislov/Backwash/`
   (create the folders if they do not exist).
2. `Backwash/Backwash_Receiver.lua` into `Scripts/vislov/Backwash/`
   (needed only for the SEND TO TRACK button).

Then:

1. Restart REAPER or rescan FX, and add the plugin via **FX > JS: Backwash (vislov)**.
2. Open **Actions > Show action list > New action > Load ReaScript...**, select
   `Scripts/vislov/Backwash/Backwash_Receiver.lua` and run it once. On first launch
   it offers to start automatically with REAPER.

## License

Free for personal and commercial projects, but redistribution and resale are not
allowed. See [LICENSE.md](LICENSE.md).

Website: [vislovprod.com](https://vislovprod.com)
