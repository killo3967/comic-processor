# Esto sirve para ordenar mis descargas

$root_dir="D:\PUBLIC\INCOMING\radarr\"
$7z="C:\program files\7-zip\7z.exe"
$Renamer = "c:\Program Files (x86)\ReNamer\ReNamer.exe"
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
            $path = $_.directoryname
            & "$7z" e "$file" -o"$path" -y -bb3
        } 
        # Listo los fichero avi y mkv 
        $v_ficheros2 = get-childitem -literalpath $film_fullpath -include *.avi,*.mkv
        $v_ficheros2 | foreach-object {
            $v2_extension = $_.extension
            $new_name = $film_fullpath + "\" + $film_path + $v2_extension
            rename-item -literalpath $_.fullname -newname $new_name 
            move-item -literalpath $new_name -Destination $root_dir
            # Si ya no queda ningun fichero de video o comprimido, borro el directorio 
            if ((get-childitem -literalpath $_.Directoryname -include *.avi,*.mkv).count -eq 0 ){
                    remove-item -literalpath $_.DirectoryName -Recurse -Force
            } 
        }
    }
}


# Paso a limpiar y renombrar los ficheros
& $Renamer /rename "PELICULAS" "D:\PUBLIC\INCOMING\radarr\*.mkv"
& $Renamer /rename "PELICULAS" "D:\PUBLIC\INCOMING\radarr\*.avi"

(get-childitem -literalpath "D:\PELICULAS" -include *.avi,*.mkv) | foreach-object {
    
    $v_extension = $_.extension

        if ((get-childitem d:\peliculas\*\"$_.name"*.* -recurse).count -eq 0 ){
        rename-item -literalpath $_.fullname -newname "D:\PUBLIC\INCOMING\radarr\" + $_.name + $v_extension
        remove-item $_.fullname
        move-item -literalpath "D:\PUBLIC\INCOMING\radarr\" + $_.name + $v_extension -Destination $_.fullname 
    }

#    $new_name = $_.FullName + $v_extension
#    rename-item -literalpath $_.FullName -newname $new_name 
#    move-item -literalpath $new_name -Destination $root_dir
}



<#
# Los paso por filebot
& $filebot -rename "D:\PUBLIC\INCOMING\radarr" -non-strict --encoding UTF-8 --conflict auto --db TheMovieDB --lang es 

# Creo las carpetas y muevo las peliculas dentro de las carpetas
$peliculas = get-childitem -literalpath $root_dir -include *.avi,*.mkv
$peliculas | foreach-object {
    $film_dir = $_.DirectoryName
    $film_name = $_.BaseName
    $new_dir = "$film_dir\$film_name"
    new-item -path $new_dir -itemtype Directory 
    move-item $_.fullname -Destination $new_dir
}
#>

# get-childitem -path d:\public\incoming\radarr -Directory 