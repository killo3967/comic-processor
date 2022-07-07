# Comparacion de imagenes

# Basado en el codigo del pluging de comicvine para comicrack y he visto que hace referencia a 
# https://www.memonic.com/user/aengus/folder/coding/id/1qVeq
# Basicamente lo que se dice aqui es que para comparar dos imagenes hay que comprimirlas
# a 32x32, convertirlas a escala de grises y despues compararlas.
# No he copiado el codigo del pluging, sino que lo he adaptado al uso con ImageMagick


# Rutas de los ejecutables de imagemagick
$img_dir = "C:\Program Files\ImageMagick-7.1.0-Q16-HDRI"
$compara    = "$img_dir\compare.exe"
$convierte  = "$img_dir\convert.exe"

# Defino el nombre de las imagenes
# $imagen_origen        = "C:\scripts\convierte\temp\escape.jpg"
$directorio_origen    = "C:\scripts\convierte\temp"
$directorio_credito  = "C:\scripts\convierte\credits"
$imagen_origen2       = "C:\windows\temp\escape2.jpg"
$imagen_credito2      = "C:\windows\temp\escape3.jpg"
$fichero_temporal     = "C:\windows\temp\temp.jpg"

# Defino los limites para comparar imagenes
[int]$limite_comp_identica = 6
[int]$limite_comp_parecida = 13




# Busco en el directorio de imagenes los archivos que sean parecidos a la imagen original
$numero_imagenes = (get-childitem -literalpath $directorio_origen -file).count
for ( $i = $numero_imagenes - 4 ; $i -lt $numero_imagenes ; $i++ ) {
    
    $imagen_origen = (get-childitem -literalpath $directorio_origen)[$i].fullname
    write-host "Imagen origen: $imagen_origen"
    # Empiezo comprimiendo la imagen original a 32x32 en escala de grises
    & $convierte $imagen_origen -resize 32x32 -colorspace Gray $imagen_origen2

    # Busco en el directorio de creditos los archivos que sean parecidos a la imagen original
    $numero_creditos = (get-childitem -literalpath $directorio_creditos -file).count
    for ( $j = 0 ; $j -lt $numero_creditos ; $j++ ) {    
        
        $imagen_credito = (get-childitem -literalpath $directorio_credito -file)[$j].fullname

        # Convierto la imagen almacenada / descargada a 32x32 en escala de grise
        (& $convierte $imagen_credito -resize 32x32 -colorspace Gray $imagen_credito2)

        # Comparo ambas imagenes y obtengo el porcentaje de similitud.
        $comp1 = (& $compara $imagen_origen2 -colorspace Gray -metric RMSE $imagen_credito2 $fichero_temporal 2>&1)
        [int]$valor_comparacion = [int](($comp1 -split '\(')[0]) * 100 / 65535

        if ($valor_comparacion -le $limite_comp_identica) {
            # Las imagenes son identicas
            write-host  $imagen_origen " <-> " $imagen_credito "`t" $valor_comparacion`% "`t <--------- IMAGEN IDENTICA"
            
        } else {
            if ($valor_comparacion -ge $limite_comp_identica -and $valor_comparacion -le $limite_comp_parecida) {
                # Las imagenes son parecidas
                write-host  $imagen_origen " <-> " $imagen_credito "`t" $valor_comparacion`% "`t <--------- IMAGEN PARECIDA" 
            } else {
                # Las imagenes son diferentes
                # write-host  $imagen_origen " <-> " $imagen_credito "`t" $valor_comparacion`% "`t <--------- SIN COINCIDENCIA"
            }
        }
    }
       
}



