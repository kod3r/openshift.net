Set-StrictMode -Version 3

$currentDir = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent

. (Join-Path $currentDir "template-mechanism.ps1")
. (Join-Path $currentDir "cygwin-passwd.ps1")
. (Join-Path $currentDir "file-ownership.ps1")
. (Join-Path $currentDir "library-importer.ps1")

function Get-NotEmpty($a, $b) 
{ 
    if ([string]::IsNullOrWhiteSpace($a)) 
    { 
        $b 
    } else 
    { 
        $a 
    }
}

function Get-IniContent ($filePath)
{
    $ini = @{}
    switch -regex -file $FilePath
    {
        "^\[(.+)\]" # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^(;.*)$" # Comment
        {
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        } 
        "(.+?)\s*=(.*)" # Key
        {
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

function Get-RandomPassword() 
{
    $length=10
    $alphabet=$NULL
    For ($a=65; $a -le 90; $a++) 
    {
        $alphabet+=,[char][byte]$a 
    }
    
    For ($loop=1; $loop -le $length; $loop++) 
    {
        $TempPassword+=($alphabet | GET-RANDOM)
    }

    return $TempPassword
}

function Write-Callstack([System.Management.Automation.ErrorRecord]$ErrorRecord=$null, [int]$Skip=1)
{
    Write-Host # blank line
    if ($ErrorRecord)
    {
        Write-Host -ForegroundColor Red "$ErrorRecord $($ErrorRecord.InvocationInfo.PositionMessage)"

        if ($ErrorRecord.Exception)
        {
            Write-Host $ErrorRecord.Exception.ToString()
        }

        if ((Get-Member -InputObject $ErrorRecord -Name ScriptStackTrace) -ne $null)
        {
            #PS 3.0 has a stack trace on the ErrorRecord; if we have it, use it & skip the manual stack trace below
            Write-Host -ForegroundColor Red $ErrorRecord.ScriptStackTrace
            return
        }
    }

    Get-PSCallStack | Select -Skip $Skip | % {
        Write-Host -ForegroundColor Yellow -NoNewLine "! "
        Write-Host -ForegroundColor Red $_.Command $_.Location $(if ($_.Arguments.Length -le 80) { $_.Arguments })
    }
}