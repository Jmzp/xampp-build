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
- [ ] T1 Inputs + versions.ini (`82=8.2.35`, `[MariaDB] 11=11.8.9`) — route: inline (mechanical)
- [ ] T2 Tcl components + `windows64XamppInstallerMultiStack` + `xamppinstallermultistack` + release notes — route: delegated writer (2+ non-trivial files)
- [ ] T3 Installer XML (`xampp-php-multi.xml`, `xampp-mysql-multi.xml`) + post-install (junctions, 11.8 init, relocation of all ini files) — route: delegated writer
- [ ] T4 Switcher `apps/xampp/multi/xampp-switch.ps1` + `.bat` (+ Pester tests if pwsh available) — route: delegated writer
- [ ] T5 `build.sh multi` support + skill docs; build installer and inspect payload — route: delegated writer + build

## Acceptance criteria
- `build.sh multi windows-x64` produces `dist-local-multi-windows-x64/*.exe`.
- Payload contains `php-versions/{8.2,8.3,8.4,8.5}` and `mysql-versions/{10.11,11.8}`.
- Switcher refuses when target is a real directory; only removes junctions.

## Progress / Evidence
- Branch `feat/xampp-multi-version` created from main (uncommitted PHP 8.4.27 bump left out of commits).

## Next step
T1.
