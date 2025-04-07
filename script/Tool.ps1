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

function New-SemMarkdownItem {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [string]
        $WorkingDirectory = (Get-Location)
    )

    Process {
        dir $InputObject |
            foreach {
                $tags = @()
                $dates = @()

                $_.FullName.
                Replace($WorkingDirectory, '') |
                Split-Path -Parent |
                foreach { $_ -split '\\' } |
                foreach { $_ -split ',' } |
                where { $_ } |
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

            $markdown | Out-File `
                -FilePath "item_-_$dtstr.md" `
                -Encoding utf8 `
                -Force
        }
    }
}

