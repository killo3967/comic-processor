$api_key = "1d15350fce8f46f6d5ce5efadbc7a57e62c834c1"
$url_base = "https://comicvine.gamespot.com/api/volumes/?"
$formato = "format=json"

function lista_comics_comicvine {
    Param (
        [Parameter(Mandatory = $true)]
        [String] $site_detail_url
    )
# Conociendo la url de la serie, busco los comics de la serie
    $volumen_id = ((split-path $site_detail_url -leaf).split('-'))[1].trim()
    write-host "BUSCANDO COMICS"
    $url_base2 = "https://comicvine.gamespot.com/api/issues/?"
    $filter   = "filter=volume:"+$volumen_id
    $v_url2 = $url_base2 + "api_key=" + $api_key + "&" + $filter +"&" + $formato
    $request2 = Invoke-WebRequest -Uri $v_url2 -Method Get 
    $respuesta2 = $request2 | ConvertFrom-Json -AsHashtable

    for ( $i = 0 ; $i -lt $respuesta2.number_of_page_results ; $i++ ){
        write-host $series_name"#"($respuesta2.results[$i].issue_number).trim()" - "$respuesta2.results[$i].name" - "$respuesta2.results[$i].id
    }
}

clear-host

function busca_serie_comicvine {

    Param (
        [Parameter()]
        [String]$in_series_name,
    
        [Parameter()]
        [String]$in_issue,

        [Parameter()]
        [String]$in_year,

        [Parameter()]
        [String]$in_publisher,

        [Parameter()]
        [String]$in_comic_path
         )


#   $series_name = "A Righteous Thirst for Vengeance"
#   $publisher = "Image"
#   $year_name = "2021"

    # Numero de maximo de resultados a mostrar
    $limites  = "limit=10"
    $filter   = "filter=" + "name:" + $series_name.trim() 
    # + ";publisher:" + $publisher
    # + ";start_year:" + $year_name
    $num_files = (get-childitem -literalpath $in_comic_path -file -include ('*.cbr','*.cbz')).count

    $v_url = $url_base + "api_key=" + $api_key + "&" + $formato + "&" + $orden + "&" + $filter + "&" + $limites
    $Escaped  = [Uri]::EscapeUriString($v_url)
    $request = Invoke-WebRequest -Uri $Escaped -Method Get 
    $respuesta = $request | ConvertFrom-Json -AsHashtable

    if ( $respuesta.error -eq "OK" ) {
        # miro cada uno de los nombre de los volumenes
        if ($respuesta.number_of_page_results -gt 0) { 
            for ( $i = 0 ; $i -lt $respuesta.number_of_page_results ; $i++ ) {
                
                $volumen            = $respuesta.results[$i].name  
                write-host "ENCONTRADO VOLUMEN: "$volumen
                $num_comics         = $respuesta.results[$i].count_of_issues
                $publisher          = $respuesta.results[$i].publisher.name
                $volume_year        = $respuesta.results[$i].start_year
                $issue              = $respuesta.results[$i].issue_number
                $site_detail_url    = $respuesta.results[$i].site_detail_url
                $issue              = $respuesta.results[$i].issue_number
                $id                 = $respuesta.results[$i].id
                $comic              = $respuesta.results[$i].name
                
                # Busco una serie en comicvine que coincida con los siguientes parametros:
                $busqueda1 = $volumen -like $in_series_name
                $busqueda2 = $in_publisher.contains($publisher)
                $busqueda3 = ($volume_year -in ([int]$in_year-1)..([int]$in_year+1))
                $busqueda4 = $num_comics -ge $num_files

                # if ( $busqueda1 -and $busqueda2 -and $busqueda3 -and  $busqueda4 ) {
                if ( $busqueda1 -and $busqueda3 ) {
                    write-host "CUMPLE TODOS LOS PARAMETROS" -BackgroundColor Green -ForegroundColor White
                    # Si el nombre del volumen coincide con el nombre de la serie, entonces es la serie que busco
                    # Si no, entonces es otra serie que tengo que buscar
                    write-host "Identificador:"$i
                    write-host "COMIC: "$comic
                    write-host "ISSUE: 001" 
                    write-host "AÑO: "$volume_year
                    write-host "NUMERO DE COMICS: "$num_comics
                    write-host "EDITORIAL: "$publisher
                    write-host "ID: "$respuesta.results[$i].id
                    write-host "URL: "$respuesta.results[$i].api_detail_url
                    write-host "ID: "$id
                        $url = $respuesta.results[$i].image.original_url
                        $out_image = $scrapping_cache_dir + "\" + $comic + " #" + $issue + "1 de $num_comics " + "($id , " + (split-path $site_detail_url -leaf) + ")" + "($publisher)" + "($volume_year)"+".jpg"
                        Invoke-WebRequest -uri $url -Method Get -OutFile $out_image
                        # Comprimo la imagen 
                        & $mogrify -resize 32x32^! -colorspace Gray -verbose -path $scrapping_temp_dir $out_image
                        # Imagen comprimida
                        $out_image_compressed = $scrapping_temp_dir + "\" + (get-childitem $out_image).name
                        # Comprimo la primera imagen de la serie
                        $portada = (get-childitem $comic_final)[0].fullname
                        & $mogrify -resize 32x32^! -colorspace Gray -verbose -path $scrapping_temp_dir $portada
                        $portada_comprimida = $scrapping_temp_dir + "\" + (get-childitem $portada).name
                        # comparo la portada con la imagen comprimida
                        $vine_compara = Get-CompareImage $portada_comprimida $out_image_compressed
                    
                        # if ($vine_compara )
                    
                        write-host "SITE DETAIL URL: "$site_detail_url
                    lista_comics_comicvine -site_detail_url $site_detail_url
                    break
                } else {
                    write-host "NO CUMPLE CON LOS PARAMETROS" -BackgroundColor Red -ForegroundColor White
                    if ($false -eq $busqueda1) {
                        write-host "    >> NO CUMPLE CON EL NOMBRE DE LA SERIE: "$volumen" no se parece a "$in_series_name
                    } else { 
                        write-host "    >> CUMPLE CON EL NOMBRE DE LA SERIE: "$volumen" se parece a "$in_series_name
                    }
                    if ($false -eq $busqueda2) {
                        write-host "    >> NO CUMPLE CON EL EDITORIAL: "$publisher" no se parece a "$in_publisher
                    } else {
                        write-host "    >> CUMPLE CON EL EDITORIAL: "$publisher" se parece a "$in_publisher
                    } 
                    if ($false -eq $busqueda3) {
                        write-host "    >> NO CUMPLE CON EL AÑO: "$volume_year" no se parece a "$in_year
                    } else {
                        write-host "    >> CUMPLE CON EL AÑO: "$volume_year" se parece a "$in_year
                    } 
                    if ($false -eq $busqueda4) {
                        write-host "    >> NO CUMPLE CON EL NUMERO DE COMICS: "$num_comics" no se parece a "$num_files
                    } else {
                        write-host "    >> CUMPLE CON EL NUMERO DE COMICS: "$num_comics" se parece a "$num_files
                    }
                }
                
            }
        } else {    
           write-host "NO SE ENCONTRO NINGUN VOLUMEN" -BackgroundColor Red -ForegroundColor White
        }
        # Separacion entre volumenes
        write-host "========================================================================================="
    }   
    
}


<#

clear-host 
write-host "=================="
write-host " INICIO DEL SCRIPT "
write-host "=================="  
get-childitem "D:\PUBLIC\JDOWNLOADER" -directory | ForEach-Object {

    $comic_path = $_
    $series_name = ((split-path $comic_path -leaf).split('('))[0].trim()
    $volume_year = ((split-path $comic_path -leaf).split('('))[1].replace(')','').trim()
    $publisher = ((split-path $comic_path -leaf).split('('))[2].replace(')','').trim()

    write-host "Buscando: "$series_name" | 1 | "$publisher" | "$volume_year 

    busca_serie_comicvine $series_name "1" $publisher $volume_year $_.name
}


Datos de un Volumen

Name                           Value
----                           -----
start_year                     2019
first_issue                    {issue_number, id, api_detail_url, name}
aliases
count_of_issues                18
description                    <p>Eighteen issue sequel to <a href="/descender/4050-80426/" data-ref-id="4050-80426">Descende…deck
publisher                      {id, api_detail_url, name}
image                          {thumb_url, original_url, image_tags, super_url…}
last_issue                     {issue_number, id, api_detail_url, name}
date_added                     2019-04-23 13:42:45
name                           Ascender
site_detail_url                https://comicvine.gamespot.com/ascender/4050-118500/
api_detail_url                 https://comicvine.gamespot.com/api/volume/4050-118500/
date_last_updated              2021-10-08 20:25:44
id                             118500

Datos de un comic

Name                           Value
----                           -----
store_date                     2021-10-06
associated_images              {8189500, 8189499, 8189498, 8189497…}
date_last_updated              2021-10-08 20:38:42
issue_number                   1
deck
api_detail_url                 https://comicvine.gamespot.com/api/issue/4000-888679/
id                             888679
image                          {medium_url, tiny_url, screen_url, super_url…}
volume                         {site_detail_url, api_detail_url, id, name}
has_staff_review               False
date_added                     2021-10-08 20:16:12
aliases
site_detail_url                https://comicvine.gamespot.com/a-righteous-thirst-for-vengeance-1/4000-888679/
description                    <p><em>A NEW ONGOING CRIME SERIES from the writer of <strong>DEADLY CLASS</strong>!</em></p><p><em>When an unassumi…name
cover_date                     2021-10-08

#>



<#
Para encontrar una lista de volúmenes basada en algunos criterios de texto:

https://comicvine.gamespot.com/api/volumes/?api_key=YOUR-KEY&format=json&sort=name:asc&filter=name:Walking%20Dead

Para buscar un conjunto de issues en función de algunos criterios de texto:

https://comicvine.gamespot.com/api/search/?api_key=YOUR-KEY&format=json&sort=name:asc&resources=issue&query=%22Master%20of%20kung%20fu%22

Para encontrar un solo issue basado en una ID:

https://comicvine.gamespot.com/api/issue/4000-14582/?api_key=YOUR-KEY&format=json 


Preguntar por los publisher con un determinado nombre:
$v_url="https://comicvine.gamespot.com/api/search/?api_key=1d15350fce8f46f6d5ce5efadbc7a57e62c834c1&format=json&sort=name:asc&query=publisher:Image"

Preguntar por los issues de un volumen 
https://comicvine.gamespot.com/api/issues/?api_key=1d15350fce8f46f6d5ce5efadbc7a57e62c834c1&filter=volume:118500&format=json&limit=20


#>