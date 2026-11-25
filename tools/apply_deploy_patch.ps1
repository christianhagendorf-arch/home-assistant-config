[CmdletBinding()]
param(
    [ValidateRange(0, 9999)]
    [int]$PatchNumber = 0,

    [switch]$Deploy,
    [switch]$DryRunOnly,
    [switch]$ExportSources,

    [ValidateRange(1, 9999)]
    [int]$AfterPatchNumber,

    [string[]]$ExportFiles = @(
        'config/dashboards/living-room-pilot.yaml',



        'config/themes/night_control_light.yaml',
        'config/themes/night_control_dark.yaml',
        'tools/deploy_ha_test.py',
        'tools/apply_deploy_patch.ps1',
        'docs/DESIGN_BACKLOG.md',
        'docs/ROADMAP.md',
        'docs/SIMULATION_BASELINE.md',
        'docs/PULL_REQUEST_SIMULATION_BASELINE.md',
        'docs/MERGE_CHECKLIST.md',
        'docs/MQTT_READONLY_BASELINE.md',
        'docs/MQTT_INVENTORY.md',
        'tools/configure_ha_test_firewall.sh',
        'tools/ha-test-mqtt-firewall.service',
        'tools/export_mqtt_inventory.py',
        'docs/MQTT_DEVICE_INVENTORY.md'
    ),

    [string]$Repository = 'D:\GitHub\home-assistant-config',
    [string]$Target = 'ha-test'
)

$PackageFiles = @(
    'config/packages/ground_floor/pilot_living_room.yaml',
    'config/packages/first_floor/pilot_first_floor.yaml',
    'config/packages/second_floor/pilot_second_floor.yaml',
    'config/packages/garden/pilot_garden.yaml',
    'config/packages/mqtt/pilot_mqtt_readonly.yaml'
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
$ExportFiles = @($ExportFiles) + $PackageFiles

if ($ExportSources) {
    if ($Deploy -or $DryRunOnly -or $PatchNumber -ne 0) {
        throw 'Use -ExportSources with -AfterPatchNumber. Do not combine it with -PatchNumber, -Deploy, or -DryRunOnly.'
    }
    if (-not $PSBoundParameters.ContainsKey('AfterPatchNumber')) {
        throw 'Specify -AfterPatchNumber when using -ExportSources.'
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
    $patchLabel = '{0:D4}' -f $AfterPatchNumber
    New-Item -ItemType Directory -Force -Path $patchDirectory | Out-Null
    $exportPath = Join-Path $patchDirectory "$patchLabel-source-export-$timestamp-$sha.md"

    $statusText = ((& git status --short --branch) -join [Environment]::NewLine)
    Assert-LastExitCode 'Unable to record Git status'
    $content = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @(
        '# Home Assistant Source Export', '', "State after patch: $patchLabel",
        "Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')", "Branch: $branch", "Commit: $sha",
        '', '## Git status', '', '````text', $statusText, '````', '', '## Included files', ''
    )) { $content.Add($line) }
    foreach ($relativePath in $ExportFiles) { $content.Add('- ' + $relativePath) }
    foreach ($relativePath in $ExportFiles) {
        $extension = [System.IO.Path]::GetExtension($relativePath).ToLowerInvariant()
        $language = switch ($extension) {
            '.yaml' { 'yaml' }
            '.yml' { 'yaml' }
            '.py' { 'python' }
            '.ps1' { 'powershell' }
            '.md' { 'markdown' }
            default { 'text' }
        }
        $fileContent = Get-Content -LiteralPath (Join-Path $Repository $relativePath) -Raw -Encoding UTF8
        foreach ($line in @(
            '', ('## FILE: ' + $relativePath), '', ('<!-- BEGIN FILE: ' + $relativePath + ' -->'),
            ('````' + $language), $fileContent, '````', ('<!-- END FILE: ' + $relativePath + ' -->')
        )) { $content.Add($line) }
    }

    $content | Set-Content -LiteralPath $exportPath -Encoding UTF8
    Write-Host ''
    Write-Host 'Source export completed successfully.' -ForegroundColor Green
    Write-Host "Export    : $exportPath"
    Write-Host "State     : after patch $patchLabel"
    Write-Host "Branch    : $branch"
    Write-Host "Commit    : $sha"
    Write-Host 'Upload this Markdown file for the next patch preparation.'
    exit 0}

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

$trackedStatus = @(Get-TrackedStatus)
if ($trackedStatus.Count -gt 0) {
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


    'config/themes/night_control_light.yaml',
    'config/themes/night_control_dark.yaml',
    'tools/deploy_ha_test.py'
)
$archiveFiles = @($archiveFiles) + $PackageFiles

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
