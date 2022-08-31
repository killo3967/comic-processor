<#
Estas funciones se encargan de limpiar los nombre de los comics antes de proceder a 
identificarlos

#>

function simplifica_caracteres {
    Param (
        [Parameter(Mandatory = $true)]
        [String] $cadena
    )

 
    # capitals filter (all is made lower)
    $word_str1 = $cadena.Tolower()

    # some symbols and words are replace so that in a comparision they are the same

    $word_str1 = $word_str1.replace('0.', '.')
    $word_str1 = $word_str1.replace('&', 'y')
    $word_str1 = $word_str1.replace('+', 'mas')
    $word_str1 = $word_str1.replace("li'l", 'little')
    $word_str1 = $word_str1.replace("'n ", 'y ')
    $word_str1 = $word_str1.replace(' and ', '')
    $word_str1 = $word_str1.replace('vs', 'contra')
    $word_str1 = $word_str1.replace('special', '')
    $word_str1 = $word_str1.replace('ultimate', '')

    $word_str1 = $word_str1.replace("' ii", ' 2')
    $word_str1 = $word_str1.replace("' iii", ' 3')
    $word_str1 = $word_str1.replace("' iv", ' 4')
    $word_str1 = $word_str1.replace("' v", ' 5')
    $word_str1 = $word_str1.replace("' vi", ' 6')
    $word_str1 = $word_str1.replace("' vii", ' 7')
    $word_str1 = $word_str1.replace("' viii", ' 8')
    $word_str1 = $word_str1.replace("' ix", ' 9')
    $word_str1 = $word_str1.replace("' x", ' 10')

    $word_str1 = $word_str1.replace("one", '1')
    $word_str1 = $word_str1.replace("two", '2')
    $word_str1 = $word_str1.replace("three", '3')
    $word_str1 = $word_str1.replace("four", '4')
    $word_str1 = $word_str1.replace("five", '5')
    $word_str1 = $word_str1.replace("six", '6')
    $word_str1 = $word_str1.replace("seven", '7')
    $word_str1 = $word_str1.replace("eight", '8')
    $word_str1 = $word_str1.replace("nine", '9')
    
    # all non letters and numbers are filtered and replaced as spaces
    $word_str1 = $word_str1 -replace '[áäâàåã@]' , "a"
    $word_str1 = $word_str1 -replace '[èéëeê]' , "e"
    $word_str1 = $word_str1 -replace '[íìïî]' , "i"
    $word_str1 = $word_str1 -replace '[öòóôõ"]' , "o"
    $word_str1 = $word_str1 -replace '[úûùü]' , "u"
    $word_str1 = $word_str1 -replace '[æ]' , "ae"
    $word_str1 = $word_str1 -replace '[¼]' , "1/4"
    $word_str1 = $word_str1 -replace '[½]' , "1/2"
    $word_str1 = $word_str1 -replace '[¾]' , "3/4"
    $word_str1 = $word_str1 -replace '[ß]' , "b"

}
function limpieza_nombre_comics {

    Param (
        [Parameter(Mandatory = $true)]
        [String] $comic_name
    )

    # Reparo signos de puntuacion
    $comic_name = reparar_signos_puntuacion ( $comic_name )

    # Quito los corchetes y su contenido.
    $comic_name = $comic_name -replace '\[[^\]]*\]' , ''

    # Quito los parentesis y su contenido.
    $comic_name = $comic_name -replace '\([^\)]*\)' , ''

    # Elimino los corchetes y parentesis y su contenido
    $comic_name = $comic_name -replace '(\[|\()[^\]\)]*(\]|\))' , ''

    # Elimino los traducido por....
    $comic_name = $comic_name -replace ( "\(de .*\)" , "")                    
    $comic_name = $comic_name -replace ( "\(spanish by .*\)" , "")            
    $comic_name = $comic_name -replace ( "\[Traducido por .*\]" , "")         
    $comic_name = $comic_name -replace ( "\[Trad por .*\]" , "")              

    # Elimino textos de recopiladores (meter en un fichero)
    $comic_name = $comic_name -replace ( "\[CRG.*\]" , "")                    
    $comic_name = $comic_name -replace ( "\[TM.*\]" , "")                     
    $comic_name = $comic_name -replace ( "\[Belisario.*\]" , "")              
    $comic_name = $comic_name -replace ( "\[SC.*\]" , "")
    $comic_name = $comic_name -replace ( "\[IC.*\]" , "")
    $comic_name = $comic_name -replace ( "\[AudioWho.*\]" , "")
    $comic_name = $comic_name -replace ( "\[ComicAlt.*\]" , "")
    $comic_name = $comic_name -replace ( "\[TBO's.*\]" , "")
    $comic_name = $comic_name -replace ( "\[Gisicom.*\]" , "")
    $comic_name = $comic_name -replace ( "\[KMQS.*\]" , "")
    $comic_name = $comic_name -replace ( "\[LLSW.*\]" , "")
    $comic_name = $comic_name -replace ( "\[Prix.*\]" , "")
    $comic_name = $comic_name -replace ( "\[Infinity.*\]" , "")
    $comic_name = $comic_name -replace ( "\[droidfactory.*\]" , "")
    $comic_name = $comic_name -replace ( "\[exvagos.*\]" , "")
    $comic_name = $comic_name -replace ( "\(www.comicrel.tk\)" , "")
    $comic_name = $comic_name -replace ( "\(Editorial.Vid\)" , "")
    $comic_name = $comic_name -replace ( "\(Panini\)" , "")

    
    # Pequeñas sustituciones
    #! pasarlas a un fichero y una funcion
    $comic_name = $comic_name -replace ( "BM " , "Biblioteca Marvel - " )
    $comic_name = $comic_name -replace ( "Star Trek TNG" , "Star Trek The Next Generation" )

    # Quitar la palabra 'comic' al principio del nombre. Mucho comics la traen.
    # $comic_name = ($comic_name -replace '^(comic|Comic)(.*)$' , '$2').trim()

    # Los guiones siempre tienen espacio delante y detras.
    $comic_name = $comic_name -replace '(.*)\s?-\s?(.*)(\.)(cbr|cbz)' , '$1 - $2.$4'

    # Elimino las expresiones de quien lo ha escaneado o traducido o maqueteado hasta el final del nombre.
    $comic_name = $comic_name -replace '(.*)\s?((\(|\[)(por|by|Traducido|Trad|scan)([a-zA-ZÀ-ÿ\u00f1\u00d1\w\d\s\-\,])*?(\)|\]))\s?(.*)(\.)(cbr|cbz)' , '$1$7.$8'
    $comic_name = $comic_name -replace '(.*)(por|by|Traducido|Trad|scan)([a-zA-ZÀ-ÿ\u00f1\u00d1\w\d\s\-\,])*(.*)' , '$1$4'

    # Pongo delante del issue una #
    $comic_name = $comic_name -replace $cadena_issue , ' #$2'

    # En las expresiones (1de3) dejo solo #1 o Parte 1 de 4 o Parte 2. Vale para parentesis y corchetes.
    $comic_name = $comic_name -replace '(\[|\()?(parte|part)?\s?(\d+)\s?(de|of)\s?(\d+)(\]|\))?' , ' #$3 '
    
    # Sustituyo los puntos por espacios, excepto el punto que separa la extension.
    $comic_name = $comic_name -replace '\.(?=[^.]*\.)' , ' '

    # Reparo signos de puntuacion
    $comic_name = reparar_signos_puntuacion ( $comic_name )
        
    Return $comic_name
}


function limpieza_nombre_manga {
    # de momento no proceso los nombre de los manga
}

# Esta es la funciona principal de limpieza y llama al resto de las funciones
Function limpia_nombres { 

    Param (
        [Parameter(Mandatory = $true)]
        $ruta_ficheros
    )

    $lista_ficheros = Get-ChildItem -LiteralPath $ruta_ficheros -File

    $lista_ficheros | foreach-object { 
        
        # Obtengo el nombre del fichero
        
        $comic_name = $_.name
        $full_comic_name = $_.fullname
        
        # Creo un array con la lista de ficheros que me gustaria borrar que esta en el fichero exclude.cfg
        $excluded_name = get-content $config_dir\exclude_name.cfg -verbose:$verbose

        # Borro la cadena de texto excluida del nombre del comic 
        foreach ( $v_texto in $excluded_name ) {
            # Elimino los textos del fichero de configuracion y antes compruebo que la linea tiene contenido
            # y escapo el contenido por si tiene caracteres especiales
            if ( $v_texto -match '[a-zA-Z0-9]' ) {
                $comic_name = $comic_name -replace [regex]::escape($v_texto) , '' 
            }
        }

        # Poner las extensiones CBR y CBZ en minusculas
        $comic_name = $comic_name -replace "CBR" , "cbr"
        $comic_name = $comic_name -replace "CBZ" , "cbz"
         
        # Llamo a la funcion de limpieza (profunda) del nombre del comic
        #! Esto habria que hacerlo mas flexible y permitir varias configuraciones segun el perfil escogido.
        #! De momento solo tengo encuenta si los ficheros son tipo 'comics' o 'tipo manga'
        #! Pero podria meterse en el fichero de configuracion y depender del sitio, de una palabra, etc 
        if ( $tipo_renombrado -eq "comics") {
            $new_comic_name = limpieza_nombre_comics $comic_name
        }
        else {
            $new_comic_name = limpieza_nombre_manga $comic_name
        }
        
        $series = extraer_serie $ruta_ficheros

        # Veo si el comic contiene el nombre de la serie, si no le cambio el nombre.
        if ($comic_name -match $series) {
            # Creo el nuevo nombre del comic
            $new_comic_name = $ruta_ficheros + "\" + $new_comic_name
        } else {
            $issue = extraer_issue $full_comic_name
            $new_comic_name = $ruta_ficheros + "\" + $series + " #" + $issue + $_.Extension 
        }
        # Renombro el comic
        rename-item -literalpath $full_comic_name -newname $new_comic_name -Force
    }
}# Fin de funcion

# Este modulo intenta dejar el nombre de los comics lo mas ordenado y limpio posible antes de identificarlo.
function reparar_signos_puntuacion {
    Param (
        [Parameter(Mandatory = $true)]
        [String] $comic_name
    )

    # Reparo los signos de puntuacion
    # Lo ejecuto varias veces ya que hace falta pasar varias veces las reglas para limpiar bien 
    for ( $i = 1 ; $i -lt 2 ; $i++ ) {
        $comic_name = $comic_name.replace( "_" , " ")
        $comic_name = $comic_name.replace( ".." , ".")
        $comic_name = $comic_name.replace( "  " , " ")
        $comic_name = $comic_name.replace( "-#" , "- #")
        $comic_name = $comic_name.replace( "--" , "-")
        $comic_name = $comic_name.replace( " -." , ".")
        $comic_name = $comic_name.replace( " ." , ".")
        $comic_name = $comic_name.replace( "nº" , "#")
        $comic_name = $comic_name.replace( ".-." , ".")
        $comic_name = $comic_name.trim()
    }
    return $comic_name
}

#Damerau–Levenshtein distance for Powershell
# based on c# code from
#http://blog.softwx.net/2015/01/optimizing-damerau-levenshtein_15.html

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

    BEGIN {
       
    }

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
        [Parameter(Position = 0)]
        [string]$String1,

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
