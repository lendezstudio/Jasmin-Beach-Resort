# Replaces the site's absolute URL used for canonical links, Open Graph tags,
# structured data, the sitemap, robots.txt and the 404 page — e.g. when moving
# to a custom domain:
#   powershell -ExecutionPolicy Bypass -File tools\set-site-url.ps1 -Url https://example.com/
param(
  [Parameter(Mandatory = $true)][string]$Url,
  [string]$From = 'https://lendezstudio.github.io/Jasmin-Beach-Resort/'
)

if (-not $Url.EndsWith('/')) { $Url += '/' }
if (-not $From.EndsWith('/')) { $From += '/' }
$site = Join-Path (Split-Path $PSScriptRoot -Parent) 'docs'
$utf8 = New-Object System.Text.UTF8Encoding $false

Get-ChildItem "$site\*" -File -Include *.html, *.xml, *.txt | ForEach-Object {
  $text = [IO.File]::ReadAllText($_.FullName)
  if ($text.Contains($From)) {
    [IO.File]::WriteAllText($_.FullName, $text.Replace($From, $Url), $utf8)
    "updated $($_.Name)"
  }
}
