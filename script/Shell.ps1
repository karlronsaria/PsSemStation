<#
- [ ] consider: default order-by clause
- [x] rename batch type
- [x] sem pool
  - [x] sem pool
  - [x] accept 'sem get item' and 'sem find', etc as pipeline input
- [x] sem batch 0
- [x] sem pool .
- [x] sem pool 20250322025429.pdf, 20250322025449.pdf, 20250322025459.pdf
- [x] sem pool (dir ~/documents/temp/*.*)
- [x] sem tag budget, paystub
- [x] sem date 2025-02-02
- [x] sem reset
- [x] sem untag claim
- [x] sem undate 2025-02-01
- [x] sem commit
- [x] sem get tag
- [x] sem get date
- [x] sem get item
  - [x] sem get item
  - [x] accept 'sem get item' and 'sem find', etc as pipeline input
  - [x] with
    - [x] tag
      - [x] eq
      - [x] ne
        - [x] name | descript | content
          - [x] eq
          - [x] ne
          - [x] like
          - [x] notlike
          - [x] match
          - [x] notmatch
        - [x] date
          - [x] eq
          - [x] ne
          - [x] after
          - [x] before
          - [x] between
  - [x] created | arrived | expiry
    - [x] eq
    - [x] ne
    - [x] after
    - [x] before
    - [x] between
- [ ] sem find
#>

class SemBatch {
    [string[]] $Items
    [string] $Command
    [string[]] $Tags
    [string[]] $Dates
    [string[]] $RemoveTags
    [string[]] $RemoveDates

    static [SemBatch[]] $Batches = @()
    static [int] $Index = -1

    static [SemBatch] Current() {
        return [SemBatch]::Batches[[SemBatch]::Index]
    }

    static [void] Add([SemBatch] $Batch) {
        $current = [SemBatch]::Current()
        $current.Items += @($Batch.Items | where { $_ })
        $current.Tags += @($Batch.Tags | where { $_ })
        $current.Dates += @($Batch.Dates | where { $_ })
        $current.RemoveTags += @($Batch.RemoveTags | where { $_ })
        $current.RemoveDates += @($Batch.RemoveDates | where { $_ })
    }

    static [void] Next() {
        [SemBatch]::Batches += @([SemBatch]::new())
        [SemBatch]::Index = -1
    }
}

function Run-SemShellCommand {
    [Alias('Sem')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [item[]]
        $InputObject,

        [Parameter(Position = 0)]
        [ValidateSet(
            'pool',
            'tag',
            'date',
            'untag',
            'undate',
            'reset',
            'commit',
            'show',
            'batch',
            'get'
        )]
        [ArgumentCompleter({
            $commands = @(
                'pool',
                'tag',
                'date',
                'untag',
                'undate',
                'reset',
                'commit',
                'show',
                'batch',
                'get'
            )

            $suggest = $commands |
                where { $_ -like "$($args[2])*" }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $commands
            }
            else {
                $suggest
            }
        })]
        [string]
        $Command,

        [Parameter(Position = 1)]
        [ArgumentCompleter({
            Param(
                $CommandName,
                $ParameterName,
                $WordToComplete,
                $CommandAst,
                $PreboundParameters
            )

            $words = switch ($PreboundParameters['Command'].ToLower()) {
                'pool' {
                    "SELECT name FROM item;" |
                        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
                }

                'tag' {
                    "SELECT name FROM tag;" |
                        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
                }

                'untag' {
                    "SELECT name FROM tag;" |
                        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
                }

                'date' {
                    "SELECT DISTINCT datetag FROM item_has_datetag;" |
                        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
                }

                'undate' {
                    "SELECT DISTINCT datetag FROM item_has_datetag;" |
                        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
                }

                'batch' {
                    0 .. [SemBatch]::Batches.Count
                }

                'get' {
                    'item', 'tag', 'date'
                }
            }

            $suggest = $words |
                where { $_ -like "$WordToComplete*" }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $words
            }
            else {
                $suggest
            }
        })]
        [string[]]
        $Argument,

        [Parameter(Position = 2)]
        [ArgumentCompleter({
            Param(
                $CommandName,
                $ParameterName,
                $WordToComplete,
                $CommandAst,
                $PreboundParameters
            )

            $words = switch ($PreboundParameters['Command'].ToLower()) {
                'get' {
                    switch ($PreboundParameters['Argument'].ToLower()) {
                        'item' {
                            'with', 'created', 'arrived', 'expiry'
                            break
                        }
                    }

                    break
                }
            }

            $suggest = $words |
                where { $_ -like "$WordToComplete*" }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $words
            }
            else {
                $suggest
            }
        })]
        [string]
        $Argument2,

        [Parameter(Position = 3)]
        [ArgumentCompleter({
            Param(
                $CommandName,
                $ParameterName,
                $WordToComplete,
                $CommandAst,
                $PreboundParameters
            )

            $words = switch ($PreboundParameters['Argument2'].ToLower()) {
                'with' {
                    'tag', 'name', 'descript', 'content', 'date'
                    break
                }

                'created' {
                    'eq', 'ne', 'after', 'before', 'between'
                    break
                }

                'arrived' {
                    'eq', 'ne', 'after', 'before', 'between'
                    break
                }

                'expiry' {
                    'eq', 'ne', 'after', 'before', 'between'
                    break
                }
            }

            $suggest = $words |
                where { $_ -like "$WordToComplete*" }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $words
            }
            else {
                $suggest
            }
        })]
        [string]
        $Argument3,

        [Parameter(Position = 4)]
        [ArgumentCompleter({
            Param(
                $CommandName,
                $ParameterName,
                $WordToComplete,
                $CommandAst,
                $PreboundParameters
            )

            $words = switch ($PreboundParameters['Argument3'].ToLower()) {
                'tag' {
                    'eq', 'ne'
                    break
                }

                'date' {
                    'eq', 'ne', 'after', 'before', 'between'
                    break
                }

                { $_ -in 'name', 'descript', 'content' } {
                    'eq', 'ne', 'like', 'notlike', 'match', 'notmatch'
                    break
                }

                { $_ -in 'eq', 'ne', 'after', 'before', 'between' } {
                    $col = $PreboundParameters['Argument2'].ToLower()

                    if ($col -notin 'created', 'arrived', 'expiry') {
                        break
                    }

                    "SELECT DISTINCT $col FROM item;" |
                        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                    break
                }
            }

            $suggest = $words |
                where { $_ -like "$WordToComplete*" }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $words
            }
            else {
                $suggest
            }
        })]
        [string[]]
        $Argument4,

        [Parameter(Position = 5)]
        [ArgumentCompleter({
            Param(
                $CommandName,
                $ParameterName,
                $WordToComplete,
                $CommandAst,
                $PreboundParameters
            )

            $words = switch ($PreboundParameters['Argument3'].ToLower()) {
                'tag' {
                    "SELECT name FROM tag ORDER BY name;" |
                        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                    break
                }

                'date' {
                    "SELECT DISTINCT datetag FROM item_has_tagtag ORDER BY datetag;" |
                        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                    break
                }

                'name' {
                    "SELECT name FROM item ORDER BY name;" |
                        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                    break
                }
            }

            $suggest = $words |
                where { $_ -like "$WordToComplete*" }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $words
            }
            else {
                $suggest
            }
        })]
        [string[]]
        $Argument5
    )

    Begin {
        function Write-Color {
            Param(
                $InputObject,

                [ValidateSet('Yellow', 'Green', 'Blue', 'Red', 'Violet', '')]
                [string]
                $Color
            )

            if (-not $Color) {
                $InputObject
            }

            "$([char]27)[38;2;$(switch ($Color) {
                'Yellow' {
                    '175;175;50'
                }

                'Green' {
                    '50;175;50'
                }

                'Blue' {
                    '50;50;175'
                }

                'Red' {
                    '175;50;50'
                }

                'Violet' {
                    '175;50;175'
                }
            })m$InputObject$([char]27)[0m"
        }

        function Find-SavedList {
            Param(
                [array]
                $InputObject,

                [scriptblock]
                $Test
            )

            if (@($InputObject | where { $_ }).Count -eq 0) {
                return
            }

            $savedItems = & $Test $InputObject

            $result = [pscustomobject]@{
                Saved = @()
                Unsaved = @()
            }

            $color = ''

            foreach ($item in $InputObject) {
                if ($item -in $savedItems) {
                    $result.Saved += @($item)
                }
                else {
                    $result.Unsaved += @($item)
                }
            }

            return $result
        }

        function Show-List {
            Param(
                [array]
                $InputObject,

                [char]
                $Indicator,

                [string]
                $Color
            )

            foreach ($item in $InputObject) {
                "  $Indicator $(Write-Color "[$item]" -Color $Color)"
            }
        }

        function Test-HasAny {
            Param(
                [array]
                $Batch,

                [string]
                $Property
            )

            $Batch |
                foreach { $_ } |
                where { $_ } |
                foreach { return $true }

            return $false
        }

        function Get-ListSubtract {
            Param(
                [array]
                $List1,

                [array]
                $List2
            )

            [pscustomobject]@{
                NewList1 = $List1 | where { $_ -notin $List2 }
                NewList2 = $List2 | where { $_ -notin $List1 }
            }
        }

        function Show-Batch {
            Param(
                [SemBatch]
                $NextBatch
            )

            $batch = [SemBatch]::Current()

            "Pool"

            $nextItems = Find-SavedList `
                -InputObject `
                    ($NextBatch.Items | where { $_ -notin $batch.Items }) `
                -Test { Param($in) $in | Test-SemItem }

            $items = Find-SavedList `
                -InputObject $batch.Items `
                -Indicator '-' `
                -Test { Param($in) $in | Test-SemItem }

            Show-List `
                -InputObject $nextItems.Saved `
                -Indicator '+' `
                -Color 'Violet'

            Show-List `
                -InputObject $nextItems.Unsaved `
                -Indicator '+' `
                -Color 'Green'

            Show-List `
                -InputObject $items.Saved `
                -Indicator '-' `
                -Color 'Violet'

            Show-List `
                -InputObject $items.Unsaved `
                -Indicator '-' `
                -Color 'Green'

            if ((Test-HasAny (
                $batch.Tags,
                $nextBatch.Tags,
                $batch.RemoveTags,
                $nextBatch.RemoveTags
            ))) {
                "`nTag"
            }

            $nextRemoveTags = Find-SavedList `
                -InputObject $nextBatch.RemoveTags `
                -Test { Param($in) $in | Test-SemTag }

            $removeTags = Find-SavedList `
                -InputObject $batch.RemoveTags `
                -Test { Param($in) $in | Test-SemTag }

            $nextTags = Find-SavedList `
                -InputObject `
                    ($NextBatch.Tags |
                    where { $_ -notin $batch.Tags } | `
                    where { $_ -notin $batch.RemoveTags }) `
                -Test { Param($in) $in | Test-SemTag }

            $tags = Find-SavedList `
                -InputObject ($batch.Tags | `
                    where { $_ -notin $batch.RemoveTags }) `
                -Test { Param($in) $in | Test-SemTag }

            <#
            tags not to be displayed:
                all unsaved tags that match a next unsaved tag removal
            tag removals not to be displayed:
                all next unsaved tag removals that match an unsaved tag
            #>

            if ($null -ne $nextTags -and $null -ne $nextRemoveTags) {
                $subtract = Get-ListSubtract `
                    -List1 $nextTags.Unsaved `
                    -List2 $nextRemoveTags.Unsaved

                $nextTags.Unsaved = $subtract.NewList1
                $nextRemoveTags.Unsaved = $subtract.NewList2

                $subtract = Get-ListSubtract `
                    -List1 $nextTags.Saved `
                    -List2 $nextRemoveTags.Saved

                $nextTags.Saved = $subtract.NewList1
            }

            if ($null -ne $tags -and $null -ne $nextRemoveTags) {
                $subtract = Get-ListSubtract `
                    -List1 $tags.Unsaved `
                    -List2 $nextRemoveTags.Unsaved

                $tags.Unsaved = $subtract.NewList1

                $nextRemoveTags.Unsaved = $nextRemoveTags.Unsaved |
                    where { $_ -in $subtract.NewList2 }

                $subtract = Get-ListSubtract `
                    -List1 $tags.Saved `
                    -List2 $nextRemoveTags.Saved

                $tags.Saved = $subtract.NewList1
            }

            Show-List `
                -InputObject $nextTags.Saved `
                -Indicator '+' `
                -Color 'Violet'

            Show-List `
                -InputObject $nextTags.Unsaved `
                -Indicator '+' `
                -Color 'Green'

            Show-List `
                -InputObject $tags.Saved `
                -Indicator '-' `
                -Color 'Violet'

            Show-List `
                -InputObject $tags.Unsaved `
                -Indicator '-' `
                -Color 'Green'

            Show-List `
                -InputObject $nextRemoveTags.Saved `
                -Indicator '+' `
                -Color 'Red'

            Show-List `
                -InputObject $nextRemoveTags.Unsaved `
                -Indicator '+' `
                -Color 'Red'

            Show-List `
                -InputObject $removeTags.Saved `
                -Indicator '~' `
                -Color 'Red'

            Show-List `
                -InputObject $removeTags.Unsaved `
                -Indicator '~' `
                -Color 'Red'

            if ((Test-HasAny (
                $batch.Dates,
                $nextBatch.Dates,
                $batch.RemoveDates,
                $nextBatch.RemoveDates
            ))) {
                "`nDate"
            }

            $nextDates = Find-SavedList `
                -InputObject ( `
                    $NextBatch.Dates |
                    where {
                        $_ -notin $batch.Dates -and $_ -notin $batch.RemoveDates
                    } `
                ) `
                -Test { Param($in) $in | Test-SemDateTag }

            $dates = Find-SavedList `
                -InputObject ($batch.Dates | `
                    where { $_ -notin $batch.RemoveDates }) `
                -Test { Param($in) $in | Test-SemDateTag }

            $nextRemoveDates = Find-SavedList `
                -InputObject ( `
                    $NextBatch.RemoveDates |
                    where {
                        $_ -notin $batch.RemoveDates
                    } `
                ) `
                -Test { Param($in) $in | Test-SemDateTag }

            $removeDates = Find-SavedList `
                -InputObject $batch.RemoveDates `
                -Test { Param($in) $in | Test-SemDateTag }

            if ($null -ne $nextDates -and $null -ne $nextRemoveDates) {
                $subtract = Get-ListSubtract `
                    -List1 $nextDates.Unsaved `
                    -List2 $nextRemoveDates.Unsaved

                $nextDates.Unsaved = $subtract.NewList1
                $nextRemoveDates.Unsaved = $subtract.NewList2

                $subtract = Get-ListSubtract `
                    -List1 $nextDates.Saved `
                    -List2 $nextRemoveDates.Saved

                $nextDates.Saved = $subtract.NewList1
            }

            if ($null -ne $dates -and $null -ne $nextRemoveDates) {
                $subtract = Get-ListSubtract `
                    -List1 $dates.Unsaved `
                    -List2 $nextRemoveDates.Unsaved

                $dates.Unsaved = $subtract.NewList1

                $nextRemoveDates.Unsaved = $nextRemoveDates.Unsaved |
                    where { $_ -in $subtract.NewList2 }

                $subtract = Get-ListSubtract `
                    -List1 $dates.Saved `
                    -List2 $nextRemoveDates.Saved

                $dates.Saved = $subtract.NewList1
            }

            Show-List `
                -InputObject $nextDates.Saved `
                -Indicator '+' `
                -Color 'Violet'

            Show-List `
                -InputObject $nextDates.Unsaved `
                -Indicator '+' `
                -Color 'Green'

            Show-List `
                -InputObject $dates.Saved `
                -Indicator '-' `
                -Color 'Violet'

            Show-List `
                -InputObject $dates.Unsaved `
                -Indicator '-' `
                -Color 'Green'

            Show-List `
                -InputObject $nextRemoveDates.Saved `
                -Indicator '+' `
                -Color 'Red'

            Show-List `
                -InputObject $nextRemoveDates.Unsaved `
                -Indicator '+' `
                -Color 'Red'

            Show-List `
                -InputObject $removeDates.Saved `
                -Indicator '~' `
                -Color 'Red'

            Show-List `
                -InputObject $removeDates.Unsaved `
                -Indicator '~' `
                -Color 'Red'

            $NextBatch.Items = @($nextItems.Saved) + @($nextItems.Unsaved)
            $NextBatch.Tags = @($nextTags.Saved) + @($nextTags.Unsaved)
            $NextBatch.Dates = @($nextDates.Saved) + @($nextDates.Unsaved)
            $NextBatch.RemoveTags = @($nextRemoveTags.Saved) + @($nextRemoveTags.Unsaved)
            $NextBatch.RemoveDates = @($nextRemoveDates.Saved) + @($nextRemoveDates.Unsaved)
            [SemBatch]::Add($NextBatch)
        }

        function Get-WhereClause {
            Param(
                [Parameter(Position = 0)]
                $Argument4,

                [Parameter(Position = 1)]
                $Argument5,

                [string]
                $ColumnName
            )

            $op = '='

            $filter = if ($Argument5 -is [array]) {
                "'$($Argument5[0])'"
            }
            else {
                "'$($Argument5)'"
            }

            switch ($Argument4) {
                'eq' {
                    $op = 'IN'
                    $filter = $(($Argument5 | foreach { "'$_'" }) -join ', ')
                    break
                }

                'ne' {
                    $op = 'NOT IN'
                    $filter = $(($Argument5 | foreach { "'$_'" }) -join ', ')
                    break
                }

                'like' {
                    $op = 'LIKE'
                    break
                }

                'notlike' {
                    $op = 'NOT LIKE'
                    break
                }

                'match' {
                    $op = 'REGEXP'
                    break
                }

                'notmatch' {
                    $op = 'NOT REGEXP'
                    break
                }

                'after' {
                    $op = '>'
                    break
                }

                'before' {
                    $op = '<'
                    break
                }

                'between' {
                    $filter = switch (@($Argument5 | where { $_ }).Count) {
                        0 {
                            '0 AND 0'
                            break
                        }

                        1 {
                            "'$Argument5' AND '$Argument5'"
                            break
                        }

                        default {
                            "'$($Argument5[0])' AND '$($Argument5[1])'"
                            break
                        }
                    }

                    return "$ColumnName BETWEEN $filter"
                }
            }

            return "$ColumnName $op ($filter)"
        }

        if ([SemBatch]::Batches.Count -eq 0) {
            [SemBatch]::Batches += @([SemBatch]::new())
        }

        $batch = [SemBatch]::Batches[[SemBatch]::Index]
        $nextBatch = [SemBatch]::new()
        $itemsList = @()
    }

    Process {
        $itemsList += @($InputObject |
            where { $null -ne ($_ | Test-SemItem) })
    }

    End {
        switch ($Command.ToLower()) {
            'pool' {
                $nextBatch.Items += $itemsList |
                    foreach { $_.Name }

                if (-not $itemsList -and ($null -eq $Argument -or '.' -eq $Argument)) {
                    $Argument = Get-ChildItem (Get-Location) -File
                }

                $nextBatch.Items += $Argument |
                    where { $_ } |
                    foreach { Split-Path $_ -Leaf } |
                    where { $_ -notin $batch.Items }
            }

            'tag' {
                $nextBatch.Tags += $Argument.ToLower() |
                    where { $_ -notin $batch.Tags }
            }

            'date' {
                $nextBatch.Dates += $Argument |
                    where { $_ -notin $batch.Dates }
            }

            'untag' {
                $nextBatch.RemoveTags += $Argument |
                    where { $_ -notin $batch.RemoveTags }
            }

            'undate' {
                $nextBatch.RemoveDates += $Argument |
                    where { $_ -notin $batch.RemoveDates }
            }

            'reset' {
                [SemBatch]::Next()
            }

            'commit' {
                $batch.Items | New-SemItem
                $items = Get-SemItem -Name $batch.Items
                $items | Add-SemTag -Tag $batch.Tags
                $items | Add-SemDateTag -DateTag $batch.Dates
                $items | Remove-SemTag -Tag $batch.RemoveTags
                $items | Remove-SemDateTag -DateTag $batch.RemoveDates

                [pscustomobject]@{
                    Transaction = 'Complete'
                    Id = $null
                    Description = $null
                }

                [SemBatch]::Next()
            }

            'batch' {
                if ($Argument -isnot [int] -or
                    $Argument -lt 0 -or
                    $Argument -ge ([SemBatch]::Batches.Count)
                ) {
                    Write-Verbose 'Invalid batch index'
                    return
                }

                [SemBatch]::Index -= $Argument
            }

            'get' {
                foreach ($subarg in ($Argument | select -Unique -CaseInsensitive)) {
                    switch ($subarg) {
                        'item' {
                            $all = $false

                            # todo: abstract
                            $from = @"
SELECT DISTINCT
item.id, item.name, item.description, item.arrival, item.expiry, item.created FROM item
"@

                            $where = if ($itemsList) {
                                "WHERE id IN ($($itemsList.Id -join ', ')) AND"
                            }
                            else {
                                "WHERE"
                            }

                            switch ($Argument2.ToLower()) {
                                'with' {
                                    switch ($Argument3.ToLower()) {
                                        'tag' {
                                            $op = switch ($Argument4.ToLower()) {
                                                'eq' {
                                                    'IS NOT NULL'
                                                    break
                                                }

                                                'ne' {
                                                    'IS NULL'
                                                    break
                                                }
                                            }

                                            $from = @"
$from
LEFT JOIN item_has_tag ON item.id = itemid
LEFT JOIN tag
    ON tag.id = tagid
    AND tag.name IN ($(($Argument5 | foreach { "'$_'" }) -join ', '))
"@

                                            $where = "`nWHERE tag.id $op"
                                            break
                                        }

                                        'date' {
                                            $from = "$from LEFT JOIN item_has_datetag ON id = itemid"

                                            $clause = Get-WhereClause `
                                                -Argument4 $Argument4 `
                                                -Argument5 $Argument5 `
                                                -ColumnName 'datetag'

                                            $where = "$where $clause"
                                            break
                                        }

                                        'descript' {
                                            $clause = Get-WhereClause `
                                                -Argument4 $Argument4 `
                                                -Argument5 $Argument5 `
                                                -ColumnName 'description'

                                            $where = "$where $clause"
                                            break
                                        }

                                        default {
                                            $clause = Get-WhereClause `
                                                -Argument4 $Argument4 `
                                                -Argument5 $Argument5 `
                                                -ColumnName $Argument3

                                            $where = "$where $clause"
                                            break
                                        }
                                    }

                                    break
                                }

                                'created' {
                                    $clause = Get-WhereClause `
                                        -Argument4 $Argument3 `
                                        -Argument5 $Argument4 `
                                        -ColumnName $Argument2

                                    $where = "$where $clause"
                                    break
                                }

                                'arrived' {
                                    $clause = Get-WhereClause `
                                        -Argument4 $Argument3 `
                                        -Argument5 $Argument4 `
                                        -ColumnName 'arrival'

                                    $where = "$where $clause"
                                    break
                                }

                                'expiry' {
                                    $clause = Get-WhereClause `
                                        -Argument4 $Argument3 `
                                        -Argument5 $Argument4 `
                                        -ColumnName $Argument2

                                    $where = "$where $clause"
                                    break
                                }

                                default {
                                    $all = $true

                                    if ($itemsList) {
                                        $itemsList
                                    }
                                    else {
                                        Get-SemItem
                                    }

                                    break
                                }
                            }

                            if (-not $all) {
                                $rows = "$from $where;" |
                                    sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                                $rows | foreach {
                                    [Item]::Marshall($_)
                                }
                            }

                            break
                        }

                        'tag' {
                            $result = "SELECT * FROM tag ORDER BY name;" |
                                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                            foreach ($row in $result) {
                                $cols = $row.Split('|')

                                [pscustomobject]@{
                                    Created = $cols[2]
                                    Name = $cols[1]
                                }
                            }

                            break
                        }

                        'date' {
                            $query = "@
SELECT DISTINCT datetag
FROM item_has_datetag ORDER BY datetag;
@"

                            $result = $query |
                                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                            foreach ($row in $result) {
                                [pscustomobject]@{
                                    Date = $row
                                }
                            }

                            break
                        }
                    }
                }
            }
        }

        if ($command.ToLower() -notin ('commit', 'get')) {
            Show-Batch -NextBatch $nextBatch
        }
    }
}







