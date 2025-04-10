function Rename-SemItem {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [string]
        $Prefix = 'item'
    )

    Process {
        Get-Item $InputObject |
        foreach {
            $dt = $_.LastWriteTime
            $dtstr = $dt | Get-Date -f yyyy-MM-dd-HHmmss-fff # Uses DateTimeFormat
            Rename-Item $_ "$($Prefix)_-_$dtstr$($_.Extension)"
        }
    }
}

function New-SemItemName {
    [CmdletBinding(DefaultParameterSetName = 'NoInput')]
    [Alias('Semuid')]
    Param(
        [Parameter(
            ValueFromPipeline = $true,
            ParameterSetName = 'Input'
        )]
        [datetime]
        $Date,

        [string]
        $Prefix = 'item',

        [string]
        $Extension = '.md'
    )

    Begin {
        $list = @()
    }

    Process {
        $list += @($Date | where { $_ })
    }

    End {
        $list = switch ($PsCmdlet.ParameterSetName) {
            'NoInput' {
                @(Get-Date)
            }

            'Input' {
                $list
            }
        }

        return $list |
        foreach {
            # Uses DateTimeFormat
            "$($Prefix)_-_$($_ | Get-Date -Format yyyy-MM-dd-HHmmss-fff)$Extension"
        }
    }
}

<#
.DESCRIPTION
Requires: gswin64, popplers
#>
function New-SemMarkdownItem {
    [CmdletBinding(DefaultParameterSetName = 'Batch')]
    Param(
        [Parameter(
            ParameterSetName = 'Single',
            ValueFromPipeline = $true
        )]
        $InputObject,

        [Parameter(
            ParameterSetName = 'Single'
        )]
        [string]
        $WorkingDirectory = (Get-Location)
    )

    Begin {
        function Compare-WorklistItem {
            Param(
                $Source,
                $Destination
            )

            $pageCount = Get-SemPdfPageCount -FilePath $Source

            $imageCount = Get-Content $Destination |
                Select-String "^\s*!\[" |
                Measure-Object |
                foreach Count

            $success = $pageCount -eq $imageCount

            if (-not $success) {
                [pscustomobject]@{
                    Srce = (Get-Item $Source).Name
                    Pages = $pageCount
                    Dest = (Get-Item $Destination).Name
                    Images = $imageCount
                }
            }
        }
    }

    Process {
        dir $InputObject |
            foreach {
                $tags = @()
                $dates = @()

                $_.FullName.
                Replace($WorkingDirectory, '') |
                Split-Path -Parent |
                foreach { $_ -split '/|\\|,' } |
                where { $_ -and $_ -notlike "__*" } |
                foreach {
                    # Uses DateTimeFormat
                    if ($_ -match "^\d{4}(-\d{2}(-d{2})?)?$") {
                        $dates += @($_)
                    }
                    else {
                        $tags += @($_)
                    }
                }

                ConvertTo-SemMarkdownItem `
                    -InputObject $_ `
                    -Tags $tags `
                    -Dates $dates `
            }
    }

    End {
        switch ($PsCmdlet.ParameterSetName) {
            'Batch' {
                $setting = Get-Item "$PsScriptRoot/../res/setting.json" |
                    Get-Content |
                    ConvertFrom-Json

                $sourceDirectory = iex "`"$($setting.DefaultSourceDirectoryExpr)`""
                $extension = $setting.DefaultExtension
                $files = Get-ChildItem "$sourceDirectory/*$extension" -Recurse

                $files |
                foreach -Begin {
                    $count = 0
                } -Process {
                    Write-Progress `
                        -Activity 'Converting item' `
                        -Status "($($count + 1) of $($files.Count)) $($_.Name)" `
                        -PercentComplete (100 * $count / $files.Count)

                    $outFile = $_ | New-SemMarkdownItem -WorkingDirectory $sourceDirectory

                    Compare-WorklistItem `
                        -Source $_ `
                        -Destination $outFile

                    $count = $count + 1
                }

                Write-Progress `
                    -Activity 'Converting item' `
                    -Completed
            }
        }
    }
}

<#
.DESCRIPTION
Requires: popplers
#>
function Get-SemPdfPageCount {
    [OutputType([int])]
    Param(
        [string]
        $FilePath
    )

    pdfinfo "$FilePath" |
    Select-String "(?<=Pages:\s+)\d+" |
    foreach { [int] $_.Matches.Value }
}

function ConvertTo-SemMarkdownItem {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [string[]]
        $Tags,

        [string[]]
        $Dates,

        [string]
        $ResourceDirectory = './res',

        [int]
        $Dpi = 300,

        [ValidateSet('pngalpha')]
        [string]
        $Device = 'pngalpha'
    )

    Begin {
        $resFullPath = Join-Path (Get-Location) $ResourceDirectory

        if (-not (Test-Path $resFullPath)) {
            $null = mkdir $resFullPath
        }
    }

    Process {
        dir $InputObject |
        foreach {
            $dt = $_.LastWriteTime
            $dtstr = $dt | Get-Date -f yyyy-MM-dd-HHmmss-fff # Uses DateTimeFormat
            $outPath = Join-Path $ResourceDirectory "$dtstr-%03d.png"
            gswin64 "-sDEVICE=$Device" -o $outPath -r"$Dpi" $_

            while ((Get-Process -Name "gswin64" -ErrorAction SilentlyContinue)) {
                sleep 0.1
            }

            $images = dir (Join-Path $ResourceDirectory "$dtstr-*.png")

            $locals = $images |
                foreach {
                    $dir = Join-Path $ResourceDirectory $_.Name
                    $dir = $dir -replace "\\", "/"
                    "![$($_.BaseName)](<$dir>)`r`n"
                }

            $tagsStr = ""
            $title = "item"

            if ($Tags) {
                $tagsStr = "tag: $($Tags -join ', ')`r`n"
                $title = "$($title): $(@($Tags)[0])"
            }

            $datesStr = if ($Dates) {
                "date: $($Dates -join ', ')`r`n"
            }
            else {
                ""
            }

            $localsStr = "$($locals -join "`r`n")"
            $datetagStr = "$tagsStr$datesStr"

            if ($datetagStr) {
                $datetagStr = "`r`n$datetagStr"
            }

            $markdown = @"
# $title
$datetagStr
$localsStr
"@

            $outFileName = "item_-_$dtstr.md"

            $markdown | Out-File `
                -FilePath $outFileName `
                -Encoding utf8 `
                -Force

            Get-Item $outFileName
        }
    }
}

