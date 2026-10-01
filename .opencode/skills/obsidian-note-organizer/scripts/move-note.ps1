<#
.SYNOPSIS
  Move or rename a note inside an Obsidian vault, updating inbound wikilinks.

.DESCRIPTION
  Moves a Markdown note to a new vault-relative path. When the file name
  (note title) changes, every wikilink in the vault that targets the old title
  or old path is rewritten to the new target, preserving aliases, headings and
  block references. Supports -DryRun to preview without touching anything.

  Obsidian normally resolves [[links]] by file name, so a pure move that keeps
  the same file name needs no link changes. This script handles both cases.

.PARAMETER Vault
  Absolute path to the Obsidian vault root (the folder containing .obsidian).

.PARAMETER From
  Current vault-relative path of the note (with or without .md).

.PARAMETER To
  Desired vault-relative path of the note (with or without .md).

.PARAMETER Force
  Allow overwriting an existing destination note.

.PARAMETER SkipLinkUpdate
  Do not rewrite inbound wikilinks (use only when you are sure it is safe).

.PARAMETER DryRun
  Report the move and the link edits without changing any file.

.EXAMPLE
  ./move-note.ps1 -Vault "C:\Users\me\Obsidian Vault" -From "杂记\未命名.md" -To "杂记\日记\2026-10-01.md" -DryRun

.OUTPUTS
  A single JSON object with .ok. Exit code 2 means the destination exists;
  3 means invalid input.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Vault,
    [Parameter(Mandatory = $true)][string]$From,
    [Parameter(Mandatory = $true)][string]$To,
    [switch]$Force,
    [switch]$SkipLinkUpdate,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

function Emit($obj) { $obj | ConvertTo-Json -Depth 8 }

function Resolve-Rel([string]$p) {
    $r = ($p -replace '\\', '/').Trim()
    if ($r.Length -eq 0) { return $null }
    if ($r -match '^([A-Za-z]:|/)') { return $null }
    if (($r -split '/') -contains '..') { return $null }
    return $r
}

try {
    $vaultRoot = (Resolve-Path -LiteralPath $Vault -ErrorAction Stop).Path
} catch {
    Emit @{ ok = $false; error = 'vault-not-found'; vault = $Vault }; exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $vaultRoot '.obsidian'))) {
    Emit @{ ok = $false; error = 'not-an-obsidian-vault'; vault = $vaultRoot }; exit 1
}

$fromRel = Resolve-Rel $From
$toRel = Resolve-Rel $To
if ($null -eq $fromRel -or $null -eq $toRel) { Emit @{ ok = $false; error = 'invalid-path'; from = $From; to = $To }; exit 3 }
if ($fromRel -notmatch '\.md$') { $fromRel += '.md' }
if ($toRel -notmatch '\.md$') { $toRel += '.md' }
if (($fromRel -split '/').Count -lt 2 -or ($toRel -split '/').Count -lt 2) {
    Emit @{ ok = $false; error = 'note-must-be-inside-a-folder' }; exit 3
}

$fromFull = Join-Path $vaultRoot ($fromRel -replace '/', '\')
$toFull = Join-Path $vaultRoot ($toRel -replace '/', '\')
if (-not (Test-Path -LiteralPath $fromFull)) { Emit @{ ok = $false; error = 'source-not-found'; from = $fromRel }; exit 1 }
if ((Test-Path -LiteralPath $toFull) -and -not $Force) {
    Emit @{ ok = $false; error = 'destination-exists'; reason = 'exists'; to = $toRel }
    exit 2
}

$oldTitle = [System.IO.Path]::GetFileNameWithoutExtension($fromFull)
$newTitle = [System.IO.Path]::GetFileNameWithoutExtension($toFull)
$newRelNoExt = $toRel -replace '\.md$', ''

$excludePattern = '\\(\.obsidian|\.trash|\.git|\.claudian|\.opencode|\.agents|copilot)(\\|$)'
$notes = @(Get-ChildItem -LiteralPath $vaultRoot -Filter '*.md' -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch $excludePattern })

$linkUpdates = New-Object System.Collections.Generic.List[object]
$totalUpdates = 0
$pendingWrites = New-Object System.Collections.Generic.List[object]

if (-not $SkipLinkUpdate) {
    $pattern = '(!?)\[\[([^\]]+?)\]\]'
    foreach ($n in $notes) {
        if ($n.FullName -eq $fromFull) { continue }
        $content = ''
        try { $content = Get-Content -LiteralPath $n.FullName -Raw -Encoding UTF8 } catch { continue }
        if ([string]::IsNullOrEmpty($content)) { continue }
        $counter = [ref]0
        $evaluator2 = {
            param($m)
            $bang = $m.Groups[1].Value
            $inner = $m.Groups[2].Value
            $parts = $inner -split '\|', 2
            $targetPart = $parts[0]
            $rest = ''
            if ($parts.Count -gt 1) { $rest = '|' + $parts[1] }
            $idx = $targetPart.IndexOfAny([char[]]@('#', '^'))
            $base = $targetPart
            $suffix = ''
            if ($idx -ge 0) { $base = $targetPart.Substring(0, $idx); $suffix = $targetPart.Substring($idx) }
            $baseTrim = $base.Trim()
            $hasPath = ($baseTrim -match '[\\/]')
            $lastSeg = ($baseTrim -replace '\\', '/')
            $lastSeg = ($lastSeg -split '/')[-1]
            $matchesOld = $false
            if ($baseTrim -ieq $oldTitle) { $matchesOld = $true }
            elseif ($lastSeg -ieq $oldTitle) { $matchesOld = $true }
            if (-not $matchesOld) { return $m.Value }
            $newBase = $newTitle
            if ($hasPath) { $newBase = $newRelNoExt }
            $rebuilt = "$bang[[$newBase$suffix$rest]]"
            if ($rebuilt -cne $m.Value) { $counter.Value++; return $rebuilt }
            return $m.Value
        }
        $newContent = [regex]::Replace($content, $pattern, $evaluator2)
        $changed = $counter.Value
        if ($changed -gt 0) {
            $rel = $n.FullName.Substring($vaultRoot.Length).TrimStart('\')
            $linkUpdates.Add([pscustomobject]@{ path = $rel; updatedLinks = $changed })
            $totalUpdates += $changed
            $pendingWrites.Add([pscustomobject]@{ full = $n.FullName; text = $newContent })
        }
    }
}

$plan = @{
    ok                  = $true
    from                = $fromRel
    to                  = $toRel
    titleChanged        = ($oldTitle -cne $newTitle)
    linkUpdates         = @($linkUpdates | ForEach-Object { $_ })
    totalLinkUpdates    = $totalUpdates
    dryRun              = [bool]$DryRun
}

if ($DryRun) {
    $plan.moved = $false
    Emit $plan
    exit 0
}

$toParent = [System.IO.Path]::GetDirectoryName($toFull)
if (-not (Test-Path -LiteralPath $toParent)) { New-Item -ItemType Directory -Path $toParent -Force | Out-Null }

if ($Force -and (Test-Path -LiteralPath $toFull)) { Remove-Item -LiteralPath $toFull -Force }
Move-Item -LiteralPath $fromFull -Destination $toFull -Force

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
foreach ($w in $pendingWrites) { [System.IO.File]::WriteAllText($w.full, $w.text, $utf8NoBom) }

$plan.moved = $true
$plan.absolute = $toFull
Emit $plan
