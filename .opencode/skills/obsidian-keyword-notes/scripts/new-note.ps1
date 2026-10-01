<#
.SYNOPSIS
  Safely create a new Markdown note inside an Obsidian vault.

.DESCRIPTION
  Validates the target path stays inside the vault, refuses to overwrite an
  existing file unless -Force is given, creates parent folders, and writes the
  content as UTF-8 without a BOM (so Chinese text is stored correctly).

  Prefer -ContentFile over -Content for anything longer than a single line, to
  avoid shell quoting problems with Chinese text and Markdown.

.PARAMETER Vault
  Absolute path to the Obsidian vault root (the folder containing .obsidian).

.PARAMETER Path
  Vault-relative path for the note. A .md extension is added if missing.
  Absolute paths and '..' segments are rejected.

.PARAMETER Content
  Note body as a string. Use only for short content.

.PARAMETER ContentFile
  File whose contents become the note body. Takes precedence over -Content.

.PARAMETER Force
  Allow overwriting an existing note. Requires explicit user approval first.

.PARAMETER DryRun
  Validate everything and report the plan without writing anything.

.EXAMPLE
  ./new-note.ps1 -Vault "C:\Users\me\Obsidian Vault" -Path "知识积累\编程\IoC.md" -ContentFile "$env:TEMP\note.md"

.OUTPUTS
  A single JSON object with .ok and, on success, .path and .absolute.
  Exit code 2 means the target already exists; 3 means invalid input.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Vault,
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Content,
    [string]$ContentFile,
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

function Emit($obj) {
    $obj | ConvertTo-Json -Depth 6
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

# Normalize and validate the relative path.
$rel = ($Path -replace '\\', '/').Trim()
if ($rel.Length -eq 0) { Emit @{ ok = $false; error = 'empty-path' }; exit 3 }
if ($rel -match '^([A-Za-z]:|/)') { Emit @{ ok = $false; error = 'absolute-path-not-allowed'; path = $Path }; exit 3 }
$segments = $rel -split '/'
if ($segments -contains '..') { Emit @{ ok = $false; error = 'path-traversal-not-allowed'; path = $Path }; exit 3 }
if ($segments.Count -eq 1) { Emit @{ ok = $false; error = 'note-must-be-inside-a-folder'; path = $Path }; exit 3 }
if ($segments[0] -match '^\.') { Emit @{ ok = $false; error = 'hidden-folder-not-allowed'; path = $Path }; exit 3 }
if ($rel -notmatch '\.md$') { $rel += '.md' }

$full = Join-Path $vaultRoot ($rel -replace '/', '\')
$parent = [System.IO.Path]::GetDirectoryName($full)
$resolvedParent = [System.IO.Path]::GetFullPath($parent)
$resolvedVault = [System.IO.Path]::GetFullPath($vaultRoot).TrimEnd('\')
if ($resolvedParent -ne $resolvedVault -and -not $resolvedParent.StartsWith($resolvedVault + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
    Emit @{ ok = $false; error = 'path-outside-vault'; path = $Path }
    exit 3
}

$exists = Test-Path -LiteralPath $full
if ($exists -and -not $Force) {
    Emit @{ ok = $false; error = 'note-exists'; reason = 'exists'; path = $rel; absolute = $full }
    exit 2
}

# Resolve the content.
$text = $null
if ($ContentFile) {
    if (-not (Test-Path -LiteralPath $ContentFile)) {
        Emit @{ ok = $false; error = 'content-file-not-found'; contentFile = $ContentFile }
        exit 3
    }
    $text = Get-Content -LiteralPath $ContentFile -Raw -Encoding UTF8
} elseif ($PSBoundParameters.ContainsKey('Content')) {
    $text = $Content
} else {
    Emit @{ ok = $false; error = 'no-content-provided' }
    exit 3
}
if ($null -eq $text) { $text = '' }
if ($text.Length -gt 0 -and -not $text.EndsWith("`n")) { $text += "`n" }

if ($DryRun) {
    Emit @{ ok = $true; dryRun = $true; path = $rel; absolute = $full; exists = $exists; bytes = $text.Length }
    exit 0
}

if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($full, $text, $utf8NoBom)

Emit @{ ok = $true; created = $true; overwritten = $exists; path = $rel; absolute = $full; bytes = $text.Length }
