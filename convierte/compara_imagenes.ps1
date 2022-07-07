###################################################################
###################################################################
####################    FUNCIONES    ##############################
###################################################################
###################################################################



function Get-CompareImage {

    Param (
        [Parameter(Mandatory=$true)]
        [String] $imagen_origen,
        [Parameter(Mandatory=$true)]
        [String] $imagen_almacenada
    )


# Defino los limites para comparar imagenes
[int]$limite_comp_identica = 3
[int]$limite_comp_parecida = 10

# Comparo ambas imagenes y obtengo el porcentaje de similitud.
$comp = (& $compara $imagen_origen -colorspace Gray -metric RMSE $imagen_almacenada $fichero_temporal 2>&1)
[int]$valor_comparacion = [int](($comp -split '\(')[0]) * 100 / 65535

    if ($valor_comparacion -le $limite_comp_identica) {
        # Las imagenes son identicas
        # if ( $verbose -eq $true) {
        write-host  "  >>"$imagen_origen " <-> " $imagen_almacenada "`t" $valor_comparacion "`t <--------- IMAGEN IDENTICA" -ForegroundColor DarkYellow
        # }
        $v_out = 0
    } else {
        if ($valor_comparacion -ge $limite_comp_identica -and $valor_comparacion -le $limite_comp_parecida) {
            # Las imagenes son parecidas
            # if ( $verbose -eq $true) {
            write-host  "  >>"$imagen_origen " <-> " $imagen_almacenada "`t" $valor_comparacion "`t <--------- IMAGEN PARECIDA"  -ForegroundColor DarkYellow
            # }
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
# Devuelvo
# 0 - Las imagenes son identicas
# 1 - Las imagenes son parecidas
# 2 - Las imagenes son diferentes
return  $v_out
}