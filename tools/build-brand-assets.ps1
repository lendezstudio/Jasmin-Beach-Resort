# Builds logo derivatives, favicons and the Open Graph share image from the original
# Jasmin Beach Resort logo and photography. Originals are never modified.
#   powershell -ExecutionPolicy Bypass -File tools\build-brand-assets.ps1 [-FontDir <dir with SpaceGrotesk-Bold.ttf, SpaceGrotesk-Medium.ttf>]
param([string]$FontDir = "$PSScriptRoot\fonts")

Add-Type -AssemblyName System.Drawing
Add-Type -Path "$PSScriptRoot\ImageKit.cs" -ReferencedAssemblies System.Drawing

$root  = Split-Path $PSScriptRoot -Parent
$docs  = Join-Path $root 'docs'
$brand = Join-Path $docs 'assets\img\brand'
New-Item -ItemType Directory -Force $brand | Out-Null

$navy  = [System.Drawing.ColorTranslator]::FromHtml('#10283D')
$sand  = [System.Drawing.ColorTranslator]::FromHtml('#F3E9D9')
$white = [System.Drawing.ColorTranslator]::FromHtml('#FCFAF6')
$coral = [System.Drawing.ColorTranslator]::FromHtml('#FF7258')
$ocean = [System.Drawing.ColorTranslator]::FromHtml('#007FA3')

function New-Canvas($w, $h) {
  $b = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'
  $g.PixelOffsetMode = 'HighQuality'; $g.TextRenderingHint = 'AntiAliasGridFit'
  return @($b, $g)
}
function Get-RoundRect($x, $y, $w, $h, $r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddArc($x, $y, 2*$r, 2*$r, 180, 90); $p.AddArc($x+$w-2*$r, $y, 2*$r, 2*$r, 270, 90)
  $p.AddArc($x+$w-2*$r, $y+$h-2*$r, 2*$r, 2*$r, 0, 90); $p.AddArc($x, $y+$h-2*$r, 2*$r, 2*$r, 90, 90)
  $p.CloseFigure(); return $p
}

# ---------- Logo derivatives ----------
$logo = [ImageKit]::Load((Join-Path $root 'Initial Image\Jasmin Beach Resort Sunset Logo.png'))
# Trim the generous white margin around the artwork (keeps the full logo intact).
$trim = [ImageKit]::Crop($logo, 80/1254, 50/1254, 1100/1254, 1110/1254)
foreach ($w in 240, 480) {
  $r = [ImageKit]::ResizeToWidth($trim, $w)
  [ImageKit]::SaveJpeg($r, (Join-Path $brand "logo-$w.jpg"), 88); $r.Dispose()
}
$clear = [ImageKit]::RemoveWhiteBackground($trim, 248, 222)
$c512 = [ImageKit]::ResizeToWidth($clear, 512)
$kit = Join-Path $root 'brand-kit'; New-Item -ItemType Directory -Force $kit | Out-Null
$c512.Save((Join-Path $kit 'logo-transparent-512.png'), [System.Drawing.Imaging.ImageFormat]::Png)
# Transparent web logos: full colour (light backgrounds) and a light-wordmark
# version for photography and navy backgrounds.
$light = [ImageKit]::LightenWordmark($clear, 680, 860, 1025, $white)
$light.Save((Join-Path $kit 'logo-transparent-light-full.png'), [System.Drawing.Imaging.ImageFormat]::Png)
foreach ($w in 240) {
  $r = [ImageKit]::ResizeToWidth($clear, $w); $r.Save((Join-Path $brand "logo-color-$w.png"), [System.Drawing.Imaging.ImageFormat]::Png); $r.Dispose()
  $r = [ImageKit]::ResizeToWidth($light, $w); $r.Save((Join-Path $brand "logo-light-$w.png"), [System.Drawing.Imaging.ImageFormat]::Png); $r.Dispose()
}
$clear.Save((Join-Path $kit 'logo-transparent-full.png'), [System.Drawing.Imaging.ImageFormat]::Png)

# ---------- Favicon: the "J" from the wordmark, on a deep ocean tile ----------
$jCrop = [ImageKit]::Crop($logo, 88/1254, 762/1254, 242/1254, 322/1254)
# Remove the sliver of the teal wave that sits above the J's top-left.
$gj = [System.Drawing.Graphics]::FromImage($jCrop)
$gj.FillRectangle([System.Drawing.Brushes]::White, 0, 0, 122, 52)
$gj.FillRectangle([System.Drawing.Brushes]::White, 212, 312, 40, 20); $gj.Dispose()
$jMask = [ImageKit]::MaskFromDark($jCrop, 95, 205, $white)

function New-Icon($size, [bool]$rounded) {
  $m = 512
  $cv = New-Canvas $m $m; $b = $cv[0]; $g = $cv[1]
  $g.Clear([System.Drawing.Color]::Transparent)
  $brush = New-Object System.Drawing.SolidBrush $navy
  if ($rounded) { $g.FillPath($brush, (Get-RoundRect 0 0 $m $m 104)) } else { $g.FillRectangle($brush, 0, 0, $m, $m) }
  # J sized to ~76% of the tile height for small-size legibility.
  $jh = 400; $jw = [int]($jMask.Width * $jh / $jMask.Height)
  $g.DrawImage($jMask, [int](($m - $jw)/2) + 14, [int](($m - $jh)/2) + 4, $jw, $jh)
  # Coral sun: a nod to the logo's sunset and hibiscus.
  $g.FillEllipse((New-Object System.Drawing.SolidBrush $coral), 92, 84, 92, 92)
  $g.Dispose()
  $out = [ImageKit]::Resize($b, $size, $size); $b.Dispose(); return $out
}
$ico = @()
foreach ($s in 16, 32, 48) {
  $i = New-Icon $s $true; $p = Join-Path $docs "favicon-$($s)x$($s).png"; $i.Save($p, [System.Drawing.Imaging.ImageFormat]::Png); $i.Dispose(); $ico += $p
}
[ImageKit]::WriteIco((Join-Path $docs 'favicon.ico'), $ico)
Remove-Item (Join-Path $docs 'favicon-48x48.png')
$a = New-Icon 180 $false; $a.Save((Join-Path $docs 'apple-touch-icon.png'), [System.Drawing.Imaging.ImageFormat]::Png); $a.Dispose()
foreach ($s in 192, 512) { $a = New-Icon $s $false; $a.Save((Join-Path $brand "icon-$s.png"), [System.Drawing.Imaging.ImageFormat]::Png); $a.Dispose() }

# ---------- Open Graph image (1200 x 630) ----------
$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$pfc.AddFontFile((Join-Path $FontDir 'SpaceGrotesk-Bold.ttf'))
$pfc.AddFontFile((Join-Path $FontDir 'SpaceGrotesk-Medium.ttf'))
$family = $pfc.Families[0]

$cv = New-Canvas 1200 630; $og = $cv[0]; $g = $cv[1]
$g.Clear($sand)
# Photo panel (right): the beachfront from the upper walkway.
$photo = [ImageKit]::Load((Join-Path $root 'Initial Image\794385407_4468532163463736_8936700106107023904_n.jpg'))
$photo = [ImageKit]::Crop($photo, 0, 0, 1, 0.925)
$pan = [ImageKit]::Cover($photo, 640, 630, 0.62, 0.5)
$g.DrawImage($pan, 560, 0, 640, 630)
# Thin coral rule where sand meets photo.
$g.FillRectangle((New-Object System.Drawing.SolidBrush $coral), 556, 0, 6, 630)

# Logo
$g.DrawImage($c512, 64, 46, 236, 238)

function Draw-Tracked($g, $text, $font, $brush, $x, $y, $track) {
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  foreach ($ch in $text.ToCharArray()) {
    $s = [string]$ch
    $g.DrawString($s, $font, $brush, $x, $y, $fmt)
    $w = if ($s -eq ' ') { $font.Size * 0.28 } else { $g.MeasureString($s, $font, 1000, $fmt).Width }
    $x += $w + $track
  }
}
$navyB  = New-Object System.Drawing.SolidBrush $navy
$coralB = New-Object System.Drawing.SolidBrush $coral
$oceanB = New-Object System.Drawing.SolidBrush $ocean
$label  = New-Object System.Drawing.Font $pfc.Families[0], 19, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
foreach ($f in $pfc.Families) { if ($f.IsStyleAvailable([System.Drawing.FontStyle]::Bold)) { $boldFam = $f } }
$head   = New-Object System.Drawing.Font $boldFam, 66, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)

Draw-Tracked $g 'JASMIN BEACH RESORT' $label $oceanB 68 334 5.2
$fmt = [System.Drawing.StringFormat]::GenericTypographic
$g.DrawString('THE COAST', $head, $navyB, 62, 376, $fmt)
$g.DrawString('IS CALLING', $head, $navyB, 62, 446, $fmt)
$w = $g.MeasureString('IS CALLING', $head, 2000, $fmt).Width
$g.DrawString('.', $head, $coralB, 62 + $w, 446, $fmt)
$g.FillRectangle($navyB, 68, 552, 56, 4)
$g.Dispose()
[ImageKit]::SaveJpeg($og, (Join-Path $docs 'assets\img\jasmin-beach-resort-og.jpg'), 88)
"Brand assets written to $brand"
