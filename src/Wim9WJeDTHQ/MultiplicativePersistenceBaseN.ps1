#https://www.youtube.com/watch?v=Wim9WJeDTHQ :: multiplicative persistence.

Function Convert-SymbolToDec {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [char]$Symbol
        ,
        [Parameter()]
        [string]$Symbols = '0123456789'
    )
    Process {
        [int]$result = $Symbols.IndexOf($Symbol) #returns -1 if Symbol is not in Symbols; 0 if it's the first char, 1 for the second, etc
        if ($result -lt 0) {
            throw [System.IndexOutOfRangeException]::new("The value $Symbol does not exist in $Symbols")
        }
        $result
    }
}

Function Convert-DecToSymbol {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [int]$DecimalNum
        ,
        [Parameter()]
        [string]$Symbols = '0123456789'
    )
    Process {
        $Symbols.Substring($DecimalNum, 1) #will throw an exception if $DecimalNum is out of bounds
    }
}

Function ConvertTo-BaseN {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline=$true, HelpMessage="Integer number to convert")]
        [System.Numerics.BigInteger]$DecimalNum
        ,
        [Parameter()]
        [string]$Symbols = '0123456789'
    )
    Process {
        [int]$base = $Symbols.Length
        [string]$baseNNum = ''
        Do {
            $remainder = ($DecimalNum % $base)
            $char = $remainder | Convert-DecToSymbol -Symbols $Symbols
            $baseNNum = [string]::Concat($char, $baseNNum)
            $DecimalNum = ($DecimalNum - $remainder) / $base
        } while ($DecimalNum -gt 0) #put the while on the end, since if we get 0 we want to output 0, not blank
        $baseNNum
    }
}

Function Get-BigIntMultiple {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [int[]]$digits
    )
    Begin {
        [System.Numerics.BigInteger]$runningTotal = 1
    }
    Process {
        foreach($d in $Digits) {
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
        ,
        [Parameter()]
        [string]$Symbols = '0123456789'
    )
    Process {
        Write-Verbose ('Step {0:000}: Input {1}' -f $Step, $InputObject)
        if ($InputObject.Length -le 1) {
            $Step
        } else {
            Get-MultiplicativePersistenceSteps -InputObject ([string]($InputObject.ToCharArray() | Convert-SymbolToDec -Symbols $Symbols | Get-BigIntMultiple | ConvertTo-BaseN -Symbols $Symbols)) -Step ($Step + 1)
        }
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
        [int]$GEDigitIndex = 1 #the next digit appended must be greater than or equal to this; to avoid generating anagrams.  
        ,
        [Parameter()]
        [string]$Symbols = '0123456789' #rule: must be at least 2 chars long; haven't bothered with validation to avoid performance hit...
    )
    Process {
        if ($Length -le 0) {
            $ValuePart
        } else {
            $GEDigitIndex..($Symbols.Length-1) | ForEach-Object {Invoke-TestMPGenerator -Symbols $Symbols -Length ($Length - 1) -ValuePart ($ValuePart + ($_ | Convert-DecToSymbol -Symbols $Symbols)) -GEDigitIndex $_}
        }
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
        ,
        [Parameter(ValueFromPipeline = $true)]
        [string]$Symbols = '0123456789' #base 10
    )
    Process {
        [int]$maxSteps = 0
        $MinLength..$MaxLength | ForEach-Object {
            Invoke-TestMPGenerator -Length $_ -Symbols $Symbols | ForEach-Object {
                $steps = Get-MultiplicativePersistenceSteps -InputObject $_ -Symbols $Symbols
                if ($steps -gt $maxSteps) {
                    $maxSteps = $steps
                    Write-Information ('Base {0:00}: New Max Found {1:000}: {2}' -f $Symbols.Length, $maxSteps, $_)
                    [pscustomobject]@{
                        Base = $Symbols.Length
                        Steps = $maxSteps
                        Sequence = $_
                    }
                }
            }
        }
    }
}
Clear-Host
[string]$baseSymbols = '0123456789ABCDEF'
1..($baseSymbols.Length-1) | %{$baseSymbols[0..$_] -join ''} | Invoke-MPHunter -InformationAction Continue | Format-Table -AutoSize

