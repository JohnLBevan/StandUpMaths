#https://www.youtube.com/watch?v=Wim9WJeDTHQ :: multiplicative persistence.

Function Get-MultiplicativePersistenceSteps {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$InputObject
        , 
        [Parameter()]
        [int]$Step = 0
    )
    Write-Verbose ('Step {0:000}: Input {1}' -f $Step, $InputObject)
    if ($InputObject.Length -le 1) {
        $Step
    } else {
        [UInt64]$total = 1
        $InputObject.ToCharArray() | ForEach-Object {$total *= [UInt64]::Parse($_)}
        Get-MultiplicativePersistenceSteps -InputObject ([string]$total) -Step ($Step + 1)
    }
}

Function Invoke-TestMPGenerator { #note: output is not sorted; we can choose to sort elsewhere; but avoiding here as for larger numbers, sorting would cause blocking
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [int]$Length
        ,
        [Parameter()]
        [string]$ValuePart = ''
        ,
        [Parameter()]
        [int]$LEDigit = 9 #the next digit appended must be less than or equal to this; to avoid generating anagrams
    )
    if ($Length -le 1) { #using le to avoid having to add error check code for length 0/negative, whilst avoiding infinite runs
        1..9 | Where-Object {$_ -le $LEDigit} | ForEach-Object {"$_" + $ValuePart}
    } else {
        5..9 | Where-Object {$_ -le $LEDigit} | ForEach-Object {Invoke-TestMPGenerator -Length ($Length - 1) -ValuePart ("$_" + $ValuePart) -LEDigit $_}
    }
}

Function Invoke-MPHunter {
    [CmdletBinding()]
    Param (
        [Parameter()]
        $MinLength = 1
        ,
        [Parameter()]
        $MaxLength = 20
    )
    [int]$maxSteps = 0
    $MinLength..$MaxLength | ForEach-Object {
        Invoke-TestMPGenerator -Length $_ | Sort-Object | ForEach-Object{
            $steps = Get-MultiplicativePersistenceSteps -InputObject $_
            if ($steps -gt $maxSteps) {
                $maxSteps = $steps
                Write-Information ('New Max Found {0:000}: {1}' -f $maxSteps, $_)
                [pscustomobject]@{
                    Steps = $maxSteps
                    Sequence = $_
                }
            }
        }
    }
}

Invoke-MPHunter -InformationAction Continue | Format-Table -AutoSize


