# The manual

`build-pack.sh` (Linux, macOS, WSL) and `build-pack.cmd` (Windows, through WSL)
make the two files the apps need. This page has the details.

## What the script does

1. **Clones the runtime once** — Peanuts Native `v0.1.7-1` into
   `.peanuts-native/` (about 700 MB). It is the exact version the apps are built
   with; a pack made with other shader tools may not load.
2. **Installs the packer's Python packages** into `.peanuts-native/.venv`
   (`capstone`, `lz4`, `backports.zstd`) the first time.
3. **Merges retail files** — if the game is an `.nsp`/`.xci`/`.nsz`/`.xcz`, it
   builds `nximport_cli` (cmake) and merges the game, the update and the DLC into
   `out/<name>.nup` with your `prod.keys`.
4. **Builds the pack** — `scripts/pack_android.py` rewrites the game code for the
   Android host and translates the shaders into `out/pack/`.
5. **Zips the pack** — `out/pack.zip`, the file the app's **PACK** card imports.

## Install the requirements

### Windows (WSL2)

```powershell
wsl --install -d Ubuntu
```

Then, inside Ubuntu:

```sh
sudo apt update && sudo apt install -y python3 python3-venv cmake build-essential git curl
curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel 10.0 --runtime dotnet
export DOTNET_ROOT="$HOME/.dotnet"
echo 'export DOTNET_ROOT="$HOME/.dotnet"' >> ~/.bashrc
```

Keep the files on the Windows side (`C:\...`) and run `build-pack.cmd` from
Windows: it calls `wsl --cd` in this folder and passes the paths through.

### Linux

Same packages as above with your distribution's package manager, plus the .NET
10 runtime from <https://dotnet.microsoft.com/download>.

### macOS

`brew install python cmake` and the .NET 10 runtime. The packer runs natively;
the shader translator is a .NET program.

## Use it

```sh
./build-pack.sh <smash|darksiders> <game> [update] [dlc ...]
```

| Game | The `game` input | Extra inputs | Output name |
|---|---|---|---|
| `smash` | `.xci`, `.nsp`, `.nup` or a dump folder | the **13.0.5 (v2031616)** update, then the DLC (up to 99) | `out/SmashUltimate.nup` |
| `darksiders` | `.nsp`, `.xci`, `.nup` or a dump folder | the DLC, if any | `out/DarksidersII.nup` |

Examples:

```sh
# Smash: base card, update, all DLC
./build-pack.sh smash "/mnt/c/Roms/Smash.xci" "/mnt/c/Roms/update-13.0.5.nsp" /mnt/c/Roms/dlc/*.nsp

# Darksiders: base, one DLC
./build-pack.sh darksiders "/mnt/c/Roms/DarksidersII.nsp" "/mnt/c/Roms/dlc/dlc1.nsp"

# An already merged .nup: no keys and no importer needed
./build-pack.sh smash "/mnt/c/Roms/SmashUltimate.nup"
```

`prod.keys` goes in this folder (or `PROD_KEYS=/path/to/prod.keys`). It is only
needed for retail `.nsp`/`.xci`/`.nsz`/`.xcz` files. The key file is never
uploaded anywhere; the script only passes its path to the importer.

`OUT=/path/to/out`, `JOBS=8`, `PYTHON=python3.12` and
`PEANUTS_REPO=/path/to/peanuts-native` override the defaults.

### Smash's update

The app and its pack are built for **13.0.5 (v2031616)**. Pass that update after
the base game. The app checks the update file and refuses other versions
(`13.0.4` is refused, for example). If you pass only the base, the script warns;
the pack it makes is for the base version and the app will not match it.

The script raises the importer's 64-file limit to **256**, so the base, the
update and all **99 DLC** fit in one `.nup` (101 files). The stock runtime stops
at 64 and would leave the fighter passes out.

### Darksiders' version

There is **no update step**: the app and its pack are for the base game (v0). A
file that already carries an update is accepted, and the app warns that the pack
was not made for that build.

## Space and time

- The clone: ~700 MB.
- The importer and the pack: a few GB free; the final `.nup` is the size of the
  game + update + DLC.
- Smash's first pack: **~1.5–2 h** on 8+ threads (35,012 shaders). Later runs
  reuse `.peanuts-native/` and its shader cache and take minutes.
- Darksiders: ~15–40 min the first time.

## Troubleshooting

| Symptom | What to do |
|---|---|
| `Python 3.12 or newer is needed` | Install a newer Python (`python3.12`) or set `PYTHON=`. |
| `no .NET 10 runtime in ...` | Install the .NET 10 **runtime** and set `DOTNET_ROOT`; check `"$DOTNET_ROOT/dotnet" --list-runtimes`. |
| `cmake is needed to build the importer` | Install cmake and a C compiler, or pass an already merged `.nup`. |
| `prod.keys not found` | Put `prod.keys` here or set `PROD_KEYS=`. |
| `the importer failed` | Check that the base file is the right game (title ID in the name) and the update is 13.0.5 for Smash. |
| The app says **Not added** after importing `pack.zip` | The zip must have `pack.tsv` at its root, not inside a folder. `pack.zip` from this script already does. |
| The app says the build is not the one the pack was made for | The pack was made for another game version. Rebuild it with the right update. |
| The clone fails | Check the network and that `git` is installed; delete a half `.peanuts-native/` and run again. |

## On the phone

1. Copy `out/<name>.nup` and `out/pack.zip` to the phone.
2. **PACK** → pick `pack.zip`; the card shows **Ready**.
3. **GAME FILE** → pick the `.nup` → **Move into the app** (the original stays if
   you copy it).
4. **PLAY**.

No keys and no firmware are needed on the phone with this route: the `.nup` is
already merged and the pack carries the shaders.

## What is in the pack, and what not to share

The pack holds the game's translated code and shaders. The `.nup` holds the
game. Both are for **your** phone: do not upload them or share them. This
repository and its releases carry only the scripts and this manual.
