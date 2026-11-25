#!/bin/sh
# Make the two files the apps play from, on a PC:
#
#   out/<game>.nup   the game (and its update/DLC) in one file
#   out/pack.zip     the code and shader data the runtime needs
#
# Usage:
#   ./build-pack.sh smash <game.xci|game.nsp|game.nup|dump folder> [update.nsp] [dlc/*.nsp ...]
#   ./build-pack.sh darksiders <game.xci|game.nsp|game.nup|dump folder> [dlc/*.nsp ...]
#
# Examples:
#   ./build-pack.sh smash "/mnt/c/Roms/Smash.xci" "/mnt/c/Roms/update-13.0.5.nsp" /mnt/c/Roms/dlc/*.nsp
#   ./build-pack.sh darksiders "/mnt/c/Roms/DarksidersII.nsp" /mnt/c/Roms/dlc/*.nsp
#
# Then, on the phone: PACK -> import pack.zip, GAME FILE -> the .nup, PLAY.
#
# The first run clones the runtime and installs its Python packages (once); the
# first Smash run also translates the shaders (about 1.5-2 h with 8+ threads).
# Later runs reuse the cache and take minutes.
#
# Needs: Linux, macOS or WSL2; Python 3.12+; the .NET 10 runtime; cmake and a C
# compiler for retail .nsp/.xci inputs (see BUILD-PACK.md).
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=${PEANUTS_REPO:-$HERE/.peanuts-native}
TAG=v0.1.7-1
OUT=${OUT:-$HERE/out}

say() { printf '%s\n' "$*" >&2; }
die() { say "[ERROR] $*"; exit 1; }
usage() { sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

[ $# -ge 2 ] || usage
KIND=$1
shift
case "$KIND" in
    smash)
        TITLE=01006A800016E000
        PACK_VERSION=2031616
        NAME=SmashUltimate.nup
        UPDATE=1
        ;;
    darksiders)
        TITLE=010071800BA98000
        PACK_VERSION=0
        NAME=DarksidersII.nup
        UPDATE=0
        ;;
    -h|--help) usage ;;
    *) say "unknown game '$KIND': use smash or darksiders"; usage ;;
esac
[ $# -ge 1 ] || usage
case "$1" in -h|--help) usage ;; esac

# ---- the runtime this pack must match: the same Peanuts Native the apps were built with
if [ ! -f "$REPO/scripts/pack_android.py" ]; then
    say "Cloning Peanuts Native $TAG into $REPO (about 700 MB, once)..."
    git clone --depth 1 --branch "$TAG" https://github.com/igawa6/peanuts-native "$REPO" || die "the clone failed"
fi

# ---- Python with the packer's packages
PY=${PYTHON:-python3}
"$PY" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 12) else 1)' || die "Python 3.12 or newer is needed"
if ! "$PY" -c 'import capstone, lz4' 2>/dev/null || { ! "$PY" -c 'import compression.zstd' 2>/dev/null && ! "$PY" -c 'import backports.zstd' 2>/dev/null; }; then
    say "Installing the packer's Python packages into $REPO/.venv (once)..."
    "$PY" -m venv "$REPO/.venv" || die "cannot make a venv"
    "$REPO/.venv/bin/python" -m pip install -q --upgrade pip
    "$REPO/.venv/bin/python" -m pip install -q 'capstone>=5,<6' lz4 backports.zstd
    PY="$REPO/.venv/bin/python"
fi

# ---- the .NET 10 runtime the shader translator runs on
if [ -z "${DOTNET_ROOT:-}" ]; then
    if command -v dotnet >/dev/null 2>&1; then DOTNET_ROOT=$(dirname "$(command -v dotnet)"); else
        die "the .NET 10 runtime is needed: install it (BUILD-PACK.md) or set DOTNET_ROOT"
    fi
fi
export DOTNET_ROOT
"$DOTNET_ROOT/dotnet" --list-runtimes 2>/dev/null | grep -q 'Microsoft.NETCore.App 10' || die "no .NET 10 runtime in $DOTNET_ROOT"

# ---- the game file: a retail .nsp/.xci/.nsz/.xcz is merged into a .nup first
need_nup=0
for f in "$@"; do
    case "$f" in *.nsp|*.xci|*.nsz|*.xcz) need_nup=1 ;; esac
done
mkdir -p "$OUT"
if [ "$need_nup" = 1 ]; then
    NX="$REPO/build-import/nximport_cli"
    if [ ! -x "$NX" ]; then
        command -v cmake >/dev/null 2>&1 || die "cmake is needed to build the importer"
        say "Building the importer (once)..."
        cmake -S "$REPO/dm/peanuts/import" -B "$REPO/build-import" >/dev/null || die "cmake configure failed"
        cmake --build "$REPO/build-import" -j >/dev/null || die "the importer did not build"
    fi
    KEYS=${PROD_KEYS:-$HERE/prod.keys}
    [ -f "$KEYS" ] || die "prod.keys not found: put it in this folder or set PROD_KEYS"
    say "Merging the game, the update and the DLC into $OUT/$NAME ..."
    "$NX" --keys "$KEYS" nup "$OUT/$NAME" "$TITLE" "$@" || die "the importer failed"
    GAME="$OUT/$NAME"
else
    GAME="$1"
    [ -e "$GAME" ] || die "no such file or folder: $GAME"
fi

if [ "$UPDATE" = 1 ] && [ $# -lt 2 ]; then
    say "WARNING: Smash's pack is made for 13.0.5 (v2031616). Pass the update file after the base game."
fi

# ---- the pack (code rewritten, shaders translated)
JOBS=${JOBS:-$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN || echo 4)}
say "Packing $GAME (version $PACK_VERSION) into $OUT/pack ..."
if [ "$KIND" = smash ]; then
    say "The first Smash run translates 35,012 shaders: about 1.5-2 hours; later runs take minutes."
fi
"$PY" "$REPO/scripts/pack_android.py" "$GAME" --version "$PACK_VERSION" --out "$OUT/pack" \
    --shader-python "$PY" -J "$JOBS" || die "the packer failed"

# ---- pack.zip, what the app's PACK card takes
say "Zipping $OUT/pack.zip ..."
"$PY" - "$OUT/pack" "$OUT/pack.zip" <<'PY'
import os, sys, zipfile
root, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=1) as z:
    for dp, dn, fn in os.walk(root):
        for f in fn:
            p = os.path.join(dp, f)
            z.write(p, os.path.relpath(p, root))
PY

say ""
say "Done. Two files, on the phone:"
say "  $OUT/$NAME     -> GAME FILE"
say "  $OUT/pack.zip  -> PACK (import it once)"
