[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
# $isbn = '84-89966-15-X'
$uri="https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn"

#turning off the progress bar
$ProgressPreference = 'SilentlyContinue'

$Request = Invoke-WebRequest -Uri $uri -method 'GET' -UserAgent $Global:user_agent

if ($response.statuscode -eq '200') {
    $isbnresult= ConvertFrom-Json $request.Content
    
    # Ahora recojo los datos
    $titulo     = ($isbnresult.items.volumeinfo.title).trim()
    $authors    = ($isbnresult.items.volumeinfo.authors -join ',').trim()
    $year       = ($isbnresult.items.volumeinfo.publishedDate -split '-')[0].trim()
    $web        = ($isbnresult.items.volumeinfo.canonicalVolumeLink).trim()
    $category   = ($isbnresult.items.volumeinfo.categories -join ',').trim()
}

    


