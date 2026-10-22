#!/usr/bin/env bash
# Build a XAMPP installer locally with Docker for a given PHP version key and target.
#
# Usage: build.sh <php_key> [target] [--rebuild-image]
#   php_key : the PHP maintenance-line key from metadata/versions/versions.ini, e.g. 84, 85,
#             or "multi" for the Windows multi-version installer (PHP 8.2-8.5 + MariaDB 10.11/11.8)
#   target  : windows-x64 (default) or osx-x64 ("multi" only supports windows-x64)
#
# Requires Docker Desktop running. On Apple Silicon, Rosetta crashes the
# (x86_64-only) InstallBuilder installer, so this script always builds/runs
# the image with --platform linux/amd64, which falls back to QEMU emulation.
# If QEMU handlers are not registered yet, it registers them automatically.

set -euo pipefail

PHP_KEY="${1:-}"
TARGET="${2:-windows-x64}"
REBUILD_IMAGE=0
for arg in "$@"; do
  [ "$arg" = "--rebuild-image" ] && REBUILD_IMAGE=1
done

if [ -z "$PHP_KEY" ]; then
  echo "Usage: $0 <php_key|multi> [windows-x64|osx-x64] [--rebuild-image]" >&2
  echo "Available PHP keys (or 'multi' for the multi-version Windows installer):" >&2
  awk '/^\[PHP\]/{f=1;next} /^\[/{f=0} f' "$(git rev-parse --show-toplevel)/metadata/versions/versions.ini" >&2
  exit 1
fi

ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$ROOT"

VERSIONS_INI="metadata/versions/versions.ini"
WORKFLOW="/.github/workflows/build.yml"
WORKFLOW="$ROOT/.github/workflows/build.yml"

# ini_get <section> <key>: value of <key>= inside [<section>] of versions.ini
ini_get() {
  awk -v section="$1" -v key="$2" 'index($0, "["section"]") == 1{f=1;next} /^\[/{f=0} f && $0 ~ "^"key"="{split($0,a,"=");print a[2]}' "$VERSIONS_INI"
}

if [ "$PHP_KEY" = "multi" ]; then
  if [ "$TARGET" != "windows-x64" ]; then
    echo "ERROR: the multi-version installer only supports windows-x64." >&2
    exit 1
  fi
  # Inputs of windows64XamppInstallerMultiStack (src/xamppwindows64.tcl), resolved from versions.ini
  # exactly like the Tcl components do. Format: <versions.ini section> <key> <zip name pattern>
  MULTI_INPUTS="
PHP 82 php-@V@-Win32-vs16-x64.zip
PHP 83 php-@V@-Win32-vs16-x64.zip
PHP 84 php-@V@-Win32-vs17-x64.zip
PHP 85 php-@V@-Win32-vs17-x64.zip
MariaDB 10 mariadb-@V@-winx64.zip
MariaDB 11 mariadb-@V@-winx64.zip"
  MULTI_ZIPS=""
  while read -r section key pattern; do
    [ -z "$section" ] && continue
    version=$(ini_get "$section" "$key")
    if [ -z "$version" ]; then
      echo "ERROR: [$section] $key not found in $VERSIONS_INI (required by the multi-version installer)." >&2
      exit 1
    fi
    MULTI_ZIPS="$MULTI_ZIPS ${pattern//@V@/$version}"
  done <<< "$MULTI_INPUTS"
  echo "==> Multi-version installer:$MULTI_ZIPS"
else
  PHP_VERSION=$(ini_get PHP "$PHP_KEY")

  if [ -z "$PHP_VERSION" ]; then
    echo "ERROR: PHP key '$PHP_KEY' not found in $VERSIONS_INI." >&2
    echo "This usually means that PHP version has not been pinned yet." >&2
    echo "Before adding it: confirm a STABLE release exists (check https://www.php.net/releases/ or https://endoflife.date/php)" >&2
    echo "and that a precompiled Windows binary (php-X.Y.Z-WinNN-vsNN-x64.zip) is published by the upstream" >&2
    echo "thirdparties tarball this repo uses (see base_tarball URL in $WORKFLOW)." >&2
    exit 1
  fi

  echo "==> PHP $PHP_KEY -> $PHP_VERSION"
fi
echo "==> Target: $TARGET"

# --- Release notes sanity check -------------------------------------------
RELEASE_NOTES="apps/xampp/RELEASENOTES-${PHP_KEY}-${TARGET}"
if [ ! -f "$RELEASE_NOTES" ]; then
  echo "WARNING: $RELEASE_NOTES does not exist." >&2
  echo "The packaging step (shipReleaseNotes in src/xamppstacks.tcl) copies this file and will fail without it." >&2
  echo "Create it (copy the structure of an existing RELEASENOTES-*-${TARGET} file) before continuing." >&2
  exit 1
fi

# --- Docker image ----------------------------------------------------------
if [ "$REBUILD_IMAGE" = "1" ] || ! docker image inspect xampp-build >/dev/null 2>&1; then
  echo "==> Building xampp-build image (linux/amd64)..."
  docker build --platform linux/amd64 . -t xampp-build
fi

# --- Tarballs ---------------------------------------------------------------
mkdir -p tarballs
cd tarballs

if [ "$TARGET" = "windows-x64" ]; then
  BASE_URL=$(grep -A2 'base_tarball:' "$WORKFLOW" | grep -oE 'https://[^"]+tarballs-windows[^"]+\.tgz' | head -1)
  BASE_SHA=$(grep 'base_tarball_sha256:' "$WORKFLOW" | grep -oE '[0-9a-f]{64}' | head -1)
  BASE_FILE=$(basename "$BASE_URL")

  if [ ! -f "$BASE_FILE" ] || ! (echo "$BASE_SHA  $BASE_FILE" | shasum -a 256 -c - >/dev/null 2>&1); then
    echo "==> Downloading base tarball ($BASE_FILE)..."
    curl -fL --retry 5 --retry-delay 3 -sS -O "$BASE_URL"
    echo "$BASE_SHA  $BASE_FILE" | shasum -a 256 -c -
    tar -xzf "$BASE_FILE"
  fi

  if [ "$PHP_KEY" = "multi" ]; then
    for zip in $MULTI_ZIPS; do
      if [ ! -f "windows/$zip" ]; then
        echo "ERROR: missing input tarballs/windows/$zip for the multi-version installer." >&2
        echo "Place the official zip in tarballs/windows/ (it may not be part of the CI base tarball)." >&2
        exit 1
      fi
    done
  else
    PHP_ZIP_GLOB="windows/php-${PHP_VERSION}-Win32-*"
    # shellcheck disable=SC2086
    if ! ls $PHP_ZIP_GLOB >/dev/null 2>&1; then
      echo "ERROR: no precompiled PHP zip matching $PHP_ZIP_GLOB found in the base tarball." >&2
      echo "This PHP version is not bundled in the current thirdparties tarball referenced by the CI workflow." >&2
      echo "The base_tarball URL/date in $WORKFLOW must be updated by upstream before this version can be packaged." >&2
      exit 1
    fi
  fi

  EXTRA=$(grep -A3 'extra_binaries:' "$WORKFLOW" | grep -oE 'https://[^ ]+ [0-9a-f]{64}' || true)
  if [ -n "$EXTRA" ]; then
    while read -r url sha; do
      [ -z "$url" ] && continue
      f=$(basename "$url")
      if [ ! -f "$f" ] || ! (echo "$sha  $f" | shasum -a 256 -c - >/dev/null 2>&1); then
        echo "==> Downloading extra binary ($f)..."
        curl -fL --retry 5 --retry-delay 3 -sS -O "$url"
        echo "$sha  $f" | shasum -a 256 -c -
      fi
    done <<< "$EXTRA"
  fi
else
  echo "NOTE: target '$TARGET' needs its own precompiled base tarball (see metadata/versions/base_tarballs.ini" >&2
  echo "under [XamppInstaller${PHP_KEY}Stack] -> ${TARGET}). Download it manually from" >&2
  echo "https://sourceforge.net/projects/xampp/files/thirdparties/ and extract it into tarballs/ before continuing." >&2
fi

cd "$ROOT"

# --- Pack --------------------------------------------------------------------
STACK_CLASS="xamppinstaller${PHP_KEY}stack"
[ "$TARGET" != "windows-x64" ] && STACK_CLASS="xamppunixinstaller${PHP_KEY}stack"

OUT_DIR="dist-local-${PHP_KEY}-${TARGET}"
mkdir -p "$OUT_DIR"

echo "==> Packing $STACK_CLASS for $TARGET ..."
docker run --rm --platform linux/amd64 \
  -v "$ROOT":/opt/xampp-build \
  -v "$ROOT/tarballs":/tmp/tarballs \
  -v "$ROOT/$OUT_DIR":/opt/installbuilder/output \
  xampp-build bash -lc "
    set -uo pipefail
    mkdir -p /bitnami
    cd /opt/xampp-build/src
    tclkit createstack.tcl pack ${STACK_CLASS} ${TARGET} || true
    ls /opt/installbuilder/output/*.exe >/dev/null 2>&1 || {
      echo 'ERROR: no installer was produced. Scroll up for the InstallBuilder error.' >&2
      exit 1
    }
  "

echo "==> Done. Installer(s):"
ls -lh "$OUT_DIR"
echo
echo "NOTE: if built without a registered InstallBuilder license, the installer is watermarked"
echo "(evaluation version) but otherwise fully functional. Request a free OSI license at"
echo "sales@installbuilder.com for a clean build (see https://installbuilder.com/open-source-licenses)."
