function New-SemItemName {
    [Alias('Semuid')]
    Param(
        [string]
        $Prefix = 'item',

        [string]
        $Extension = '.md'
    )

    return "$($Prefix)_-_$(Get-Date -Format yyyy-MM-dd-HHmmss-fff)$Extension" # Uses DateTimeFormat
}

