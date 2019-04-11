#https://www.youtube.com/watch?v=Wim9WJeDTHQ :: multiplicative persistence.
Function Get-BigIntMultiple {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [int[]]$Digit
    )
    Begin {
        [System.Numerics.BigInteger]$runningTotal = 1
    }
    Process {
        foreach($d in $Digit) {
            $runningTotal *= $d
        }
    }
    End {
        $runningTotal
    }
}

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
        Get-MultiplicativePersistenceSteps -InputObject ([string]($InputObject.ToCharArray() | ForEach-Object {[int]::Parse($_)} | Get-BigIntMultiple)) -Step ($Step + 1)
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
        [int]$GEDigit = 1 #the next digit appended must be greater than or equal to this; to avoid generating anagrams
    )
    if ($Length -le 0) {
        $ValuePart
        if ($ValuePart -like '*999999999') {Write-Information "- Progress Update: Just Processed $ValuePart"} #just whacked this in so we know something's happenning
    } else {
        $GEDigit..9 | ForEach-Object {Invoke-TestMPGenerator -Length ($Length - 1) -ValuePart ($ValuePart + "$_") -GEDigit ([Math]::Max($_,5))}
    }
}

Function Invoke-MPHunter {
    [CmdletBinding()]
    Param (
        [Parameter()]
        [int]$MinLength = 1
        ,
        [Parameter()]
        [int]$MaxLength = 20
    )
    [int]$maxSteps = 0
    $MinLength..$MaxLength | ForEach-Object {
        Invoke-TestMPGenerator -Length $_ | ForEach-Object {
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

#note from the video you'd want to run start at minlength 233 (or 234) to start looking for new values; e.g.  Invoke-MPHunter -InformationAction Continue -MinLength 233 -MaxLength 1000 | Format-Table -AutoSize
