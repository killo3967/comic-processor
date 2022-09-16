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
    $new_comic = $full_name.replace('&nbsp','')
    
    # Obtengo el numero del comic    
    $issue = extraer_issue $nombre_fichero   #! Extrae el issue de la serie en formato INT
    
    # Obtengo el año de la serie o del comic
    $v_año.clear
    $v_año = extraer_año (get-childitem $file_name)

    # Obtengo el publisher de la serie o del comic
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
        #! habra que pensar que se hace cuando no coincidan 
        $comic_series_name = $series_name
    }

    # Defino los años a probar
    if ( $v_año -eq '' ){
        # Si no encuentra año solo lo busca en el nombre del comic
        $posibles_años = @( '' )
        #! Pero antes miro si encuentro el ISBN en las imagenes
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

                if ( $comic.r.comicvine_volume_id -ne "" ) {
                    #! Antes de salir tengo que obtener el resto de los valores y crear el XML

                    # Obtengo los datos especificos de la serie y los escribo en el array XML
                    get-seriesdetail_cv 

                    # Obtengo los datos especificos del comic y los escribo en el array XML
                    get-issuedetail_cv

                    # Traduzco el campo summary si existe.
                    #! Esto se puede mejorar buscando en Amazon por ISBN, si no existe este campo.
                    if ( $comic.r.Summary.length -gt 0 ) {
                        $comic.r.Summary = traduce_deepl ($comic.r.Summary) "EN" "ES"
                    }    
                    # Crear el XML llamado comicinfo dentro del comic
                    create_comicinfo


                    # Como lo he encontrado me salgo del bucle
                    break outer
                }
            }
        }
    }
}

