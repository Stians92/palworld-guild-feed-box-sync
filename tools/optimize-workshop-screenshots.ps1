param(
    [string]$InputDirectory = (Join-Path $PSScriptRoot '..\screenshots'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\screenshots\steam'),
    [ValidateRange(1, 100)]
    [int]$Quality = 95
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object MimeType -eq 'image/jpeg' |
    Select-Object -First 1

if (-not $jpegCodec) {
    throw 'The Windows JPEG encoder is unavailable.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$encoderParameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
$encoderParameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new(
    [System.Drawing.Imaging.Encoder]::Quality,
    [long]$Quality
)

try {
    Get-ChildItem -LiteralPath $InputDirectory -Filter '*.png' -File | ForEach-Object {
        $source = [System.Drawing.Image]::FromFile($_.FullName)
        try {
            $outputPath = Join-Path $OutputDirectory ($_.BaseName + '.jpg')
            $source.Save($outputPath, $jpegCodec, $encoderParameters)

            $output = Get-Item -LiteralPath $outputPath
            [pscustomobject]@{
                Name = $output.Name
                Quality = $Quality
                SizeMB = [math]::Round($output.Length / 1MB, 2)
            }
        }
        finally {
            $source.Dispose()
        }
    }
}
finally {
    $encoderParameters.Dispose()
}
