# Feature: xampp-multi-version

## Objective
Single Windows x64 XAMPP installer bundling PHP 8.2/8.3/8.4/8.5 and MariaDB 10.11/11.8 side by side,
with a switcher that selects the active version via NTFS directory junctions
(`xampp\php` -> `xampp\php-versions\<ver>`, `xampp\mysql` -> `xampp\mysql-versions\<ver>`).

## Problem / Why
Each installer ships exactly one PHP and one MariaDB. Users want to pick versions without rebuilding.
All configs and the prebuilt `xampp-control.exe` hardcode `xampp\php` and `xampp\mysql`, so junctions
keep them working unchanged.

## Scope
- In: Tcl components/stack for multi build, installer XML + post-install actions, switcher script
  (`xampp-switch.ps1`/`.bat`), `build.sh multi` support, release notes, versions.ini.
- Out: PHP 7.4, Control Panel integration (Delphi not built here), installer-generator app, CI changes.

## Constraints
- Inputs (verified SHA-256, in `tarballs/windows/`, not committed): php-8.2.35-Win32-vs16-x64.zip,
  php-8.3.30-Win32-vs16-x64.zip, php-8.4.27-Win32-vs17-x64.zip, php-8.5.5-Win32-vs17-x64.zip,
  mariadb-10.11.16-winx64.zip, mariadb-11.8.9-winx64.zip.
- Real runtime test needs a Windows x64 machine; cannot be done on this Mac.
- Delivery strategy: ask-on-risk. Forecast ~600-900 authored lines (> 400) → ask chain strategy
  before the commit that crosses the budget.

## Tasks
- [x] T1 Inputs + versions.ini (`82=8.2.35`, `[MariaDB] 11=11.8.9`) — route: inline (mechanical) — commit 1d6e1c0
- [x] T2 Tcl components + `windows64XamppInstallerMultiStack` + `xamppinstallermultistack` + release notes — route: delegated writer (2+ non-trivial files)
- [x] T3 Installer XML (`xampp-php-multi.xml`, `xampp-mysql-multi.xml`) + post-install (junctions, 11.8 init, relocation of all ini files) — route: delegated writer
- [x] T4 Switcher `apps/xampp/multi/xampp-switch.ps1` + `.bat` (+ Pester tests if pwsh available) — route: delegated writer
- [x] T5 `build.sh multi` support + skill docs — route: delegated writer (installer build itself pending, see below)

## Acceptance criteria
- `build.sh multi windows-x64` produces `dist-local-multi-windows-x64/*.exe`.
- Payload contains `php-versions/{8.2,8.3,8.4,8.5}` and `mysql-versions/{10.11,11.8}`.
- Switcher refuses when target is a real directory; only removes junctions.

## Progress / Evidence
- Branch `feat/xampp-multi-version` created from main; PHP 8.4.27 bump committed as b7bba38; branch pushed to origin (Jmzp/xampp-build).
- Commits: T1 1d6e1c0, T2 94d8fe4, T3 61d5723, T4 50383d2, T5 d24bccf.
- Native review: assess = high/review_due; preflight STATUS blocked on an intended-untracked selection input (schema undocumented) — review not run.
- Parent spot check: `tclsh createstack.tcl getStackInstallerName xamppinstallermultistack windows-x64` -> xampp-windows-x64-multi-8.4.27-0-installer.exe.

### T2 evidence
- Test-first exception: no runnable deterministic test harness exists for Tcl stacks / InstallBuilder XML /
  PowerShell in this repo; proportional checks used instead.
- `tclsh` `info complete` parse check: src/xamppwindows64.tcl ok, src/xamppstacks.tcl ok.
- Scratch tclsh check of the `::xamppmulti` helper procs (relocation list rewrite: 47 php + 1 mysql entries
  expanded to 190 versioned lines, no junction entries left; staging/merge/move; LoadFile de-duplication): ok.
- `tclsh createstack.tcl getStackInstallerName xamppinstallermultistack windows-x64` ->
  `xampp-windows-x64-multi-8.4.27-0-installer.exe`.
- `tclsh createstack.tcl logComponents xamppinstallermultistack windows-x64` resolves every component:
  MariaDB 10.11.16 + 11.8.9, PHP 8.4.27/8.2.35/8.3.30/8.5.5, layout step before `xampp` (standard).
- Design: each versioned component builds into xampp/php or xampp/mysql exactly like its single-version parent
  and is then moved to `php-versions/<branch>` / `mysql-versions/<branch>`; shared PHP add-ons are staged in
  xampp/php and merged into every branch by `windows64XamppMultiVersionsLayout`, which also rewrites
  `install/xamppbasic.inc` so install.php relocates each branch's files once (junction entries dropped).
- `xamppinstallermultistack` overrides `createStack` so no base_tarballs.ini entry is needed.
- Intermediate state: the stack is not packable until T3 swaps in the multi installer XML.

### T3 evidence
- `xmllint --noout apps/xampp/xampp-php-multi.xml apps/xampp/xampp-mysql-multi.xml`: ok.
- `tclsh` parse check of src/xamppstacks.tcl: ok.
- Scratch tclsh run of the `copyProjectFiles` substitutions on copies of xampp-common.xml and
  xampp-installer-standalone.xml: excludeFiles gains `*/xampp/mysql-versions` and `*/xampp/php-versions`,
  installerFilename becomes `xampp-windows-x64-multi-8.4.27-0-installer.exe`.
- Design: the multi XML files keep the `xampp_php`/`xampp_mysql` component names and are shipped as
  xampp-php.xml/xampp-mysql.xml, so every include and `component(...)` reference keeps working.
- Junctions (`mklink /J`, relative paths, working dir `${installdir}`) are created in the folder
  `<actionList>`, which runs after unpacking and before xampp-common's install.php post-install step.
- Relocation of every branch's php.ini/my.ini: install.php through the versioned xamppbasic.inc (T2).
- MariaDB 11.8 data: `mariadb-install-db.exe --datadir=<installdir>/mysql-versions/11.8/data` post-install
  (root without password), copied to `backup/`; skipped when the data dir already exists.
- Junction removal runs in postUninstallationActionList (`rmdir` without `/S`), after xampp-common's
  pre-uninstall step stopped the services resolved through the junctions.
- Runtime behaviour on Windows not verified (no Windows machine available).

### T4 evidence
- `pwsh` is not installed on this Mac: no Pester tests and no PowerShell parse check were run (test-first
  exception); the script targets Windows PowerShell 5.1 and was reviewed manually.
- `tclsh` parse check of src/xamppwindows64.tcl after adding `copySwitcher`: ok.
- Behaviour: validates the version against the installed folders, refuses when xampp\php or xampp\mysql is
  a real folder, refuses to switch MariaDB to a branch without `data\`, stops Apache/MySQL with the XAMPP stop
  scripts and waits for httpd/mysqld/mariadbd to exit, removes only the junction
  (`[IO.Directory]::Delete(path, $false)`), creates the new one with `New-Item -ItemType Junction`, copies the
  active PHP `icu*.dll`/`libsasl.dll` into apache\bin and prints `php -v` / `mariadbd --version`.
- The layout step copies xampp-switch.bat/.ps1 to the XAMPP root (shipped by xampp-common.xml).
- Note: `core.autocrlf=input` stores the .bat with LF endings; it has no labels, so cmd runs it fine.

### T5 evidence
- `bash -n .claude/skills/xampp-build-installer/scripts/build.sh`: ok.
- Extracted `ini_get` + multi input resolution/check from build.sh and ran them against the real
  versions.ini and tarballs/windows: resolves php-8.2.35/8.3.30 (vs16), php-8.4.27/8.5.5 (vs17),
  mariadb-10.11.16, mariadb-11.8.9 -> all present (exit 0); with one name altered -> clear
  "missing input tarballs/windows/<zip>" error (exit 1).
- Numeric keys keep the same versions.ini lookup (`ini_get PHP 84` -> 8.4.27), stack class and output dir.
- NOT run: the full `build.sh multi windows-x64` pack (Rosetta crashes InstallBuilder on this Mac; Docker
  settings must not be changed), so acceptance criteria "produces dist-local-multi-windows-x64/*.exe" and
  "payload contains php-versions/... and mysql-versions/..." remain pending (CI or a QEMU-enabled Docker run).
- Runtime test on Windows x64 (install, junctions, switcher, MariaDB 11.8 init) remains pending.

## Next step
Build the installer (GitHub Actions `build.yml` with `multi` or Docker with Rosetta disabled), inspect the
payload, then test on a Windows x64 machine.
