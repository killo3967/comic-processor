# Uso una serie de programas externos con licenciaa GPL
# Para convertir pdf a imagen uso de http://www.xpdfreader.com el programa de linea de comandos pdfimages.exe
# Para convertir o comparar imagenes uso ImageMagick de http://www.imagemagick.org/script/index.php
# El siguiente programa no tiene licencia GPL pero lo sustituire por una funcion
# Para limpiar los nombres yso Renamer de https://www.den4b.com/products/renamer
# Para la comparacion de imagenes he basado el codigo en el codigo del pluging de comicvine para comicrack  
# y he visto que hace referencia a https://www.memonic.com/user/aengus/folder/coding/id/1qVeq
# Basicamente lo que se dice aqui es que para comparar dos imagenes hay que comprimirlas
# a 32x32, convertirlas a escala de grises y despues compararlas.
# No he copiado el codigo del pluging, sino que lo he adaptado al uso con ImageMagick
#
# Convert from PDF (https://codegard1.com/imagemagick-notes/)
# For this to work, you first need to install GhostScript (a library that interprets PDF’s). 
# 
#
# Este script esta todavia en version ALPHA, por lo que no es seguro.

clear-host
$Error.clear()

##############################################################
###############    CHEQUEOS DE MODULOS   #####################
##############################################################

# Esto es para comprobar que se ha instalado el modulo de parsing de html de Anglesharp
If ( -Not ([System.Management.Automation.PSTypeName]'AngleSharp.Parser.Html.HtmlParser').Type ) {
    $standardAssemblyFullPath = (Get-ChildItem -Filter '*.dll' -Recurse (Split-Path (Get-Package -Name 'AngleSharp').Source)).FullName | Where-Object { $_ -Like "*standard*" } | Select-Object -Last 1
    Add-Type -Path $standardAssemblyFullPath -ErrorAction 'SilentlyContinue'
} # Terminate If - Not Loaded

################################################################################
###############    COMPROBACION DEL DIRECTORIO DE COMICS   #####################
################################################################################


# Defino el directorio donde estan los comics.
$Global:comic_dir = "S:\PRUEBAS\" 

if ( (get-childitem $comic_dir -File -Recurse).count -eq 0 ) {
    write-host "NO HAY COMICS A PROCESAR."
    break
}


###################################################################
###############    DECLARACION DE VARIABLES   #####################
###################################################################

# Veo cual es el directorio del script
$prog_dir = (Split-Path -parent $MyInvocation.MyCommand.Definition)

$Global:prog_dir             = "$prog_dir"
$Global:config_dir           = "$prog_dir\config" 
$Global:log_dir              = "$prog_dir\log"
$Global:comic_unzip_dir      = "$prog_dir\comic\unzip"
$Global:comic_final_dir      = "$prog_dir\comic\final"
$Global:comic32x32_dir       = "$prog_dir\comic\32x32"
$Global:original_credits_dir = "$prog_dir\original_credits"
$Global:credits_dir          = "$prog_dir\credits" 
$Global:backup_dir           = "$prog_dir\backup"
$Global:scrapping_cache_dir  = "$prog_dir\scrapping_cache"
$Global:scrapping_temp_dir   = "$prog_dir\scrapping_temp"
$Global:ocr_temp_dir         = "$prog_dir\ocr"
$Global:fichero_temporal     = "C:\windows\temp\temp.jpg"
        

# Incluimos los modulos necesarios
. $config_dir\configuracion.ps1
. $prog_dir\variables.ps1
. $prog_dir\procesar_imagenes.ps1
. $prog_dir\traducir.ps1
. $prog_dir\scrapping.ps1
. $prog_dir\procesar_nombre.ps1
. $prog_dir\Damerau–Levenshtein
. $prog_dir\identifica_comic.ps1
. $prog_dir\ocr.ps1
. $prog_dir\ask_comicvine.ps1
. $prog_dir\ask_isbn.ps1
. $prog_dir\metadata.ps1


# Rutas de los ejecutables auxiliares
$Global:img_dir    = "C:\Program Files\ImageMagick-7.1.0-Q16-HDRI"
$Global:compara    = "$img_dir\compare.exe"
$Global:convierte  = "$img_dir\convert.exe"
$Global:mogrify    = "$img_dir\mogrify.exe"
$Global:renamer    = "C:\Program Files (x86)\ReNamer\ReNamer.exe"
$Global:tesseract  = "C:\Program Files\Tesseract-OCR\tesseract.exe"

# Rutas de ficheros
$Global:comicinfo_filepath = "$comic_final_dir\comicinfo.xml"

$Global:comic_final

###################################################################
###############    PREPARACION DEL ENTORNO    #####################
###################################################################

# Creo los directorios necesarios para el funcionamiento del script
$directorios_necesarios = @(
    $log_dir,
    $comic_unzip_dir,
    $comic_final_dir,
    $comic32x32_dir,
    $original_credits_dir,
    $credits_dir,
    $backup_dir,
    $scrapping_cache_dir,
    $scrapping_temp_dir,
    $ocr_temp_dir,
    $fichero_temporal
)
for ($i = 1; $i -lt $directorios_necesarios.count; $i++) {
    if (Test-Path $directorios_necesarios[$i]) {
            if ($verbose -eq $true) {
                write-output "El directorio $directorios_necesarios[$i] ya existe"
            }
    } else {
        New-Item -Path $directorios_necesarios[$i] -ItemType Directory -Force -ErrorAction Stop
    }
}

# Limpio los directorios temporales
$directorios_temporales = @(
    $comic_unzip_dir,
    $comic_final_dir,
    $comic32x32_dir,
    $scrapping_temp_dir,
    $ocr_temp_dir,
    $fichero_temporal
)
foreach ( $temp_dir in $directorios_temporales){
    Remove-item $temp_dir\*.* -Recurse -Force -Confirm:$False -ErrorAction SilentlyContinue -Verbose:$verbose | out-null
}


# Hago un backup de las imagenes de creditos
copy-item $original_credits_dir\*.* $backup_dir -Force -ErrorAction Stop

# Renombro las imagenes de creditos
$i = 0
get-childitem $original_credits_dir | foreach-object { 
    rename-item -path $_.fullname -newname ($_.directoryname + "\" + "imagen_creditos_" + $(get-date -f yyyy_MM_dd_hh_mm_ss) + "_" + ($i++).tostring("000") + ".jpg") -verbose:$verbose 
}

# Convierto las imagenes de creditos a 32x32 en escala de grises para poder compararlas
if ( (get-childitem $original_credits_dir).count -ne (get-childitem $credits_dir).count  ){
    remove-item -path "$credits_dir\*.*" -force -verbose:$verbose -erroraction stop
    write-host "Creando minuatura de imagenes de creditos"
    $num_miniaturas = (get-childitem $original_credits_dir).count
    for ( $i=0 ; $i -lt $num_miniaturas ; $i++) {
        $nombre_fichero_original = ((get-childitem $original_credits_dir)[$i]).fullname
        $nombre_fichero_convertido = $credits_dir + "\" + "Imagen_" + $i.tostring("D2") + ".jpg"
        (& $convierte $nombre_fichero_original -resize 32x32^! -colorspace Gray $nombre_fichero_convertido 2>&1)
        if ( $verbose -eq $true ) {
        write-host "Convirtiendo imagen " $nombre_fichero_original " -> " $nombre_fichero_convertido
        } else {
            #write-host -NoNewLine '.'
            $porcentaje = [int]$i*100/[int]$num_miniaturas
            $displayname = ((get-childitem $original_credits_dir)[$i]).basename
            Write-Progress -Activity "Procesando: $displayname" -PercentComplete ($porcentaje)
        }
    }
}

###################################################################
###############       PROGRAMA PRINCIPAL      #####################
###################################################################

# Creo un array con la lista de ficheros que me gustaria borrar que esta en el fichero exclude.cfg
$excluded_files = get-content $config_dir\exclude.cfg -verbose:$verbose 

# Hago una lista de directorios o series. Considero cada directorio una serie y todos los comic dentro
# de ese directorio pertenecen a la misma serie.

if ( $true -eq $incluir_directorio_raiz) {
    $dir_list = get-childitem $comic_dir -Recurse -verbose:$verbose 
} else {
    $dir_list = get-childitem $comic_dir -Directory -Recurse -verbose:$verbose 
}

####################################################################
# BUCLE PRINCIPAL PARA PROCESAR CADA UNO DE LOS DIRECTORIOS/SERIES #
####################################################################
for ($i=0; $i -lt $dir_list.count; $i++) {

    # Directorio donde esta la serie a procesar
    $Global:dp_series_name_path = $dir_list[$i].fullname                
    
    # Renombro el directorio quitando los "&nbsp" que encuentre
    $new_series_dir = $Global:dp_series_name_path.replace('&nbsp','')
    rename-item -path $Global:dp_series_name_path -newname $new_series_dir -Force -Confirm:$False -verbose:$verbose -ErrorAction:SilentlyContinue 
    $Global:dp_series_name_path = $new_series_dir  

    # Extraigo el nombre de la serie, el publisher y el año del nombre del directorio del comic
    # $series_name = extraer_serie  
    $Global:dp_series_name = ((split-path $Global:dp_series_name_path -leaf ) -replace '(\[|\()[^\]\)]*(\]|\))' , '' ).trim()
    $Global:dp_series_path_publisher    = [regex]::match( $Global:dp_series_name_path , $Global:cadena_publisher_year ).Groups[4].value
    $Global:dp_series_path_year         = [regex]::match( $Global:dp_series_name_path , $Global:cadena_publisher_year ).Groups[9].value

    
    # Defino el fichero de log. Hago un log para cada serie, que contiene la conversion de varios comics.
    $log_file = $log_dir + "\" + $series_name + "_" + $(get-date -f yyyy_MM_dd_hh_mm_ss) + ".log"
    write-host ""
    # Paro la transcipcion para cerrar el fichero por si hubiese una en ejecucion.
    try { 
        # Existia una transcripcion anterior no cerrada. La cierro.
        stop-transcript -ErrorAction:SilentlyContinue | Out-Null
    }
    catch {
        write-output ">> No existia una transcipcion previa abierta."
    }     
    finally {
        write-output ">> Iniciando transcripcion en fichero de log $log_file"
        start-transcript -IncludeInvocationHeader -literalpath $log_file | out-null
    }

    write-host
    write-host "#####################################################################################################"
    write-Host "#### PROCESANDO NUEVA SERIE: $series_name"
    write-host "#####################################################################################################"
    write-host

    # Hago un bucle con toda la lista de comics
    # Solo escojo los ficheros con extensiones 'cbr' y 'cbz'
    $lista_comics = get-childitem -literalpath $Global:dp_series_name_path -Include *.cbr,*.cbz -file -recurse

    # Si la lista esta vacia me salgo
    if ( $lista_comics.count -eq 0 ) {
        write-output "NADA QUE PROCESAR. SALIENDO"
        write-output
        break
    }else{
        # Saco por pantalla esta lista de ficheros as procesar de la serie
        write-output "    >> Lista de ficheros a procesar:"
        write-output "    "($lista_comics.fullname | Format-Table -HideTableHeaders) 
    }

 
    # MUEVO TODOS LOS COMIS AL DIRECTORIO RAIZ Y BORRO EL RESTO DE LOS DIRECTORIOS
    if ($un_solo_directorio -eq $true) { 
        write-host
        write-host "MUEVO TODOS LOS COMIS AL DIRECTORIO RAIZ DE LA SERIE Y BORRO DIRECTORIOS VACIOS RECURSIVAMENTE"
        write-host
        Get-childitem -literalpath $Global:dp_series_name_path -Include *.cbr, *.cbz -file -recurse | foreach-object { Move-Item -literalpath $_.fullname -destination $Global:dp_series_name_path } 
        Get-childitem -path $Global:dp_series_name_path -Directory -Recurse | foreach-object { if ( $_.fullname -ne $Global:dp_series_name_path ) { Remove-Item $_.fullname -force -recurse -verbose:$verbose  } }
    }

    # RENOMBRO LOS COMICS Y PONGO TODO LO BIEN QUE SE PUEDE EL NOMBRE DE LOS COMICS
    if ( $tipo_renombrado -eq "comics"){
        write-host
        write-host "LIMPIO EL NOMBRE DEL COMIC"
        write-host
        limpia_nombres #($Global:dp_series_name_path)
    }

    # Despues de la limpieza vuelvo a listar los comics ya que los nombres han cambiado.
    $lista_comics = get-childitem -literalpath $Global:dp_series_name_path -Include *.cbr,*.cbz -file -recurse

    #! AQUI EN MEDIO HABRIA QUE COMPROBAR, QUE LOS NOMBRES DE LOS COMICS COINCIDEN CON EL NOMBRE DEL DIRECTORIO
    #! Y si no es asi intentar detectar el nombre de la serie y sustuir el nombre del comic.
    
    # ENTRO EN UN BUBLE PARA PROCESAR CADA UNO DE LOS COMIS
    for ( $j = 0 ; $j -lt $lista_comics.count ; $j++ ) {
    
        $Global:dp_comic_fullname = $lista_comics[$j].fullname

        write-host "#####################################################################################################"
        write-Host "#### PROCESANDO NUEVO COMIC: $Global:dp_comic_fullname"
        write-host "#####################################################################################################"  
        
        ################################
        # DESCOMPRIMO EL COMIC
        ################################
        write-output "DESCOMPRIMO EL COMIC"
        
        # Limpio los directorios temporales
        write-host "    >> Borro los directorios temporales"
        Remove-item $comic_unzip_dir\*.* -Recurse -Force -Confirm:$False -verbose:$verbose  
        Remove-item $comic_final_dir\*.* -Recurse -Force -Confirm:$False -verbose:$verbose 
        Remove-item $comic32x32_dir\*.*  -Recurse -Force -Confirm:$False -verbose:$verbose  
        
        # Llamo a 7Z para descomprimir el comic
        write-host "    >> Descomprimo el comic"
        start-process -wait -verbose:$verbose -nonewwindow "C:\program files\7-zip\7z.exe" -ArgumentList "e `"$Global:dp_comic_fullname`" -o$comic_unzip_dir -y -bb3" -RedirectStandardOutput "$log_dir\descomprime.log" 
        if ( $verbose -eq $true ) {
        Get-Content -LiteralPath "$log_dir\descomprime.log" -verbose:$verbose 
        }

        # Le cambio los atributos a -R,-H,-S ya que he encontrado con algunos casos raros de que los ficheros estaban con attributos de oculto, de sistema etc.
        write-host "    >> Cambio los atributos a los ficheros para poder tener acceso"
        Get-ChildItem -LiteralPath $comic_unzip_dir -Attribute h,r,s -Recurse -verbose:$verbose  | foreach-object { $_.Attributes = 'Normal'} 
         
        ###########################
        # LIMPIO EL COMIC 
        ###########################
        # Borro todos los ficheros menores a 5k ya que algunos comics traen a demas de las imagenes unos pequeños iconos de ellas.
        write-host "EJECUTO UNA LIMPIEZA DEL COMIC"
        write-host "    >> Borro todos los ficheros menores de 5k que son thumbnais y los visores de comics no entienden"
        get-childitem $comic_unzip_dir | ForEach-Object { 
            if ($_.Length -lt 5000) {
                remove-item -LiteralPath $_.FullName -Force -Confirm:$False -ErrorAction:Stop -verbose:$verbose  -exclude comicinfo.xml,cvinfo
            }
        }

        # Borro ciertos directorios de MAC/OSX ( y su contenido ). 
        # Es un fastidio encontrarse estos directorios que no reconoce ComicRack
        write-host "    >> Quito directorios de MACOSX"
        remove-item -path $comic_unzip_dir"\.DS_Store" -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -verbose:$verbose 
        remove-item -path $comic_unzip_dir"\__MACOSX"  -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -verbose:$verbose 
        

        # Solo dejo los ficheros con extensiones que sean jpg, png, webp o xml.
        # Me he encontrado dentro de los ficheros de los comics muchos otros ficheros que no son imagenes,
        # como thumbnais, ficheros nfo, ficheros txt, etc.
        write-host "    >> Elimino todos los ficheros que nos son jpg, png, xml ó webp"
        Get-ChildItem -literalpath $comic_unzip_dir -Exclude *.jpg, *.png, *.xml, *.webp | foreach-object { 
            remove-item $_.fullname -Recurse -Force -verbose:$verbose -Confirm:$False -ErrorAction:SilentlyContinue -exclude cvinfo
        }

        #! AQUI HABRIA QUE RENOMBRAR LOS NOMBRES DE LAS IMAGENES AL PATRON <serie>_<volumen>_<comic>_nnn.jpg
        #####################################################################
        # CONVIERTO LOS FICHEROS DE IMAGENES A UN FORMATO ADECUADO
        #####################################################################

        # Uso ImageMagick para convertir los ficheros a un formato personalizado.
        # Reduzco las dimensiones de las imagenes a un maximo de 1440x2210. He encontrado
        # que estas dimensiones son sufucientes y hay una buena relacion tamaño del comic / calidad de la imagen
        
        if ( $true -eq $reprocesar_imagen) {
            write-host "CONVIERTO LOS FICHEROS DE IMAGENES DEL COMIC A UN FORMATO ADECUADO"
            write-host "    >> Convirtiendo imagenes.... ( ¡Espere!, este proceso puede durar varios minutos )"
            $lista_ficheros = (get-childitem -literalpath $comic_unzip_dir -exclude *.xml).fullname
            reprocesar_imagen $lista_ficheros $comic_final_dir
        } else {
            # Como no los reproceso los tengo que copiar
            copy-item "$comic_unzip_dir\*" -Destination $comic_final_dir -verbose:$verbose -Confirm:$False -ErrorAction:SilentlyContinue
        }
               
        ############################################
        # ELIMINO LAS IMAGENES DE CREDITOS
        ############################################

        # Existen dos formas de elimiar estas imagenes. 
        # 1.- Elimino ciertos ficheros con nombres/patrones especificos que se encuentran almacenados en un fcihero
        #     de texto llamado 'exclude.cfg'
        # 2.- La segunda forma y la mas complicada es extraer de los comics las imagenes de creditos de los recopiladores
        #     y almacenarlas en el directorio 'original_credits', para despues eliminarlas de los comics comparando las imagenes.
        #! Podria existir una tercera forma y es haciendo un OCR a las 'n' ultimas imagenes del comic y buscando patrones de texto, 
        #! pero no esta implementada HACERLO YA
        
        if ( $buscar_creditos -eq $true ) {
            write-host "ELIMINO LAS IMAGENES DE CREDITOS"

            # Elimino los ficheros segun un patron definido en el array $archivos segun una serie de
            # palabras clave que se encuentran en el nombre del fichero.
            write-host "    >> Borro ciertas imagenes que añaden lo recopiladores"
            
            # Antes de borrar los ficheros los paso por renamer para que limpie los nombres ya que se me ha
            # dado el caso de que todos ficheros tenian nombres con que coincidian con los filtros a borrar.
            #! Esto habria que cambiarlo por una funcion pero ya!
            if ($Global:tipo_renombrado = 'comic'){
                & "C:\Program Files (x86)\ReNamer\ReNamer.exe" /silent /rename "COMICS" $comic_unzip_dir
            }
            if ($Global:tipo_renombrado = 'manga'){
                & "C:\Program Files (x86)\ReNamer\ReNamer.exe" /silent /rename "MANGA" $comic_unzip_dir
            }
            # Tengo que poner esto para esperar a Renamer
            wait-process -name "ReNamer" -Timeout 500
            
            # Borro los ficheros que siguen un patron segun se define en el fichero que contiene la variable $exclude_files
            foreach ( $v_archivo in $excluded_files ) { 
                get-childitem -path $comic_unzip_dir -filter $v_archivo | foreach-object { 
                    $fichero_a_borrar = $_.FullName
                    remove-item -LiteralPath $fichero_a_borrar -Force -Confirm:$False -ErrorAction:Stop -exclude comicinfo.xml,cvinfo -verbose:$verbose 
                } 
            }

            # Genero las miniaturas de 32x32 a partir de las imagenes tratadas del comic
            
            write-host "    >> Genero las ultimas $numero_imagenes_creditos miniaturas en formato 32x32"
            # primero calculo el numero de imagenes que tiene el comic
            [int]$num_imagenes = (get-childitem $comic_final_dir -exclude comicinfo.xml,cvinfo -file).count
            
            # Solo genero las '$numero_imagenes_creditos' ultimas para acelerar el proceso
            for ( $k = ($num_imagenes - $numero_imagenes_creditos) ; $k -lt $num_imagenes ; $k++) {  
                $imagen = (get-childitem $comic_final_dir -exclude comicinfo.xml,cvinfo)[$k].fullname
                genera_miniatura $imagen $comic32x32_dir
            }

            # Inicializo el array de imagenes a eliminar
            $imagenes_a_borrar = @()
            
            # Y ahora busco las imagenes que coinciden
            write-host "    >> Buscando creditos en las $numero_imagenes_creditos ultimas imagenes del comic"
            for ( $n = $num_imagenes - $numero_imagenes_creditos ; $n -lt $num_imagenes ; $n++ ) {
                $imagen_miniatura = ( get-childitem $comic32x32_dir )[$n].fullname
                $imagen_real  = ( get-childitem $comic_final_dir )[$n].fullname
                
                # Miro todas las imagenes de creditos que tengo almacenadas en el directorio de credits
                $numero_creditos = (get-childitem -literalpath $credits_dir -file).count
                for ( $m = 0 ; $m -lt $numero_creditos ; $m++ ) {
                    # Obtengo el nombre del fichero de creditos
                    $imagen_credito = (get-childitem -literalpath $credits_dir -file)[$m].fullname
                    # Llamo a la funcion de comparacion de imagenes
                    $compara_imagen = Get-CompareImage $imagen_miniatura $imagen_credito 
                        if ( $compara_imagen -eq "0" ) {
                            # Si devuelve "0" las imagenes son identicas y con 1 so muy parecidas y la borro
                            write-host "    >> Borrando la imagen del comic $imagen_miniatura por ser igual a la imagen del credito" -ForegroundColor Red
                            # Guardo el nombre de la imagen en el array de imagenes a borrar
                            $imagenes_a_borrar += $imagen_real
                            break 
                        }
                }
                
            }

            # Y ahora borro las imagenes del comic que he almacenado en el array $imagenes_a_borrar
            foreach ( $imagen in $imagenes_a_borrar ) {
                remove-item -LiteralPath $imagen -Force -Confirm:$False -ErrorAction:Stop -verbose:$verbose 
            }
        }

        # ==================================
        # =========== SCRAPPING ============
        # ==================================

        if ( $true -eq $Global:scrapper_comic ) {
            scrap_comic                         
        }


        #######################
        # CREO EL NUEVO COMIC
        #######################

        # Uso el mismo nombre y le cambio la extension a CBZ
        write-host "CREO EL NUEVO NOMBRE"
        $new_comic = $lista_comics[$j].directoryname + "\" + $lista_comics[$j].basename + ".cbz"
        $new_comic = "$new_comic"
        write-host "    >> Creo el nuevo nombre del comic: " $new_comic
        
        # Renombro el fichero antiguo antes de recrearlo por si el nuevo no sale bien
        write-host "HAGO UNA COPIA DE SEGURIDAD DEL COMIC"

        $backup_comic = $lista_comics[$j].directoryname + "\" + $lista_comics[$j].basename + ".bck"
        write-host "    >> Borro la copia de seguridad antes de crearla por si existe"
        remove-item -LiteralPath "$backup_comic" -Recurse -Force -verbose:$verbose  -Confirm:$False -ErrorAction:SilentlyContinue
        write-host "    >> Creo la copia de seguridad por si fallase algun proceso despues"
        rename-item -Literalpath $lista_comics[$j].fullname -Newname "$backup_comic" -Force -verbose:$verbose -Confirm:$False

        # Comprimo el directorio temp con el nuevo nombre
        write-host "COMPRIMO EL NUEVO COMIC"
        start-process -wait -NoNewWindow "C:\program files\7-zip\7z.exe" -ArgumentList "a -tzip -bb3 -mx0 -y -r `"$new_comic`" $comic_final_dir\*.*" -RedirectStandardOutput "$log_dir\comprime.log"
        if ( $verbose -eq $true ) {
            Get-Content -LiteralPath "$log_dir\comprime.log"
        }
        
        # Compruebo los tamaños de los ficheros excepto si el fichero inicial es un cbz ya que al recomprimir la diferencia puede dar 0
        write-host "COMPRUEBO EL NUEVO COMIC"
        if ( ( [math]::abs( ( get-childitem -Literalpath $new_comic).length - (get-childitem -Literalpath $backup_comic ).length ) -gt 1 ) -or ( ( get-childitem -literalpath $Global:dp_comic_fullname).extension -eq ".cbz" ) ) {
            # Los comics tienen un tamaño parecido. Se puede borrar el antiguo
            write-host "    >> EL COMIC ES CORRECTO" -ForegroundColor Green

            # Borro el backup    
            write-host "    >> Borro el backup"
            remove-item -LiteralPath "$backup_comic" -Recurse -Force -Verbose:$verbose  -Confirm:$False -ErrorAction:SilentlyContinue
      
        } else {
            ##################################
            # RESTAURO EL COMIC ORIGINAL
            ##################################
            
            # Hay que borrar el nuevo y el backup y dejar el antiguo.
            write-host "    >> Elimino el nuevo comic"
            remove-item -LiteralPath "$new_comic" -Recurse -Force -Verbose:$verbose -Confirm:$False -ErrorAction:SilentlyContinue
            write-host "    >> Restauro el backup" 
            rename-item -LiteralPath "$backup_comic" "$Global:dp_comic_fullname"
            write-host "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" -ForegroundColor Red
            write-host "@@@@@@@@ ERROR PROCESANDO COMIC, RESTAURANDO COPIA DE SEGURIDAD @@@@@@@@@" -ForegroundColor Red
            write-host "@@@@@@@@ POR FAVOR REVISE EL FICHERO DE LOG ANTES DE CONTINUAR  @@@@@@@@@" -ForegroundColor Red
            write-host "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" -ForegroundColor Red
            break
            
        }

            
        # Elimino el contenido de los directorios temporales
        write-host "LIMPIO DIRECTORIOS TEMPORALES Y DE LOGS"
        Remove-item $comic_unzip_dir\*.* -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -Verbose:$verbose
        Remove-item $comic_final_dir\*.* -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -Verbose:$verbose
        Remove-item $log_dir\comprime.log -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -Verbose:$verbose
        Remove-item $log_dir\descomprime.log -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -Verbose:$verbose
        # Remove-item $log_dir\comictagger.log -Recurse -Force -Confirm:$False -ErrorAction:SilentlyContinue -Verbose:$verbose

        
        # write-output "#######################################################################################################################################"
        write-output ""
      

    }


    ###########################################
    # MUEVO LA SERIE A LA CARPETA DE DESTINO
    ##########################################
    if ( $mover_comic -eq $true ) {
        # PASO FINAL - MUEVO EL COMIC A LA CARPETA DE DESTINO DEPENDIENDO DE SI TODOS LOS PROCESOS ANTERIORES SON CORRECTOS
        write-host "PASO FINAL - MUEVO EL COMIC A LA CARPETA DE DESTINO"
        # Miro si todos los comics se han escrapeados 
        if ( [int]$comic_encontrado -eq [int](get-childitem -literalpath $Global:dp_series_name_path -file).count) {
            # Todos los ficheros han sido procesados y scrapeados. Se puede mover el directorio
            write-host "  >> TODOS LOS COMICS HAN SIDO PROCESADOS Y SCRAPEADOS"
            move-item -LiteralPath $Global:dp_series_name_path -Destination $directorio_destino_con_scrapping -Force -Confirm:$False -ErrorAction:SilentlyContinue -verbose:$verbose 
            
        } else {
            # No todos los comics han sido procesados. Se puede mover el directorio
            write-host "  >> NO TODOS LOS COMICS HAN SIDO CORRECTAMENTE PROCESADOS"
            move-item -LiteralPath $Global:dp_series_name_path -Destination $directorio_destino_sin_scrapping -Force -Confirm:$False -ErrorAction:SilentlyContinue -verbose:$verbose 
        }
        write-host "  >> Muevo la serie de comics a $series_dir_final"
    }

    # PARO LA TRANSCRIPCION DE LOGS
    Stop-Transcript -verbose:$verbose 
    start-sleep 1
    
}