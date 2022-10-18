<#
Estas funciones se encargan de limpiar los nombre de los comics antes de proceder a 
identificarlos

#>

# Esta es la funciona principal de limpieza y llama al resto de las funciones
Function limpia_nombres { 

    # Param (
    #     [Parameter(Mandatory = $true)]
    #     $ruta_ficheros
    # )

    $ruta_ficheros = $Global:dp_series_name_path

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
        
        $series = $Global:dp_series_name
        # = extraer_serie $ruta_ficheros

        # Veo si el comic contiene el nombre de la serie, si no le cambio el nombre.
        if ($comic_name -match $series) {
            # Creo el nuevo nombre del comic
            $new_comic_name = $ruta_ficheros + "\" + $new_comic_name
        } else {
            $issue = extraer_issue $full_comic_name
            $new_comic_name = $ruta_ficheros + "\" + $series + " #" + $issue + $_.Extension 
        }
        # Renombro el comic si no existe
        if (-not $new_comic_name) { 
            rename-item -literalpath $full_comic_name -newname $new_comic_name -Force
        }
    }
}# Fin de funcion


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


