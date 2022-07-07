#
# Uso una serie de programas externos con licenciaa GPL
# Para convertir pdf a imagen uso de http://www.xpdfreader.com el programa de linea de comandos pdfimages.exe
#
clear-host


# Defino los directorios

#! Hay que definir Jdownloader como directorio origen donde estan el resto de los directorios a procesar
# $comic_dir="c:\public\jdownloader"

write-output "PATH DEL SCRIPT ="(Split-Path -parent $MyInvocation.MyCommand.Definition)
$prog_dir = (Split-Path -parent $MyInvocation.MyCommand.Definition)
$prog_dir = "$prog_dir"
$log_dir = "$prog_dir\log"
$temp_dir = "$prog_dir\temp"
$temp2_dir = "$prog_dir\temp2"

# Limpio los directorios temporales
Remove-item $temp_dir\*.* -Recurse -Force -Confirm:$False
Remove-item $temp2_dir\*.* -Recurse -Force -Confirm:$False

#! De momento este servira para hacer pruebas
$comic_dir = "D:\PUBLIC\JDOWNLOADER\PRUEBAS" # <-------- Esto habria que cambiarlo en su dia por un input 

# Creao un array con la lista de ficheros que me gustaria borrar que esta en el
# fichero exclude.cfg
$excluded_files = get-content $prog_dir\exclude.cfg

# Hago una lista de directorios
$dir_list = get-childitem $comic_dir -recurse -Directory

# BUCLE PRINCIPAL
$dir_list | foreach-object { 

    # Directorio donde esta la serie a procesar
    $series_dir=$_.fullname

    # Extraigo el nombre de la serie del nombre de la carpeta el nombre de la editoria y el año para usarlo
    # posteriormente en el scrapping
    $series_name = $_.name.split("(")[0].trim()
    $ed_name = $_.name.split("(")[1].split(")")[0].trim()
    $year_name= $_.name.split("(")[2].split(")")[0].trim()  

    write-host "#####################################################################################################"
    write-Host "#### PROCESANDO NUEVA SERIE: $series_name"
    write-host "#####################################################################################################"

    # Defino el fichero de log. Hago un log por cada Comic, Quizas seria mejor para una serie.
    $log_file = $log_dir + "\" + $series_name.basename + "_" + $(get-date -f yyyy_MM_dd_hh_mm_ss) + ".log"
    write-output $log_file

    # Paro la transcipcion para cerrar el fichero por si hubiese una en ejecucion.
    try { 
        stop-transcript -ErrorAction:SilentlyContinue 
    }
    catch {
        write-output " No existia una transcipcion previa abierta."
    }     
    finally {
        write-output " Iniciando transcripcion."
        start-transcript -IncludeInvocationHeader -literalpath $log_file
    }



    # PASO 0.5 -  COPIO TODOS LOS COMIS AL DIRECTORIO RAIZ
    write-host "PASO 0.5 -  COPIO TODOS LOS COMIS AL DIRECTORIO RAIZ"
    Get-childitem -path $series_dir -Include *.cbr, *.cbz -file -recurse | foreach-object { Move-Item -literalpath $_.fullname -destination $series_dir } 

    # PASO 0.6 - BORRO TODOS LOS DIRECTORIOS RECURSIVAMENTE
    write-host "PASO 0.6 - BORRO TODOS LOS DIRECTORIOS RECURSIVAMENTE"
    get-childitem -path $series_dir -Directory -Recurse | foreach-object { if ( $_.fullname -ne $series_dir ) { Remove-Item $_.fullname -force -recurse } }


    # PASO 0.7 - USO RENAMER PARA PONER BIEN EL NOMBRE DE LOS COMICS
    # Esto habria que convertirlo en una funcion en la proxima version
    # Y dejar el formato en la forma [{series}][ {volume}][ #{number}] - [{title}]
    write-host "PAS0 0.7 - LIMPIO EL NOMBRE DEL COMIC"
    & "C:\Program Files (x86)\ReNamer\ReNamer.exe" /silent /rename "COMICS" $series_dir

    # Hago un bucle con toda la lista de comics
    # Solo escojo los ficheros con extensiones 'cbr' y 'cbz'
    start-sleep -s 3
    $lista_comics = get-childitem -path $_.fullname -Include *.cbr, *.cbz -file -recurse

        # Si la lista esta vacia me salgo
        if ( $lista_comics.count -eq 0 ) {
            write-output "NADA QUE PROCESAR"
            break
        }else{
            # Saco por pantalla esta lista
            write-output ($lista_comics.fullname | Format-Table -HideTableHeaders) 

        }
    
    # Entro en un blucle para procesar todos los comics
    foreach ( $comic in $lista_comics ) { 
        

        $old_comic = $comic.fullname
        write-host "#####################################################################################################"
        write-Host "#### PROCESANDO NUEVO COMIC: ($old_comic.fullname)"
        write-host "#####################################################################################################"
    
        
        # PASO 1 - DESCOMPRIMO EL COMIC
        write-output "PASO 1 - DESCOMPRIMO EL COMIC"
        
        # Limpio los directorios temporales
        Remove-item $temp_dir\*.* -Recurse -Force -Confirm:$False
        Remove-item $temp2_dir\*.* -Recurse -Force -Confirm:$False
        
        # Llamo a 7Z para descomprimir
        start-process -wait -nonewwindow "C:\program files\7-zip\7z.exe" -ArgumentList "e `"$old_comic`" -o$temp_dir -y -bb3" -RedirectStandardOutput "$log_dir\descomprime.log" 
        Get-Content -LiteralPath "$log_dir\descomprime.log" 
        
        # Le cambio los atributos a -R,-H,-S ya que he encontrado con algunos casos raros de que los ficheros estaban con attributos de oculto, de sistema etc.
        Get-ChildItem -LiteralPath $temp_dir -Attribute h,r,s -Recurse -Verbose | foreach-object { $_.Attributes = 'Normal'} 
        # FIN PASO 1 


        # PASO 2 - LIMPIO EL COMIC 
        # Borro todos los ficheros menores a 5k ya que algunos comics traen a demas de las imagenes unos pequeños iconos de ellas.
        write-host "PASO 2 - LIMPIEZA (Borro ficheros <5k, quito directorios de MAC, borro banners, elimino ficheros no imagenes, etc)"
        get-childitem $temp_dir | Where-Object { $_.Length -lt 5000 } | ForEach-Object { 
                remove-item -LiteralPath $_.FullName -Force -Confirm:$False -ErrorAction:Stop -Verbose 
            }

        # Borro ciertos directorios de MAC ( y su contenido ). Es un fastidio encontrarse estos directorios que no reconoce ComicRack
        remove-item -path $temp_dir"\.DS_Store" -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -verbose
        remove-item -path $temp_dir"\__MACOSX"  -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -verbose
        
        # Elimino los ficheros segun un patron definido en el array $archivos
        foreach ( $v_archivo in $excluded_files ) { 
            get-childitem -path $temp_dir -filter $v_archivo | foreach-object { 
                remove-item -LiteralPath $_.FullName -Force -Confirm:$False -ErrorAction:Stop -verbose 
            } 
        }
        # Solo dejo los ficheros con extensiones que no sean jpg, png, webp o xml.
        Get-ChildItem $temp_dir -Exclude *.jpg, *.png, *.xml, *.webp | foreach-object { 
            remove-item $_.fullname -Recurse -Force -Verbose -Confirm:$False -ErrorAction:SilentlyContinue 
        }
        # FIN PASO 2
        
        # PASO 3 - CONVIERTO LOS FICHEROS DE IMAGENES A UN FORMATO ADECUADO
        # Uso ImageMagick para convertir los ficheros a uno de los formatos adecuados.
        write-host "PASO 3 - CONVIERTO LOS FICHEROS A UN FORMATO ADECUADO"
        & magick mogrify -format jpg -auto-level -auto-orient -colorspace RGB -quality 65 -sampling-factor 2x2 -depth 24 -interlace line -path $temp2_dir $temp_dir"\*.*"


        # "PAS0 4 - CREO EL NUEVO NOMBRE"
        # Uso el mismo nombre y le cambio la extension a CBZ
        write-host "PAS0 4 - CREO EL NUEVO NOMBRE"
        $new_comic = $comic.directoryname + "\" + $comic.basename + ".cbz"
        $new_comic = "$new_comic"
        #write-output $new_comic

        
        # Renombro el fichero antiguo antes de recrearlo por si el nuevo no sale bien
        write-host "PAS0 6 - HAGO UNA COPIA DE SEGURIDAD DEL COMIC"
        $backup_comic = $comic.directoryname + "\" + $comic.basename + ".bck"
        #borro la copia de seguridad antes de crearla por si existe
        remove-item -LiteralPath "$backup_comic" -Recurse -Force -Verbose  -Confirm:$False -ErrorAction:SilentlyContinue
        rename-item -Literalpath $comic.fullname -Newname "$backup_comic" -Force -Verbose  -Confirm:$False

        

        # Comprimo el directorio temp con el nuevo nombre
        write-host "PAS0 7 - COMPRIMO EL NUEVO COMIC"
        start-process -wait -NoNewWindow "C:\program files\7-zip\7z.exe" -ArgumentLis "a -tzip -bb3 -mx0 -y -r `"$new_comic`" $temp2_dir\*.*" -RedirectStandardOutput "$log_dir\comprime.log"
        Get-Content -LiteralPath "$log_dir\comprime.log"
        

        # Compruebo los tamaños de los ficheros excepto si el fichero inicial es un cbz ya que al recomprimir la diferencia puede dar 0
        write-host "PAS0 8 - COMPRUEBO EL NUEVO COMIC"
        if ( ( [math]::abs( ( get-childitem -Literalpath $new_comic).length - (get-childitem -Literalpath $backup_comic ).length ) -gt 1 ) -or ( ( get-childitem -literalpath $old_comic).extension -eq ".cbz" ) ) {
            # Los comics tienen un tamaño parecido. Se puede borrar el antiguo
            write-host ">>>>>>>>>>>>>>>    EL COMIC ES CORRECTO    <<<<<<<<<<<<<<<<<<<<<<<"

            # Borro el backup    
            remove-item -LiteralPath "$backup_comic" -Recurse -Force -Verbose  -Confirm:$False -ErrorAction:SilentlyContinue
        } 
        else {
            # Hay que borrar el nuevo y el backup y dejar el antiguo.
            remove-item -LiteralPath "$new_comic" -Recurse -Force -Verbose  -Confirm:$False -ErrorAction:SilentlyContinue
            rename-item -LiteralPath "$backup_comic" "$old_comic"
            write-host "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            write-host "@@@@@@@@ ERROR PROCESANDO COMIC, RESTAURANDO @@@@@@@@@"
            write-host "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        }

    
        # Elimino el contenido del temporal
        write-host "PAS0 9 - ELIMINO EL DIRECTORIO TEMPORAL"
        Remove-item $temp_dir\*.* -Recurse -Force -Confirm:$False
        Remove-item $temp2_dir\*.* -Recurse -Force -Confirm:$False


        write-output ""
        write-output "#######################################################################################################################################"
        write-output ""

        

    }

    # PARO LA TRANSCRIPCION DE LOGS
    Stop-Transcript -Verbose
    

    # Hago un scrapping del comic con ComicVine usando el software de comictagger
    # Se podria hacer una funcion llamando a la API de comicvine y sacando el id del comic
    # Pero es mas facil hacerlo con el software de comictagger
    # El scrapping de los comics en español fallan, se podria probar a traducir el nombre de la serie
    # Tambien seria interesanta probar el primer comic de la serie y si lo encuentra y hay mas hacer el resto.
    write-host "SCRAPEO EL COMIC"
    # Con este comando obtengo informacion del comic y escribo el fichero XML dentro del comic



    & "C:\Program Files (x86)\ComicTagger\comictagger.exe" -s -R -o -t cr -f $series_dir -m "series=$series_name, year=" --terse
    # Con este comando cambio el nombre del comic con el nombre del comic de ComicVine
    & "C:\Program Files (x86)\ComicTagger\comictagger.exe" -r -R -t cr $new_comic

    #! SI FALLA ALGUN COMIC, PERO OTRO SI LO SCRAPEA BIEN, SE PUEDE OBTEBER EL ID DE ESTE ULTIMO COMIC CON LA OPCION -p
    #! & "C:\Program Files (x86)\ComicTagger\comictagger.exe" -p $series_dir 
    #! y luego buscar la linea de notes, y dentro de esta linea aparece 
    #! notes:      Tagged with ComicTagger 1.3.2a3 using info from Comic Vine on 2022-05-07 19:09:59.  [Issue ID 595002]
    #! y de aqui se obtine el ID que se vuelve a aplicar a los comics
    #! & "C:\Program Files (x86)\ComicTagger\comictagger.exe" -s -R -o --id=XXXXXX -t cr $series_dir 

    #! MOVER EL COMIC SEGUN EL RESULTADO DEL SCRAPPING


    
}