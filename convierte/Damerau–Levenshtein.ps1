# Damerau–Levenshtein distance for Powershell
# based on c# code from
# http://blog.softwx.net/2015/01/optimizing-damerau-levenshtein_15.html

function Get-DamLev {
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 0)]
        
        [string] 
        $s,

        # Param2 help description
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 1)]
        [string]
        $t,

        # Param3 help description
        [Parameter(Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, [int]::MaxValue)]
        [int]
        $maxDistance = [int]::MaxValue,
        
        # Param3 help description
        [Parameter(Mandatory = $false, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true, 
            ValueFromRemainingArguments = $false, 
            Position = 3)]
        [string]
        $dn
    )
    $input2 = $t
    if ([string]::IsNullOrEmpty($t) -and [string]::IsNullOrEmpty($s)) { return -1; }
    if ([string]::IsNullOrEmpty($t)) { if ($s.length -lt $maxDistance) { $s.length }else { return -1; } }

    if ([string]::IsNullOrEmpty($s)) { if ($t.length -lt $maxDistance) { $t.length }else { return -1; } }
    if ($s.Length -gt $t.Length) {
        $temp = $s; $s = $t; $t = $temp; # swap s and t
    }

    [int] $sLen = $s.Length; # this is also the minimun length of the two strings
    [int] $tLen = $t.Length;

    [int] $lenDiff = $tLen - $sLen;
    if (($maxDistance -lt 0) -or ($maxDistance -gt $tLen)) {
        $maxDistance = $tLen;
    }
    else { if ($lenDiff -gt $maxDistance) { return -1 } };
    while (($sLen -gt 0) -and ($s[$sLen - 1] -eq $t[$tLen - 1])) { $sLen--; $tLen--; }
    
    [int] $start = 0;
    if (($s[0] -eq $t[0]) -or ($sLen -eq 0)) {
        # if there's a shared prefix, or all s matches t's suffix
        # prefix common to both strings can be ignored
        while (($start -lt $sLen) -and ($s[$start] -eq $t[$start])) { $start++ };
        $sLen -= $start; # length of the part excluding common prefix and suffix
        $tLen -= $start;
 
        # if all of shorter string matches prefix and/or suffix of longer string, then
        # edit distance is just the delete of additional characters present in longer string
        if ($sLen -eq 0) { if ($tLen -le $maxDistance) { return $tLen }else { return -1 } };
 
        $t = $t.Substring($start, $tLen); # faster than t[start+j] in inner loop below
    }

    [int] $lenDiff = $tLen - $sLen;
    if (($maxDistance -lt 0) -or ($maxDistance -gt $tLen)) {
        $maxDistance = $tLen;
    }
    else { if ($lenDiff -gt $maxDistance) { return -1 } };
 
    $v0 = New-Object 'int[]' $tLen;
    $v2 = New-Object 'int[]' $tLen; # stores one level further back (offset by +1 position)
    for ($j = 0; $j -lt $maxDistance; $j++) { $v0[$j] = $j + 1 };
    for (; $j -lt $tLen; $j++) { $v0[$j] = $maxDistance + 1 };
 
    [int] $jStartOffset = $maxDistance - ($tLen - $sLen);
    [bool] $haveMax = $maxDistance -lt $tLen;
    [int] $jStart = 0;
    [int] $jEnd = $maxDistance;
    [char] $sChar = $s[0];
    [int] $current = 0;
    for ($i = 0; $i -lt $sLen; $i++) {
        [char] $prevsChar = $sChar;
        $sChar = $s[$start + $i];
        [char] $tChar = $t[0];
        [int] $left = $i;
        $current = $left + 1;
        [int] $nextTransCost = 0;
        # no need to look beyond window of lower right diagonal - maxDistance cells (lower right diag is i - lenDiff)
        # and the upper left diagonal + maxDistance cells (upper left is i)
        if ($i -gt $jStartOffset) { $jStart += 1 }
        if ($jEnd -lt $tLen) { $jEnd += 1 }
        for ($j = $jStart; $j -lt $jEnd; $j++) {
            [int] $above = $current;
            [int] $thisTransCost = $nextTransCost;
            $nextTransCost = $v2[$j];
            $v2[$j] = $current = $left; # cost of diagonal (substitution)
            $left = $v0[$j]; # left now equals current cost (which will be diagonal at next iteration)
            [char] $prevtChar = $tChar;
            $tChar = $t[$j];
            if ($sChar -ne $tChar) {
                if ($left -lt $current) { $current = $left }; # insertion
                if ($above -lt $current) { $current = $above }; # deletion
                $current++;
                if (($i -ne 0) -and ($j -ne 0) -and ($sChar -eq $prevtChar) -and ($prevsChar -eq $tChar)) {
                    $thisTransCost++;
                    if ($thisTransCost -lt $current) { $current = $thisTransCost }; # transposition
                }
            }
            $v0[$j] = $current;
        }
        if ($haveMax -and ($v0[$i + $lenDiff] -gt $maxDistance)) { return -1 };
    }
    if ($current -le $maxDistance) {
        return [PSCustomObject]@{
            Scoring = $current
            text1   = $s
            text2   = $input2
            dn      = $dn
        }
    
    }
    else { return -1 }
}

function Select-DamLevString {
    [CmdletBinding()]
    param (
        # The search query.
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Search,

        # The data you want to search through.
        [Parameter(Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('In')]
        $Data,

        # Set to True (default) it will calculate the match score.
        [Parameter()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, [int]::MaxValue)]
        [int]
        $maxDistance = [int]::MaxValue
    )

    BEGIN {}

    PROCESS {

        if ($Data.displayname.length -gt 0 -and $Search.length -gt 0) {
            Get-DamLev -s $Data.displayname -t $Search -dn $Data.distinguishedname -maxDistance $maxDistance | Where-Object { $_.Scoring -gt 0 }
        }
    }
}

function Get-LevenshteinDistance {
    <#
        .SYNOPSIS
            Get the Levenshtein distance between two strings.
        .DESCRIPTION
            The Levenshtein Distance is a way of quantifying how dissimilar two strings (e.g., words) are to one another by counting the minimum 
            number of operations required to transform one string into the other.
        .EXAMPLE
            Get-LevenshteinDistance 'kitten' 'sitting'
        .LINK
            http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#C.23
            http://en.wikipedia.org/wiki/Edit_distance
            https://communary.wordpress.com/
            https://github.com/gravejester/Communary.PASM
        .NOTES
            Author: Øyvind Kallstad
            Date: 07.11.2014
            Version: 1.0
    #>
    [CmdletBinding()]
    param(
        # First string to compare
        [Parameter(Position = 0)]
        [string]$String1,

        # Second string to compare
        [Parameter(Position = 1)]
        [string]$String2,

        # Makes matches case-sensitive. By default, matches are not case-sensitive.
        [Parameter()]
        [switch] $CaseSensitive,

        # A normalized output will fall in the range 0 (perfect match) to 1 (no match).
        [Parameter()]
        [switch] $NormalizeOutput
    )

    if (-not($CaseSensitive)) {
        $String1 = $String1.ToLowerInvariant()
        $String2 = $String2.ToLowerInvariant()
    }

    $d = New-Object 'Int[,]' ($String1.Length + 1), ($String2.Length + 1)

    try {
        for ($i = 0; $i -le $d.GetUpperBound(0); $i++) {
            $d[$i, 0] = $i
        }

        for ($i = 0; $i -le $d.GetUpperBound(1); $i++) {
            $d[0, $i] = $i
        }

        for ($i = 1; $i -le $d.GetUpperBound(0); $i++) {
            for ($j = 1; $j -le $d.GetUpperBound(1); $j++) {
                $cost = [Convert]::ToInt32((-not($String1[$i - 1] -ceq $String2[$j - 1])))
                $min1 = $d[($i - 1), $j] + 1
                $min2 = $d[$i, ($j - 1)] + 1
                $min3 = $d[($i - 1), ($j - 1)] + $cost
                $d[$i, $j] = [Math]::Min([Math]::Min($min1, $min2), $min3)
            }
        }

        $distance = ($d[$d.GetUpperBound(0), $d.GetUpperBound(1)])

        if ($NormalizeOutput) {
            Write-Output (1 - ($distance) / ([Math]::Max($String1.Length, $String2.Length)))
        }

        else {
            Write-Output $distance
        }
    }

    catch {
        Write-Warning $_.Exception.Message
    }
}