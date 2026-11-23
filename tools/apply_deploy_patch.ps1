[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 9999)]
    [int]$PatchNumber,

    [switch]$Deploy,
    [switch]$DryRunOnly,

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

$number = '{0:D4}' -f $PatchNumber
$patchDirectory = Join-Path $Repository 'patches'
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
    & git --no-pager diff --stat
    Assert-LastExitCode 'Unable to display diff summary'
    & git status --short
    Assert-LastExitCode 'Unable to display Git status'

    Write-Host ''
    Write-Host 'Patch applied. Review the diff, then commit in Visual Studio Code and push with GitHub Desktop.' -ForegroundColor Green
    exit 0
}

$trackedStatus = @(Get-TrackedStatus)
if ($trackedStatus.Count -gt 0) {
    $trackedStatus | ForEach-Object { Write-Host $_ }
    throw 'Tracked working tree changes exist. Commit them before deployment.'
}

$aheadBehind = (& git rev-list --left-right --count "origin/$branch...HEAD").Trim() -split '\s+'
Assert-LastExitCode 'Unable to compare local branch with origin'
if ($aheadBehind.Count -lt 2 -or [int]$aheadBehind[1] -gt 0) {
    throw 'Local commits have not been pushed to origin. Push with GitHub Desktop before deployment.'
}

$hostName = (& ssh $Target hostname).Trim()
Assert-LastExitCode 'SSH target check failed'
if ($hostName -cne 'ha-test') {
    throw "Deployment target check failed. Received hostname '$hostName'."
}

$sha = (& git rev-parse --short=12 HEAD).Trim()
Assert-LastExitCode 'Unable to determine current Git commit'
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
