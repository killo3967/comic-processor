$api_key = "1d15350fce8f46f6d5ce5efadbc7a57e62c834c1"
$url_base = "https://comicvine.gamespot.com/api/volumes/?"
$comic_dir = "D:\PUBLIC\JDOWNLOADER\PRUEBAS"

# Hago una lista de directorios = SERIES
$dir_list = get-childitem $comic_dir -recurse -verbose -directory

# BUCLE PRINCIPAL PARA PROCESAR TODOS LOS DIRECTORIOS
#! coger esto y utilizarlo para buscar las series que puedan ser paracida a los datos que tengo


for ($i=0; $i -lt ($dir_list.count); $i++) {

    # Extraigo el nombre de la serie del nombre de la carpeta, el nombre de la editorial y el año 
    # Lo usase posteriormente en el scrapping si es necesario (Scrapping = Preguntar a ComicVine los datos de cada comic)
    $series_name = $dir_list[$i].name.split("(")[0].trim()
    $ed_name     = $dir_list[$i].name.split("(")[1].split(")")[0].trim()
    $year_name   = $dir_list[$i].name.split("(")[2].split(")")[0].trim()

        
    $campos   = "field_list=name,volume,last_issue,publisher"
    $formato  = "format=json"
    $orden    = "sort=name:asc"
    $filter   = "filter=" + "name:" + ($series_name.tostring())
    #+ ";publisher:" + $ed_name + ";start_year:" + $year_name
    $limites  = "limit=10"

    $v_url = $url_base + "api_key=" + $api_key + "&" + $formato + "&" + $orden + "&" + $filter + "&" + $limites


    # Pregunto por el nombre del comic
       
    $request = Invoke-WebRequest -Uri $v_url -Method Get 
    $respuesta = $request | ConvertFrom-Json -AsHashtable

    if ( $respuesta.number_of_total_results -gt 1000 ){
        # Si el numero de respuestas es mayor de 100 es que no ha encontrado nada
        write-host "NO ENCONTRADO"
        break
    } else {
        write-host $respuesta.error
        # miro si ha respondido bien
        if ( $respuesta.error -eq "OK" ) {
            # miro cada uno de los nombre de los volumenes
            for ( $i = 0 ; $i -lt $respuesta.number_of_page_results ; $i++ ) {
                
                $volumen = $respuesta.results[$i].name   
                $num_comics = $respuesta.results[$i].last_issue.issue_number
                $publisher = $respuesta.results[$i].publisher.name
                
                $site_detail_url = $respuesta.results[$i].site_detail_url
                $id = $respuesta.results[$i].$id

                if ( $volumen -like $series_name -and $publisher.contains($ed_name) ) {
                    # Si el nombre del volumen coincide con el nombre de la serie, entonces es la serie que busco
                    # Si no, entonces es otra serie que tengo que buscar
                    write-host "COMIC: "$volumen
                    write-host "NUMERO DE COMICS: "$num_comics
                    write-host "EDITORIAL: "$editorial
                    write-host "========================================================================================="
                } else {
                    write-host "Comic no encontrado"
                }
            }
        }    
    }
}

<#
Para encontrar una lista de volúmenes basada en algunos criterios de texto:

https://comicvine.gamespot.com/api/volumes/?api_key=YOUR-KEY&format=json&sort=name:asc&filter=name:Walking%20Dead

Para buscar un conjunto de problemas en función de algunos criterios de texto:

https://comicvine.gamespot.com/api/search/?api_key=YOUR-KEY&format=json&sort=name:asc&resources=issue&query=%22Master%20of%20kung%20fu%22

Para encontrar un solo problema basado en una ID:

https://comicvine.gamespot.com/api/issue/4000-14582/?api_key=YOUR-KEY&format=json 

#>