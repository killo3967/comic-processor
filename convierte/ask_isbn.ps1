<#
GOOGLE
	https://www.google.es/search?hl=es&tbo=p&tbm=bks&q=isbn:9788415839019&num=10
	

AMAZON	
	Amazon.es busqueda avanzada- Permite la busqueda por palabras claves, titulo, autor isbn y editorial
	https://www.amazon.es/advanced-search/books?ie=UTF8
    https://www.amazon.es/s?i=stripbooks&rh=p_66%3A9782302076204&Adv-Srch-Books-Submit.x=0&Adv-Srch-Books-Submit.y=0&__mk_es_ES=%C3%85M%C3%85Z%C3%95%C3%91&unfiltered=1&ref=sr_adv_b
    https://www.amazon.es/s?i=stripbooks&rh=p_66%3A9782302076204 <- con esto es suficiente
    https://www.amazon.es/s?i=stripbooks&rh=p_66%3A<ISBN>
    https://www.amazon.es/s?k=isbn+9782302059184&i=stripbooks&rh=n%3A599364031%2Cn%3A902516031%2Cn%3A28166967031%2Cp_n_availability%3A831279031&dc&ds=v1%3A3AkCkXp0g7Z29SxB6HTkVKuKZWJt%2B1JzdTleozHQAeY&__mk_es_ES=%C3%85M%C3%85%C5%BD%C3%95%C3%91&crid=1XCY9TRCOYRTY&qid=1665055773&rnid=599364031&sprefix=isbn+9782302059184%2Cstripbooks%2C92&ref=sr_nr_n_1
    https://www.amazon.com/advanced-search/books
    "https://www.amazon.es/s?i=stripbooks&rh=n%3A902516031%2Cp_66%3A$isnbAdv-Srch-Books-Submit.x=26&Adv-Srch-Books-Submit.y=10&__mk_es_ES=%C3%85M%C3%85Z%C3%95%C3%91&unfiltered=1&ref=sr_adv_b"
    
    
ISBNSEARCH
    Sabiendo un ISBN busco en la web https://isbnsearch.org por los datos de la serie


BOOKFINDER
    https://www.bookfinder.com/search/?author=&title=&lang=en&isbn=9782800148762&submitBtn=Search&new_used=*&destination=es&currency=EUR&mode=basic&st=sr&ac=qr

#>

function buscar_año_isbn_ocr {

    #Llamo a isbnsearch.org
    buscar_isbn_bookfinder

    if ($Global:dp_ocr_year -eq ''){
        # No se ha encontrado el año. Buscando en ISBNsearch.org 
        buscar_isbn_isbnsearch
    }

    
}

# TODO: hay que implementar la busqueda por otras webs. Habria que implementar esto como un plugin

function buscar_isbn_bookfinder {
    $isbn = $Global:dp_ocr_isbn
    $uri="https://www.bookfinder.com/search/?author=&title=&lang=en&isbn=$isbn&submitBtn=Search&new_used=*&destination=es&currency=EUR&mode=basic&st=sr&ac=qr
    "
    $comic_year = ''
    
    $Request = Invoke-WebRequest -Uri $uri
    $Parser = New-Object AngleSharp.Html.Parser.HtmlParser
    $Parsed = $Parser.ParseDocument($Request.Content)

    $ForecastList = $Parsed.All | Where-object { $_.classname -eq 'describe-isbn' }
    # En la misma linea esta el Publisher seguido del año (o no)
    if ( $ForecastList.length -gt 0 ) {
        if ( ($ForecastList.Textcontent[0] -split ',') -eq 1 ) {
            # Solo hay un dato. El publisher y no hay año
            $Publisher = ($ForecastList.Textcontent[0]).trim()
            #$ ASIGNACION DE VARIABLE GLOBAL
            $Global:dp_ocr_publisher = $Publisher
            $Global:dp_ocr_year = ''
        } else {
            $Publisher = ($ForecastList.Textcontent[0] -split ',')[0].trim()
            $comic_year = ($ForecastList.Textcontent[0] -split ',')[1].trim()
                #$ ASIGNACION DE VARIABLE GLOBAL
                $Global:dp_ocr_year = $comic_year
                $Global:dp_ocr_publisher = $Publisher
        }
    } else {
        # No se han obtenido datos ni de Publisher ni del año 
        write-host "   >> Error en la respuesta de bookfinder.com" -ForegroundColor Red
        $Global:dp_ocr_year = ''
        $Global:dp_ocr_publisher = ''
    }
}




function buscar_isbn_isbnsearch {
    $isbn = $Global:dp_ocr_isbn
    $uri="https://isbnsearch.org/search?s="
    $comic_year=''
    
    $Request = Invoke-WebRequest -Uri $uri+$isbn
    $Parser = New-Object AngleSharp.Html.Parser.HtmlParser
    $Parsed = $Parser.ParseDocument($Request.Content)
    $ForecastList = $Parsed.All | Where-Object {  $_.Classname -eq "bookinfo" }
    if ( $ForecastList.length -gt 0 ) {
        for ( $i=1 ; $i -lt ($ForecastList.childnodes.length) ; $i=$i+2 ) {
            $v_valor = $ForecastList.childnodes[$i].TextContent
            switch -Regex ($v_valor) 
            {
                "ISBN-13"           {$isbn13 = ($v_valor.split(':'))[1].trim()}
                "ISBN-10"           {$isbn10 = ($v_valor.split(':'))[1].trim()}
                "Author"            {$Author = ($v_valor.split(':'))[1].trim()}
                "Binding"           {$Binding = ($v_valor.split(':'))[1].trim()}
                "Publisher"         {$Publisher = ($v_valor.split(':'))[1].trim()}
                # El año esta en Published con el formato "Published: mes año"
                "Published"         {$Published = ($v_valor.split(':'))[1].trim()}
                default             {$comic_name = ($v_valor.split(':'))[1].trim()}
            }
            # Solo me hacen falta las variable de año y publisher, pero dejo las demas por si las necesitase en un futuro
        }
        #$ ASIGNACION DE VARIABLE GLOBAL
        $Global:dp_ocr_year = ($Published.split(' '))[1]
        $Global:dp_ocr_publisher = $Publisher.Trim()
    } else {
        # A veces esta web fuerza un captcha y da una respuesta vacia 
        write-host "   >> Error en la respuesta de isbnsearch.org" -ForegroundColor Red
        $Global:dp_ocr_year.clear()
        $Global:dp_ocr_publisher.clear()
    }
}

function buscar_isbn_google {

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri="https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn"

    #turning off the progress bar
    $ProgressPreference = 'SilentlyContinue'

    $Request = Invoke-WebRequest -Uri $uri -method 'GET' -UserAgent $Global:user_agent
    if ($response.statuscode -eq '200') {
        $isbnresult= ConvertFrom-Json $request.Content
        
        # Ahora recojo los datos
        $Global:dp_comic_name               = ($isbnresult.items.volumeinfo.title).trim()
        $comicinfo_xml.ComicInfo.Writer     = ($isbnresult.items.volumeinfo.authors -join ',').trim()
        $Global:dp_series_year              = ($isbnresult.items.volumeinfo.publishedDate -split '-')[0].trim()
        $comicinfo_xml.ComicInfo.Web        = ($isbnresult.items.volumeinfo.canonicalVolumeLink).trim()
        $comicinfo_xml.ComicInfo.Genre      = ($isbnresult.items.volumeinfo.categories -join ',').trim()            # Es el genero
        #TODO Hay que añadir el genero el ask_comicvine y en metadata
    }

}


function buscar_isbn_bne {

}

function buscar_isbn_amazon {
    # Sacado de https://webservices.amazon.com/paapi5/documentation/sending-request.html

$uri = "https://www.amazon.es/s?i=stripbooks&rh=n%3A902516031%2Cp_66%3A$isbn&Adv-Srch-Books-Submit.x=26&Adv-Srch-Books-Submit.y=10&__mk_es_ES=%C3%85M%C3%85Z%C3%95%C3%91&unfiltered=1&ref=sr_adv_b"


    


}

