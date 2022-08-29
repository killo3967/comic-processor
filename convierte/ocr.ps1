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
    
    :outer foreach ( $imagen_id in @(0,1,2,3,4,-3,-2,-1)) {

        # Escaneo las 5 primeras y 3 ultimas imagenes del comic
        $imagen = (get-childitem -literalpath $comic_final)[$imagen_id].fullname
        write-host "   >> Seleccionada imagen para OCR: $imagen"

        # Preparo la imagen para una mejor lectura
        & C:\scripts\convierte\textcleaner.sh  $imagen $imagen_salida
        write-host "   >> Mejorando imagen para OCR: $imagen"
        
        # Esto escanea la imagen y da un fichero tsv.
        # Despues de escanear la imagen, se puede usar el fichero tsv para extraer los datos.
        write-host "   >> Generando datos en formato TSV del OCR"
        $tsv_salida = (& $tesseract $imagen_salida stdout --dpi 1200 --psm 6 --oem 1 -c preserve_interword_spaces=1,textord_min_xheight=6 tsv quiet)

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

        # Primero busco el ISBN. Si lo encuentro llamare a la web de isbnsearch.org para obtener el dato del año
        write-host "   >> Buscado ISBN"
        $v_isbn = buscar_isbn_ocr
        if ( $null -ne $v_isnb ) {
            $v_isbn = $v_isbn -replace '\.' , ''
            $v_isbn = $v_isbn -replace ':' , ''
            $v_isbn = $v_isbn -replace '-' , ''
            $v_isbn = $v_isbn -replace ' ' , ''  
            write-host "   >> Encontrado ISBN: "$v_isbn -foregrounf-color "yellow"       
            # Ahora llamo a la web de isbnsearch.org para obtener el dato del año
            $v_año = buscar_año_isbn_ocr $v_isbn
            
            if ( $null -ne $v_año ) {
                write-host "   >> Encontrado año en ISBN: "$v_año -foregrounf-color "yellow"       
            }
            break outer      
        } else {
            # como no he encontrado el isnb busco el año
            $v_año = buscar_año_ocr
            write-host "   >> Buscado año usando OCR"
            if ( $v_año -gt 1960 -and $v_año -lt 2020 ) {
                write-host "   >> Encontrado año por OCR: $v_año"
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

function buscar_año_ocr {   
    $texto_salida_ocr = "$ocr_temp_dir\texto.txt"

    $encontrados = [regex]::matches( (get-content $texto_salida_ocr) , '[(1|2][9|0][67890123]\d' )

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


function buscar_año_isbn_ocr {

    Param (
        [Parameter(Mandatory=$true)]
        $isbn
    )
    $uri="https://isbnsearch.org/search?s="
    $comic_year=''

    $Request = Invoke-WebRequest -Uri $uri+$isbn
    $Parser = New-Object AngleSharp.Html.Parser.HtmlParser
    $Parsed = $Parser.ParseDocument($Request.Content)
    $ForecastList = $Parsed.All | Where-Object {  $_.Classname  -eq "bookinfo" }
    # $comic_name = $ForecastList[1].TextContent
    # $comic_publisher = $ForecastList[11].TextContent
    $comic_year = $ForecastList[13].TextContent
    # Extraigo el año del comic
    [int]$comic_year = ($comic_year -replace '(.*)(\d{4})' , '$2').Trim()

    Return $comic_year
}