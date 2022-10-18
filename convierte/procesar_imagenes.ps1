function genera_miniatura {
    Param (
        [Parameter(Mandatory=$true)]
        [String] $imagen_origen,
        [Parameter(Mandatory=$true)]
        [String] $ruta_destino
    )
    if ( $verbose -eq $true ) {
        & $mogrify -resize 32x32^! -colorspace Gray -verbose -path $ruta_destino $imagen_origen 2>&1
    } else {
        & $mogrify -resize 32x32^! -colorspace Gray -path $ruta_destino $imagen_origen 2>&1
    }
    #! comprobar que el fichero de destino se ha generado
}

function reprocesar_imagen {
    Param(
        [Parameter(Mandatory=$true)]
        $lista_ficheros,
        [Parameter(Mandatory=$true)]
        [String] $comic_final
    )
    if ( $verbose -eq $true ) {
        if ( $tipo_conversion -eq "baja" ) {
            $lista_ficheros | foreach-object { & $mogrify -verbose -resize 1440x2210^> -format jpg  -path $comic_final $_ 2>&1 } 
        } else {
            $lista_ficheros | ForEach-Object { & $mogrify -verbose -resize 1440x2210^> -format jpg -gamma 2.2 -auto-level -auto-orient -colorspace RGB -quality 65 -sampling-factor 2x2 -depth 24 -interlace line -path $comic_final $_ 2>&1 }
        }
    } else {
        if ( $tipo_conversion -eq "baja" ) {
            $lista_ficheros | foreach-object { & $mogrify -resize 1440x2210^> -format jpg  -path $comic_final $_ 2>&1 }
        } else {
            $lista_ficheros | ForEach-Object { & $mogrify -resize 1440x2210^> -format jpg -gamma 2.2 -auto-level -auto-orient -colorspace RGB -quality 65 -sampling-factor 2x2 -depth 24 -interlace line -path $comic_final $_ 2>&1 }
        }
    }
}


function Get-CompareImage {

    Param (
        [Parameter(Mandatory=$true)]
        [String] $imagen_origen,
        [Parameter(Mandatory=$true)]
        [String] $imagen_almacenada
    )


# Defino los limites para comparar imagenes
[int]$limite_comp_identica = 5
[int]$limite_comp_parecida = 12

# Comparo ambas imagenes y obtengo el porcentaje de similitud.
$comp = (& $compara $imagen_origen -colorspace Gray -metric RMSE $imagen_almacenada $fichero_temporal 2>&1)
[int]$valor_comparacion = [int](($comp -split '\(')[0]) * 100 / 65535

    if ($valor_comparacion -le $limite_comp_identica) {
        # Las imagenes son identicas
        if ( $verbose -eq $true) {
        write-host  "  >>"$imagen_origen " <-> " $imagen_almacenada "`t" $valor_comparacion "`t <--------- IMAGEN IDENTICA" -ForegroundColor DarkYellow
        }
        $v_out = 0
    } else {
        if ($valor_comparacion -ge $limite_comp_identica -and $valor_comparacion -le $limite_comp_parecida) {
            # Las imagenes son parecidas
            if ( $verbose -eq $true) {
            write-host  "  >>"$imagen_origen " <-> " $imagen_almacenada "`t" $valor_comparacion "`t <--------- IMAGEN PARECIDA"  -ForegroundColor DarkYellow
            }
            $v_out = 1
        } else {
            # Si verbose no esta a true no muestro nada
            if ( $verbose -eq $true) {
            # Las imagenes son diferentes
            write-host  $imagen_origen " <-> " $imagen_almacenada "`t" $valor_comparacion "`t <--------- SIN COINCIDENCIA"
            }
            $v_out = 2
            
        }
    }
#######################################################################
#                           Devuelvo
# 0 - Las imagenes son identicas (menor de un 5% de diferencia)
# 1 - Las imagenes son parecidas (entre un 5 y un 10 % de diferencia)
# 2 - Las imagenes son diferentes (mas de un 10% de diferencia)
#######################################################################
return  $v_out
}
