# $api_key = "1d15350fce8f46f6d5ce5efadbc7a57e62c834c1"
# $url_base = "https://comicvine.gamespot.com/api/volumes/?"

function get-serie_cv {

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
        [String]$in_comic_path,

        [Parameter()]
        [String]$in_num_issues
         )


#   

    # Numero de maximo de resultados a mostrar

    $url_base = "https://comicvine.gamespot.com/api/search/?"
    $v_url = $url_base + "api_key=" + $api_key + "&" + $client_id + "&" + $formato + "&" + $limites + "&resource=volume" + "&query=" + $series_name.trim()
    $url_escaped  = [Uri]::EscapeUriString($v_url)
    $request = Invoke-WebRequest -Uri $url_escaped -Method Get 
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
                $site_detail_url    = $respuesta.results[$i].site_detail_url
                $issue              = $in_issue
                $id                 = $respuesta.results[$i].id
                $Series              = $respuesta.results[$i].name
                
                # Busco una serie en comicvine que coincida con los siguientes parametros:
                $busqueda1 = $volumen -like $in_series_name
                $busqueda2 = $publisher.contains($in_publisher)
                $busqueda3 = ($volume_year -in ([int]$in_year-1)..([int]$in_year+1))
                $busqueda4 = $num_comics -ge $in_num_issues

                $busqueda2 = $true          # hasta que haga OCR
                $busqueda3 = $true          # hasta que haga OCR

                if ( $busqueda1 -and $busqueda2 -and $busqueda3 -and  $busqueda4 ) {
                    write-host "CUMPLE TODOS LOS PARAMETROS" -BackgroundColor Green -ForegroundColor White
                    # Si el nombre del volumen coincide con el nombre de la serie, entonces es la serie que busco
                    # Si no, entonces es otra serie que tengo que buscar
                    write-host "Identificador:"$i
                    write-host "COMIC: "$series
                    write-host "ISSUE: $issue" 
                    write-host "AÑO: "$volume_year
                    write-host "NUMERO DE COMICS: "$num_comics
                    write-host "EDITORIAL: "$publisher
                    write-host "ID: "$respuesta.results[$i].id
                    write-host "URL: "$respuesta.results[$i].api_detail_url
                    write-host "ID: "$id

                    # Cargo los datos que he obtenido de comicvine en la variable xml
                    $comicinfo_xml.ComicInfo.comicvine_volume_id = $id
                    $comicinfo_xml.ComicInfo.Series     = $volumen
                    $comicinfo_xml.ComicInfo.Volume     = $volume_year
                    $comicinfo_xml.ComicInfo.Publisher  = $publisher
                    $comicinfo_xml.ComicInfo.Count      = $num_comics
                    $comicinfo_xml.ComicInfo.Notes      = "Creado por Comic-Convert"
                    $comicinfo_xml.ComicInfo.Number     = $issue
                    $comicinfo_xml.ComicInfo.Series     = $series

                    # Preparo las imagenes de las portadas del comic y de comicvine para compararlas

                    # Descargo la imagen de la serie ( que es la del primer comic )     
                    if ( $issue -eq 1 ) {
                        # Si el issue es 1
                        $url = $respuesta.results[$i].image.original_url
                    } else {
                        # Si es otro issue hay que buscar la imagen de ese comic
                        $url = get-issue_image_cv
                    }
                    $out_image = $scrapping_cache_dir + "\" + $series + " #" + $issue + " de $num_comics " + "($id , " + (split-path $site_detail_url -leaf) + ")" + "($publisher)" + "($volume_year)"+".jpg"
                    Invoke-WebRequest -uri $url -Method Get -OutFile $out_image


                    # Comprimo la imagen 
                    & $mogrify -resize 32x32^! -colorspace Gray -verbose -path $scrapping_temp_dir $out_image 2>&1 | Out-Null

                    # Imagen comprimida
                    $out_image_compressed = $scrapping_temp_dir + "\" + (get-childitem $out_image).name

                    # Comprimo la primera imagen de la serie 
                    $portada = (get-childitem $comic_final_dir)[0].fullname
                    & $mogrify -resize 32x32^! -colorspace Gray -verbose -path $scrapping_temp_dir $portada 2>&1 | out-null
                    $portada_comprimida = $scrapping_temp_dir + "\" + (get-childitem $portada).name

                    # Comparo la portada con la imagen comprimida
                    $vine_compara = Get-CompareImage $portada_comprimida $out_image_compressed
                    
                    if ($vine_compara -eq 0){
                        # write-host "SITE DETAIL URL: "$site_detail_url
                        write-host "Las portadas son iguales ->>>> SERIE IDENTIFICADA: $id" -ForegroundColor green
                        #! Aqui puede venir lo de sustituir la portada por la original. 
                        
                        break
                    } else {
                        write-host "Las imagenes son diferentes, se trata de otro comic o de otra portada alternativa"
                        
                    }
                  
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
                        write-host "    >> NO CUMPLE CON EL NUMERO DE COMICS: "$num_comics" es mayor o igual a "$num_comics
                    } else {
                        write-host "    >> CUMPLE CON EL NUMERO DE COMICS: "$num_comics" es mayor o igual a "$num_comics
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



function get-seriesdetail_cv {
        
    $series_id = $comicinfo_xml.ComicInfo.comicvine_volume_id
    
    # Obtiene los valores requeridos de la serie
    $url_base2 = "https://comicvine.gamespot.com/api/volume/4050-$series_id/?"
    $v_url2 = $url_base2 + "api_key=" + $api_key + "&" + $client_id + "&" + $formato + "&" + $limites 
    $url_escaped2 = [Uri]::EscapeUriString($v_url2)
    $request2 = Invoke-WebRequest -Uri $url_escaped2 -Method Get 
    $respuesta2 = $request2 | ConvertFrom-Json -AsHashtable

    $Locations = $respuesta2.results.locations.name
    $issue = $comicinfo_xml.ComicInfo.Number
    
    # Extraigo los datos de comicvine
    $comic_name = $respuesta2.results.issues[[int]($issue-1)].name
    $comic_id = $respuesta2.results.issues[[int]($issue-1)].id
    $comic_web = $respuesta2.results.issues[[int]($issue-1)].site_detail_url
    $issue = $respuesta2.results.issues[[int]($issue-1)].issue_number

    # Meto los datos de la serie en el array XML
    $comicinfo_xml.ComicInfo.Title              = $comic_name                         
    $comicinfo_xml.ComicInfo.comicvine_issue_id = $comic_id
    $comicinfo_xml.ComicInfo.Web                = $comic_web
    $comicinfo_xml.ComicInfo.Locations          = $Locations
}

function get-issue_image_cv {
    $issue = $comicinfo_xml.ComicInfo.Number
    $volumen_id = $comicinfo_xml.ComicInfo.comicvine_volume_id
    $url_base2 = "https://comicvine.gamespot.com/api/issues/?"
    $filter   = "filter=volume:" + $volumen_id
    $v_url2 = $url_base2 + "api_key=" + $api_key + "&" + $client_id  + "&" + $filter +"&" + $formato
    $request2 = Invoke-WebRequest -Uri $v_url2 -Method Get 
    $respuesta2 = $request2 | ConvertFrom-Json -AsHashtable
    $imagen = $respuesta2.results[[int]($issue-1)].image.original_url
return $imagen
}

function get-issuedetail_cv{
    
    $comic_id = $comicinfo_xml.ComicInfo.comicvine_issue_id
    $url_base4 = "https://comicvine.gamespot.com/api/issue/4000-$comic_id/?"
    $v_url4 = $url_base4 + "api_key=" + $api_key + "&" + $client_id + "&" + $formato 
    $request4 = Invoke-WebRequest -Uri $v_url4 -Method Get 
    $respuesta4 = $request4 | ConvertFrom-Json -AsHashtable

    # Obtengo los datos de comicvine
    $year = ($respuesta4.results.store_date -split '-')[0]
    $month = ($respuesta4.results.store_date -split '-')[1]
    $day = ($respuesta4.results.store_date -split '-')[2]

    # Carga y limpieza del campo summary
    $summary = $respuesta4.results.description
    $summary = $summary -replace "<[bB][rR] ?/?>|<[Pp] ?>","`r`n"
    $summary = $summary -replace " {2,}"," "
    $summary = $summary -replace "&nbsp;?", " "
    $summary = $summary -replace "<.*?>" , ""
    $summary = $summary -replace '&amp;', '&'
    $summary = $summary -replace '&quot;', '"'
    $summary = $summary -replace '&lt;', '<'
    $summary = $summary -replace '&gt;', '>'
    $summary = $summary -replace "(?is)list of covers.*$",""
    $summary = $summary.trim()

    # Datos del comic los meto en el array XML
    $comicinfo_xml.ComicInfo.Summary    = $summary
    $comicinfo_xml.ComicInfo.Year       = $year
    $comicinfo_xml.ComicInfo.month      = $month
    $comicinfo_xml.ComicInfo.day        = $day
    $comicinfo_xml.ComicInfo.PageCount  = (get-childitem -literalpath $comic_final_dir -file -include *.png,*.jpg,*.webp).count

    # Para obtener los creaores del comic
    for ( $d = 0 ; $d -lt ($respuesta4.results.person_credits.count) ; $d++ ) {
        switch ($respuesta4.results.person_credits[$d].role) {
            'cover'       { $comicinfo_xml.ComicInfo.CoverArtist    = $respuesta4.results.person_credits[$d].name }
            'writer'      { $comicinfo_xml.ComicInfo.Writer         = $respuesta4.results.person_credits[$d].name }
            'artist'      { $comicinfo_xml.ComicInfo.inker          = $respuesta4.results.person_credits[$d].name }
            'colorist'    { $comicinfo_xml.ComicInfo.colorist       = $respuesta4.results.person_credits[$d].name }
            'letterer'    { $comicinfo_xml.ComicInfo.letterer       = $respuesta4.results.person_credits[$d].name }
            'penciller'   { $comicinfo_xml.ComicInfo.penciller      = $respuesta4.results.person_credits[$d].name }
            'editor'      { $comicinfo_xml.ComicInfo.editor         = $respuesta4.results.person_credits[$d].name }
        }
    }

    # Personajes del comic
    $comicinfo_xml.ComicInfo.Characters     = $respuesta4.results.character_credits.name -join', '
    $comicinfo_xml.ComicInfo.Storyarc       = $respuesta4.results.story_arc_credits
    $comicinfo_xml.ComicInfo.Teams          = $respuesta4.results.team_disbanded_in
}


<#
function get-issuelist_cv {
    
    # Conociendo la url de la serie, busco los comics de la serie
    $volumen_id = ((split-path $site_detail_url -leaf).split('-'))[1].trim()
    write-host "BUSCANDO COMICS"
    $url_base2 = "https://comicvine.gamespot.com/api/issues/?"
    $filter   = "filter=volume:"+$volumen_id
    $v_url2 = $url_base2 + "api_key=" + $api_key + "&" + $client_id + "&" + $filter +"&" + $formato
    $request2 = Invoke-WebRequest -Uri $v_url2 -Method Get 
    $respuesta2 = $request2 | ConvertFrom-Json -AsHashtable

    for ( $i = 0 ; $i -lt $respuesta2.number_of_page_results ; $i++ ){
        write-host $series_name"#"($respuesta2.results[$i].issue_number).trim()" - "$respuesta2.results[$i].name" - "$respuesta2.results[$i].id
        $url_base3 = "https://comicvine.gamespot.com/api/issues/?"
        $filter   = "filter=volume:"+$volumen_id
        $v_url3 = $url_base3 + "api_key=" + $api_key + "&" + $formato + "&" + $filter 
        $request3 = Invoke-WebRequest -Uri $v_url3 -Method Get 
        $respuesta3 = $request3 | ConvertFrom-Json -AsHashtable
    
        # write-host $respuesta3.results
        $comic_id=$respuesta3.results[$i].id
        get-issuedetail_cv $comic_id
    }
}
#>

<#

#>


<#
DATOS DE UN VOLUMEN
===================
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


DATOS DE UN COMIC
=================
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


DETALLES DE UN COMIC
====================
Name                           Value
----                           -----
first_appearance_concepts
api_detail_url                 https://comicvine.gamespot.com/api/issue/4000-767894/
volume                         {name, id, api_detail_url, site_detail_url}
story_arc_credits              {}
date_added                     2020-06-13 02:52:21
object_credits                 {}
first_appearance_teams
issue_number                   1
name
first_appearance_locations
id                             767894
location_credits               {}
store_date                     2020-06-10
first_appearance_characters
cover_date                     2020-06-13
first_appearance_storyarcs
character_died_in              {}
aliases
team_disbanded_in              {}
has_staff_review               False
site_detail_url                https://comicvine.gamespot.com/adventureman-1/4000-767894/
first_appearance_objects
person_credits                 {Clayton Cowles, Lauren Sankovitch, Leonardo Olea, Matt Fraction…}
concept_credits                {}
date_last_updated              2020-06-13 04:16:36
description                    <p><em>SERIES PREMIERE!</em></p><p><em>A CATACLYSMIC ADVENTURE DECADES IN THE MAKING!</em></p><p><em>In this WILDLY AF…team_credits                   {}
character_credits              {Adventureman, Akaal, Baron Bizarre, Baroness Bizarre…}
associated_images              {}
image                          {medium_url, image_tags, screen_large_url, icon_url…}
deck

#>
