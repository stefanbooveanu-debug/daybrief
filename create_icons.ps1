param(
  [string]$IconDir = (Join-Path $PSScriptRoot "assets\icon")
)

Add-Type -AssemblyName System.Drawing

if (!(Test-Path $IconDir)) { New-Item -ItemType Directory -Force -Path $IconDir | Out-Null }

$bmp = New-Object System.Drawing.Bitmap(1024, 1024)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(26, 115, 232))

$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$font = New-Object System.Drawing.Font('Arial', 400, [System.Drawing.FontStyle]::Bold)
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$format.LineAlignment = [System.Drawing.StringAlignment]::Center
$rect = New-Object System.Drawing.RectangleF(0, 0, 1024, 1024)
$g.DrawString("DB", $font, $brush, $rect, $format)

$bmp.Save("$IconDir\app_icon.png", [System.Drawing.Imaging.ImageFormat]::Png)

$fg = New-Object System.Drawing.Bitmap(1024, 1024)
$gf = [System.Drawing.Graphics]::FromImage($fg)
$gf.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$brush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$gf.DrawString("DB", $font, $brush2, $rect, $format)
$fg.Save("$IconDir\app_icon_foreground.png", [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$fg.Dispose()
$bmp.Dispose()
$gf.Dispose()
$brush.Dispose()
$brush2.Dispose()
$font.Dispose()

Write-Host "Icons written to $IconDir"
