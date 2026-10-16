# Replaces the placeholder site URL used for canonical links, Open Graph tags,
# structured data, the sitemap, robots.txt and the 404 page.
#   powershell -ExecutionPolicy Bypass -File tools\set-site-url.ps1 -Url https://example.com/
param([Parameter(Mandatory = $true)][string]$Url)

if (-not $Url.EndsWith('/')) { $Url += '/' }
$placeholder = 'https://YOUR-GITHUB-USERNAME.github.io/jasmin-beach-resort/'
$docs = Join-Path (Split-Path $PSScriptRoot -Parent) 'docs'
$utf8 = New-Object System.Text.UTF8Encoding $false

Get-ChildItem $docs -File -Include *.html, *.xml, *.txt -Recurse | ForEach-Object {
  $text = [IO.File]::ReadAllText($_.FullName)
  if ($text.Contains($placeholder)) {
    [IO.File]::WriteAllText($_.FullName, $text.Replace($placeholder, $Url), $utf8)
    "updated $($_.Name)"
  }
}
