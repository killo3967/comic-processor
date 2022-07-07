# La siguiente funcion trata de normalizar los nombres de los comics
# Las regla son las siguientes:
#   Estructura: <contador> <serie> <Vol. volumen> <#issue> . <extension>
#   No todos los campos existiran. Algunas veces los campos contador y volumen no existen, pero series,issue y extension son obligatorios
#   El problema es cuando el campo serie empieza por un nuemro y entonces en el nombre hay dos numeros consecutivos.
#   Habra que ir extrayendo cada posible campo trozo a trozo
#
#
# EN LA DOCUMENTACION DE COMICTAGGER (https://code.google.com/archive/p/comictagger/wikis/UserGuide.wiki#Search_vs._Auto-Identify_vs._Auto-Tag)
# ESTA LAS SIGUIENTES INSTRUCCIONES:
<#
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



##### guardo esto que parece que funciona con el directorio
#>




function identifica_comic {
# the idea is to identify all parts of the filename and put them in the variables $serie, $volumen, $numero, $numero_de_edicion, $año, $extension
Param (
    [Parameter(Mandatory=$true)]
    $ruta_fichero
)

    # Lo primero es identificar la serie a partir del nombre del directorio


}

function extraer_serie {
    Param (
    [Parameter(Mandatory=$true)]
    $ruta_fichero
)
    $dir_list[$i].name.split("(")[0].trim()

}
function extraer_año {
    # Uso la expresion de la variable global $cadena_año para extraer el año tanto en el directorio como en el comic 
    # Se extrae del directorio donde esta contenido el comic o desde el propio comic
    Param (
        [Parameter(Mandatory=$true)]
        $ruta_ficheros
    )
    # Primero busco el año en el nombre del comic.  
    $v_año = [regex]::match( $ruta_ficheros.name , $cadena_año )
    if ( $v_año.Success -eq $true) {
        # El grupo de captura es $4
        $v_año = $v_año.Groups[4].value
    } else {
        # Si no lo encuentro, busco en el directorio.
        $v_año = [regex]::match( $ruta_ficheros.directory , $cadena_año )
        if ( $v_año.Success -eq $true) {
            # El grupo de captura es $4
            $v_año = $v_año.Groups[4].value
        } else {
            # Si no lo encuentro lo pongo a "0000" 
            $v_año = "0000"
        }
    }

    # El 'grupo 1' $1 extrae el año y los parentesis
    Return $v_año
}

function extraer_issue {
    Param (
        [Parameter(Mandatory=$true)]
        $ruta_ficheros
        )

    $issue = ($new_comic.tostring().split('#'))[1] -replace '(\d{1,3})(.*)' , '$1'
    if ( $issue -eq 0 ) { $issue = 1 }

    # cuento cuantos grupos de numeros hay en el comic que tengan menos de 3 digitos
    $grupos_numeros = [regex]::match( $comic_name , '\d{1,3}').count
    
    # Si hay uno solo, entiendo que es el issue.
    if ( $grupos_numeros -eq 1 ) {
        $comic_name = $comic_name -replace '(\d{1,3})' , ' #$1 '
    } else {
        # Miro si hay un patron de numero con '#'
        $issue = [regex]::match( $comic_name , '(\d{1,3})')
        if ( $issue.count -eq 1 ) {
            # Si encuentra un patron con #
            $comic_name = $comic_name -replace '(\d{1,3})' , '#$1'
        } else {
            # o hay ningun numero con '#'
            $comic_name = $comic_name -replace '(\d{1,3})' , '#1'
        }
    }
    
    # El numero del comic debe tener 3 Digitos. Si no lo tiene, lo añado.
    $issue = [regex]::match( $comic_name , '\#([0]*)\d{1,3}')
    if ( $issue.sucess -eq $true) {
            $new_issue = '#' + (($issue.value -split '#')[1]).padleft(3,'0')
            $comic_name = $comic_name -replace $issue.value , $new_issue
    } else {
        $comic_name = $comic_name + "#001"
    }

    # Se extrae del numero del comic 
    $issue = [regex]::match( $ruta_ficheros.name , '\#([0]*)\d{1,3}')
    
    # El numero del comic debe tener 3 Digitos. Si no lo tiene, lo añado.
    if ( $issue.sucess -eq $true) {
            $new_issue = '#' + (($issue.value -split '#')[1]).padleft(3,'0')
            $comic_name = $comic_name -replace $issue.value , $new_issue
    } else {
        $comic_name = $comic_name + "#001"
    }
    return 
}


function extraer_editorial {

}

function extraer_indice {

}




