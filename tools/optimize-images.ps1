# Builds web-ready responsive JPEGs from the original photographs in "Initial Image".
# Originals are never modified. Run from the project root:
#   powershell -ExecutionPolicy Bypass -File tools\optimize-images.ps1
Add-Type -AssemblyName System.Drawing
Add-Type -Path "$PSScriptRoot\ImageKit.cs" -ReferencedAssemblies System.Drawing

$root = Split-Path $PSScriptRoot -Parent
$src  = Join-Path $root 'Initial Image'
$out  = Join-Path $root 'assets\img\photos'
New-Item -ItemType Directory -Force $out | Out-Null

# slug, source file id prefix, crop (x, y, w, h as fractions). Crops remove camera
# timestamps / watermarks burned into some originals.
$photos = @(
  @('beachfront-balcony',    '794385407', 0, 0, 1, 0.925),
  @('kayak-calm-water',      '794727123', 0, 0, 1, 1),
  @('veranda-coast-view',    '795132733', 0, 0, 1, 1),
  @('main-building-palms',   '795809497', 0, 0, 1, 1),
  @('grounds-under-trees',   '797105134', 0, 0, 1, 0.86),
  @('grounds-two-wings',     '800715609', 0, 0, 1, 1),
  @('shoreline-portrait',    '806129276', 0, 0, 1, 1),
  @('kiosks-garden-tables',  '807830485', 0, 0, 1, 1),
  @('main-building',         '811711212', 0, 0, 1, 1),
  @('sunset-headland',       '812645802', 0, 0, 1, 1),
  @('palms-shore-view',      '813923229', 0, 0, 1, 0.94),
  @('beach-huts',            '814034541', 0, 0, 1, 0.95),
  @('beach-kiosks',          '814230812', 0, 0, 1, 1),
  @('balcony-tables',        '814471858', 0, 0, 1, 1),
  @('floating-cottages',     '814608748', 0, 0, 1, 1),
  @('driftwood-deck',        '814740715', 0, 0, 1, 1),
  @('kayak-shore',           '815631207', 0, 0, 1, 1),
  @('beach-path-palms',      '815920427', 0, 0, 1, 1),
  @('boardwalk-to-resort',   '816928729', 0, 0, 1, 1),
  @('grounds-shade',         '817329479', 0, 0, 1, 1),
  @('accommodation-wing',    '817342911', 0, 0, 1, 1),
  @('jetty-portrait',        '818743120', 0, 0, 1, 1),
  @('veranda-beach',         '818922412', 0, 0, 1, 1),
  @('kiosk-garden',          '818922629', 0, 0, 1, 1),
  @('kiosk-view-rooms',      '818940418', 0, 0, 1, 1),
  @('kiosk-night',           '821523449', 0, 0, 1, 1),
  @('jetty-night',           '824129132', 0, 0, 1, 1),
  @('lounger-sea-view',      '825292899', 0, 0, 1, 1),
  @('kayaks-on-sand',        '828391761', 0, 0, 1, 1),
  @('accommodation-block',   '828632216', 0, 0, 1, 1)
)
$widths = 480, 960, 1600
$report = @()

foreach ($p in $photos) {
  $file = Get-ChildItem $src -Filter "$($p[1])*" | Select-Object -First 1
  $bmp  = [ImageKit]::Load($file.FullName)
  $crop = [ImageKit]::Crop($bmp, $p[2], $p[3], $p[4], $p[5]); $bmp.Dispose()
  $made = @()
  foreach ($w in $widths) {
    $tw = [Math]::Min($w, $crop.Width)
    if ($made -contains $tw) { continue }
    $r = [ImageKit]::ResizeToWidth($crop, $tw)
    [ImageKit]::SaveJpeg($r, (Join-Path $out "$($p[0])-$w.jpg"), 78)
    $r.Dispose(); $made += $tw
  }
  $report += "{0} {1}x{2}" -f $p[0], $crop.Width, $crop.Height
  $crop.Dispose()
}
$report
