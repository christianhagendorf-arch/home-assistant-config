[CmdletBinding()]
param(
    [ValidateRange(0, 9999)]
    [int]$PatchNumber = 0,

    [switch]$Deploy,
    [switch]$DryRunOnly,
    [switch]$ExportSources,

    [string[]]$ExportFiles = @(
        'config/dashboards/living-room-pilot.yaml',
        'config/packages/ground_floor/pilot_living_room.yaml',
        'config/themes/night_control_light.yaml',
        'config/themes/night_control_dark.yaml',
        'tools/deploy_ha_test.py',
        'tools/apply_deploy_patch.ps1'
    ),

    [string]$Repository = 'D:\GitHub\home-assistant-config',
    [string]$Target = 'ha-test'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-LastExitCode {
    param([string]$Message)
    if ($LASTEXITCODE -ne 0) {
        throw "$Message (exit code $LASTEXITCODE)"
    }
}

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
    )
    & $FilePath @Arguments
    Assert-LastExitCode "$FilePath failed"
}

function Get-TrackedStatus {
    $status = @(& git status --short --untracked-files=no)
    Assert-LastExitCode 'Unable to read Git status'
    return $status
}

Set-Location -LiteralPath $Repository

$branch = (& git branch --show-current).Trim()
Assert-LastExitCode 'Unable to determine current branch'
if ($branch -notmatch '^feature/.+') {
    throw "Unexpected branch '$branch'. Patch work must run on a feature/* branch."
}

$patchDirectory = Join-Path $Repository 'patches'

if ($ExportSources) {
    if ($Deploy -or $DryRunOnly -or $PatchNumber -ne 0) {
        throw 'Use -ExportSources by itself. Do not combine it with -PatchNumber, -Deploy, or -DryRunOnly.'
    }

    $trackedStatus = @(Get-TrackedStatus)
    if ($trackedStatus.Count -gt 0) {
        $trackedStatus | ForEach-Object { Write-Host $_ }
        throw 'Tracked working tree changes exist. Commit, restore, or stash them before exporting sources.'
    }

    $missingFiles = @($ExportFiles | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $Repository $_))
    })
    if ($missingFiles.Count -gt 0) {
        $missingFiles | ForEach-Object { Write-Host "Missing: $_" }
        throw 'One or more requested source files do not exist.'
    }

    $untrackedFiles = @(& git ls-files --others --exclude-standard -- $ExportFiles)
    Assert-LastExitCode 'Unable to validate source tracking state'
    if ($untrackedFiles.Count -gt 0) {
        $untrackedFiles | ForEach-Object { Write-Host "Untracked: $_" }
        throw 'Source export accepts only versioned repository files.'
    }

    $sha = (& git rev-parse --short=12 HEAD).Trim()
    Assert-LastExitCode 'Unable to determine current commit'
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    New-Item -ItemType Directory -Force -Path $patchDirectory | Out-Null
    $zipPath = Join-Path $patchDirectory "source-export-$timestamp-$sha.zip"
    $tempDirectory = Join-Path $env:TEMP "ha-source-export-$timestamp-$sha"

    if (Test-Path -LiteralPath $tempDirectory) {
        Remove-Item -LiteralPath $tempDirectory -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDirectory | Out-Null

    try {
        foreach ($relativePath in $ExportFiles) {
            $sourcePath = Join-Path $Repository $relativePath
            $destinationPath = Join-Path $tempDirectory $relativePath
            $destinationDirectory = Split-Path -Parent $destinationPath
            New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
            Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
        }

        $statusText = ((& git status --short --branch) -join [Environment]::NewLine)
        Assert-LastExitCode 'Unable to record Git status'
        $manifest = @(
            'Home Assistant dashboard source export'
            "Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')"
            "Repository: $Repository"
            "Branch: $branch"
            "Commit: $sha"
            ''
            'Git status:'
            $statusText
            ''
            'Included files:'
            ($ExportFiles | ForEach-Object { "- $_" })
        )
        $manifest | Set-Content -LiteralPath (Join-Path $tempDirectory 'SOURCE_EXPORT_MANIFEST.txt') -Encoding UTF8

        if (Test-Path -LiteralPath $zipPath) {
            Remove-Item -LiteralPath $zipPath -Force
        }
        Compress-Archive -Path (Join-Path $tempDirectory '*') -DestinationPath $zipPath -CompressionLevel Optimal
    }
    finally {
        if (Test-Path -LiteralPath $tempDirectory) {
            Remove-Item -LiteralPath $tempDirectory -Recurse -Force
        }
    }

    Write-Host ''
    Write-Host 'Source export completed successfully.' -ForegroundColor Green
    Write-Host "ZIP       : $zipPath"
    Write-Host "Branch    : $branch"
    Write-Host "Commit    : $sha"
    Write-Host 'Upload this ZIP for the next patch preparation.'
    exit 0
}

if ($PatchNumber -lt 1) {
    throw 'Specify -PatchNumber for patch/deployment mode, or use -ExportSources.'
}

$number = '{0:D4}' -f $PatchNumber
$patches = @(Get-ChildItem -LiteralPath $patchDirectory -File -Filter "$number-*.patch")
if ($patches.Count -ne 1) {
    throw "Expected exactly one patch matching patches\$number-*.patch, found $($patches.Count)."
}

$patch = $patches[0].FullName
Write-Host "Repository : $Repository"
Write-Host "Branch     : $branch"
Write-Host "Patch      : $patch"

if (-not $Deploy) {
    $trackedStatus = @(Get-TrackedStatus)
    if ($trackedStatus.Count -gt 0) {
        $trackedStatus | ForEach-Object { Write-Host $_ }
        throw 'Tracked working tree changes exist. Commit, restore, or stash them before applying a patch.'
    }

    Write-Host 'Checking patch...'
    Invoke-Native git apply --check --ignore-space-change $patch

    Write-Host 'Applying patch...'
    Invoke-Native git apply --ignore-space-change $patch

    Write-Host 'Checking resulting diff...'
    Invoke-Native git diff --check

    Write-Host ''
    Write-Host 'Changed files:'
    & git status --short --untracked-files=no
    Assert-LastExitCode 'Unable to show Git status'

    Write-Host ''
    Write-Host 'Diff summary:'
    & git --no-pager diff --stat
    Assert-LastExitCode 'Unable to show diff summary'

    Write-Host ''
    Write-Host 'Patch applied successfully.' -ForegroundColor Green
    Write-Host 'Review the diff, then commit in Visual Studio Code and push in GitHub Desktop.'
    exit 0
}

if ((Get-TrackedStatus).Count -gt 0) {
    throw 'Tracked working tree changes exist. Commit them before deployment.'
}

$upstream = (& git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($upstream)) {
    throw 'The current branch has no upstream. Publish/push the branch first.'
}

$localSha = (& git rev-parse HEAD).Trim()
Assert-LastExitCode 'Unable to determine local commit'
$upstreamSha = (& git rev-parse '@{u}').Trim()
Assert-LastExitCode 'Unable to determine upstream commit'
if ($localSha -ne $upstreamSha) {
    throw 'Local HEAD is not equal to upstream. Push the commit before deployment.'
}

$hostName = (& ssh $Target hostname).Trim()
Assert-LastExitCode 'Unable to verify target host'
if ($hostName -cne 'ha-test') {
    throw "Unexpected deployment target '$hostName'."
}

$sha = (& git rev-parse --short=12 HEAD).Trim()
Assert-LastExitCode 'Unable to determine short commit'
$archive = Join-Path $env:TEMP "ha-pilot-$sha.tar"
if (Test-Path -LiteralPath $archive) {
    Remove-Item -LiteralPath $archive -Force
}

$archiveFiles = @(
    'config/dashboards/living-room-pilot.yaml',
    'config/packages/ground_floor/pilot_living_room.yaml',
    'config/themes/night_control_light.yaml',
    'config/themes/night_control_dark.yaml',
    'tools/deploy_ha_test.py'
)

Write-Host "Creating archive for commit $sha..."
& git archive --format=tar --output=$archive HEAD @archiveFiles
Assert-LastExitCode 'Unable to create deployment archive'
if (-not (Test-Path -LiteralPath $archive)) {
    throw 'Deployment archive was not created.'
}

$stage = (& ssh $Target 'mktemp -d ~/ha-pilot.XXXXXXXX').Trim()
Assert-LastExitCode 'Unable to create staging directory'
if ([string]::IsNullOrWhiteSpace($stage)) {
    throw 'Staging directory is empty.'
}
Write-Host "Staging    : $stage"
Write-Host "Archive    : $archive"

& scp $archive "${Target}:${stage}/pilot.tar"
Assert-LastExitCode 'Archive transfer failed'

& ssh $Target "cd '$stage' && tar -xf pilot.tar && python3 -m py_compile tools/deploy_ha_test.py"
Assert-LastExitCode 'Remote Python syntax check failed'

Write-Host 'Running deployment dry-run...'
& ssh $Target "cd '$stage' && python3 tools/deploy_ha_test.py"
Assert-LastExitCode 'Deployment dry-run failed'

if ($DryRunOnly) {
    Write-Host ''
    Write-Host 'Dry-run completed. No files were applied.' -ForegroundColor Green
    Write-Host "Staging directory retained: $stage"
    exit 0
}

$confirmation = Read-Host "Type APPLY to deploy commit $sha to ha-test"
if ($confirmation -cne 'APPLY') {
    Write-Host 'Deployment cancelled. No files were applied.' -ForegroundColor Yellow
    Write-Host "Staging directory retained: $stage"
    exit 0
}

Write-Host 'Applying deployment...'
& ssh $Target "cd '$stage' && python3 tools/deploy_ha_test.py --apply"
Assert-LastExitCode 'Deployment apply failed'

Write-Host ''
Write-Host 'Deployment completed successfully.' -ForegroundColor Green
Write-Host "Commit  : $sha"
Write-Host "Staging : $stage"
Write-Host 'Record the backup path printed by deploy_ha_test.py before closing this terminal.'
