class Item {
    hidden [int] $Id
    hidden [string] $Description
    hidden [string] $Arrival
    hidden [string] $Expiry
    hidden [string] $Content
    [string] $Created
    [string] $Name

    static [string[]] $RowNames = (
        'id',
        'name',
        'description',
        'arrival',
        'expiry',
        'created',
        'content'
    )

    static [Item] Marshall(
        [string] $ResultRow
    ) {
        return [Item]::Marshall($ResultRow, [Item]::RowNames)
    }

    static [Item] Marshall(
        [string] $ResultRow,
        [string[]] $RowNames
    ) {
        $item = @{}
        $cols = $ResultRow.Split('|')

        foreach ($i in (0 .. ($RowNames.Count - 1))) {
            $item[$RowNames[$i]] = $cols[$i]
        }

        return [Item]$item
    }
}

$global:semDbName = 'my'

function Get-SemItem {
    [OutputType([item])]
    [CmdletBinding(DefaultParameterSetName = 'AllItems')]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [array]
        $InputObject,

        [Parameter(ParameterSetName = 'ByName')]
        [ArgumentCompleter({
            Param($A, $B, $C)

            $results = "SELECT DISTINCT name FROM item ORDER BY name;" |
                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

            $suggest = $results | where {
                $_ -like "$C*"
            }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $results
            }
            else {
                $suggest
            }
        })]
        [string[]]
        $Name,

        [Parameter(ParameterSetName = 'ByTag')]
        [ArgumentCompleter({
            Param($A, $B, $C)

            $results = "SELECT DISTINCT name FROM tag ORDER BY name;" |
                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

            return $results

            $suggest = $results | where {
                $_ -like "$C*"
            }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $results
            }
            else {
                $suggest
            }
        })]
        [string[]]
        $Tag,

        [Parameter(ParameterSetName = 'ByDateTag')]
        [ArgumentCompleter({
            Param($A, $B, $C)

            $results = "SELECT DISTINCT datetag FROM item_has_datetag ORDER BY datetag;" |
                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

            $suggest = $results | where {
                $_ -like "$C*"
            }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $results
            }
            else {
                $suggest
            }
        })]
        [ValidateScript({
            $_ | where {
                $_ -notmatch "^\d{4}-\d{2}-\d{2}$"
            } | foreach {
                return $false
            }

            return $true
        })]
        [string[]]
        $DateTag
    )

    Begin {
        $setting = Get-Item "$PsScriptRoot/../res/setting.json" |
            Get-Content |
            ConvertFrom-Json

        $itemIdList = @()
        $index = 0
    }

    Process {
        foreach ($item in @($InputObject | where { $_ })) {
            $itemIdList += @(
                switch ($item) {
                    { $_ -is [int] } {
                        $_
                    }

                    { $_ -is [item] } {
                        $itemId = $item | Test-SemItem

                        if ($null -eq $itemId) {
                            "Item '$($item.name)' is not a valid object"
                        }
                        else {
                            $item.id
                        }
                    }

                    default {
                        "Item $index in the list is not a valid object"
                    }
                }
            )

            $index = $index + 1
        }
    }

    End {
        $itemIdListStr = $itemIdList -join ', '

        $query = switch ($PsCmdlet.ParameterSetName) {
            'AllItems' {
@"
SELECT *
FROM
    item
$(if ($itemIdListStr) { "WHERE id IN ($itemIdListStr)" })
LIMIT '$($setting.MaxItems)'
;
"@
            }

            'ByName' {
                $Name = $Name.ToLower() |
                    select -Unique |
                    foreach { "'$_'" }

                $Name = $Name -join ', '

@"
SELECT *
FROM
    item
WHERE
    name IN ($Name)
    $(if ($itemIdListStr) { "AND id IN ($itemIdListStr)" })
;
"@
            }

            'ByTag' {
                $Tag = $Tag.ToLower() |
                    select -Unique |
                    foreach { "'$_'" }

                $Tag = $Tag -join ', '

@"
SELECT *
FROM
    item
    LEFT JOIN
    item_has_tag
    ON id = itemid
WHERE
    tagid = (
        SELECT id
        FROM tag
        WHERE name IN ($Tag)
    )
    $(if ($itemIdListStr) { "AND id IN ($itemIdListStr)" })
;
"@
            }

            'ByDateTag' {
                $DateTag = $DateTag |
                    select -Unique |
                    foreach { "'$_'" }

                $DateTag = $DateTag -join ', '

@"
SELECT *
FROM
    item
    LEFT JOIN
    item_has_datetag
    ON id = itemid
WHERE
    datetag IN ($DateTag)
    $(if ($itemIdListStr) { "AND id IN ($itemIdListStr)" })
;
"@
            }
        }

        $result = $query | sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

        foreach ($item in $result) {
            $row = $item.Split('|')

            [item]@{
                Id = $row[0]
                Name = $row[1]
                Description = $row[2]
                Arrival = $row[3]
                Expiry = $row[4]
                Content = $row[5]
                Created = $row[6]
            }
        }
    }
}

function Test-SemDateTag {
    [OutputType([nullable[int]])]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [ValidateScript({ $_ -match "^(\d{4}-\d{2}-\d{2})?$" })]
        [string]
        $DateTag
    )

    Begin {
        $datetags = @()
    }

    Process {
        $datetags += @($DateTag | where { $_ })
    }

    End {
        $query = @"
SELECT datetag
FROM item_has_datetag
WHERE datetag IN ($(($datetags | foreach { "'$_'" }) -join ', '));
"@

        return $query | sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
    }
}

function Test-SemTag {
    [OutputType([nullable[int]])]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [string]
        $Tag
    )

    Begin {
        $tags = @()
    }

    Process {
        $tags += @($Tag | where { $_ })
    }

    End {
        $query = @"
SELECT name FROM tag WHERE name IN ($(($tags | foreach { "'$_'" }) -join ', '));
"@

        return $query | sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
    }
}

function Test-SemItem {
    [OutputType([nullable[int]])]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    Begin {
        $query = @()
        $type = ""
    }

    Process {
        if ($null -eq $InputObject) {
            return $null
        }

        if (-not $type) {
            $type = $(
                if (@($InputObject | where { $_ }).Count -eq 1) {
                    $InputObject
                }
                else {
                    $InputObject[0]
                }
            ).GetType().Name.ToLower()
        }

        $query += @(switch ($type) {
            'string' {
                @($InputObject | where { $_ })
            }

            'item' {
                foreach ($item in @($InputObject | where { $_ })) {
                    @(
@"
SELECT id FROM item
WHERE
    id = '$($InputObject.id)'
    AND
    name = '$($InputObject.name)'
    AND
    created = '$($InputObject.created)';
"@
                    )
                }
            }
        })
    }

    End {
        $query = switch ($type) {
            'string' {
@"
SELECT name FROM item
WHERE name IN ($(($query | foreach { "'$_'" }) -join ', '));
"@
            }

            'item' {
                $query -join ''
            }
        }

        return $query | sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
    }
}

function Start-SemDb {
    Param(
        [switch]
        $Force
    )

    $dbPath = "$PsScriptRoot/../res/$($global:semDbName).db"
    $dbExists = Test-Path $dbPath

    if ($dbExists) {
        if ($Force) {
            rm $dbPath -Force
        }
        else {
            return "Database '$($global:semDbName).db' already exists"
        }
    }

    gc "$PsScriptRoot/../sql/new-semantic-system-db.sqlite.sql" |
        sqlite3 $dbPath
}

function Add-SemDateTag {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [item[]]
        $InputObject,

        [ArgumentCompleter({
            Param($A, $B, $C)

            $results = "SELECT DISTINCT datetag FROM item_has_datetag ORDER BY datetag;" |
                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

            $suggest = $results | where {
                $_ -like "$C*"
            }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $results
            }
            else {
                $suggest
            }
        })]
        [ValidateScript({ $_ -match "^\d{4}-\d{2}-\d{2}$" })]
        [string[]]
        $DateTag
    )

    Process {
        foreach ($item in @($InputObject | where { $_ })) {
            $itemId = $item | Test-SemItem

            if ($null -eq $itemId) {
                return "Item '$($item.name)' is not a valid object"
            }

            foreach ($tag in @($DateTag | where { $_ })) {
                $testQuery = @"
SELECT itemid FROM item_has_datetag WHERE itemid = $itemId AND datetag = '$tag';
"@

                $itemHasTag = $testQuery |
                    sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                if ($itemHasTag) {
                    "Item '$($item.name)' already has date tag '$tag'"
                }
                else {
                    $command = @"
INSERT INTO item_has_datetag (itemid, datetag) VALUES ('$itemId', '$tag');
SELECT last_insert_rowid();
"@

                    $id = $command |
                        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                    if ($null -eq $id) {
                        return
                    }

                    [pscustomobject]@{
                        Transaction = 'Date Item'
                        Id = $id
                        Description = $tag, $item.name
                    }
                }
            }
        }
    }
}

function Add-SemTag {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [item[]]
        $InputObject,

        [ArgumentCompleter({
            Param($A, $B, $C)

            $results = "SELECT DISTINCT name FROM tag ORDER BY name;" |
                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

            $suggest = $results | where {
                $_ -like "$C*"
            }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $results
            }
            else {
                $suggest
            }
        })]
        [string[]]
        $Tag
    )

    Begin {
        $tags = $Tag |
        foreach {
            $_.ToLower() |
            select -Unique |
            foreach {
                $id = "SELECT id FROM tag WHERE name = '$_';" |
                    sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                if ($null -eq $id) {
                    $command = @"
INSERT INTO tag (name, created) VALUES ('$_', date('now'));
SELECT last_insert_rowid();
"@

                    $id = $command | sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
                }

                [pscustomobject]@{
                    id = [int]$id
                    name = $_
                }
            }
        }
    }

    Process {
        $itemId = $InputObject | Test-SemItem

        if ($null -eq $itemId) {
            return "Item '$($InputObject.name)' is not a valid object"
        }

        foreach ($tagObject in $tags) {
            $testQuery = @"
SELECT itemid FROM item_has_tag WHERE itemid = $itemId AND tagid = $($tagObject.id);
"@

            $itemHasTag = $testQuery |
                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

            if ($itemHasTag) {
                "Item '$($InputObject.name)' already has tag '$($tagObject.name)'"
            }
            else {
                $command = @"
INSERT INTO item_has_tag (itemid, tagid) VALUES ('$itemId', '$($tagObject.id)');
SELECT last_insert_rowid();
"@

                $id = $command |
                    sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                if ($null -eq $id) {
                    return
                }

                [pscustomobject]@{
                    Transaction = 'Tag Item'
                    Id = $id
                    Description = $tag, $InputObject.name
                }
            }
        }
    }
}

function New-SemItem {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]
        $Name,

        [string]
        $Description
    )

    Begin {
        $rows = @()
    }

    Process {
        $rows += $Name |
            where {
                $result = "SELECT id FROM item WHERE name = '$_';" |
                    sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                $null -eq $result
            } |
            foreach {
                "('$_', '$Description', date('now'))"
            }
    }

    End {
        if (-not $rows) {
            return [pscustomobject]@{
                Transaction = 'New Item'
                Id = 0
                Description = "Rows added"
            }
        }

        $rows = $rows -join ', '

        $command = @"
INSERT INTO item (name, description, created) VALUES $rows;
SELECT changes();
"@

        $result = $command |
            sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

        if ($null -eq $result) {
            return
        }

        [pscustomobject]@{
            Transaction = 'New Item'
            Id = $result
            Description = "Rows added"
        }
    }
}

function Get-SemStaleTag {
    $result = "SELECT id, name, created FROM tag WHERE id NOT IN (SELECT tagid FROM item_has_tag);" |
        sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

    $row = $result.Split('|')

    [pscustomobject]@{
        Id = $row[0]
        Name = $row[1]
        Created = $row[2]
    }
}

function Get-SemTag {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [array]
        $InputObject
    )

    Begin {
        $setting = Get-Item "$PsScriptRoot/../res/setting.json" |
            Get-Content |
            ConvertFrom-Json

        $itemIdList = @()
        $index = 0
    }

    Process {
        foreach ($item in @($InputObject | where { $_ })) {
            $itemIdList += @(
                switch ($item) {
                    { $_ -is [int] } {
                        $_
                    }

                    { $_ -is [item] } {
                        $itemId = $item | Test-SemItem

                        if ($null -eq $itemId) {
                            "Item '$($item.name)' is not a valid object"
                        }
                        else {
                            $item.id
                        }
                    }

                    default {
                        # # todo: remove
                        # "Item $index in the list is not a valid object"
                    }
                }
            )

            $index = $index + 1
        }
    }

    End {
        $itemIdListStr = $itemIdList -join ', '

        $query = @"
SELECT
    DISTINCT id, name, created
FROM
    tag
    LEFT JOIN
    item_has_tag
    ON id = tagid
WHERE
    itemid in (
        SELECT id
        FROM item
        WHERE id IN ($itemIdListStr)
    )
;
"@

        $query |
            sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db" |
            foreach {
                $row = $_.Split('|')

                [item]@{
                    Id = $row[0]
                    Name = $row[1]
                    Created = $row[2]
                }
            }
    }
}

function Get-SemDateTag {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [array]
        $InputObject
    )

    Begin {
        $setting = Get-Item "$PsScriptRoot/../res/setting.json" |
            Get-Content |
            ConvertFrom-Json

        $itemIdList = @()
        $index = 0
    }

    Process {
        foreach ($item in @($InputObject | where { $_ })) {
            $itemIdList += @(
                switch ($item) {
                    { $_ -is [int] } {
                        $_
                    }

                    { $_ -is [item] } {
                        $itemId = $item | Test-SemItem

                        if ($null -eq $itemId) {
                            "Item '$($item.name)' is not a valid object"
                        }
                        else {
                            $item.id
                        }
                    }

                    default {
                        "Item $index in the list is not a valid object"
                    }
                }
            )

            $index = $index + 1
        }
    }

    End {
        $itemIdListStr = $itemIdList -join ', '

        $query = @"
SELECT
    DISTINCT datetag
FROM
    item_has_datetag
WHERE
    itemid in ($itemIdListStr)
;
"@

        $query |
            sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
    }
}

function Remove-SemTag {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [item[]]
        $InputObject,

        [ArgumentCompleter({
            Param(
                $CommandName,
                $ParameterName,
                $WordToComplete,
                $CommandAst,
                $PreboundParameters
            )

            $pipelineElements = $CommandAst.Parent.PipelineElements
            $items = @()

            if ($pipelineElements) {
                $items = $pipelineElements.
                    Extent.
                    Text[0 .. (($pipelineElements).Count - 2)] -join ' | ' |
                    Invoke-Expression |
                    where { $null -ne ($_ | Test-SemItem) }
            }

            $query = if (@($items | where { $_ }).Count -gt 0) {
@"
SELECT
    name
FROM
    tag
LEFT JOIN
    item_has_tag
ON
    id = tagid
WHERE
    itemid IN ($($items.id -join ', '))
;
"@
            }
            else {
@"
SELECT name FROM tag;
"@
            }

            $tags = $query |
                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

            $suggest = $tags | where {
                $_ -like "$C*"
            }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $tags
            }
            else {
                $suggest
            }
        })]
        [string[]]
        $Tag
    )

    Begin {
        $tags = $Tag |
            foreach { $_.ToLower() } |
            select -Unique |
            foreach {
                $id = "SELECT id FROM tag WHERE name = '$_';" |
                    sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

                if ($null -eq $id) {
                    Write-Verbose "Tag '$_' not found"
                }
                else {
                    [pscustomobject]@{
                        id = [int]$id
                        name = $_
                    }
                }
            }
    }

    Process {
        $itemId = $InputObject | Test-SemItem

        if ($null -eq $itemId) {
            return "Item '$($InputObject.name)' is not a valid object"
        }

        foreach ($tagObject in $tags) {
            $command = @"
DELETE FROM item_has_tag WHERE itemid = $itemId AND tagid = $($tagObject.id);
SELECT changes();
"@

            $command |
                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
        }
    }
}

function Remove-SemDateTag {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [item[]]
        $InputObject,

        [ArgumentCompleter({
            Param(
                $CommandName,
                $ParameterName,
                $WordToComplete,
                $CommandAst,
                $PreboundParameters
            )

            $pipelineElements = $CommandAst.Parent.PipelineElements
            $items = @()

            if ($pipelineElements) {
                $items = $pipelineElements.
                    Extent.
                    Text[0 .. (($pipelineElements).Count - 2)] -join ' | ' |
                    Invoke-Expression |
                    where { $null -ne ($_ | Test-SemItem) }
            }

            $query = if (@($items | where { $_ }).Count -gt 0) {
@"
SELECT
    datetag
FROM
    item_has_datetag
WHERE
    itemid IN ($($items.id -join ', '))
;
"@
            }
            else {
@"
SELECT datetag FROM item_has_datetag;
"@
            }

            $tags = $query |
                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"

            $suggest = $tags | where {
                $_ -like "$C*"
            }

            if (@($suggest | where { $_ }).Count -eq 0) {
                $tags
            }
            else {
                $suggest
            }
        })]
        [string[]]
        $DateTag
    )

    Process {
        $itemId = $InputObject | Test-SemItem

        if ($null -eq $itemId) {
            return "Item '$($InputObject.name)' is not a valid object"
        }

        foreach ($subtag in @($DateTag | where { $_ })) {
            $command = @"
DELETE FROM item_has_datetag WHERE itemid = $itemid AND datetag = '$subtag';"
SELECT changes();
"@

            $command |
                sqlite3 "$PsScriptRoot/../res/$($global:semDbName).db"
        }
    }
}


