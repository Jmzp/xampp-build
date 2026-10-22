---
name: xampp-build-installer
description: Build a local XAMPP installer for a given PHP version (Windows x64, or macOS/Linux with a manually supplied base tarball). Use whenever asked to bump/generate/package a XAMPP installer for a specific PHP version, or to check whether a PHP version can be packaged yet.
---

# Building a XAMPP installer

This repo (`xampp-build`) is Apache Friends' XAMPP build system. Producing an
installer for a PHP version is almost always just a **packaging** exercise —
PHP itself is never compiled here on Windows; it comes precompiled inside a
"thirdparties" base tarball referenced by `.github/workflows/build.yml`.

## Step 0 — Confirm the PHP version is actually released and packageable

Before doing anything: **PHP alpha/beta/RC versions cannot be packaged.** XAMPP
only bundles precompiled binaries of stable releases. If asked for a version
that doesn't appear in `metadata/versions/versions.ini`, check its real-world
status (e.g. web search "PHP X.Y release date status") before attempting
anything — if it's pre-alpha/alpha/beta, tell the user and stop; there's
nothing to build until upstream ships stable binaries.

## Step 1 — Check if the version is already pinned

```bash
grep -A10 '^\[PHP\]' metadata/versions/versions.ini
```

Each line is `<key>=<version>`, e.g. `84=8.4.20`. The `<key>` (e.g. `84`) is
what everything else in the codebase keys off: Tcl stack classes
(`src/xamppstacks.tcl`), release notes filenames, revisions.

- If the target version's key already has the right value: skip to Step 2.
- If it's missing or stale: update it in `versions.ini`. No other code change
  is normally needed — `xamppinstaller<key>stack` classes for `74`–`85`
  already exist in `src/xamppstacks.tcl`. Only a genuinely new key (e.g. the
  first time `86` becomes real) requires adding a new stack class there,
  modeled on the `xamppinstaller85stack` block.

## Step 2 — Check release notes exist

`src/xamppstacks.tcl`'s `shipReleaseNotes` copies
`apps/xampp/RELEASENOTES-<key>-<target>` and **fails the whole build** if it's
missing. Check:

```bash
ls apps/xampp/RELEASENOTES-<key>-*
```

If the target (`windows-x64`, `linux-x64`, or `osx-x64`) is missing, create it
by copying the format of an existing file for that same target (e.g.
`RELEASENOTES-82-osx-x64`) and filling in the version/date/component list from
`versions.ini`.

## Step 3 — Run the build script

```bash
.claude/skills/xampp-build-installer/scripts/build.sh <key> windows-x64
```

This script (idempotent, safe to re-run):
1. Builds the `xampp-build` Docker image if not already built — always with
   `--platform linux/amd64` (see "Apple Silicon" note below).
2. Downloads and SHA-256-verifies the Windows base tarball + extra binaries,
   reusing the exact URL/hash already pinned in `.github/workflows/build.yml`
   (single source of truth — don't hardcode a second copy anywhere).
3. Confirms a precompiled `php-<version>-Win32-*` zip for that version
   actually exists inside the tarball before attempting to pack (if it
   doesn't, the thirdparties tarball upstream needs updating first — this is
   not something to work around locally).
4. Runs `tclkit createstack.tcl pack xamppinstaller<key>stack windows-x64`
   inside the container, mounted so the installer lands in
   `./dist-local-<key>-windows-x64/` on the host.

For `osx-x64` (or `linux-x64`) pass it as the second argument — the script
will point out that those targets need their own base tarball (see
`metadata/versions/base_tarballs.ini` under `[XamppInstaller<key>Stack]`),
fetched manually from https://sourceforge.net/projects/xampp/files/thirdparties/
into `tarballs/`, since CI currently only builds `windows-x64`.

## Multi-version Windows installer (`multi`)

```bash
.claude/skills/xampp-build-installer/scripts/build.sh multi windows-x64
```

Packs `xamppinstallermultistack` (Tcl stack `windows64XamppInstallerMultiStack`
in `src/xamppwindows64.tcl`) into `./dist-local-multi-windows-x64/`. It bundles
PHP 8.2/8.3/8.4/8.5 (`[PHP]` keys `82`–`85`) and MariaDB 10.11/11.8 (`[MariaDB]`
keys `10`/`11`) side by side under `xampp\php-versions\<x.y>` and
`xampp\mysql-versions\<x.y>`. `xampp\php` and `xampp\mysql` are NTFS junctions
created at install time (defaults PHP 8.4 and MariaDB 10.11) and re-pointed with
`xampp-switch.bat` (`apps/xampp/multi/`).

- Only `windows-x64` is supported. The script skips the single-version check and
  instead requires every PHP/MariaDB zip resolved from `versions.ini`
  (e.g. `php-8.2.35-Win32-vs16-x64.zip`, `mariadb-11.8.9-winx64.zip`) to exist
  in `tarballs/windows/`, naming the missing one otherwise.
- Release notes: `apps/xampp/RELEASENOTES-multi-windows-x64`.
- Installer XML: `apps/xampp/xampp-php-multi.xml` and `xampp-mysql-multi.xml`
  replace `xampp-php.xml`/`xampp-mysql.xml` for this stack only.
- Adding or removing a branch means updating `::xamppmulti` and the stack in
  `src/xamppwindows64.tcl`, both multi XML files, the input list in
  `build.sh` and the release notes.

## Known gotchas (already handled by the script, keep in mind if debugging)

- **Apple Silicon + Rosetta crashes InstallBuilder.** The `.run` installer is
  x86_64-only and segfaults under Docker Desktop's default Rosetta
  acceleration (`rosetta error: failed to open elf`, exit 133). Fix: Docker
  must run the container under QEMU instead — either pass
  `--platform linux/amd64` (works either way) with Rosetta disabled in Docker
  Desktop settings (`UseVirtualizationFrameworkRosetta: false` in
  `~/Library/Group Containers/group.com.docker/settings-store.json`, requires
  restarting Docker Desktop), or ensure QEMU binfmt handlers are registered
  (`docker run --privileged --rm tonistiigi/binfmt --install amd64`).
- **Evaluation-mode InstallBuilder exits 1 even on success.** Without a
  registered license, `builder` prints "EVALUATION VERSION: Please update the
  InstallBuilder license" and still exits non-zero — *after* placing a fully
  working (watermarked) installer in `/opt/installbuilder/output/`. Don't
  treat that exit code as fatal; check whether the `.exe` was produced
  instead (the script and the CI workflow both do this already).
- **Free licensing option:** InstallBuilder is free for OSI-compliant open
  source projects (which this is). Request one from
  sales@installbuilder.com — see https://installbuilder.com/open-source-licenses.
  With a license registered (`INSTALLBUILDER_LICENSE` secret in CI, or
  `/opt/installbuilder/license.xml` locally), the watermark disappears.

## Building via GitHub Actions instead

`.github/workflows/build.yml` (`workflow_dispatch`) builds natively on
`ubuntu-latest` — no Rosetta/QEMU concerns. Useful as a second, independent
build path:

```bash
gh workflow run build.yml --ref <branch>
gh run watch <run-id> --exit-status
gh run download <run-id> -n xampp-<key>-windows-x64 -D dist-ci
```

Edit the `matrix.version` list in the workflow to include the key(s) you want
built.
