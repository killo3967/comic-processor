##################################
##### CONFIGURACION GENERAL ######
##################################
$Global:comicvine_api_key = "1d15350fce8f46f6d5ce5efadbc7a57e62c834c1"               #? API-KEY DE COMICVINE
$Global:deepl_api_key = "c614d9d4-54dc-f4dd-22b9-6d7daef47864:fx"                    #? API-KEY de DeepL
$Global:verbose = $false
$Global:user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'                    #? User-Agent para peticiones HTTP

# A continuacion vienen las expresiones REGEX para buscar ciertas cadenas dentro del nombre del directorio o del nombre del comic, que faciliten su scrapping

# Con esta expresion de regex se puede extraer la cadena que contenga el año en $3
# Para que acepte acentos, dieresis y la ñ pongo 'a-zA-ZÀ-ÿ\u00f1\u00d1' 
$Global:cadena_año = '((\(|\[)([a-zA-ZÀ-ÿ\u00f1\u00d1\w\d\s\-\,])*?\s?([(1|2][9|0][67890123]\d)\s?([a-zA-ZÀ-ÿ\u00f1\u00d1\w\d\s\-\,])*?(\)|\]))'
$Global:cadena_issue = '( #| t| t.| T| T.| Tomo| Tomo.|-|-#| )(\d{1,3})'

# La siguiente cadena es para buscar el ISBN del OCR de la imagen del comic. A veces el OCR interpreta el guion por un punto
$Global:cadena_isbn = '(I\.?S\.?B\.?N\.?\s*?:?\s*?)((((978|979)(\-|\.)?)?(\d{1,5}(\-|\.)?)(\d{1,5}(\-|\.)?)(\d{1,5}(\-|\.)?)(\d|X)))(.*)'


# La siguiente caena es para extraer el año y el publisher del path del comic
# El publisher esta en el grupo 4 y el año en eñ grupo 9
$Global:cadena_publisher_year = '(.*)((\(|\[)(.*)(\)|\]))\s?((\(|\[)([a-zA-ZÀ-ÿ\u00f1\u00d1\w\d\s\-\,])*?\s?([(1|2][9|0][67890123]\d)\s?([a-zA-ZÀ-ÿ\u00f1\u00d1\w\d\s\-\,])*?(\)|\]))'


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
$Global:buscar_creditos = $true                                             #? ¿Busco y borro imagenes de creditos?
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
$Global:scrapper_cvcomic = $true                                            #? Mirar si existe cvcomic.* y tenerlo en cuenta para el scrapping.
                                                                            #? Esto hara que no se mire otros datos del comic y que solo se tenga  
                                                                            #? en cuenta el numero del comic
$Global:scrapper_cvcomic_image = $true                                      #? Indica si hay que comparar las portadas de los comics durante
                                                                            #? el scrapping usando los datos del fichero cvcomic                                                                            

#####################
##### COMICVINE #####
#####################
$Global:client_id = 'client=cvscraper'                                      #? Cadena de cliente en la comunicacion con ComiCVine 
$Global:formato = "format=json"                                             #? Cadena de formato de respuesta de ComicVine
$Global:limites= "20"                                                       #? Numero maximo de resultados de ComicVine
$url_base = "https://comicvine.gamespot.com/api/"                           #? URL de la api de ComicVine



################
##### OCR ######
################
$Global:confianza_ocr = 60                                                  #? Define el nivel de confianza de lo escaneado
                                                                            #? Cuanto mas se bajo, mas "ruido" se obtiene


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

Function perfil_solo_limpieza {
    $Global:tipo_conversion                 = "baja"
    $Global:un_solo_directorio              = $false
    $Global:buscar_creditos                 = $true
    $Global:scrapper_comic                  = $false
    $Global:mover_comic                     = $false
    $Global:tipo_renombrado                 = "comics"
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
# perfil_solo_scrapping('')
perfil_solo_limpieza('')
