<# New-PhoneBackground.ps1
Jon Shults
Binnacle Technologies, LLC

.DESCRIPTION

    This script uses the native .NET API to create a blank background, colors it if desired, resizes a provided image file while preserving the aspect ratio, and centers the logo based on parameters defined.
    Pre-defined parameters for my personal preference on a Yealink T46S where the logo is as large as possible without it being able to overlayed by Line Key labels.

    Source image formats supported: BMP, GIF, JPEG, PNG, TIFF

    -OutputFile parameter requires full directory path for consistent behavior

    Color options are limited to system-defined colors, see https://docs.microsoft.com/en-us/dotnet/api/system.drawing.color?redirectedfrom=MSDN&view=netframework-4.8#properties

.EXAMPLE
    .\New-PhoneBackground.ps1 -logo "Company Logo.png" -Outputfile "c:\Temp\PhoneLogo.jpg"

    Takes the source logo, scales it based on contents of knownphones.csv and outputs c:\Temp\PhoneLogo.jpg with a clear background.

.EXAMPLE
    .\New-PhoneBackground.ps1 -logo "Company Logo.png" -Outputfile "c:\Temp\PhoneLogo.jpg" -Color "Black"

    Takes the source logo, scales it based on contents of knownphones.csv and outputs c:\Temp\PhoneLogo.jpg with a black background.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Logo,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [Parameter()]
    [string]$Color
)

# Change the below to match your phone's specifications and preference on logo placement
$ScreenWidth = 480
$ScreenHeight = 272
$LogoWidth = 280
$LogoHeight = 160

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

# Import the Picture
$PhoneLogo = [system.drawing.image]::FromFile((Get-Item $Logo))

# Creating Blank Canvas, and colors if necessary
$BG = New-Object System.Drawing.Bitmap($ScreenWidth, $ScreenHeight)
Write-Output "Creating a blank image with dimensions $($ScreenWidth)x$($ScreenHeight)."
If ($Color) {
    Write-Output "Coloring it $($Color)..."
    for ($i = 0; $i -lt $ScreenWidth; $i++) {
        for ($j = 0; $j -lt $ScreenHeight; $j ++) {
            $BG.SetPixel($i, $j, $color)
        }
    }
}

# Calculate if we're scaling based on width or hight, as well as how large the final logo will be
$Ratio = $PhoneLogo.Width / $LogoWidth
If (($PhoneLogo.Height / $Ratio) -gt $LogoHeight) {
    # Logo scaled based on width will be too tall
    Write-Output "Scaling logo based on height"
    $Ratio = $PhoneLogo.Height / $LogoHeight
    $FinalWidth = [math]::Round($PhoneLogo.width / $Ratio)
    $FinalHeight = $LogoHeight
}
Else {
    Write-Output "Scaling logo based on width"
    $Ratio = $PhoneLogo.Width / $LogoWidth
    $FinalHeight = [math]::Round($PhoneLogo.Height / $Ratio)
    $finalWidth = $LogoWidth
}

# Calculate logo position, place, and output
$StartingY = (($ScreenHeight / 2) - ($FinalHeight / 2))
$StartingX = (($ScreenWidth / 2) - ($FinalWidth / 2))
$graph = [System.Drawing.Graphics]::FromImage($BG)
$graph.DrawImage($PhoneLogo, $startingX, $StartingY, $FinalWidth, $FinalHeight)
Write-Output "Applying a $($finalWidth)x$($FinalHeight) logo starting at $($StartingX),$($StartingY), and saving to $($outputfile)."
$BG.Save($OutputFile)
