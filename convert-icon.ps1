# PNG to ICO Converter for Player by HEIMLICH - High Quality Multi-Resolution Version
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Converting icon_win.png to High Quality ICO Format" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Load required assemblies
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Input and output paths
$pngPath = "assets\Images\icon_win.png"
$icoPath = "assets\Images\icon_win.ico"

# Check if PNG file exists
if (-not (Test-Path $pngPath)) {
    Write-Host "[ERROR] PNG file not found: $pngPath" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Loading PNG image: $pngPath" -ForegroundColor Green

try {
    # Load the original image
    $originalImage = [System.Drawing.Image]::FromFile((Resolve-Path $pngPath))
    Write-Host "[INFO] Original image size: $($originalImage.Width)x$($originalImage.Height) pixels" -ForegroundColor Yellow
    
    # Create multiple high-quality sizes for professional icons
    $sizes = @(16, 20, 24, 32, 40, 48, 64, 96, 128, 256, 512, 1024)
    $bitmaps = @()
    
    Write-Host "[INFO] Creating high-quality multi-resolution icon..." -ForegroundColor Green
    
    foreach ($size in $sizes) {
        # Create high-quality bitmap
        $bitmap = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        # Set highest quality rendering to preserve gradients
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
        
        # Clear with transparent background
        $graphics.Clear([System.Drawing.Color]::Transparent)
        
        # Draw with high quality to preserve gradients and details
        $destRect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
        $graphics.DrawImage($originalImage, $destRect, 0, 0, $originalImage.Width, $originalImage.Height, [System.Drawing.GraphicsUnit]::Pixel)
        $graphics.Dispose()
        
        $bitmaps += $bitmap
        Write-Host "[SUCCESS] Created ${size}x${size} high-quality layer" -ForegroundColor Green
    }
    
    # Save as multi-resolution ICO with manual format control
    $fileStream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $binaryWriter = [System.IO.BinaryWriter]::new($fileStream)
    
    # Write ICO header
    $binaryWriter.Write([UInt16]0)          # Reserved, must be 0
    $binaryWriter.Write([UInt16]1)          # Type: 1 for ICO
    $binaryWriter.Write([UInt16]$bitmaps.Count) # Number of images
    
    # Calculate data offset (6 bytes header + 16 bytes per directory entry)
    $offset = 6 + ($bitmaps.Count * 16)
    $imageData = @()
    
    # Process each bitmap and prepare directory entries
    for ($i = 0; $i -lt $bitmaps.Count; $i++) {
        $bitmap = $bitmaps[$i]
        $size = $sizes[$i]
        
        # Convert bitmap to PNG format to preserve transparency and quality
        $memStream = [System.IO.MemoryStream]::new()
        $bitmap.Save($memStream, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngData = $memStream.ToArray()
        $memStream.Close()
        $imageData += ,$pngData
        
        # Write directory entry (16 bytes)
        $binaryWriter.Write([Byte]([Math]::Min($size, 255)))  # Width (0 = 256)
        $binaryWriter.Write([Byte]([Math]::Min($size, 255)))  # Height (0 = 256)
        $binaryWriter.Write([Byte]0)      # Color count (0 for no palette)
        $binaryWriter.Write([Byte]0)      # Reserved
        $binaryWriter.Write([UInt16]1)    # Color planes
        $binaryWriter.Write([UInt16]32)   # Bits per pixel
        $binaryWriter.Write([UInt32]$pngData.Length)  # Data size
        $binaryWriter.Write([UInt32]$offset)          # Data offset
        
        $offset += $pngData.Length
    }
    
    # Write actual image data
    foreach ($data in $imageData) {
        $binaryWriter.Write($data)
    }
    
    $binaryWriter.Close()
    $fileStream.Close()
    
    # Clean up
    foreach ($bitmap in $bitmaps) {
        $bitmap.Dispose()
    }
    $originalImage.Dispose()
    
    # Verify the created file
    if (Test-Path $icoPath) {
        $fileInfo = Get-Item $icoPath
        Write-Host "[SUCCESS] High-quality multi-resolution ICO created!" -ForegroundColor Green
        Write-Host "[INFO] File size: $($fileInfo.Length) bytes" -ForegroundColor Yellow
        Write-Host "[INFO] Resolutions: $($sizes -join ', ') pixels" -ForegroundColor Cyan
        Write-Host "[INFO] Format: PNG-compressed layers for maximum quality" -ForegroundColor Cyan
        Write-Host "[INFO] Location: $icoPath" -ForegroundColor Yellow
    } else {
        Write-Host "[ERROR] Failed to create ICO file" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "[ERROR] Conversion failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "" 
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "High-Quality ICO conversion completed successfully!" -ForegroundColor Green
Write-Host "Ready for professional application and installer use!" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan 