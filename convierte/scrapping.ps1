#! De momento el scrapping solo lo hago con comictagger desde comicvine, pero se podria hacer directamente
#! de las web mediante el modulo de anglesharp que permite hacer un scrapping despues de meter la pagina web en una variable


function scrap_comic {
# Esta funcion es la principal, la que se encarga de llamar a las funciones que hacen el scrapping y a la que se le pasa los parametros
    Param (
        [Parameter(Mandatory)]
        [String]$series_name,
    
        [Parameter(Mandatory)]
        [String]$file_name
    )

    $nombre_fichero = (get-childitem $file_name)

    $full_name = $nombre_fichero.fullname

    # A veces se cuela en el nombre de la serie o en cualquier parte un "&nbsp" y la siguiente linea lo quita.
    # Lo suyo seria renombrar el directorio antes de empezar
    $full_name=$full_name.replace('&nbsp','')
    
    # Obtengo el nombre del comic
    $new_comic = $full_name

    # Obtengo el numero del comic    
    $issue = extraer_issue $nombre_fichero   #! Extrae el issue de la serie en formato INT
    
    # Obtengo el año de la serie o del comic
    $v_año.clear
    $v_año = extraer_año (get-childitem $file_name)
    $publisher = get-publisher $file_name
    $num_issues = (get-childitem(get-childitem $full_name).directoryname).count
        
    write-host "========================================================"
    write-host "=================== DATOS OBTENIDOS ===================="
    write-host "Serie: $series_name"
    write-host "Numero: $issue"
    write-host "Comic: $new_comic"
    write-host "Editorial" $publisher
    write-host "Numero de comics:" $num_issues
    write-host "Año de la serie: "($v_año -join (' , '))
    write-host "========================================================"
    write-host "========================================================"
    write-host 

    write-host "BUSCANDO DATOS (SCRAPPING) DEL COMIC"

    $folder_series_name = $series_name
    $comic_series_name = extraer_serie_nombre_comic $file_name

    if ($comic_series_name -eq $series_name ) {
        # si el nombre de la serie del comic no es el que aparece en el directorio
        # hago que prevalezca el nombre de la serie en el directorio, como nombre final de la serie 
        $comic_series_name = $series_name
    }

    # Defino los años a probar
    if ( $v_año -eq '' ){
        # Si no encuentra año solo lo busca en el nombre del comic
        $posibles_años = @( '' )
        # Pero antes miro si encuentro el ISBN en las imagenes
    } else {
        # Si encuentra algun año lo pruevo en vacio y con el año posterior y anterior. Ya que mas de una vez he visto errores
        # Tanto en el año de comicvine como en el año del directorio. 
        $posibles_años=@()
        $posibles_años.clear
        # $posibles_años += ''

        if ( $v_año.gettype().name -eq 'String' ) {
            # Si se devuelve un sollo año en un string
            $posibles_años += [int]$v_año 
            $posibles_años += ( [int]$v_año - 1 )
            $posibles_años += ( [int]$v_año + 1 )
        } else {
            for ( $i = 0 ; $i -lt $v_año.count ; $i++ ) {
                # Si devuelve un array de años
                $posibles_años += [int]$v_año[$i] 
                $posibles_años += ( [int]$v_año[$i] - 1 )
                $posibles_años += ( [int]$v_año[$i] + 1 )
            }
        } 
    }

    # Existen varias posiblilidades dependiendo de los años encontrados durante el OCR
    :outer foreach ( $t_año in $posibles_años ) {
        foreach ($t_series_name in @( $folder_series_name , $comic_series_name )) {
            foreach ($t_idioma in @( 'español' , 'ingles' )) {

                # paso 1 - Pongo el nombre de la serie en el idioma correspondiente
                if ($t_idioma -eq 'español') {
                    # no toco el nombre 
                } else {
                    $t_series_name = traduce_deepl $t_series_name
                }
                write-host "   >> Buscando comic SERIE: $series_name | ISSUE: $issue | AÑO: $t_año | COMIC: $new_comic | IDIOMA: $t_idioma | ISSUES: $num_issues"
                
                get-serie_cv $series_name $issue $t_año $publisher $new_comic $num_issues

                if ( $comicinfo_xml.ComicInfo.comicvine_volume_id -ne "" ) {
                    #! Antes de salir tengo que obtener el resto de los valores y crear el XML

                    # Obtengo los datos especificos de la serie y los escribo en el array XML
                    get-seriesdetail_cv 

                    # Obtengo los datos genericos del comic y los escribo en el array XML
                    # get-issue_cv

                    # Obtengo los datos especificos del comic y los escribo en el array XML
                    get-issuedetail_cv

                    # Traduzco el campo summary
                    $comicinfo_xml.ComicInfo.Summary = traduce_deepl $comicinfo_xml.ComicInfo.Summary "EN" "ES"

                    # creo la seccion de Paginal del XML
                    create_xml_pages_section

                    # Crear el XML llamado comicinfo dentro del comic
                    [xml]$comicinfo_xml.save("C:\scripts\convierte\comic\final\comicinfo.xml")
                    break outer
                }
            }
        }
    }
}

<# ESTO ERA CON COMIC TAGGER
                write-host "   >> Buscando comic SERIE: $series_name | ISSUE: $issue | AÑO: $t_año | COMIC: $new_comic | IDIOMA: $t_idioma"
                paso 2 - Grabo los datos de la serie y el numero en el fichero de metadatos sin usar el año 
                write-host "    >> Escribiendo metadatos"
                llamar_a_comictagger $series_name $issue $t_año $new_comic 'crea_xml'
                paso 4 busco datos online del comic
                write-host "    >> Buscando datos online del comic"
                llamar_a_comictagger "" "" "" $new_comic 'busca_online'
                $respuesta_ct = repuesta_comictagger 
                if ($respuesta_ct[0] -eq 0 )
                {
                        # LO HA ENCONTRADO A LA PRIMERA
                        write-host "SCRAPPING EXITOSO" -ForegroundColor Green
                        # Imprimo los datos 
                        # llamar_a_comictagger '' '' '' $new_comic 'imprime_xml'
                        # Renombro el comic
                        # llamar_a_comictagger '' '' '' $new_comic 'renombra_comic'
                        # Me salgo del bucle
                        break outer
                } else {
                        # NO LO HA ENCONTRADO A LA PRIMERA
                        # write-host "SCRAPPING FALLIDO. ERROR: "$respuesta_ct[1] -ForegroundColor Red
                }
                #>


<#
function llamar_a_comictagger {
# Esta funcion se encarga de llamar al programa comictagger y asegurar que se ejecute correctamente
    Param (
        [Parameter()]
        [String]$series_name,
    
        [Parameter()]
        [String]$issue,

        [Parameter()]
        [String]$v_año,

        [Parameter()]
        [String]$new_comic,

        [Parameter()]
        [String]$commando
        )

        switch ( $commando ) {
            'crea_xml'
                {
                (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -s -f -t cr -m "series=$series_name,issue=$issue,year=$v_año" $new_comic.tostring())2>&1 > $log_dir\comictagger.log
                }
            'busca_online'
                {
                (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -s -o -t cr  $new_comic.tostring() ) 2>&1 > $log_dir\comictagger.log
                }
            'imprime_xml'
                {
                (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -p -t cr $new_comic.tostring()) 2>&1 > $log_dir\comictagger.log
                }
            'renombra_comic'
                {
                (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -r -t cr $new_comic.tostring()) 2>&1 > $log_dir\comictagger.log
                }
        }
}
function repuesta_comictagger {
    # Analizo el fichero de log dejado por comictagger, para esto no necesito parametros
    # Pero si devuelvo $true si lo ha encontrado o $false ni no lo ha encontrado 
    $respuesta = get-content -literalpath "$log_dir\comictagger.log"

    $error_code_return = @{
        'Save complete' = '0'
        'Successful matches:' = '0'
        'Error' = '1'
        'No matches:' = '1'
        'File Write Failures:' = '1'
        'Network Data Fetch Failures:' = '1'
        'Archives with multiple high-confidence matches:' = '2'
        'Multiple high-confidence matches' = '2'
        'Archives with low-confidence matches:' = '2'
        'Single low-confidence match' = '2'
        'Multiple low-confidence matches' = '2'
        'You must specify at least one filename' = '3'
        "Can't rename without series name" = '4'
        'Network error while getting issue details.' = '4'
        'No metadata given to search online with' = '4'
    }
    $error_code_return.getenumerator() | foreach-object { if ($respuesta -contains $_.key) { $vla_return = @($_.value , $_.key) } }
    return $vla_return
}

#>