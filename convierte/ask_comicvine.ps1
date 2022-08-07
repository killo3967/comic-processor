$api_key = "1d15350fce8f46f6d5ce5efadbc7a57e62c834c1"
$url_base = "https://comicvine.gamespot.com/api/volumes/?"
$formato = "format=json"

clear-host

# BUSCANDO LA SERIE

$series_name = "Bone parish"
$publisher = ""
$year_name = "2019"
$limites  = "limit=10"

$filter   = "filter=" + "name:" + $series_name 
# + ";publisher:" + $publisher
# + ";start_year:" + $year_name

write-host $filter

$v_url = $url_base + "api_key=" + $api_key + "&" + $formato + "&" + $orden + "&" + $filter + "&" + $limites
$request = Invoke-WebRequest -Uri $v_url -Method Get 
$respuesta = $request | ConvertFrom-Json -AsHashtable

if ( $respuesta.error -eq "OK" ) {
    # miro cada uno de los nombre de los volumenes
    for ( $i = 0 ; $i -lt $respuesta.number_of_page_results ; $i++ ) {
        
        $volumen = $respuesta.results[$i].name   
        # $num_comics = $respuesta.results[$i].last_issue.issue_number
        $publisher = $respuesta.results[$i].publisher.name
        $year = $respuesta.results[$i].start_year
        $site_detail_url = $respuesta.results[$i].site_detail_url
        
        # Primero busco la serie en comicvine
        if ( ($volumen -like $series_name) ) {
            # Quito la comparacion por publisher de momento '-and $publisher.contains($ed_name)'
            # Quito la comparacion por year de momento ' -and ($year -eq $year_name)'

            # Si el nombre del volumen coincide con el nombre de la serie, entonces es la serie que busco
            # Si no, entonces es otra serie que tengo que buscar
            write-host "Identificador:"$i
            write-host "COMIC: "$respuesta.results[$i].name
            write-host "AÑO: "$respuesta.results[$i].start_year
            write-host "NUMERO DE COMICS: "$respuesta.results[$i].count_of_issues
            write-host "EDITORIAL: "$respuesta.results[$i].publisher.name
            write-host "ID: "$respuesta.results[$i].id
            write-host "URL: "$respuesta.results[$i].api_detail_url
            write-host "IMAGEN: "$respuesta.results[$i].image.original_url
            write-host "SITE DETAIL URL: "$respuesta.results[$i].site_detail_url
            write-host "========================================================================================="
            $site_detail_url =  split-path ($respuesta.results[$i].site_detail_url) -leaf
            break
        }
    }
}   
$volumen_id = ($site_detail_url.split('-'))[1].trim()

write-host "BUSCANDO COMICS"
$url_base2 = "https://comicvine.gamespot.com/api/issues/?"
$filter   = "filter=volume:"+$volumen_id
$v_url2 = $url_base2 + "api_key=" + $api_key + "&" + $filter +"&" + $formato
$request2 = Invoke-WebRequest -Uri $v_url2 -Method Get 
$respuesta2 = $request2 | ConvertFrom-Json -AsHashtable

write-host $respuesta2

for ( $i = 0 ; $i -lt $respuesta2.number_of_page_results ; $i++ ){
    write-host $series_name"#"($respuesta2.results[$i].issue_number).trim()" - "$respuesta2.results[$i].name" - "$respuesta2.results[$i].id
}


<#
$repuesta.results[$i] -> responde lo siguiente

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