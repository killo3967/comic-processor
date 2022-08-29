# ComicVine API KEY
$Global:comicvine_api_key = "1d15350fce8f46f6d5ce5efadbc7a57e62c834c1"

# DeepL API KEY
$Global:deepl_api_key = "c614d9d4-54dc-f4dd-22b9-6d7daef47864:fx"

# Configuracion General
$Global:verbose = $false

# Configuracion de procesado de las imagenes
$Global:formato_imagen = "jpg"
$Global:compresion = "80"
$Global:correccion_gamma = "2.2"

# Configuracion del comic
$Global:formato_comic = "cbz"

# A continuacion vienen las expresiones REGEX para buscar ciertas cadenas dentro del nombre del directorio o del nombre del comic, que faciliten su scrapping
# Con esta expresion de regex se puede extraer la cadena que contenga el año en $3
# Para que acepte acentos, dieresis y la ñ pongo 'a-zA-ZÀ-ÿ\u00f1\u00d1' 
# Cadenas de busqueda
$Global:cadena_año = '((\(|\[)([a-zA-ZÀ-ÿ\u00f1\u00d1\w\d\s\-\,])*?\s?([(1|2][9|0][67890123]\d)\s?([a-zA-ZÀ-ÿ\u00f1\u00d1\w\d\s\-\,])*?(\)|\]))'
$Global:cadena_issue = '( #| t| t.| T| T.| Tomo| Tomo.|-|-#| )(\d{1,3})'


# Incluir directorio raiz en la lista de directorios a procesar
#! Futuro
$Global:incluir_directorio_raiz = $false

# Mover todos los comics a directorio base y borra todo el arbol de subdirectorios
$Global:un_solo_directorio  = $false

# Renombrado de comics segun datos obtenidos del Scrapping
$Global:renombrar_comics = $true

# Indica que tipo de renombrado sera, de momento solo hay dos. 'Manga' y 'Comics'
$Global:tipo_renombrado = "comics"

# Indica si se buscan imagenes de creditos
$Global:buscar_creditos = $true

# Numero de imagenes al final del comic en las que busco los creditos
[int]$Global:numero_imagenes_creditos = 7       

# Indica si reproceso las imagenes del comic
$Global:reprocesar_imagen = $true

# Indica tipo de procesado de imagenes
$Global:tipo_conversion = "alta"

# Indica si se hace y como se hace el scrapping
$Global:scrapper_comic = $true
$Global:scrapper_overwrite = $true
$Global:scrapper_other_languages = $true
$Global:scrapper_languajes = 'ES,EN,FR'
$Global:limites= "20"                            # Numero maximo de resultados de ComicVine

# Variables del proceso de OCR

# Define el nivel de confianza de lo escaneado
$Global:confianza_ocr = 80                      # Define el nivel de confianza de lo escaneado (cuanto mas se baja mas "ruido" se obtiene)

# Indica si muevo un comic y a donde lo muevo
$Global:mover_comic = $false
$Global:directorio_destino_sin_scrapping = ""
$Global:directorio_destino_con_scrapping = ""


############
# PERFILES #
############
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
    $Global:un_solo_directorio          = $false
    $Global:scrapper_comic              = $false
    $Global:reprocesar_imagen           = $false
    $Global:buscar_creditos             = $false
    $Global:scrapper_overwrite          = $true
    $Global:scrapper_other_languages    = $false
    $Global:tipo_renombrado = "comics"
}

###############################################
###### SELECCIONO EL PERFIL A PROCESAR ########
###############################################

# perfil_nuevo_comic('')
# perfil_manga('')
# perfil_manga_nuevo('')
perfil_solo_scrapping('')
