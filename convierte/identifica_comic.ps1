<#
La siguiente funcion trata de normalizar los nombres de los comics
Las regla son las siguientes:
Estructura: <contador> <serie> <Vol. volumen> <#issue> . <extension>
No todos los campos existiran. Algunas veces los campos contador y volumen no existen, pero series,issue y extension son obligatorios
El problema es cuando el campo serie empieza por un nuemro y entonces en el nombre hay dos numeros consecutivos.
Habra que ir extrayendo cada posible campo trozo a trozo


EN LA DOCUMENTACION DE COMICTAGGER (
    https://code.google.com/archive/p/comictagger/wikis/UserGuide.wiki#Search_vs._Auto-Identify_vs._Auto-Tag
    https://github.com/comictagger/comictagger/wiki/UserGuide#general-geatures

    ESTA LAS SIGUIENTES INSTRUCCIONES:

Análisis de nombre de archivo
Cuando se abre un archivo y no tiene etiquetas, ComicTagger intentará analizar el nombre del archivo para obtener información. 
Generalmente, espera un formato similar a este:
 - SERIES_NAME vVOLNUM ISSUENUM (of COUNT) (PUBYEAR).ext o 
 - SERIES_NAME (SERIESYEAR) ISSUENUM (of COUNT) (PUBYEAR).ext

Ejemplos:
Plastic Man v1 002 (1942).cbz Blue Beetle 02.cbr 
Monster Island vol. 2 #2.cbz Crazy Weird Comics 2 (of 2) (1969).rar 
Super Strange Yarns (1957) #92 (1969).cbz 
Action Spy Tales v1965 #3.cbr

En este esquema, PUBYEAR se refiere al año de publicación del número y SERIESYEAR al año de inicio del volumen/serie

Algunas otras notas:
    ComicTagger es más feliz cuando el número de edición tiene un "#" delante: Foobar-Man #121 (1974).cbz
    
    El nombre del volumen debe ir después del nombre de la serie y antes del número de edición. Foobar-Man Annual v2 #121 (1984).cbz 
    Foobar-Man Annual Vol. 2 121 (1984).cbz
    
    Lo primero que intenta encontrar el analizador de nombre de archivo es el número de problema (ISSUE). Si no se usa el '#', 
    el analizador intentará encontrar el número más probable. En general, se consideran las partes del nombre del archivo que no tienen paréntesis 
    alrededor. 
    
    El primer ejemplo se analizará bien: 
        Foobar-Man Annual v2 121 (The Wrath of Foobar-Man, Part 1 of 2).cbz
    Este segundo ejemplo no analizará correctamente ya que el analizador no sabe qué número es el número de problema: 
        Foobar-Man Annual 121 - The Wrath of Foobar-Man, Part 1 of 2.cbz
    También puede usar un guión doble ("--") o un guión bajo doble (" __") para preceder a la parte del nombre de archivo que no se analizará. 
    
    El siguiente ejemplo se analizará correctamente, ya que se ignorará el texto después del doble guión: 
            Foobar-Man Annual v2 121 -- The Wrath of Foobar-Man, Part 1 of 2.cbz 
    Como se mencionó anteriormente, la mayoría del texto entre paréntesis será ignorado. 
    Esto también es cierto para el texto después de "--" o " __": 
            Monster Island v1 1 (orginal cover) (c2c) .cbz 
            Monster_Island_v1_2__repaired__c2c.cbz 
            Monster Island v1 3 (1957) -- The Revenge Of King Klong (noads).cbz 
    
    Cualquier texto que no se analice explícitamente como nombre de la serie, volumen, número de edición o año de publicación o número de ediciones 
    se guardará en el campo "información de escaneo", si está habilitado.
    
    Solo debe haber un número de volumen o un año de serie en el nombre del archivo, ya que el analizador los interpreta como la misma cosa. 
    Usar el año de inicio o números de volumen secuenciales parece una cuestión de preferencia personal, pero como incluso el uso de números de volumen 
    secuenciales por parte de los editores es inconsistente, el año de inicio es menos ambiguo.
    
    Los siguientes ejemplos muestran variaciones en el uso de la serie año. Cualquier texto entre paréntesis después de "-" será ignorado por el análisis: 
        Dusk Vampire (2010) #1.cbz Dusk Vampire (2010-) #1.cbz 
        Dusk Vampire (2010-2012) #1.cbz

Cuanto más limpio sea el nombre de archivo original, mejor será ComicTagger para hacer coincidir en línea. 

formatos de nombres de fichero

SERIES_NAME vVOLNUM #ISSUENUM (of COUNT) (PUBYEAR).ext
SERIES_NAME (SERIESYEAR) #ISSUENUM (of COUNT) (PUBYEAR) - Nombre del archivo.ext <- Este es el mio

#>

function extraer_serie {
    Param (
    [Parameter(Mandatory=$true)]
    $ruta_fichero
    )
    $series_directory = split-path $ruta_fichero -leaf
    $series_directory = ($series_directory -replace '(\[|\()[^\]\)]*(\]|\))' , '').trim()
    
    return $series_directory
}

function extraer_serie_nombre_comic {
    Param (
    [Parameter(Mandatory=$true)]
    $ruta_fichero
    )
    $nombre_fichero = split-path -leaf $ruta_fichero
    $series_name = ($nombre_fichero.split('#'))[0].trim()
    return $series_name 
}

function extraer_año {
    # Se extrae del directorio donde esta contenido el comic o desde el propio comic
    Param (
        [Parameter(Mandatory=$true)]
        $ruta_ficheros
    )
    
    # Primero busco el año en el nombre del comic.  
    $v_año = [regex]::match( $ruta_ficheros , $cadena_año )
    if ( $v_año.Success -eq $true) {
        # El grupo de captura es $4
        $v_año = $v_año.Groups[4].value
    } else {
        # Si no lo encuentro, busco en el directorio.
        $v_año = [regex]::match( $ruta_ficheros.directory.name , $cadena_año )
        if ( $v_año.Success -eq $true) {
            # El grupo de captura es $4
            $v_año = $v_año.Groups[4].value
        } else {
            # Si no lo encuentro hago un OCR de las paginas iniciales y finales del comic para extraer el año. 
            $v_año.clear
            $v_año = escaner_ocr
        }
    }
    Return $v_año
}

function extraer_issue {
    Param (
        [Parameter(Mandatory=$true)]
        $ruta_ficheros
        )

    # Extraigo el nombre del comic
    $comic_name = $ruta_ficheros.name

    # Cuento cuantos grupos de numeros hay en el comic que tengan menos de 3 digitos
    $grupos_numeros = [regex]::match( $comic_name , '\d{1,3}')
    
    # Si hay uno solo, entiendo que es el issue.
    if ( $grupos_numeros.count -eq 1 ) {
        # No hago nada ya que el numero buscado es el issue
    } else {
        #! Cuidado aqui hay que ver porque hay dos o mas patrones menores de tres digitos
        #! uno puede ser el numero al principio, el otro el issue y otro podria ser el numero de volumen.
        #! Habria que extraer cada uno de ellos y ponerlos en una variable.
        #! De momento lo formateo igualmente a la variable cadena_issue

        # si hay varios debe ser el que sea < de 500. Si hay un año en el titulo se debe ignorar ese elemento.
        # montamos un bucle para ver todas las soluciones y elegir la que mas correspoda
        # Se podria buscar si tiene una almohadilla y seria ese. Si no tiene la almohadilla es un problema.

        $comic_name = $comic_name -replace $cadena_issue , ' #$2 '
    }       
  
    # Se extrae del numero del comic
    $issue = [regex]::match( $comic_name , $cadena_issue )
    
    $issue = [int]($issue.value -split '#')[1]
    <#! DE MOMENTO LO FORMATERARE EN UN FUTURO CUANDO FALLE EL SCRAPPING o cuando no tenga #
    # El numero del comic debe tener 3 Digitos. Si no lo tiene, lo añado.
    if ( $issue.Success -eq $true) {
            $new_issue = (($issue.value -split '#')[1]).padleft(3,'0')
    }
    #>

return $issue
}

function get-publisher {
    Param (
        [Parameter(Mandatory=$true)]
        $in_ruta_fichero
    )
    $out_publisher = ($in_ruta_fichero.split('('))[1].split(')')[0]
    #! Si esto no contiene nada habra que implementar el OCR
return $out_publisher
}







