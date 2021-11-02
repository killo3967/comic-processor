#
# Uso una serie de programas externos con licenciaa GPL
# Para convertir pdf a imagen uso de http://www.xpdfreader.com el programa de linea de comandos pdfimages.exe
#
# 
#
#
º


#Defino los directorios
write-output "PATH DEL SCRIPT ="(Split-Path -parent $MyInvocation.MyCommand.Definition)
$prog_dir = (Split-Path -parent $MyInvocation.MyCommand.Definition)
$prog_dir = "$prog_dir"
$log_dir = "$prog_dir\log"
$temp_dir = "$prog_dir\temp"
$comic_dir = "$prog_dir\prueba" # <-------- Esto habria que cambiarlo en su dia por un input 

write-output "PATH DEL SCRIPT ="(Split-Path -parent $MyInvocation.MyCommand.Definition)

# Creao un array con la lista de ficheros que me gustaria borrar que esta en el
# fichero exclude.cfg
$excluded_files = get-content $prog_dir\exclude.cfg

# Hago un bucle con toda la lista de comics
# Solo escojo los ficheros con extensiones 'cbr' y 'cbz'
$lista_comics = get-childitem $comic_dir -Include *.cbr, *.cbz -file -recurse

# Saco por pantalla esta lista
write-output ($lista_comics.fullname | Format-Table -HideTableHeaders) 

# Si la lista esta vacia me salgo
if ( $lista_comics.count -eq 0 ) {
    write-output "NADA QUE PROCESAR"
    break
}

# Entro en un blucle para procesar todos los comics
foreach ( $comic in $lista_comics ) { 

        # Defino el fichero de log
        $log_file = $log_dir + "\" + $comic.basename + "_" + $(get-date -f yyyy_MM_dd_hh_mm_ss) + ".log"
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

    $old_comic = $comic.fullname
    write-host "NOMBRE DEL COMIC: $old_comic"    

    # PASO 1 - DESCOMPRIMO EL COMIC
    write-output "PASO 1 - DESCOMPRIMO EL COMIC"
    
    # Primero borro el directorio temporal por si quedase algun resto
    Remove-item $temp_dir -Recurse -Force -Confirm:$False -verbose
    # Y lo vuelvo a crear
    New-Item -ItemType directory -Path $temp_dir -Force -verbose
    
    # Llamo a 7Z para descomprimir
    start-process -wait -nonewwindow "C:\program files\7-zip\7z.exe" -ArgumentList "e `"$old_comic`" -o$temp_dir -y -bb3" -RedirectStandardOutput "$log_dir\descomprime.log" 
    Get-Content -LiteralPath "$log_dir\descomprime.log" 
    
    # Le cambio los atributos a -R,-H,-S ya que he encontrado con algunos casos raros de que los ficheros estaban con attributos de oculto, de sistema etc.
    Get-ChildItem -LiteralPath $temp_dir -Attribute h,r,s -Recurse -Verbose | foreach-object { $_.Attributes = 'Normal'} 



    # Borro todos los ficheros menores a 5k ya que algunos comics traen a demas de las imagenes unos pequeños iconos de ellas.
    write-host "PASO 2 - BORRO FICHEROS MENORES A 5k"
    get-childitem $temp_dir | Where-Object { $_.Length -lt 5000 } | ForEach-Object { 
            remove-item -LiteralPath $_.FullName -Force -Confirm:$False -ErrorAction:Stop -Verbose 
        }
    



    # Borro ciertos directorios de MAC ( y su contenido ). Es un fastidio encontrarse estos directorios que no reconoce ComicRack
    write-host "PASO 3 - BORRO LOS DIRECTORIOS de MAC"
    remove-item -path $temp_dir"\.DS_Store" -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -verbose
    remove-item -path $temp_dir"\__MACOSX"  -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -verbose
    


    # Elimino los ficheros segun un patron definido en el array $archivos
    write-host "PASO 4 - BORRO CIERTOS FICHEROS BASURA"
    foreach ( $v_archivo in $excluded_files ) { 
        get-childitem -path $temp_dir -filter $v_archivo | foreach-object { 
            remove-item -LiteralPath $_.FullName -Force -Confirm:$False -ErrorAction:Stop -verbose 
        } 
    }

    # Y borro todos los ficheros con extensiones que no sean jpg, png O xml.
    # En algun caso encuentro txt, nfo y gif.
    Get-ChildItem $temp_dir -Exclude *.jpg, *.png *.xml | foreach-object { 
        remove-item $_.fullname -Recurse -Force -Verbose -Confirm:$False -ErrorAction:SilentlyContinue 
    }
    


    # Uso el mismo nombre y le cambio la extension a CBZ
    write-host "PAS0 5 - CREO EL NUEVO NOMBRE"
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
    start-process -wait -NoNewWindow "C:\program files\7-zip\7z.exe" -ArgumentLis "a -tzip -bb3 -mx0 -y -r `"$new_comic`" $temp_dir\*.*" -RedirectStandardOutput "$log_dir\comprime.log"
    Get-Content -LiteralPath "$log_dir\comprime.log"
    
    
    # Compruebo los tamaños de los ficheros excepto si el fichero inicial es un cbz ya que al recomprimir la diferencia puede dar 0
    write-host "PAS0 8 - COMPRUEBO EL NUEVO COMIC"
    if ( ( [math]::abs( ( get-childitem -Literalpath $new_comic).length - (get-childitem -Literalpath $backup_comic ).length ) -gt 1 ) -or ( ( get-childitem -literalpath $old_comic).extension -eq ".cbz" ) ) {
        # Los comics tienen un tamaño parecido. Se puede borrar el antiguo
        write-host ">>>>>>>>>>>>>>>    EL COMIC ES CORRECTO    <<<<<<<<<<<<<<<<<<<<<<<"
        remove-item -LiteralPath "$backup_comic" -Recurse -Force -Verbose  -Confirm:$False -ErrorAction:SilentlyContinue
    } 
    else {
        # Hay que borrar el nuevo y el backup y dejar el antiguo.
        remove-item -LiteralPath "$new_comic" -Recurse -Force -Verbose  -Confirm:$False -ErrorAction:SilentlyContinue
        rename-item -LiteralPath "$backup_comic" "$old_comic"
        write-host "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        write-host "@@@@@@@@    ERROR PROCESANDO COMIC @@@@@@@@@"
        write-host "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    }

   
    # Elimino el contenido del temporal
    write-host "PAS0 9 - ELIMINO EL DIRECTORIO TEMPORAL"
    Remove-item $temp_dir\*.* -Recurse -Force -Confirm:$False

    write-output ""
    write-output "#######################################################################################################################################"
    write-output ""

}
Stop-Transcript

