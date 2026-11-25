# PC pack builder

Builds the two files the phone apps play from, **on a PC**, from your own game
dump:

| Output | What it is |
|---|---|
| `out/SmashUltimate.nup` / `out/DarksidersII.nup` | The game (with its update and DLC) in one file. |
| `out/pack.zip` | The code and shader data the runtime needs; the app's **PACK** card imports it. |

Two apps use it:

- **[Smash Ultimate Native](https://github.com/hanxl-native/smash-native)** —
  Super Smash Bros. Ultimate, update **13.0.5 (v2031616)** and the DLC.
- **[Darksiders II Native](https://github.com/hanxl-native/darksiders-native)** —
  Darksiders II Deathinitive Edition (base game; no update).

The phone can build both files too, but Smash's 35,012 shaders take hours there;
a PC does them in one go and leaves the phone free.

## Download

- Latest release: **[pack-builder v1.0](https://github.com/hanxl-native/pack-builder/releases/latest)**
  (a `.zip` with these scripts and the manual).
- Or clone this repository.

Nothing else is bundled: the first run downloads the runtime it needs (see below).
There is no game data, no keys and no firmware here.

## Quick start

**Windows** (needs WSL2 with Ubuntu):

```bat
build-pack.cmd smash "C:\Roms\Smash.xci" "C:\Roms\update-13.0.5.nsp" C:\Roms\dlc\*.nsp
build-pack.cmd darksiders "C:\Roms\DarksidersII.nsp" C:\Roms\dlc\*.nsp
```

**Linux / macOS / WSL**:

```sh
./build-pack.sh smash "/path/Smash.xci" "/path/update-13.0.5.nsp" /path/dlc/*.nsp
./build-pack.sh darksiders "/path/DarksidersII.nsp" /path/dlc/*.nsp
```

A `.nup` or an extracted dump folder works too: pass it as the game and skip the
`prod.keys` requirement.

The first run clones **Peanuts Native `v0.1.7-1`** (about 700 MB) into
`.peanuts-native/` and installs the packer's Python packages there; later runs
reuse it and its shader cache. It also raises the importer's 64-file limit to
256, so Smash's base + update + **99 DLC** (101 files) go in one `.nup`.

## What you need

- Windows with **WSL2 (Ubuntu)**, Linux, or macOS.
- **Python 3.12+**.
- The **.NET 10 runtime** — the shader translator runs on it.
- **cmake** and a C compiler — only for `.nsp`/`.xci`/`.nsz`/`.xcz` inputs (they
  build the importer that merges the files).
- Your **`prod.keys`** — only for retail files. Put it in this folder or set
  `PROD_KEYS=/path/to/prod.keys`.
- About **10 GB** free and your game files.

Install them:

```sh
sudo apt update && sudo apt install -y python3 python3-venv cmake build-essential git curl
curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel 10.0 --runtime dotnet
export DOTNET_ROOT="$HOME/.dotnet"     # add it to ~/.bashrc to keep it
```

## How long it takes

| | First run | Later runs |
|---|---|---|
| **Smash** (8+ threads) | ~1.5–2 h (the shaders) | minutes |
| **Darksiders II** | ~15–40 min | minutes |
| Phone, in the app | Smash: 3–6 h | — |

The PC job can run unattended.

## On the phone

1. Copy the `.nup` and `pack.zip` to the phone (USB, SD card or cloud).
2. Open the app → **PACK** → import `pack.zip`; it shows **Ready**.
3. **GAME FILE** → pick the `.nup` (move into the app; the original stays if you
   copy).
4. **PLAY**.

No `prod.keys` and no firmware are needed on the phone this way: the `.nup` is
already merged and the pack carries the shaders.

**Smash:** use the **13.0.5 (v2031616)** update. The app refuses any other
version. **Darksiders:** there is no update step; the pack is for the base game
(v0).

## Notes

- The pack and the `.nup` contain the game's own data. **Do not share them.**
- The runtime is pinned to `v0.1.7-1`, the version the apps are built with: a
  pack made with another version's shader tools may not load.
- The `.nup` is the same format the phone's `BUILD GAME FILE` writes, so either
  route produces a file the app accepts.

## Credits

- [Peanuts Native](https://github.com/igawa6/peanuts-native) by seedds and its
  contributors: the runtime, its importer and packer (MIT; the Android host and
  on-device packer are GPL-3.0-or-later). See [NOTICE](NOTICE).
- .NET (MIT), capstone (BSD-3-Clause), lz4 (BSD-2-Clause), zstandard
  (BSD-3-Clause).
- Not affiliated with Nintendo, Bandai Namco or Sora Ltd.

## License

This repository's own scripts and docs are MIT, see [LICENSE](LICENSE).
