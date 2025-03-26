function New-Closure {
    Param(
        [ScriptBlock]
        $ScriptBlock,

        $Parameters
    )

    return & {
        Param($Parameters)
        return $ScriptBlock.GetNewClosure()
    } $Parameters
}

class DbRequest {
    [string] $DbName
    [string] $Local = "$PsScriptRoot/../res"
    [scriptblock] $Command =
{
Param(
    [string] $CommandStr
)

$CommandStr
}

    static [DbRequest] GetDefault() {
        $setting = Get-Item "$PsScriptRoot/../res/setting.json" |
            Get-Content |
            ConvertFrom-Json

        $myManager = $setting.Manager
        $myLocal = "$PsScriptRoot/../res"
        $myDbName = $setting.DbName
        return [DbRequest]::new($myManager, $myLocal, $myDbName)
    }

    static [void] BuildDefault() {
        if ($null -eq [DbRequest]::Recent) {
            [DbRequest]::Recent = [DbRequest]::GetDefault()
        }
    }

    static [string] DbPath($Local, $DbName) {
        return Join-Path $Local "$($DbName).db"
    }

    static [string] RecentDbPath() {
        return [DbRequest]::Recent.DbPath()
    }

    [string] DbPath() {
        return [DbRequest]::DbPath($this.Local, $this.DbName)
    }

    static [string] $RecentDbName
    static [string] $RecentManager
    static [DbRequest] $Recent = $null

    static [Hashtable] $Managers = @{
        'sqlite' = [scriptblock]{
Param(
    [string] $CommandStr
)

$path = Join-Path $Parameters.Local "$($Parameters.DbName).db"
return $CommandStr | sqlite3 $path
}
    }

    DbRequest([string] $Manager, [string] $Local, [string] $DbName) {
        $this.Local = $Local
        $this.DbName = $DbName

        [DbRequest]::RecentDbName = $DbName
        [DbRequest]::RecentManager = $Manager

        $this.Command = New-Closure `
            -ScriptBlock $([DbRequest]::Managers[$Manager]) `
            -Parameters $([pscustomobject]@{
                Local = $this.Local
                DbName = $this.DbName
            })
    }

    DbRequest([string] $Manager, [string] $DbName) {
        $temp = [DbRequest]::new(
            $Manager,
            $this.Local,
            $DbName
        )

        $this.Local = $temp.Local
        $this.DbName = $temp.DbName
        $this.Command = $temp.Command
    }

    DbRequest([string] $Manager) {
        $temp = [DbRequest]::new(
            $Manager,
            $this.Local,
            [DbRequest]::RecentDbName
        )

        $this.Local = $temp.Local
        $this.DbName = $temp.DbName
        $this.Command = $temp.Command
    }

    DbRequest() {
        $temp = [DbRequest]::new(
            [DbRequest]::Manager,
            $this.Local,
            [DbRequest]::RecentDbName
        )

        $this.Local = $temp.Local
        $this.DbName = $temp.DbName
        $this.Command = $temp.Command
    }

    [string[]] Invoke([string] $CommandStr) {
        return $this.Command.Invoke($CommandStr)
    }
}

function Invoke-SemDbRequest {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]
        $InputObject
    )

    Process {
        foreach ($item in $InputObject) {
            [DbRequest]::Recent.Invoke($item)
        }
    }
}

