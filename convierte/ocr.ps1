<#
aqui dice como hacer el ocr de una imagen de un comic
lo hago para buscar datos del ISBN, del año y de la editorial
de esta forma despues se puede hacer el scrapping a comicvine mejor
https://github.com/largecats/comics-ocr/blob/master/comicsocr/src/reader.py
Es excesivamente complejo 
Voy a seguir estos consejos
https://tesseract-ocr.github.io/tessdoc/ImproveQuality.html
que me llevan a:
http://www.fmwconcepts.com/imagemagick/textcleaner/index.php


#>

function escaner_ocr {

    $imagen_salida = "$ocr_temp_dir\imagen_salida.jpg"
    $texto_salida_ocr = "$ocr_temp_dir\texto.txt"

    # Escaneo las 5 primeras y 3 ultimas imagenes del comic para buscar los datos necesarios
    # Esto lo hago ya que a veces no encuentro 
    :outer foreach ( $imagen_id in @(0,1,2,3,4,-3,-2,-1)) {

        $imagen = (get-childitem -literalpath $comic_final_dir -include *.jpg,*.bmp,*.png,*.webp -file )[$imagen_id].fullname
        write-host "   >> Seleccionada imagen para OCR: $imagen"

        # Preparo la imagen para una mejor lectura
        #! Esto hay que convertirlo en una funcion de powershell
        Remove-Item -LiteralPath $imagen_salida -Force -ErrorAction SilentlyContinue -Verbose:$verbose | out-null
        & C:\scripts\convierte\textcleaner.sh  $imagen $imagen_salida
        write-host "   >> Mejorando imagen para OCR: $imagen"
        # Como es un procedimiento asincrono espero hasta que se cree la imagen
        while (!( Test-Path $imagen_salida )) { Start-Sleep 1 }
        

        # Ahora procedo a escanear la imagen y generar un fichero tsv.
        # Despues de escanear la imagen, se puede usar el fichero tsv para extraer los datos.
        write-host "   >> Generando datos en formato TSV del OCR"
        $tsv_salida = (& $tesseract $imagen_salida stdout --dpi 1200 --psm 6 --oem 1 -c preserve_interword_spaces=1,textord_min_xheight=6 tsv quiet)

        # Convierto el fichero TSV en un formato inteligible en formato texto.
        write-output $null > $texto_salida_ocr
        write-host "   >> Procesando datos del OCR"
        $ocr_csv = ( $tsv_salida | Convertfrom-Csv -Delimiter "`t" )
        write-host "   >> Generando fichero de texto"
        
        # Existe un campo 'conf" que es la confiabilidad del OCR
        # Cuando conf vale -1 es un retorno de carro
        # Lo junto todo en un fichero de texto
        $ocr_csv | where-object { $_.conf -gt $confianza_ocr -or $_.conf -eq -1 } | foreach-object {
            if ($_.conf -ne -1) { 
                write-output (" " + $_.text) | out-file -filepath $texto_salida_ocr -NoNewLine -Append
            } else {
                write-output "" | out-file -filepath $texto_salida_ocr -Append
            }
        }

        # Primero busco el ISBN. Si lo encuentro llamare a la web de isbnsearch.org para obtener el dato del año.
        write-host "   >> Buscado ISBN"
        $v_isbn = buscar_isbn_ocr
        if ( $v_isbn.length -ne 0 ) {
            $v_isbn = $v_isbn -replace '\.' , ''
            $v_isbn = $v_isbn -replace ':' , ''
            $v_isbn = $v_isbn -replace '-' , ''
            $v_isbn = $v_isbn -replace ' ' , ''  
            write-host "   >> Encontrado ISBN: $v_isbn" -ForegroundColor yellow
            
            #$ ASIGNACION DE VARIABLE GLOBAL  
            $Global:dp_ocr_isbn = $v_isbn     
            
            # Ahora llamo a la web de isbnsearch.org para obtener el dato del año
            # $v_año = buscar_año_isbn_ocr $v_isbn
            # $v_año = 
            $Global:dp_ocr_year = @()
            $Global:dp_ocr_year.Clear()
            buscar_año_isbn_ocr
            
            # if ( $null -ne $v_año ) {
            if ( $null -ne $Global:dp_ocr_year ) {
              
                write-host "   >> Encontrado año en ISBN: $v_año" -ForegroundColor yellow       
            }
            break outer      
        } else {
            # como no he encontrado el isnb busco el año
            $v_año = buscar_año_ocr
            write-host "   >> Buscado año usando OCR"
            if ( $v_año -gt 1960 -and $v_año -lt 2020 ) {
                write-host "   >> Encontrado año por OCR: $v_año" -ForegroundColor yellow
                # exit main loop
                break outer
            } else {
                write-host "   >> Año no encontrado"
                write-host "   >> ========================================================================================================================="
                $v_año = ''
            }
        }    
    }
    return $v_año
}

function buscar_isbn_ocr {   

    $texto_salida_ocr = "$ocr_temp_dir\texto.txt"
    
    # Delante tiene la palabra isbn seguida de 2 puntos (o no)  y separados por punto (o no)
    $encontrados = [regex]::match( (get-content $texto_salida_ocr) , '(I\.?S\,?B\.?N\.?\:?)(.*)' )

    if ($encontrados.success -eq $true){
        $isbn = $encontrados.Groups[2].value
    } else {
        $isbn = '' 
    }
    return $isbn
}

function buscar_año_ocr {   
    $texto_salida_ocr = "$ocr_temp_dir\texto.txt"

    $encontrados = [regex]::matches( (get-content $texto_salida_ocr) , '[(1|2][9|0][67890123]\d{2}' )

    $v_año = @()
    if ($encontrados.success -eq $true){
        for ( $i = 0 ; $i -lt $encontrados.count ; $i++ ) {
            $v_año += $encontrados[$i].value
        }
    } else {
        $v_año = ''
    }
    # Elimino posibles duplicados
    $v_año = ( $v_año | sort-object -unique )

    return $v_año
}




