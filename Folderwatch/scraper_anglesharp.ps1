###########################################################################################
# 
# Descarga comics de la web whotoarsenio.blogspot.com  
#
# Hace falta tener instalado jdownloader y configurado el plugin de 
# vigilancia de carpetas, de forma que coincida donde se deja el json que genera este script
# con donde el jdownloader importa (vigila) estos ficheros.
#
# Este script se queda de fondo ejecutandose a la espera de que en el portapapeles haya una  
# url de esta web. Intentara decodificarla y extraele el nombre de la serie, los comics y sus
# nombres y con todo ello generara un paquete, depues creara un fichero con formato json 
# y extension "crawljob" que dejara en el directorio que vigila el jdownloader. Este, lo importara 
# y bajara los comics al directorio configurado y lo extraera. 
#
# Gracias al modulo para parsear HTML (una belleza)
# https://github.com/AngleSharp/AngleSharp
#
#
# Tomas Platero - V 1.2 - 25/11/2021

#Limpio la pantalla
Clear-Host

# Esto es para comprobar que se ha instalado el modulo de parsing de html de Anglesharp
If ( -Not ([System.Management.Automation.PSTypeName]'AngleSharp.Parser.Html.HtmlParser').Type ) {
    $standardAssemblyFullPath = (Get-ChildItem -Filter '*.dll' -Recurse (Split-Path (Get-Package -Name 'AngleSharp').Source)).FullName | Where-Object { $_ -Like "*standard*" } | Select-Object -Last 1

    Add-Type -Path $standardAssemblyFullPath -ErrorAction 'SilentlyContinue'
} # Terminate If - Not Loaded

# Variables globales del script
$jd_dir = "D:\Folderwatch"                      # Directorio de captura de jdownloader
$down_dir = "D:\PUBLIC\JDOWNLOADER"             # Directorio de descarga de los comics
$jd_downloaded_dir = "D:\Folderwatch\added"     # Directorio de crawlerjob descargados

while ($true) {

    if ((get-clipboard) -like "*://howtoarsenio.blogspot.com*") {

        #Limpio la pantalla
        Clear-Host

        # Capturo el contenido del portapapeles
        $clip = get-clipboard
        write-output "#######################################################################"
        write-output "ENLACE CAPTURADO: $clip"
        write-output "#######################################################################"

        $Request = Invoke-WebRequest -Uri $clip

        $Parser = New-Object AngleSharp.Html.Parser.HtmlParser
        $Parsed = $Parser.ParseDocument($Request.Content)

        # Lista de series
        $ForecastList = $Parsed.All | Where-Object  ClassName -eq 'post hentry' 

        # Creo un blucle para procesar cada entrada que tiene la cadena "post hentry"
        for ( $j = 0 ; $j -lt $forecastlist.length ; $j++) {

            # Obtengo el nombre de la serie
            $series_name = $forecastlist[$j].children[4].textcontent.trim()

            # Obtengo los valores auxiliares. No he podido parsearlos adecuadamente ya que estos datos no estan etiquetados en el codigo HTML
            # y cuesta mucho sacarlos, el codigo es complejo ya que cada vez es diferente.
            # Con este codigo " -replace '<[^>]+>', ';' " convierto todas las etiquetas html/ccs/xml en un ; para poder separarlos
            $aux_data = $Forecastlist[$j].childnodes.where({ $_.ClassName -eq "post-body entry-content" }).childnodes.where({ $_.ChildElementCount -gt '15' }).Innerhtml -replace '<[^>]+>', ';'

            # Ahora quito los ";"" duplicados, los separo y limpio los espacios
            $aux_data = ($aux_data -replace ";{2,}", ';' -split ';').trim()

            # Como queda un elemento sobre otro, busco el texto y lo que viene a continuacion es lo que estoy buscando, aunque no
            # siempre estan y a veces estan otros
            for ( $k = 0 ; $k -lt $aux_data.length ; $k++ ) {
                switch ( $aux_data[$k] ) {
                    "Editorial:" {
                        $aux_editorial = $aux_data[$k + 1].trim()
                        continue
                    }
                    "Año:" {
                        $aux_ano = $aux_data[$k + 1].replace('&nbsp','').trim()
                        continue
                    }
                    "Archivos:" {
                        #! Esto hay que depurarlo un poco mas
                        if ($aux_data[$k + 2] -eq "Actualizable") {
                            $aux_archivos = ($aux_data[$k + 1] + '- ' + $aux_data[$k + 2] + $aux_data[$k + 3]) 
                        }
                        else {
                            $aux_archivos = $aux_data[$k + 1].trim()
                        }
                        $aux_archivos = $aux_archivos -replace '[\(\)\[\]\/\"\n\r]', '' -replace '  ', ' '
                        continue
                    }
                }
            }

            # Ignoro si es titulo es la reseña de un libro o pelicula, por lo que elimino las reseñas.
            if ( ( $series_name -notlike "Reseña*" )  ) {
                
                # Compongo en nuevo nombre de la serie
                $series_name = $series_name + " ($aux_editorial)" + "($aux_ano)" -replace '[\:\\\/\r\n]', ' -'
                
                # He quitado ' + "(comics $aux_archivos)' depues de aux_ano y antes del replace ya que al final no aporta nada

                # Miro si ya lo he bajado, para no volver a bajarlo de nuevo
                # si quisiera volver a bajarlo solo tengo que quitar el fichero con extension crawljob de la carpeta "added"    
                if ( -Not (Test-Path -path "$jd_downloaded_dir\$series_name.crawljob" -PathType Leaf) ) {    
                    # Imprimo nombre y numero
                    write-host "SERIE NUMERO: " ($j + 1)
                    write-host "NOMBRE DE LA SERIE : "$series_name 
                        
                    # Obtengo el numero de ficheros a descargar 
                    $numero = $Forecastlist[$j].childnodes.where({ $_.ClassName -eq "post-body entry-content" }).childnodes.where({ $_.localname -eq 'ul' }).childnodes.where({ $_.localname -eq 'li' }).count
                        
                    write-host "NUMERO DE FICHEROS A DESCARGAR: " $numero

                    # Defino el nombre del fichero que usara jdownloader, Tiene formato json
                    # y estan todos los datos de los ficheros

                    $jd_crawler_file_name = $jd_dir + "\" + $series_name + ".crawljob"

                    # Bucle principal donde se generan los ficheros
                    for ( $i = 0 ; $i -lt $numero ; $i++ ) { 
                        
                        # Obtengo el nombre del comic y la url
                        write-host "FICHERO NUMERO: " ($i + 1)
                        $comic_name = $Forecastlist[$j].childnodes.where({ $_.ClassName -eq "post-body entry-content" }).childnodes.where({ $_.localname -eq 'ul' }).childnodes.where({ $_.localname -eq 'li' }).children[$i].textcontent
                        $url_path = $Forecastlist[$j].childnodes.where({ $_.ClassName -eq "post-body entry-content" }).childnodes.where({ $_.localname -eq 'ul' }).childnodes.where({ $_.localname -eq 'li' }).children[$i].href
                        write-host "       NOMBRE :"$comic_name"   URL:"$url_path
                        
                        # Comienzo la creacion del fichero si i=0 o añado para cualquier otro valor
                        if ( $i -eq 0 ) {
                            # Primer bucle y creacion del fichero
                            $f_inicio = '[' 
                            $f_inicio | out-file -filepath $jd_crawler_file_name -encoding "utf8"
                            $f_abre = '{'    
                        }
                        else {
                            # A partir del primer bucle se añade
                            $f_abre = ',{'
                        }

                        # Defino las variables a usar en la creacion del ficher
                        $f_extractpassword = '"extractPasswords": ["", ""],'
                        $f_downloadpassword = '"downloadPassword": "",'
                        $f_enabled = '"enabled": "TRUE",' 
                        $f_text = '"text": "' + $url_path + '",'
                        $f_packageName = '"packageName": "' + $series_name + '",'
                        $f_comment = '"comment": "Descargado con script en powershell",'
                        $f_autoconfirm = '"autoConfirm": "TRUE",'
                        $f_autostart = '"autoStart": "TRUE",'
                        $f_extract = '"extractAfterDownload": "TRUE",'
                        $f_forcestart = '"forcedStart": "TRUE",'
                        $f_downloadFolder = '"downloadFolder": "' + ($down_dir.replace('\', '\\')) + "\\" + $series_name + '",'
                        $_overwritePackagizerEnabled = '"overwritePackagizerEnabled": true'
                        $f_cierra = '}' 

                        write-host "CREANDO FICHERO DE DESCARGA (CRAWLJOB) PARA JDOWNLOADER"
                        # Creo el fichero, con formato json,  para pasarlo a JDownloader 
                        #! Ojo es muy delicado, no moficiar la estructura.
                        # Esta en beta en el jdownloader y cualquier minimo cambio hace que deje de funcionar
                        # Esto me ha llevado varias horas y puede dejar de uncionar en la proxima actualizacion
                        
                        $f_abre | out-file -filepath $jd_crawler_file_name -append -encoding "utf8" 
                        $f_extractpassword | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_downloadpassword | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_enabled | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_text | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_packageName | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_autoconfirm | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_comment | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_autostart | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_extract | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_forcestart | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_downloadFolder | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $_overwritePackagizerEnabled | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                        $f_cierra | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                    }
                    # Se termino el bucle y ahora escribo el fin del fichero
                    $f_fin = ']'
                    $f_fin | out-file -filepath $jd_crawler_file_name -append -encoding "utf8"
                }
                # Ya he descargado anteriormente esta serie
                else { write-host "SERIE: $series_name"
                        write-host "ESTA SERIE YA SE HA DESCARGADO" 
                } 
            }
            # Esto no son comics, es una Reseña
            else { 
                write-host "$series_name  (IGNORANDOLO)" 
            }
            
            write-host ==========================================================================================================================================
        }
        write-host "!!!!! SE HA TERMINADO DE PROCESAR TODA LA PAGINA !!!!!!"
        
        # borro el clipboard para que no se ejecute de nuevo
        set-clipboard -value $null      

    
    } # fin del if del clipboard

    #espero 3 segundos para el siguiente bucle
    Start-Sleep -Seconds 2
    write-host "." -NoNewline

} # fin del while 