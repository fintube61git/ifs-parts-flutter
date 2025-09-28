# Auto-tag a stable release by bumping the MINOR version and appending a timestamp.
# Usage:
#   .\scripts\tag-stable.ps1
#
# Behavior:
#   - Finds latest tag matching ^vX.Y.Z (ignores any suffix like -stable-...)
#   - Bumps MINOR: v1.1.0 -> v1.2.0 (PATCH reset to 0)
#   - Commits pending changes (message includes version)
#   - Creates/updates branch: stable-vX.Y.Z (from current HEAD)
#   - Creates annotated tag:  vX.Y.Z-stable-YYYYMMDD-HHMMSS
#   - Pushes branch + tag to origin

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Get-NextMinorVersion {
    # Collect all tags beginning with 'v'
    $tags = git tag --list "v*" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

    # Parse semantic core 'vX.Y.Z' from each tag, ignoring suffixes like '-stable-...'
    $parsed = @()
    foreach ($t in $tags) {
        if ($t -match '^v(\d+)\.(\d+)\.(\d+)') {
            $ver = [version]::new([int]$matches[1], [int]$matches[2], [int]$matches[3])
            $parsed += [pscustomobject]@{ Tag = $t; Version = $ver }
        }
    }

    if ($parsed.Count -eq 0) {
        # No prior versioned tags: start at v1.0.0
        return [version]::new(1,0,0)
    }

    $latest = ($parsed | Sort-Object Version -Descending | Select-Object -First 1).Version
    # bump MINOR, reset PATCH
    return [version]::new($latest.Major, $latest.Minor + 1, 0)
}

# Derive next version
$next = Get-NextMinorVersion
$baseVersion = "v{0}.{1}.{2}" -f $next.Major, $next.Minor, $next.Build

# Timestamp & names
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$branch = "stable-$baseVersion"
$tag    = "$baseVersion-stable-$timestamp"

Write-Host "=== Creating stable for $baseVersion ($tag) ===" -ForegroundColor Cyan

# Stage & commit any pending changes
git add -A
$changes = git status --porcelain
if ($changes) {
    git commit -m "Stable snapshot $baseVersion: auto-commit before tagging"
} else {
    Write-Host "No pending changes; proceeding with current HEAD..." -ForegroundColor DarkGray
}

# Create/Update branch from current HEAD (-B recreates if it exists)
git checkout -B $branch
git push -u origin $branch

# Create annotated tag; if it already exists, abort to avoid ambiguity
$existing = git tag --list $tag
if ($existing) {
    throw "Tag '$tag' already exists. Resolve manually or re-run to mint a new timestamp."
}
git tag -a $tag -m "Stable $baseVersion ($timestamp): auto-tagged"
git push origin $tag

Write-Host ""
Write-Host "✅ Stable branch created/updated: $branch" -ForegroundColor Green
Write-Host "✅ Tag created and pushed:       $tag" -ForegroundColor Green
Write-Host ""
Write-Host "Rollback hints:" -ForegroundColor DarkCyan
Write-Host "  git fetch --tags" -ForegroundColor Gray
Write-Host "  git checkout $tag" -ForegroundColor Gray
