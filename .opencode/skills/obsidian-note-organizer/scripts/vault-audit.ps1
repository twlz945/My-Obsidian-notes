<#
.SYNOPSIS
  Read-only audit of an Obsidian vault for note-organization problems.

.DESCRIPTION
  Reports findings in five areas: metadata/tags, filing/placement,
  duplicates, links/indexes, and Markdown formatting. Nothing is modified.
  Use the JSON output to build a report and a change plan for the user.

.PARAMETER Vault
  Absolute path to the Obsidian vault root (the folder containing .obsidian).

.PARAMETER Scope
  Comma-separated subset of: metadata, filing, duplicates, links, format.
  Defaults to all five.

.PARAMETER StubThreshold
  Notes with fewer non-whitespace characters than this are flagged as stubs (default 40).

.PARAMETER MinFolderNotes
  A folder needs at least this many notes before a missing index is reported (default 3).

.PARAMETER MaxItems
  Cap for list fields (default 200). Totals are always reported.

.EXAMPLE
  ./vault-audit.ps1 -Vault "C:\Users\me\Obsidian Vault"

.OUTPUTS
  A single JSON object. Check .ok before using other fields.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Vault,
    [string]$Scope = 'metadata,filing,duplicates,links,format',
    [int]$StubThreshold = 40,
    [int]$MinFolderNotes = 3,
    [int]$MaxItems = 200
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

function Emit($obj) { $obj | ConvertTo-Json -Depth 8 }

$scopeSet = @{}
foreach ($s in ($Scope -split ',')) {
    $t = $s.Trim().ToLowerInvariant()
    if ($t.Length -gt 0) { $scopeSet[$t] = $true }
}
function Want([string]$name) { return $scopeSet.ContainsKey($name) }

try {
    $vaultRoot = (Resolve-Path -LiteralPath $Vault -ErrorAction Stop).Path
} catch {
    Emit @{ ok = $false; error = 'vault-not-found'; vault = $Vault }; exit 1
}
if (-not (Test-Path -LiteralPath (Join-Path $vaultRoot '.obsidian'))) {
    Emit @{ ok = $false; error = 'not-an-obsidian-vault'; vault = $vaultRoot }; exit 1
}

$excludePattern = '\\(\.obsidian|\.trash|\.git|\.claudian|\.opencode|\.agents|copilot)(\\|$)'

$mdFiles = @(Get-ChildItem -LiteralPath $vaultRoot -Filter '*.md' -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch $excludePattern })
$allFiles = @(Get-ChildItem -LiteralPath $vaultRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch $excludePattern })

function Get-Frontmatter([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return '' }
    $t = $text
    if ($t.Length -gt 0 -and [int][char]$t[0] -eq 0xFEFF) { $t = $t.Substring(1) }
    $m = [regex]::Match($t, '(?s)^---\r?\n(.*?)\r?\n---')
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
}

function Get-YamlListValues([string]$fm, [string]$key) {
    $out = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrEmpty($fm)) { return @() }
    $m = [regex]::Match($fm, "(?ms)^$key\s*:\s*(.*?)(?=^[^\s\-#]|\z)")
    if (-not $m.Success) { return @() }
    $block = $m.Groups[1].Value
    $inline = [regex]::Match($block, '\[(.*?)\]')
    if ($inline.Success) {
        foreach ($part in ($inline.Groups[1].Value -split ',')) {
            $v = $part.Trim().Trim('"').Trim("'")
            if ($v.Length -gt 0) { [void]$out.Add($v) }
        }
    }
    foreach ($mm in [regex]::Matches($block, '(?m)^\s*-\s*(.+?)\s*$')) {
        $v = $mm.Groups[1].Value.Trim().Trim('"').Trim("'")
        if ($v.Length -gt 0) { [void]$out.Add($v) }
    }
    return @($out)
}

function Get-InlineTags([string]$text) {
    $tags = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrEmpty($text)) { return @() }
    $inFence = $false
    foreach ($line in ($text -split "\r?\n")) {
        $t = $line.TrimStart()
        if ($t -match '^(```|~~~)') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        foreach ($m in [regex]::Matches($line, '(?<![\p{L}\p{N}/_])#([\p{L}\p{N}_][\p{L}\p{N}_\-/]*)')) {
            [void]$tags.Add($m.Groups[1].Value)
        }
    }
    return @($tags)
}

# ---- Load notes and build an index -----------------------------------------
$notes = New-Object System.Collections.Generic.List[object]
$titleMap = @{}
$aliasMap = @{}
$pathMap = @{}
$fileNameMap = @{}

foreach ($f in $allFiles) {
    $k = $f.Name.ToLowerInvariant()
    if ($fileNameMap.ContainsKey($k)) { $fileNameMap[$k]++ } else { $fileNameMap[$k] = 1 }
}

foreach ($f in $mdFiles) {
    $rel = $f.FullName.Substring($vaultRoot.Length).TrimStart('\')
    $title = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    $folder = [System.IO.Path]::GetDirectoryName($rel)
    if ($null -eq $folder) { $folder = '' }
    $content = ''
    try { $content = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 } catch { }
    if ($null -eq $content) { $content = '' }
    $fm = Get-Frontmatter $content
    $tags = @(Get-YamlListValues $fm 'tags') + @(Get-InlineTags $content)
    $tags = @($tags | Where-Object { $_.Length -gt 0 } | Select-Object -Unique)
    $aliases = @(Get-YamlListValues $fm 'aliases')

    $note = [pscustomobject]@{
        rel     = $rel
        full    = $f.FullName
        title   = $title
        folder  = $folder
        content = $content
        fm      = $fm
        tags    = $tags
        aliases = $aliases
    }
    $notes.Add($note)

    $tk = $title.ToLowerInvariant()
    if (-not $titleMap.ContainsKey($tk)) { $titleMap[$tk] = New-Object System.Collections.Generic.List[string] }
    [void]$titleMap[$tk].Add($rel)
    foreach ($a in $aliases) {
        $ak = $a.ToLowerInvariant()
        if (-not $aliasMap.ContainsKey($ak)) { $aliasMap[$ak] = New-Object System.Collections.Generic.List[string] }
        [void]$aliasMap[$ak].Add($rel)
    }
    foreach ($pk in @($rel.ToLowerInvariant(), ($rel -replace '\.md$', '').ToLowerInvariant())) {
        if (-not $pathMap.ContainsKey($pk)) { $pathMap[$pk] = $rel }
    }
}

function Resolve-NoteTarget([string]$target) {
    if ([string]::IsNullOrEmpty($target)) { return $null }
    $k = $target.ToLowerInvariant().Trim()
    if ($titleMap.ContainsKey($k)) { return $titleMap[$k][0] }
    if ($aliasMap.ContainsKey($k)) { return $aliasMap[$k][0] }
    if ($pathMap.ContainsKey($k)) { return $pathMap[$k] }
    if ($pathMap.ContainsKey($k + '.md')) { return $pathMap[$k + '.md'] }
    return $null
}

$noteExt = '\.(md|png|jpe?g|gif|svg|webp|bmp|pdf|excalidraw|canvas|mp3|mp4|wav|m4a|zip|ogg|mov|avi)$'

# ---- Links ------------------------------------------------------------------
$brokenLinks = New-Object System.Collections.Generic.List[object]
$outCount = @{}
$inCount = @{}
foreach ($n in $notes) { $outCount[$n.rel] = 0; $inCount[$n.rel] = 0 }

foreach ($n in $notes) {
    $lines = $n.content -split "\r?\n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        foreach ($m in [regex]::Matches($lines[$i], '!?\[\[([^\]]+?)\]\]')) {
            $inner = $m.Groups[1].Value
            $target = ($inner -split '\|')[0]
            $target = ($target -split '#')[0]
            $target = ($target -split '\^')[0]
            $target = $target.Trim()
            if ($target.Length -eq 0) { continue }
            if ($target -match '^[a-z][a-z0-9+.\-]*://') { continue }

            if ($target -match $noteExt) {
                if ($target -match '\.md$') {
                    $resolved = Resolve-NoteTarget ($target -replace '\.md$', '')
                    if ($null -eq $resolved) {
                        $brokenLinks.Add([pscustomobject]@{ path = $n.rel; line = $i + 1; link = $m.Value; target = $target })
                    }
                } else {
                    $base = [System.IO.Path]::GetFileName($target).ToLowerInvariant()
                    if (-not $fileNameMap.ContainsKey($base)) {
                        $brokenLinks.Add([pscustomobject]@{ path = $n.rel; line = $i + 1; link = $m.Value; target = $target })
                    }
                }
                continue
            }

            $resolved = Resolve-NoteTarget $target
            if ($null -eq $resolved) {
                $brokenLinks.Add([pscustomobject]@{ path = $n.rel; line = $i + 1; link = $m.Value; target = $target })
            } else {
                $outCount[$n.rel]++
                $inCount[$resolved]++
            }
        }
    }
}

# ---- Metadata ---------------------------------------------------------------
$noFrontmatter = New-Object System.Collections.Generic.List[string]
$noTags = New-Object System.Collections.Generic.List[string]
$missingTitle = New-Object System.Collections.Generic.List[string]
$tagCounts = @{}
foreach ($n in $notes) {
    if ($scopeSet.ContainsKey('metadata')) {
        if ([string]::IsNullOrEmpty($n.fm)) { [void]$noFrontmatter.Add($n.rel) }
        else {
            if (-not ($n.fm -match '(?m)^title\s*:')) { [void]$missingTitle.Add($n.rel) }
        }
        if ($n.tags.Count -eq 0) { [void]$noTags.Add($n.rel) }
    }
    foreach ($t in $n.tags) {
        if ($tagCounts.ContainsKey($t)) { $tagCounts[$t]++ } else { $tagCounts[$t] = 1 }
    }
}

# ---- Filing -----------------------------------------------------------------
$untitled = New-Object System.Collections.Generic.List[string]
$rootNotes = New-Object System.Collections.Generic.List[string]
$stubs = New-Object System.Collections.Generic.List[object]
foreach ($n in $notes) {
    if ($scopeSet.ContainsKey('filing')) {
        if ($n.title -match '^(未命名|无标题|untitled|new note|新建笔记)(\s*\d+)?$') { [void]$untitled.Add($n.rel) }
        if ($n.folder -eq '') { [void]$rootNotes.Add($n.rel) }
        $chars = ($n.content -replace '\s', '').Length
        if ($chars -lt $StubThreshold) { $stubs.Add([pscustomobject]@{ path = $n.rel; chars = $chars }) }
    }
}

$folderNotes = @{}
foreach ($n in $notes) {
    if ($n.folder -eq '') { continue }
    if (-not $folderNotes.ContainsKey($n.folder)) { $folderNotes[$n.folder] = New-Object System.Collections.Generic.List[string] }
    [void]$folderNotes[$n.folder].Add($n.title)
}
$foldersWithoutIndex = New-Object System.Collections.Generic.List[object]
if ($scopeSet.ContainsKey('links')) {
    foreach ($folder in $folderNotes.Keys) {
        if ($folderNotes[$folder].Count -lt $MinFolderNotes) { continue }
        $leaf = ($folder -split '\\')[-1].ToLowerInvariant()
        $hasIndex = $false
        foreach ($t in $folderNotes[$folder]) {
            $tl = $t.ToLowerInvariant()
            if ($tl -eq 'index' -or $tl -eq 'readme' -or $tl -eq '目录' -or $tl -eq 'index of' -or $tl -eq $leaf) { $hasIndex = $true; break }
        }
        if (-not $hasIndex) { $foldersWithoutIndex.Add([pscustomobject]@{ folder = $folder; notes = $folderNotes[$folder].Count }) }
    }
}

# ---- Duplicates -------------------------------------------------------------
$sameTitle = New-Object System.Collections.Generic.List[object]
$titleOverlaps = New-Object System.Collections.Generic.List[object]
if ($scopeSet.ContainsKey('duplicates')) {
    foreach ($kv in $titleMap.GetEnumerator()) {
        if ($kv.Value.Count -gt 1) { $sameTitle.Add([pscustomobject]@{ title = $kv.Key; paths = @($kv.Value) }) }
    }
    $titleList = @($notes | ForEach-Object { $_.title })
    for ($i = 0; $i -lt $titleList.Count; $i++) {
        for ($j = $i + 1; $j -lt $titleList.Count; $j++) {
            $a = $titleList[$i]; $b = $titleList[$j]
            if ($a.Length -lt 2 -or $b.Length -lt 2) { continue }
            $al = $a.ToLowerInvariant(); $bl = $b.ToLowerInvariant()
            if ($al -eq $bl) { continue }
            if ($al.Contains($bl) -or $bl.Contains($al)) {
                $titleOverlaps.Add([pscustomobject]@{ a = $a; b = $b; shorter = $(if ($al.Length -le $bl.Length) { $a } else { $b }) })
            }
        }
    }
}

# ---- Orphans / link health --------------------------------------------------
$orphans = New-Object System.Collections.Generic.List[string]
$noOutgoing = New-Object System.Collections.Generic.List[string]
if ($scopeSet.ContainsKey('links')) {
    foreach ($n in $notes) {
        if ($inCount[$n.rel] -eq 0 -and $outCount[$n.rel] -eq 0) { [void]$orphans.Add($n.rel) }
        if ($outCount[$n.rel] -eq 0) { [void]$noOutgoing.Add($n.rel) }
    }
}

# ---- Format -----------------------------------------------------------------
$formatIssues = New-Object System.Collections.Generic.List[object]
$formatSummary = @{ multipleH1 = 0; noH1 = 0; headingNoSpace = 0; unclosedFence = 0; manyBlankLines = 0; trailingWhitespace = 0; noFinalNewline = 0; tabs = 0; bom = 0 }
if ($scopeSet.ContainsKey('format')) {
    foreach ($n in $notes) {
        $issues = New-Object System.Collections.Generic.List[string]
        $lines = $n.content -split "\r?\n"
        $inFence = $false; $h1 = 0; $noSpace = $false; $fenceCount = 0
        foreach ($line in $lines) {
            $t = $line.TrimStart()
            if ($t -match '^(```|~~~)') { $fenceCount++; $inFence = -not $inFence; continue }
            if ($inFence) { continue }
            if ($line -match '^#\s') { $h1++ }
            elseif ($line -match '^#{1,6}[^\s#]') { $noSpace = $true }
        }
        if ($h1 -gt 1) { $issues.Add('multiple-h1'); $formatSummary.multipleH1++ }
        elseif ($h1 -eq 0 -and ($n.content -replace '\s', '').Length -gt 0) { $issues.Add('no-h1'); $formatSummary.noH1++ }
        if ($noSpace) { $issues.Add('heading-no-space'); $formatSummary.headingNoSpace++ }
        if ($fenceCount % 2 -ne 0) { $issues.Add('unclosed-code-fence'); $formatSummary.unclosedFence++ }
        if ($n.content -match '(?:\r?\n[ \t]*){4,}') { $issues.Add('many-blank-lines'); $formatSummary.manyBlankLines++ }
        if ($n.content -match '(?m)[ \t]+$') { $issues.Add('trailing-whitespace'); $formatSummary.trailingWhitespace++ }
        if ($n.content.Length -gt 0 -and -not $n.content.EndsWith("`n")) { $issues.Add('no-final-newline'); $formatSummary.noFinalNewline++ }
        if ($n.content.Contains("`t")) { $issues.Add('tabs'); $formatSummary.tabs++ }
        if ($n.content.Length -gt 0 -and [int][char]$n.content[0] -eq 0xFEFF) { $issues.Add('bom'); $formatSummary.bom++ }
        if ($issues.Count -gt 0) {
            $formatIssues.Add([pscustomobject]@{ path = $n.rel; issues = @($issues) })
        }
    }
}

# Return any enumerable as a plain array. Enumerating through the pipeline
# avoids a Windows PowerShell bug where @() fails on a List[object] variable.
function ToArr($x) {
    if ($null -eq $x) { return @() }
    return @($x | ForEach-Object { $_ })
}

function Take($list) {
    $arr = ToArr $list
    if ($arr.Count -gt $MaxItems) { return @($arr | Select-Object -First $MaxItems) }
    return $arr
}

$tagsSorted = @($tagCounts.GetEnumerator() |
        Sort-Object -Property @{ Expression = 'Value'; Descending = $true }, @{ Expression = 'Name'; Descending = $false } |
        ForEach-Object { [pscustomobject]@{ tag = $_.Key; count = $_.Value } })
$rareTags = @($tagsSorted | Where-Object { $_.count -eq 1 } | ForEach-Object { $_.tag })

Emit @{
    ok          = $true
    vault       = $vaultRoot
    scannedAt   = (Get-Date).ToString('s')
    noteCount   = $notes.Count
    fileCount   = $allFiles.Count
    scope       = @($scopeSet.Keys)
    metadata    = @{
        noFrontmatter = @(Take $noFrontmatter)
        noTags        = @(Take $noTags)
        missingTitle  = @(Take $missingTitle)
        tagCounts     = @($tagsSorted | Select-Object -First 80)
        rareTags      = @(Take $rareTags)
    }
    filing      = @{
        untitled            = @(Take $untitled)
        rootNotes           = @(Take $rootNotes)
        stubCount           = $stubs.Count
        stubs               = @(Take $stubs)
        foldersWithoutIndex = @(ToArr $foldersWithoutIndex)
    }
    duplicates  = @{
        sameTitle     = @(Take $sameTitle)
        titleOverlaps = @(Take $titleOverlaps)
    }
    links       = @{
        brokenCount  = $brokenLinks.Count
        broken       = @(Take $brokenLinks)
        orphanCount  = $orphans.Count
        orphans      = @(Take $orphans)
        noOutgoing   = @(Take $noOutgoing)
    }
    format      = @{
        summary = $formatSummary
        issues  = @(Take $formatIssues)
    }
}
