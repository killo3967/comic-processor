# Estructura de un fichero comicinfo.xml segun especificaciones proyecto ANASI
# https://github.com/anansi-project/comicinfo/blob/main/schema/v2.0/ComicInfo.xsd
# Este proyecto no incluye los campo especiales ISBN, comicvine_issue y comicvine_volume.
# Esto lo hago para futuro uso.
# Tampoco voy a incluir los datos de las paginas ya que en muchos casos no son relevantes.


create_comicinfo{

    
}


function create_xml_pages_section {

    $lista = (& magick identify -format "\<Page Type=\"" \"" ImageHeight=\""%w\""  ImageWith=\""%h\""  ImageSize=\""%B\""  Image=\""%t\""\/\> \n" "$comic_final_dir\*.jpg" ) 

    $Pages = $comicinfo_xml.CreateNode('element', 'Pages', '') 

    for ( $k=0 ; $k -lt (get-childitem "$comic_final_dir\*.jpg").count ; $k++) {
        $fichero = (get-childitem -literalpath $comic_final_dir -include *.jpg -file)[0].fullname
        $lista[$k] = (& magick identify -format "\<Page Type=\"" \"" ImageHeight=\""%w\""  ImageWith=\""%h\""  ImageSize=\""%B\""  Image=\""%t\""\/\> \n\r" $fichero)
        $datos = $lista[$k] + "`r`n"
        $data = $comicinfo_xml.CreateTextNode($datos)  
        [void]$Pages.AppendChild($data)    
    }

    $node = $comicinfo_xml.SelectSingleNode("//ISBN") 
    [void]$node.ParentNode.InsertBefore($Pages, $node)  

}
