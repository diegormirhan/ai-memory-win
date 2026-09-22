<#
.SYNOPSIS
Instala o ai-memory para o usuário atual do Windows.

.DESCRIPTION
Bootstrapper para o fluxo único do projeto. Em desenvolvimento, use
`-SourcePath` com um ai-memory.exe local. Para publicação, configure
`$ReleaseRepository` abaixo e publique um ZIP contendo ai-memory.exe mais um
arquivo SHA-256 com o mesmo nome e sufixo `.sha256`.

.EXAMPLE
./install.ps1 -SourcePath .\target\release\ai-memory.exe -Agent Codex

.EXAMPLE
irm https://example.invalid/install.ps1 | iex
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidatePattern('^[0-9A-Za-z._-]+$')]
    [string]$Version = 'latest',

    [ValidateSet('None', 'Codex', 'ClaudeCode')]
    [string]$Agent = 'None',

    [string]$SourcePath,

    [switch]$SkipPath,

    [switch]$SkipServer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Release configuration: set this once when the project has a public GitHub
# repository. The release asset is `ai-memory-windows-x86_64.zip`.
$ReleaseRepository = '__SET_RELEASE_REPOSITORY__'
$AssetName = 'ai-memory-windows-x86_64.zip'
$TaskName = 'ai-memory'
$InstallRoot = Join-Path $env:LOCALAPPDATA 'Programs\ai-memory'
$DataRoot = Join-Path $env:LOCALAPPDATA 'ai-memory'

function Assert-WindowsHost {
    if ($env:OS -ne 'Windows_NT') {
        throw 'ai-memory only supports native Windows.'
    }
}

function Get-ReleaseAssetUri {
    param([string]$RequestedVersion)

    if ($ReleaseRepository -eq '__SET_RELEASE_REPOSITORY__') {
        throw 'Release repository is not configured. Set $ReleaseRepository in install.ps1 or use -SourcePath during development.'
    }

    $releasePath = if ($RequestedVersion -eq 'latest') {
        'releases/latest/download'
    } else {
        "releases/download/v$RequestedVersion"
    }

    return "https://github.com/$ReleaseRepository/$releasePath/$AssetName"
}

function New-InstallerTempDirectory {
    $directory = Join-Path ([System.IO.Path]::GetTempPath()) ("ai-memory-install-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    return $directory
}

function Get-ExpectedSha256 {
    param([string]$ChecksumPath)

    $contents = (Get-Content -LiteralPath $ChecksumPath -Raw).Trim()
    $match = [regex]::Match($contents, '(?im)\b[a-f0-9]{64}\b')
    if (-not $match.Success) {
        throw "Checksum file does not contain a SHA-256 value: $ChecksumPath"
    }
    return $match.Value.ToUpperInvariant()
}

function Assert-ArchiveChecksum {
    param(
        [string]$ArchivePath,
        [string]$ChecksumPath
    )

    $expected = Get-ExpectedSha256 -ChecksumPath $ChecksumPath
    $actual = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actual -ne $expected) {
        throw "Checksum verification failed for $ArchivePath. Expected $expected, received $actual."
    }
}

function Get-BinaryFromRelease {
    param([string]$WorkingDirectory)

    $archivePath = Join-Path $WorkingDirectory $AssetName
    $checksumPath = "$archivePath.sha256"
    $assetUri = Get-ReleaseAssetUri -RequestedVersion $Version

    Write-Host "Downloading ai-memory $Version..."
    Invoke-WebRequest -Uri $assetUri -OutFile $archivePath
    Invoke-WebRequest -Uri "$assetUri.sha256" -OutFile $checksumPath
    Assert-ArchiveChecksum -ArchivePath $archivePath -ChecksumPath $checksumPath

    $extractRoot = Join-Path $WorkingDirectory 'extract'
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractRoot -Force
    $binaries = @(Get-ChildItem -LiteralPath $extractRoot -Recurse -File -Filter 'ai-memory.exe')
    if ($binaries.Count -ne 1) {
        throw "Expected one ai-memory.exe in the release archive; found $($binaries.Count)."
    }
    return $binaries[0].FullName
}

function Install-Binary {
    param([string]$BinaryPath)

    if (-not (Test-Path -LiteralPath $BinaryPath -PathType Leaf)) {
        throw "ai-memory.exe was not found: $BinaryPath"
    }

    $stagingRoot = "$InstallRoot.staging"
    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
    Copy-Item -LiteralPath $BinaryPath -Destination (Join-Path $stagingRoot 'ai-memory.exe') -Force

    if ($PSCmdlet.ShouldProcess($InstallRoot, 'Install ai-memory.exe')) {
        if (Test-Path -LiteralPath $InstallRoot) {
            Remove-Item -LiteralPath $InstallRoot -Recurse -Force
        }
        Move-Item -LiteralPath $stagingRoot -Destination $InstallRoot
    }

    return Join-Path $InstallRoot 'ai-memory.exe'
}

function Add-InstallRootToUserPath {
    if ($SkipPath) {
        return
    }

    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($currentPath -split ';' | Where-Object { $_ })
    if ($entries -contains $InstallRoot) {
        return
    }

    $updatedPath = (@($entries) + $InstallRoot) -join ';'
    if ($PSCmdlet.ShouldProcess('User PATH', "Add $InstallRoot")) {
        [Environment]::SetEnvironmentVariable('Path', $updatedPath, 'User')
    }
}

function Invoke-AiMemory {
    param(
        [string]$BinaryPath,
        [string[]]$Arguments
    )

    & $BinaryPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ai-memory failed with exit code ${LASTEXITCODE}: $($Arguments -join ' ')"
    }
}

function Install-ServerTask {
    param([string]$BinaryPath)

    $action = New-ScheduledTaskAction -Execute $BinaryPath -Argument "--data-dir `"$DataRoot`" serve"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Days 0)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited

    if ($PSCmdlet.ShouldProcess("Scheduled Task/$TaskName", 'Register ai-memory server')) {
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description 'Runs the local ai-memory server.' -Force | Out-Null
        Start-ScheduledTask -TaskName $TaskName
    }
}

function Install-AgentIntegration {
    param([string]$BinaryPath)

    if ($Agent -eq 'None') {
        return
    }

    $agentName = switch ($Agent) {
        'Codex' { 'codex' }
        'ClaudeCode' { 'claude-code' }
        default { throw "Unsupported agent: $Agent" }
    }

    Invoke-AiMemory -BinaryPath $BinaryPath -Arguments @('--data-dir', $DataRoot, 'install-mcp', '--client', $agentName, '--apply')
    Invoke-AiMemory -BinaryPath $BinaryPath -Arguments @('--data-dir', $DataRoot, 'install-hooks', '--agent', $agentName, '--apply')
}

function Install-AiMemory {
    Assert-WindowsHost
    $temporaryDirectory = New-InstallerTempDirectory

    try {
        $binarySource = if ($SourcePath) {
            (Resolve-Path -LiteralPath $SourcePath).Path
        } else {
            Get-BinaryFromRelease -WorkingDirectory $temporaryDirectory
        }

        $binaryPath = Install-Binary -BinaryPath $binarySource
        Add-InstallRootToUserPath

        if (-not $WhatIfPreference) {
            Invoke-AiMemory -BinaryPath $binaryPath -Arguments @('--data-dir', $DataRoot, 'init')
            if (-not $SkipServer) {
                Install-ServerTask -BinaryPath $binaryPath
            }
            Install-AgentIntegration -BinaryPath $binaryPath
            Invoke-AiMemory -BinaryPath $binaryPath -Arguments @('--data-dir', $DataRoot, 'status')
        }

        Write-Host "ai-memory installed in $InstallRoot"
        Write-Host "Data directory: $DataRoot"
        Write-Host 'Open a new PowerShell window before using ai-memory from PATH.'
    } finally {
        if (Test-Path -LiteralPath $temporaryDirectory) {
            Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
        }
    }
}

Install-AiMemory
