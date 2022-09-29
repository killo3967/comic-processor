#
# Variable donde se encuentran los datos finales y de procesos del comic.
#
[xml]$Global:comic = @(
"<?xml version=""1.0""?>",
"<ComicInfo xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema"">",
    "<Title>$null</Title>"
    "<Series>$null</Series>"
    "<Number>$null</Number>"
    "<Count>$null</Count>"
    "<Volume>$null</Volume>"
    "<Storyarc>$null</Storyarc>"
    "<Summary>$null</Summary>"
    "<Notes>$null</Notes>"
    "<Year>$null</Year>"
    "<Month>$null</Month>"
    "<Day>$null</Day>"
    "<Writer>$null</Writer>"
    "<Penciller>$null</Penciller>"
    "<Inker>$null</Inker>"
    "<Colorist>$null</Colorist>"
    "<Letterer>$null</Letterer>"
    "<CoverArtist>$null</CoverArtist>"
    "<Editor>$null</Editor>"
    "<Publisher>$null</Publisher>"
    "<Web>$null</Web>"                               
    "<PageCount>$null</PageCount>"
    "<Characters>$null</Characters>"
    "<Teams>$null</Teams>"
    "<Locations>$null</Locations>"
    "<ISBN>$null</ISBN>"
    "<comicvine_issue_id>$null</comicvine_issue_id>"
    "<comicvine_volume_id>$null</comicvine_volume_id>"
"</ComicInfo>"
   
)

[string]$Global:dp_series_name                       #? Nombre de la serie obtenido del directorio del comic
[string]$Global:dp_series_name_path                  #? Nombre del directorio de la serie ( se usa para extraer el nombre, año y publisher )

[int]$Global:dp_comic_issue                          #? Numero del comic en la serie ( obtenido del nombre del comic ) 
[string]$Global:dp_comic_fullname                    #? Ruta completa del comic ( incluida la extension )
[string]$Global:dp_comic_path                        #? Directorio completo donde se encuentra el comic
[string]$Global:dp_comic_name                        #? Nombre del comic sin extension
[string]$Global:dp_comic_extension                   #? Extension del fichero del comic

[string]$Global:dp_comic_year                        #? Año obtenido del nombre del comic
[string]$Global:dp_series_path_year                  #? Año obtenido del directorio del comic ( $dp_series_name_path )
[string]$Global:dp_series_path_publisher             #? Publisher obtenido del directorio del comic ( $dp_series_name_path )

[array]$Global:dp_ocr_year = @()                     #? Año extraido mediante OCR de las imagenes (Pueden ser varios años)
[array]$Global:dp_ocr_publisher = @()                #? Publisher extraido mediante OCR de las imagenes (Pueden ser varios publisher)
[string]$Global:dp_ocr_isbn                          #? ISBN extraido mediante OCR de las imagenes

[Boolean]$Global:dp_comic_vine_match = $False        #? Se ha encontrado el comic en ComicVine

