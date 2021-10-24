# Esto sirve para ordenar mis descargas

$limpiar = @(
    'www.*.com'
    'pct*.*'
    'maxi*.*'
    'DVDRIP'
    'XviD'
    'castellano'
    '(HDRip)'
    'BD1080'
    'm1080?'
    'AC3'
    '5.1'
    'ingles'
)

$root_dir="D:\PUBLIC\INCOMING\radarr\"
$7z="C:\program files\7-zip\7z.exe"
# $root_dir = 'D:\PUBLIC\INCOMING'
# $Renamer = "c:\Program Files (x86)\ReNamer\ReNamer.exe"
$FileBot = 'C:\Program Files\FileBot\filebot.exe'

# Saco la lista de los directorios y los proceso
$directorios = get-childitem -literalpath $root_dir -directory 

$directorios | foreach-object {
    
    write-host "PROCESANDO: $dir_fullpath"


    # Directorio completo (todo el path)
    $film_fullpath = $_.FullName

    # Directorio de la pelicula
    $film_path = $_.name 
    

    # Listo los fichero avi,mkv y rar
    $v_ficheros = get-childitem -literalpath $film_fullpath -include *.avi,*.mkv,*.rar 

    # Proceso la lista
    $v_ficheros[0] | ForEach-Object {
        # Miro la extension
        $v_extension = $_.extension 
        # si es rar hay que descomprimirlo
        if ( $v_extension -eq ".rar" ) {
            # descomprimir
            $file = $_.fullname
            & "$7z" e "$file" -o"$root_dir" -y -bb3
        } else {
        
            # Listo los fichero avi y mkv 
            $v_ficheros2 = get-childitem -literalpath $film_fullpath -include *.avi,*.mkv
            $v_ficheros2 | foreach-object {
                $v2_extension = $_.extension
                $new_name = $film_fullpath + "\" + $film_path + $v2_extension
                rename-item -literalpath $_.fullname -newname $new_name 
                move-item -literalpath $new_name -Destination $root_dir
            }
    
        }
    }
    # Paso a limpiar los ficheros
    $v3_ficheros = get-childitem -literalpath $root_dir -include *.avi,*mkv -File
    $v3_ficheros | foreach-object {

        # Limpio el nombre del fichero. Quito los corchetes y lo que hay dentro excepto si tiene 4 digitos y entonces cambio los corchetes por parentesis
        $v_fichero3 = $_.fullname

        # Reemplazo el año entre corchetes por el año entre parentesis si existe
        $new_filename = $v_fichero3 -replace "\[[\d\d\d\d]\]","\($1\)" 
        # Despues quito los corchetes y su contenido
        $new_filename2 = $new_filename -replace "\[[\w*\s*-\.]*\]",""

        <#
        # Lo paso por filebot
        & $filebot -rename "$new_filename2" -non-strict --encoding UTF-8 --conflict auto --db TheMovieDB --lang es --format "{n.replace(':',' -') }"

        # Busco el destino y veo si la pelicula Existe
        $v_destino = get-childitem "D:\peliculas\$_.basename" -directory
        
        if ( $null -ne $v_destino ) {

            # Veo si lo bajado es mejor y esta en español
            # $peliculas = get-mediainfo -path "D:\PUBLIC\INCOMING\radarr"

            # Sustituyo la pelicula por la nueva
            Move-Item -literalpath $new_filename2 -Destination $v_destino.name 

        # Borro el directorio
        } else {
            # como no existe sera una pelicula nueva y no la toco, para procesarla manualmente
        }
            #>

    }

<#
    #! Queda renombrar el fichero y despues el directorio para poder ejecutar el file bot. 
    #! ERROR Despues de descomprimir muevo el fichero al directorio inferior
    #! Cuando haya terminado con todo hago otro bucle, lo limpio y paso el filebot
    #! Despues borro el directorio. Para renombrar puedo usar el renamer si regexp se pone duro.

    # Renombre el fichero
    rename-item -literalpath $old_filename -newname $new_filename -whatif
    
    # Lo paso por filebot
    & $filebot -rename "$new_filename3" -non-strict --encoding UTF-8 --conflict auto --db TheMovieDB --lang es --format "{n.replace(':',' -') }"

    
#>
write-host 

}