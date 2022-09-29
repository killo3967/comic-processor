<#
GOOGLE
	https://www.google.es/search?hl=es&tbo=p&tbm=bks&q=isbn:9788415839019&num=10
	

BNE (biblioteca Nacional de España)
	http://catalogo.bne.es/uhtbin/ptp?http://www.syndetics.com/index.aspx?isbn=9788415839019/INDEX.XML&client=biblionaces&type=xw12&upc=&oclc=
	
	
AMAZON	
	Amazon.es busqueda avanzada- Permite la busqueda por palabras claves, titulo, autor isbn y editorial
	https://www.amazon.es/advanced-search/books?ie=UTF8
    https://www.amazon.es/s?i=stripbooks&rh=p_66%3A9782302076204&Adv-Srch-Books-Submit.x=0&Adv-Srch-Books-Submit.y=0&__mk_es_ES=%C3%85M%C3%85Z%C3%95%C3%91&unfiltered=1&ref=sr_adv_b
    https://www.amazon.es/s?i=stripbooks&rh=p_66%3A9782302076204 <- con esto es suficiente
    https://www.amazon.es/s?i=stripbooks&rh=p_66%3A<ISBN>
    
ISBNSEARCH
    Sabiendo un ISBN busco en la web https://isbnsearch.org por los datos de la serie
#>

function buscar_año_isbn_ocr {

    <#
    Param (
        [Parameter(Mandatory=$true)]
        $isbn
    )
    #>
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
                "ISBN-13"           {$isbn13 = $v_valor}
                "ISBN-10"           {$isbn10 = $v_valor}
                "Author"            {$Author = $v_valor}
                "Binding"           {$Binding = $v_valor}
                "Publisher"         {$Publisher = $v_valor}
                "Published"         {$Published = $v_valor}
                "year"              {$comic_year = $v_valor}
                default             {$comic_name = $v_valor}
                # Solo me hacen falta las variable de año y publisher, pero dejo las demas por si las necesitase en un futuro
            }
        }
        # Extraigo el año del comic si existe
        # [int]$comic_year = ($comic_year -replace '(.*)(\d{4})' , '$2').Trim()
        
        #$ ASIGNACION DE VARIABLE GLOBAL
        $Global:dp_ocr_year = ($comic_year -replace '(.*)(\d{4})' , '$2').Trim()
        $Global:dp_ocr_publisher = $Publisher.Trim()

    } else {
        # A veces esta web fuerza un captcha y da una respuesta vacia 
        write-host "   >> Error en la respuesta de isbnsearch.org" -ForegroundColor Red
        $Global:dp_ocr_year.clear()
        $Global:dp_ocr_publisher.clear()
    }
    
    # TODO: hay que implementar la busqueda por otras webs

    # Return $comic_year
}