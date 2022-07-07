#! De momento el scrapping solo lo hago con comictagger desde comicvine, pero se podria hacer directamente
#! de las web mediante el modulo de anglesharp que permite hacer un scrapping despues de peter la pagina web en una variable
function scrap_comic {

    Param (
        [Parameter(Mandatory)]
        [String]$series_name,
    
        [Parameter(Mandatory)]
        [String]$file_name
    )

    
    $nombre_fichero = (get-childitem $file_name)

    # $base_name = $nombre_fichero.basename
    # $short_name = $nombre_fichero.name
    $full_name = $nombre_fichero.fullname

    #! A veces se cuela en el nombre de la serie o en cualquier parte un "&nbsp" y la siguiente linea lo quita.
    #! Lo suyo seria renombrar el directorio antes de empezar

    $full_name=$full_name.replace('&nbsp','')

    
    [int]$issue = extraer_issue $full_name   #! Extrae el numero de la serie en formato INT
    $new_comic = $full_name

    # $issue = [regex]::match( $comic_name , '\#([0]*)\d{1,3}').value
    
    write-host "============== DATOS OBTENIDOS ===================="
    write-host "Nombre de la serie: $series_name"
    write-host "Issue: $issue"
    write-host "Comic: $new_comic"
    write-host "==================================================="
    write-host 

    write-host "BUSCANDO DATOS (SCRAPPING) DEL COMIC"
    # paso 1 grabo los datos de la serie, la editoria y el numero en el fichero de metadatos usando la opcion '-f' 
    write-host "    >> Escribiendo metadatos en el comic"
    (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -s -f -t cr -m "series=$series_name,issue=$issue" $new_comic) 2>&1 > $log_dir\comictagger.log
    # get-content -literalpath "$log_dir\comictagger.log" 

    # paso 2 compruebo los tags escritos 
    write-host "    >> Imprimiendo metadatos del comic"
    (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -p -t cr $new_comic) 2>&1 > $log_dir\comictagger.log
    get-content -literalpath "$log_dir\comictagger.log" | write-host 

    # paso 3 mirar si puedo encontrar on-line los datos usando el nombre del directorio como nombre de serie
    Write-Host "    >> Busccando los datos online"
    (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -s -o -t cr  $new_comic ) 2>&1 > $log_dir\comictagger.log
    
    $respuesta = get-content -literalpath "$log_dir\comictagger.log"
    # write-host $respuesta 
    write-host

    # Saco el año de la serie o del comic
    $v_año = extraer_año $file_name

    # Ahora miro si se encuentra mas de una coincidencia y entonces uso el año si es posible
    if (( $respuesta | select-string 'Archives with multiple high-confidence matches').count -gt 0 -and $v_año -ne '0000') {
        write-host "    >> Encontrada mas de una coincidencia, añadiendo el dato del año a la busqueda"
        # Escribo los datos en el fichero de metadatos
        (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -s -f -t cr -m "series=$series_name,issue=$issue,year=$v_año" $new_comic) 2>&1 > $log_dir\comictagger.log
        # Busco on-line los datos
        (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -s -o -t cr  $new_comic ) 2>&1 > $log_dir\comictagger.log
        get-content -literalpath "$log_dir\comictagger.log" | write-host
    } else {
        # Si tampoco lo encuentra pruebo traduciendo al ingles el nombre de la serie ( sin año)
        if (( $respuesta | select-string 'ERROR | Online search: No match found. Save aborted').count -gt 0 ) {
            write-host "    >> No se encuentra el nombre de la serie en el idioma español, buscandolo en inglés"
            $series_name = traduce_deepl($series_name)
            # Escribo los datos en el fichero de metadatos
            (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -s -f -t cr -m "series=$series_name,issue=$issue" $new_comic) 2>&1 > $log_dir\comictagger.log
            # Busco on-line los datos
            (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -s -o -t cr  $new_comic ) 2>&1 > $log_dir\comictagger.log
            get-content -literalpath "$log_dir\comictagger.log" | write-host
            } else {
            # compruebo se encuentra mas de una coincidencia y entonces uso el año y el nombre de la serie en ingles
                if (( $respuesta | select-string 'Archives with multiple high-confidence matches'-and $v_año -ne '0000').count -gt 0 ) {
                    "    >> Encontrada mas de una coincidencia en ingles, añadiendo el dato del año a la busqueda"
                    # Escribo los datos en el fichero de metadatos
                    (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -s -f -t cr -m "series=$series_name,issue=$issue,year=$v_año" $new_comic) 2>&1 > $log_dir\comictagger.log
                    # Busco on-line los datos
                    (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -s -o -t cr  $new_comic ) 2>&1 > $log_dir\comictagger.log
                    get-content -literalpath "$log_dir\comictagger.log" | write-host
                }
        }
    }
    #! Aqui en medio se podria hacer que tradujeta el tag 'comments' al español

    # paso 4 compruebo los tags escritos 
    write-host "    >> Imprimiendo metadatos en el comic"
    (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -p -t cr $new_comic) 2>&1 > $log_dir\comictagger.log
    get-content -literalpath "$log_dir\comictagger.log" | write-host

    # paso 5 renombro el comic con los datos de los tags obtenidos
    write-host "    >> Renombro el comic con el nombre del TAG de ComicVine"
    (& "C:\Program Files (x86)\ComicTagger\comictagger.exe" -v -r -t cr $new_comic) 2>&1 > $log_dir\comictagger.log
    get-content -literalpath "$log_dir\comictagger.log"
    #! aqui tengo que comprobar que se ha cambiado mirando el log

}


function repuesta_comictagger {
    # Analizo el fichero de log dejado por comictagger, para esto no necesito parametros
    # Pero si devuelvo $true si lo ha encontrado o $false ni no lo ha encontrado 

    if (((get-content -literalpath "$log_dir\comictagger.log") | select-string "Save complete").count -gt 0)
        {
            $encontrado = (get-content -literalpath "$log_dir\comictagger.log") | select-string "----->"
            $encontrado = $encontrado.tostring().split('>')[1].split('-')[0].trim()
            #! Hay que analizar lo que se devuelve con mas detenimiento cuendo son varias lineas
            # $ID = (get-content -literalpath "$log_dir\comictagger.log") | select-string "ID: "
            # $ID = $ID.tostring().split(':')[1].trim().split(' ')[0].trim()
            # write-host "    >> Encontrado comic: $encontrado con el ID: $ID" -ForegroundColor Green
            write-host "    >> Encontrado comic: $encontrado" -ForegroundColor Green
            [int]$comic_encontrado = [int]$comic_encontrado + 1
        
            if ($verbose -eq $true) {
                get-content -literalpath "$log_dir\comictagger.log"
            }
        } else {
            write-host "    >> No se ha encontrado el comic en ComicVine" -ForegroundColor Red
    }

}

