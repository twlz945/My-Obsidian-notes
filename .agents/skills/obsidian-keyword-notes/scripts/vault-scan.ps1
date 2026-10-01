<#
.SYNOPSIS
  Read-only scan of an Obsidian vault for notes related to a set of keywords.

.DESCRIPTION
  Finds existing notes whose title or body matches any keyword, and reports the
  vault's folder layout and tag vocabulary so the caller can plan new notes that
  fit the vault. Nothing is written to disk.

.PARAMETER Vault
  Absolute path to the Obsidian vault root (the folder containing .obsidian).

.PARAMETER Keywords
  One or more search keywords. Matching is case-insensitive substring matching.

.PARAMETER Limit
  Maximum number of matched notes to return (default 20).

.PARAMETER ExcerptLength
  Maximum excerpt length in characters (default 160).

.EXAMPLE
  ./vault-scan.ps1 -Vault "C:\Users\me\Obsidian Vault" -Keywords "依赖注入","IoC"

.OUTPUTS
  A single JSON object. Check .ok before using the other fields.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Vault,
    [Parameter(Mandatory = $true)][string[]]$Keywords,
    [int]$Limit = 20,
    [int]$ExcerptLength = 160
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

function Emit($obj) {
    $obj | ConvertTo-Json -Depth 8
}

# Directories that are never content notes.
$excludePattern = '\\(\.obsidian|\.trash|\.git|\.claudian|\.opencode|copilot)(\\|$)'

# Calling a script with -File joins array arguments with commas, so split each
# element again to support both "-Keywords a,b" and a real string array.
$keywords = @($Keywords |
        ForEach-Object { $_ -split ',' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_.Length -gt 0 } |
        Select-Object -Unique)
if ($keywords.Count -eq 0) {
    Emit @{ ok = $false; error = 'no-keywords' }
    exit 1
}

try {
    $vaultRoot = (Resolve-Path -LiteralPath $Vault -ErrorAction Stop).Path
} catch {
    Emit @{ ok = $false; error = 'vault-not-found'; vault = $Vault }
    exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $vaultRoot '.obsidian'))) {
    Emit @{ ok = $false; error = 'not-an-obsidian-vault'; vault = $vaultRoot }
    exit 1
}

$files = @(Get-ChildItem -LiteralPath $vaultRoot -Filter '*.md' -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch $excludePattern })

$foundNotes = New-Object System.Collections.Generic.List[object]
$tagCounts = @{}

foreach ($file in $files) {
    $rel = $file.FullName.Substring($vaultRoot.Length).TrimStart('\')
    $title = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $folder = [System.IO.Path]::GetDirectoryName($rel)
    if ($null -eq $folder) { $folder = '' }

    $content = ''
    try { $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 } catch { }
    if ($null -eq $content) { $content = '' }

    $score = 0
    $hits = New-Object System.Collections.Generic.List[string]

    foreach ($k in $keywords) {
        if ($title.IndexOf($k, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $score += 5
            if (-not $hits.Contains($k)) { [void]$hits.Add($k) }
        }
    }
    foreach ($k in $keywords) {
        $count = ([regex]::Matches($content, [regex]::Escape($k), 'IgnoreCase')).Count
        if ($count -gt 0) {
            if (-not $hits.Contains($k)) { [void]$hits.Add($k) }
            $score += [Math]::Min($count, 3)
        }
    }

    # Collect tags for the vault vocabulary (from all notes, matched or not).
    $inFence = $false
    foreach ($line in ($content -split "\r?\n")) {
        $trimmed = $line.TrimStart()
        if ($trimmed -match '^(```|~~~)') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        foreach ($m in [regex]::Matches($line, '(?<![\p{L}\p{N}/_])#([\p{L}\p{N}_][\p{L}\p{N}_\-/]*)')) {
            $t = $m.Groups[1].Value
            if ($tagCounts.ContainsKey($t)) { $tagCounts[$t]++ } else { $tagCounts[$t] = 1 }
        }
    }

    if ($score -le 0) { continue }

    $excerpt = ''
    $lines = $content -split "\r?\n"
    foreach ($line in $lines) {
        $t = $line.Trim()
        if ($t.Length -eq 0 -or $t -eq '---') { continue }
        foreach ($k in $keywords) {
            if ($t.IndexOf($k, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $excerpt = $t; break }
        }
        if ($excerpt) { break }
    }
    if (-not $excerpt) {
        foreach ($line in $lines) {
            $t = $line.Trim()
            if ($t.Length -gt 0 -and $t -ne '---') { $excerpt = $t; break }
        }
    }
    if ($excerpt.Length -gt $ExcerptLength) { $excerpt = $excerpt.Substring(0, $ExcerptLength) }

    $foundNotes.Add([pscustomobject]@{
            path    = $rel
            title   = $title
            folder  = $folder
            score   = $score
            hits    = @($hits)
            excerpt = $excerpt
        })
}

$sorted = @($foundNotes | Sort-Object -Property @{ Expression = 'score'; Descending = $true }, @{ Expression = 'path'; Descending = $false } | Select-Object -First $Limit)

$folders = @(Get-ChildItem -LiteralPath $vaultRoot -Directory -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch $excludePattern } |
        ForEach-Object { $_.FullName.Substring($vaultRoot.Length).TrimStart('\') } |
        Sort-Object)

$tags = @($tagCounts.GetEnumerator() |
        Sort-Object -Property Value -Descending |
        Select-Object -First 80 |
        ForEach-Object { [pscustomobject]@{ tag = $_.Key; count = $_.Value } })

Emit @{
    ok           = $true
    vault        = $vaultRoot
    scannedAt    = (Get-Date).ToString('s')
    noteCount    = $files.Count
    matchedCount = $sorted.Count
    keywords     = $keywords
    matches      = $sorted
    folders      = $folders
    tags         = $tags
}
