function debug ([switch]$help) {# Insert a pause and provide details, so that we can see where errors originate.

# Modify fields sent to it with proper word wrapping.
function wordwrap ($field, $maximumlinelength) {if ($null -eq $field) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()
if (-not $maximumlinelength) {[int]$maximumlinelength = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($maximumlinelength -lt 60) {[int]$maximumlinelength = 60}
if ($maximumlinelength -gt $Host.UI.RawUI.BufferSize.Width) {[int]$maximumlinelength = $Host.UI.RawUI.BufferSize.Width}
foreach ($line in $field -split "`n", [System.StringSplitOptions]::None) {if ($line -eq "") {$wrapped += ""; continue}
$remaining = $line
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1
foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1}
$chunk = $segment.Substring(0, $breakIndex + 1); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1)}
if ($remaining.Length -gt 0 -or $line -eq "") {$wrapped += $remaining}}
return ($wrapped -join "`n")}

# Display a horizontal line.
function line ($colour, $length, [switch]$pre, [switch]$post, [switch]$double) {if (-not $length) {[int]$length = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($length) {if ($length -lt 60) {[int]$length = 60}
if ($length -gt $Host.UI.RawUI.BufferSize.Width) {[int]$length = $Host.UI.RawUI.BufferSize.Width}}
if ($pre) {Write-Host ""}
$character = if ($double) {"="} else {"-"}
Write-Host -f $colour ($character * $length)
if ($post) {Write-Host ""}}

function help {# Inline help.
function scripthelp ($section) {# (Internal) Generate the help sections from the comments section of the script.
line yellow 100 -pre; $pattern = "(?ims)^## ($section.*?)(##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; Write-Host $lines[0] -f yellow; line yellow 100
if ($lines.Count -gt 1) {wordwrap $lines[1] 100 | Write-Host -f white | Out-Host -Paging}; line yellow 100}
$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)")
if ($sections.Count -eq 1) {cls; Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)) Help:" -f cyan; scripthelp $sections[0].Groups[1].Value; ""; return}

$selection = $null
do {cls; Write-Host -f cyan "$(Get-ChildItem (Split-Path $PSCommandPath) | Where-Object { $_.FullName -ieq $PSCommandPath } | Select-Object -ExpandProperty BaseName) Help Sections:`n"
for ($i = 0; $i -lt $sections.Count; $i++) {Write-Host "$($i + 1). " -f cyan -n; Write-Host $sections[$i].Groups[1].Value -f white}
if ($selection) {scripthelp $sections[$selection - 1].Groups[1].Value}
Write-Host -f yellow "`nEnter a section number to view " -n; $input = Read-Host
if ($input -match '^\d+$') {$index = [int]$input
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index}
else {$selection = $null}} else {""; return}}
while ($true); return}

# External call to help.
if ($help) {help; return}

line cyan -pre
$stack = Get-PSCallStack
if ($stack.Count -le 2) {wordwrap "This function is designed to be used inside other functions during development, in order to provide feedback regarding the previous line of code, such that errors can be tracked down and corrected." | Write-Host -f white; line cyan; ""}
if ($stack.Count -gt 2) {$functionlist = ($stack[($stack.Count - 2)..1] | Where-Object {$_.FunctionName -notlike '<ScriptBlock*'} | ForEach-Object {$_.FunctionName}) -join ' -> '; Write-Host -f green "DEBUG: Functions Path: " -n; wordwrap "$functionlist" 100 | Write-Host -f white
line cyan
$lastline = $null
if ($error.Count -gt 0 -and $error[0].InvocationInfo.Line) {$lastline = $error[0].InvocationInfo.Line.Trim()}
elseif ($MyInvocation.ScriptName -and $MyInvocation.ScriptLineNumber -gt 1) {try {$lines = Get-Content $MyInvocation.ScriptName; $lastline = $lines[$MyInvocation.ScriptLineNumber - 2].Trim()}
catch {$lastline = "(Could not retrieve previous line from file)"}}
else {$lastline = "(Unable to determine previous line)"}
Write-Host -f green "DEBUG: Last line of code:"; wordwrap "$lastline"
line cyan
""; Read-Host}}
<#
## Overview
This function is designed to be used inside other functions during development, such that errors can be tracked down and corrected.

Simply add it as a command inside the script or module are troubleshooting, right before or after the problem areas, so that the debug command can pause the execution, show you the last command that ran and let you view any on screen errors.
## License
MIT License

Copyright © 2025 Craig Plath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.
##>