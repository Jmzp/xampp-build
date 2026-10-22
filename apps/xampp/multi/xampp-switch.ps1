<#
.SYNOPSIS
    Switches the active PHP or MariaDB version of a multi-version XAMPP.

.DESCRIPTION
    Every bundled version lives in xampp\php-versions\<version> and
    xampp\mysql-versions\<version>. xampp\php and xampp\mysql are NTFS
    directory junctions to the active versions, so Apache, the XAMPP Control
    Panel and every configuration file keep using \xampp\php and \xampp\mysql.

    This script stops Apache or MySQL if they are running, re-points the
    junction and prints the version that is now active. It only ever removes
    junctions: if xampp\php or xampp\mysql is a real folder it refuses to
    touch it.

.EXAMPLE
    xampp-switch php 8.3
.EXAMPLE
    xampp-switch mysql 11.8
.EXAMPLE
    xampp-switch list
.EXAMPLE
    xampp-switch
    Shows an interactive menu.
#>
param(
    [Parameter(Position = 0)] [string] $Component,
    [Parameter(Position = 1)] [string] $Version
)

$ErrorActionPreference = 'Stop'

# The script is shipped in the XAMPP root folder
$XamppDir = $PSScriptRoot

$Components = [ordered]@{
    php   = @{
        Label       = 'PHP'
        Link        = 'php'
        VersionsDir = 'php-versions'
        Server      = 'Apache'
        Processes   = @('httpd')
        StopScript  = 'apache_stop.bat'
    }
    mysql = @{
        Label       = 'MariaDB'
        Link        = 'mysql'
        VersionsDir = 'mysql-versions'
        Server      = 'MySQL'
        Processes   = @('mysqld', 'mariadbd')
        StopScript  = 'mysql_stop.bat'
    }
}

function Get-ComponentInfo([string] $Name) {
    $key = $Name.ToLowerInvariant()
    if (-not $Components.Contains($key)) {
        throw "Unknown component '$Name'. Use 'php' or 'mysql'."
    }
    return $Components[$key]
}

function Get-AvailableVersions($Info) {
    $dir = Join-Path $XamppDir $Info.VersionsDir
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        throw "$dir does not exist. Is this a multi-version XAMPP installation?"
    }
    # Sort numerically: 8.10 comes after 8.9, 11.8 after 10.11
    return @(Get-ChildItem -LiteralPath $dir -Directory |
        Sort-Object {
            $parsed = $null
            if ([version]::TryParse($_.Name + '.0', [ref] $parsed)) { $parsed } else { [version] '0.0' }
        } |
        ForEach-Object { $_.Name })
}

# Returns the xampp\php or xampp\mysql entry without following it, or $null.
# Listing the parent folder also finds junctions whose target is missing.
function Get-LinkItem($Info) {
    return Get-ChildItem -LiteralPath $XamppDir -Force |
        Where-Object { $_.Name -eq $Info.Link } |
        Select-Object -First 1
}

function Test-Junction($Item) {
    return [bool]($Item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Get-ActiveVersion($Info) {
    $item = Get-LinkItem $Info
    if (-not $item -or -not (Test-Junction $item)) {
        return $null
    }
    $target = @($item.Target) | Select-Object -First 1
    if (-not $target) {
        return $null
    }
    return Split-Path -Leaf $target.TrimEnd('\')
}

function Get-ServerProcesses($Info) {
    # Only processes started from this XAMPP folder. Path can be empty for
    # processes of other users (e.g. services), treat those as ours to be safe.
    $prefix = $XamppDir.TrimEnd('\') + '\'
    return @(Get-Process -Name $Info.Processes -ErrorAction SilentlyContinue |
        Where-Object { -not $_.Path -or $_.Path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) })
}

function Stop-Server($Info) {
    if ((Get-ServerProcesses $Info).Count -eq 0) {
        return
    }
    Write-Host "Stopping $($Info.Server)..."
    $stopScript = Join-Path $XamppDir $Info.StopScript
    if (Test-Path -LiteralPath $stopScript) {
        & $stopScript | Out-Null
    }
    # The XAMPP stop scripts return immediately, wait for the processes to exit
    for ($i = 0; $i -lt 30; $i++) {
        if ((Get-ServerProcesses $Info).Count -eq 0) {
            return
        }
        Start-Sleep -Seconds 1
    }
    throw "$($Info.Server) is still running (is it installed as a Windows service?). Stop it from the XAMPP Control Panel and try again."
}

function Copy-PhpRuntimeLibraries([string] $PhpDir) {
    # Apache loads these PHP dependencies from apache\bin
    $apacheBin = Join-Path $XamppDir 'apache\bin'
    if (-not (Test-Path -LiteralPath $apacheBin -PathType Container)) {
        return
    }
    Get-ChildItem -LiteralPath $PhpDir -File |
        Where-Object { $_.Name -like 'icu*.dll' -or $_.Name -eq 'libsasl.dll' } |
        ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $apacheBin -Force }
}

function Show-ActiveVersion($Info) {
    $link = Join-Path $XamppDir $Info.Link
    if ($Info.Link -eq 'php') {
        & (Join-Path $link 'php.exe') -v
    } else {
        $server = Join-Path $link 'bin\mariadbd.exe'
        if (-not (Test-Path -LiteralPath $server)) {
            $server = Join-Path $link 'bin\mysqld.exe'
        }
        & $server --version
    }
}

function Switch-Version([string] $Name, [string] $NewVersion) {
    $info = Get-ComponentInfo $Name
    $versions = Get-AvailableVersions $info
    if ($versions -notcontains $NewVersion) {
        throw "$($info.Label) $NewVersion is not installed. Available: $($versions -join ', ')"
    }

    $link = Join-Path $XamppDir $info.Link
    $target = Join-Path (Join-Path $XamppDir $info.VersionsDir) $NewVersion

    if ($info.Link -eq 'mysql' -and -not (Test-Path -LiteralPath (Join-Path $target 'data') -PathType Container)) {
        throw "$target\data does not exist. Initialize it first with: `"$target\bin\mariadb-install-db.exe`" --datadir=`"$target\data`""
    }

    # Never remove a real folder: it may hold user data
    $item = Get-LinkItem $info
    if ($item -and -not (Test-Junction $item)) {
        throw "$link is a real folder, not a junction. Refusing to replace it; move it away manually first."
    }

    if ((Get-ActiveVersion $info) -eq $NewVersion) {
        Write-Host "$($info.Label) $NewVersion is already active."
        return
    }

    Stop-Server $info

    if ($item) {
        # Non-recursive delete of a reparse point removes the junction only,
        # never the content of its target (same as "rmdir" without /S)
        [IO.Directory]::Delete($item.FullName, $false)
    }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null

    if ($info.Link -eq 'php') {
        Copy-PhpRuntimeLibraries $target
    }

    Write-Host "$($info.Label) switched to $NewVersion ($link -> $target)" -ForegroundColor Green
    Show-ActiveVersion $info
    Write-Host "Start $($info.Server) again from the XAMPP Control Panel."
}

function Show-List {
    foreach ($name in $Components.Keys) {
        $info = $Components[$name]
        $active = Get-ActiveVersion $info
        Write-Host "$($info.Label) ($name):"
        foreach ($v in (Get-AvailableVersions $info)) {
            $marker = if ($v -eq $active) { '*' } else { ' ' }
            Write-Host "  $marker $v"
        }
    }
    Write-Host '(* = active)'
}

function Read-Choice([string] $Prompt, [string[]] $Options) {
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host ("  {0}) {1}" -f ($i + 1), $Options[$i])
    }
    $answer = Read-Host $Prompt
    $index = 0
    if (-not [int]::TryParse($answer, [ref] $index) -or $index -lt 1 -or $index -gt $Options.Count) {
        throw "Invalid choice '$answer'"
    }
    return $Options[$index - 1]
}

function Show-Menu {
    Show-List
    Write-Host ''
    Write-Host 'What do you want to switch?'
    $name = Read-Choice 'Component' @($Components.Keys)
    $info = $Components[$name]
    Write-Host "Available $($info.Label) versions:"
    $newVersion = Read-Choice 'Version' (Get-AvailableVersions $info)
    Switch-Version $name $newVersion
}

function Show-Usage {
    Write-Host 'Usage:'
    Write-Host '  xampp-switch php <version>     e.g. xampp-switch php 8.3'
    Write-Host '  xampp-switch mysql <version>   e.g. xampp-switch mysql 11.8'
    Write-Host '  xampp-switch list'
    Write-Host '  xampp-switch                   interactive menu'
}

try {
    if (-not $Component) {
        Show-Menu
    } elseif ($Component -eq 'list') {
        Show-List
    } elseif ($Component -in @('help', '-h', '--help', '/?')) {
        Show-Usage
    } elseif (-not $Version) {
        Show-Usage
        exit 1
    } else {
        Switch-Version $Component $Version
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
