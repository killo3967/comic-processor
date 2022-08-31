##################################
##### CONFIGURACION GENERAL ######
##################################
$Global:comicvine_api_key = "1d15350fce8f46f6d5ce5efadbc7a57e62c834c1"  #? API-KEY DE COMICVINE
$Global:deepl_api_key = "c614d9d4-54dc-f4dd-22b9-6d7daef47864:fx"
$Global:verbose = $false

# A continuacion vienen las expresiones REGEX para buscar ciertas cadenas dentro del nombre del directorio o del nombre del comic, que faciliten su scrapping
# Con esta expresion de regex se puede extraer la cadena que contenga el año en $3
# Para que acepte acentos, dieresis y la ñ pongo 'a-zA-ZÀ-ÿ\u00f1\u00d1' 
# Cadenas de busqueda
$Global:cadena_año = '((\(|\[)([a-zA-ZÀ-ÿ\u00f1\u00d1\w\d\s\-\,])*?\s?([(1|2][9|0][67890123]\d)\s?([a-zA-ZÀ-ÿ\u00f1\u00d1\w\d\s\-\,])*?(\)|\]))'
$Global:cadena_issue = '( #| t| t.| T| T.| Tomo| Tomo.|-|-#| )(\d{1,3})'

#################
##### COMIC #####
#################

$Global:formato_comic = "cbz"                                               #? Formato de fichero de comic. De momento solo esta soportado cbz
$Global:incluir_directorio_raiz = $false                                    #! FUTURO
$Global:un_solo_directorio  = $false                                        #? ¿Meto todos los comics en un solo directorio y borro los subdirectorios?
$Global:renombrar_comics = $true                                            #? ¿ Renombro el fichero segun los datos obtenidps del scrapping ?
$Global:tipo_renombrado = "comics"                                          #? ¿ Como es el tipo de nombre del fichero de comic ?

####################
##### LIMPIEZA #####
####################
$Global:buscar_creditos = $true                                             #? ¿Busco imagenes de creditos?
[int]$Global:numero_imagenes_creditos = 7                                   #? Numero de imagenes a procesar para ver sin son creditos


###################################
##### TRATAMIENTO DE IMAGENES #####
###################################
$Global:formato_imagen = "jpg"                                              #? Formato del fichero de imagen dentro del comic
$Global:compresion = "80"                                                   #? Nivel de compresion para JPEG 
$Global:correccion_gamma = "2.2"                                            #? Correccion gamma para JPEG 
$Global:reprocesar_imagen = $true                                           #? ¿Reproceso las imagenes del comic?
$Global:tipo_conversion = "alta"                                            #? Grado de conversion de las imagenes. Opciones alta/baja


#####################
##### SCRAPPING #####
#####################
$Global:scrapper_comic = $true                                              #? ¿Hago un scrapping del comic?             
$Global:scrapper_overwrite = $true                                          #? ¿Tengo en cuenta el archivo comicinfo.xml existente ?
$Global:scrapper_other_languages = $true                                    #? ¿Buscar el comic en otros idiomas?
$Global:scrapper_languajes = 'ES,EN,FR'                                     #? Lenguaje a los que traduce el comic para buscar en la web


#####################
##### COMICVINE #####
#####################
$Global:client_id = 'client=cvscraper'                                      #? Cadena de cliente en la comunicacion con ComiCVine 
$Global:formato = "format=json"                                             #? Formato de respuesta de ComicVine
$Global:limites= "20"                                                       #? Numero maximo de resultados de ComicVine
$url_base = "https://comicvine.gamespot.com/api/"                           #? URL de la api de ComicVine



################
##### OCR ######
################
$Global:confianza_ocr = 80                                                  #? Define el nivel de confianza de lo escaneado (cuanto mas se baja mas "ruido" se obtiene)


#######################
##### POSTPROCESO #####
#######################
$Global:mover_comic = $false                                                #? ¿Muevo el comic despues de procesarlo?
$Global:directorio_destino_sin_scrapping = ""
$Global:directorio_destino_con_scrapping = ""


#####################
##### PERFILES ######
#####################
Function perfil_nuevo_comic {
    $Global:tipo_conversion                 = "baja"
    $Global:un_solo_directorio              = $true
    $Global:mover_comic                     = $false
    $Global:directorio_destino_sin_scrapping = "Q:\2.- CONVERTIDOS Y RENOMBRADOS"
    $Global:directorio_destino_con_scrapping = "Q:\3.- SCRAPEADOS"
}

Function perfil_comic_procesado {
    $Global:un_solo_directorio  = $false
}

Function perfil_manga {
    $Global:un_solo_directorio  = $false
    $Global:tipo_renombrado     = "manga"
    $Global:buscar_creditos     = $false
    $Global:scrapper_comic      = $false
    $Global:buscar_creditos     = $false

}

Function perfil_manga_nuevo {
    $Global:incluir_directorio_raiz = $true
    $Global:un_solo_directorio      = $true
    $Global:tipo_renombrado         = "manga"
    $Global:buscar_creditos         = $false
    $Global:scrapper_comic          = $false
    $Global:buscar_creditos         = $false
    $Global:tipo_conversion         = "baja"
}

Function perfil_solo_scrapping {
    $Global:un_solo_directorio          = $true
    $Global:scrapper_comic              = $true
    $Global:reprocesar_imagen           = $false
    $Global:buscar_creditos             = $false
    $Global:scrapper_overwrite          = $true
    $Global:scrapper_other_languages    = $true
    $Global:tipo_renombrado             = "comics"
}

###############################################
###### SELECCIONO EL PERFIL A PROCESAR ########
###############################################

# perfil_nuevo_comic('')
# perfil_manga('')
# perfil_manga_nuevo('')
perfil_solo_scrapping('')
