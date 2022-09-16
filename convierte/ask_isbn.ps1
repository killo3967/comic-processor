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