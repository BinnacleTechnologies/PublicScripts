<#
    .SYNOPSIS
        Takes an image (typically a company logo), resizes and centers it on a background scaled to fit VOIP phone screens.

    .DESCRIPTION
        This script uses the native .NET API to create a blank background, colors it if desired, resizes a provided image file while preserving the aspect ratio, and centers the logo based on parameters defined.
        If the -Model parameter and the known models csv import fails, it will prompt to create a new sample csv.

        Example parameters for my personal preference on a Yealink T46S where the logo is as large as possible without it being able to overlayed by Line Key labels.

        The script assumes you're referencing a KnownPhoneModels.csv in the working directory, but you can also call an existing one with the -ModelList parameter.
        
        Source image formats supported: BMP, GIF, JPEG, PNG, TIFF

        Color options are limited to system-defined colors, see https://docs.microsoft.com/en-us/dotnet/api/system.drawing.color?redirectedfrom=MSDN&view=netframework-4.8#properties
 
    .EXAMPLE
        .\New-VoipBackground.ps1 -logo "Company Logo.png" -Outputfile "c:\Temp\PhoneLogo.jpg" -Model "Yealink T46S"

        Takes the source logo, scales it based on contents of knownphones.csv and outputs c:\Temp\PhoneLogo.jpg with a clear background.

    .EXAMPLE
        .\New-VoipBackground.ps1 -logo "Company Logo.png" -Outputfile "c:\Temp\PhoneLogo.jpg" -ScreenWidth 400 -ScreenHeight 250 -LogoWidth 100 -LogoHeight 100 -Color "Black"

        Takes the source logo, scales it based on the manually defined parameters, and outputs PhoneLogo.jpg with a black background. Remember that this script preserves the logo's aspect ratio, so
        the values for -LogoWidth and -LogoHeight are maximum values, not explicit settings.

    .LINK
        Author: Jon Shults - https://binnacle-it.com
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Logo,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByModel')]
    [string]$Model,

    [Parameter(ParameterSetName = 'ByModel')]
    [string]$ModelList = ".\KnownPhoneModels.csv",

    [Parameter(Mandatory = $true, ParameterSetName = 'ByDimension')]
    [int]$ScreenWidth,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByDimension')]
    [int]$ScreenHeight,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByDimension')]
    [int]$LogoWidth,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByDimension')]
    [int]$LogoHeight,

    [Parameter()]
    [string]$Color
)

# Checks if Outputfile parameter includes a drive letter designation, if not, we prefix the .\ so we can assume the working directory.
If ($OutputFile.IndexOf(":") -eq 2) {
    Write-Output "Colon present in second character index 2, drive letter assumed."
} Else {
    $OutputFile = ".\" + "$OutputFile"
    Write-Output "Updated OutputFile value is $($Outputfile)"
}

# If -Model is used, imports the known models and pull the associated information
If ($PsCmdlet.ParameterSetName -match "ByModel") {
    Try {
        $KnownModels = Import-Csv $Modellist
    }
    Catch {
        Write-Host "Import of $($ModelList) failed. Verify that ($($ModelList) exists, and  try including the full path to file as part of the -ModelList parameter." -ForegroundColor Red
        $create = Read-Host "Would you like a new file created? (Y/N)"
        Switch ($Create) {
            Y {
                "Model,ScreenWidth,ScreenHeight,LogoWidth,LogoHeight" + "`r`n" + "Yealink T46S,480,272,280,160" | Out-File -FilePath $ModelList
                $Success = Test-Path $ModelList
                If (!$Success) {
                    Write-Output "Creating file failed. Verify you have write access to $($ModelList), or re-run New-VoipBackground.ps1 specifying the full path with the -ModelList parameter."
                    Exit
                }
                Else {
                    Write-Output "New $($ModelList) file created. Make any entries or adjustments necessary, then re-run New-VoipBackground."
                    Exit
                }
            }
            Default {
                Write-Output "Exiting script."
                Exit
            }
        }
    }
    Foreach ($phone in $KnownModels) {
        If ($Model -eq $Phone.Model) {
            $ScreenWidth = $Phone.ScreenWidth
            $ScreenHeight = $Phone.ScreenHeight
            $LogoWidth = $Phone.LogoWidth
            $LogoHeight = $Phone.LogoHeight
            $Match = $true
            break
        }
    }
    If (!$Match) {
        Write-Output "No entry for $($Model) was found in $($Modellist). Verify that you're specifying a model that precisely matches an existing entry."
        Exit
    }
    # The below check seems to be  very unreliable for some reason
    If ($Match -and (!$ScreenWidth -or !$ScreenHeight -or !$LogoWidth -or $LogoHeight)) {
        Write-Output "Match value is $($Match), but ($($ModelList) either contains incomplete information for $($Model) or is impropperly formatted. What we show is Screenwidth: $($ScreenWidth), ScreenHeight: $($ScreenHeight), LogoWidth: $($LogoWidth), LogoHeight: $($LogoHeight). Ensure it contains information about the screen size and logo dimensions, then try again."
        Exit
    }
}
                
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

# Final check for success
$FinalSuccess = Test-Path $OutputFile
If (!$FinalSuccess) {
    Write-Output "Creating final output file failed. Try using the full output path in the -Outputfile parameter, and verify you have write access to $($OutputFile)."
    Exit
}
