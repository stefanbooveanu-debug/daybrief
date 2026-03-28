Add-Type -AssemblyName System.Drawing

$iconDir = "C:\Users\Mircea\Desktop\cal2.0\assets\icon"
if (!(Test-Path $iconDir)) { New-Item -ItemType Directory -Force -Path $iconDir }

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

$bmp.Save("$iconDir\app_icon.png", [System.Drawing.Imaging.ImageFormat]::Png)

$fg = New-Object System.Drawing.Bitmap(1024, 1024)
$gf = [System.Drawing.Graphics]::FromImage($fg)
$gf.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$brush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$gf.DrawString("DB", $font, $brush2, $rect, $format)
$fg.Save("$iconDir\app_icon_foreground.png", [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$fg.Dispose()
$bmp.Dispose()
$fg.Dispose()

Write-Host "Icons created successfully!"