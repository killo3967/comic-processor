# Estructura de un fichero comicinfo.xml segun especificaciones proyecto ANASI
# https://github.com/anansi-project/comicinfo/blob/main/schema/v2.0/ComicInfo.xsd
# Este proyecto no incluye los campo especiales ISBN, comicvine_issue y comicvine_volume.
# Esto lo hago para futuro uso.
# Tampoco voy a incluir los datos de las paginas ya que en muchos casos no son relevantes.


function create_comicinfo{
$out_data1 = @(
"<?xml version=""1.0""?>",
"<ComicInfo xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema"">",
("  <Title>" + $comicinfo_xml.ComicInfo.Title + "</Title>"),
("  <Series>" + $comicinfo_xml.ComicInfo.Series + "</Series>"),
("  <Number>" + $comicinfo_xml.ComicInfo.Number + "</Number>"),
("  <Count>" + $comicinfo_xml.ComicInfo.Count + "</Count>"),
("  <Volume>" + $comicinfo_xml.ComicInfo.Volume + "</Volume>"),
("  <Storyarc>" + $comicinfo_xml.ComicInfo.Storyarc + "</Storyarc>"),
("  <Summary>" + $comicinfo_xml.ComicInfo.Summary + "</Summary>"),
("  <Notes>" + $comicinfo_xml.ComicInfo.Notes + "</Notes>"),
("  <Year>" + $comicinfo_xml.ComicInfo.Year + "</Year>"),
("  <Month>" + $comicinfo_xml.ComicInfo.month + "</Month>"),
("  <Day>" + $comicinfo_xml.ComicInfo.day + "</Day>"),
("  <Writer>" + $comicinfo_xml.ComicInfo.Writer + "</Writer>"),
("  <Penciller>" + $comicinfo_xml.ComicInfo.penciller + "</Penciller>"),
("  <Inker>" + $comicinfo_xml.ComicInfo.inker + "</Inker>"),
("  <Colorist>" + $comicinfo_xml.ComicInfo.colorist + "</Colorist>"),
("  <Letterer>" + $comicinfo_xml.ComicInfo.letterer + "</Letterer>"),
("  <CoverArtist>" + $comicinfo_xml.ComicInfo.CoverArtist + "</CoverArtist>"),
("  <Editor>" + $comicinfo_xml.ComicInfo.editor + "</Editor>"),
("  <Publisher>" + $comicinfo_xml.ComicInfo.Publisher + "</Publisher>"),
("  <Web>" + $comicinfo_xml.ComicInfo.Web + "</Web>"),
("  <PageCount>" + $comicinfo_xml.ComicInfo.PageCount + "</PageCount>"),
("  <Characters>" + $comicinfo_xml.ComicInfo.Characters + "</Characters>"),
("  <Teams>" + $comicinfo_xml.ComicInfo.Teams + "</Teams>"),
("  <Locations>" + $comicinfo_xml.ComicInfo.Locations + "</Locations>")
)
$out_data2 = @(
("  <ISBN>" + $comicinfo_xml.comicinfo.isbn + "</ISBN>"),
("  <comicvine_issue_id>" + $comicinfo_xml.ComicInfo.comicvine_issue_id + "</comicvine_issue_id>"),
("  <comicvine_volume_id>" + $comicinfo_xml.ComicInfo.comicvine_volume_id + "</comicvine_volume_id>"),
"</ComicInfo>"
    )

    remove-item $comicinfo_filepath -Force
    
    $out_data1 | ForEach-Object {
        write-output $_ | out-file -filepath $comicinfo_filepath -Encoding utf8 -Append 
    }

    create_xml_pages_section

    $out_data2 | ForEach-Object {
        write-output $_ | out-file -filepath $comicinfo_filepath -Encoding utf8 -Append 
    }


}


function create_xml_pages_section {
    $lista = @()
    $lista = (& magick identify -format "\<Page Type=\"" \"" ImageHeight=\""%w\""  ImageWith=\""%h\""  ImageSize=\""%B\""  Image=\""%t\""\/\> \n" "$comic_final_dir\*.jpg" ) 
    write-output "  <Pages>" | out-file -filepath $comicinfo_filepath -Encoding utf8 -Append 
    for ( $k=0 ; $k -lt (get-childitem "$comic_final_dir\*.jpg").count ; $k++) {
        $fichero = (get-childitem -literalpath $comic_final_dir -include *.jpg -file)[$k].fullname
        $lista[$k] = (& magick identify -format "%w-%h-%B-%t" $fichero)
        $i_with     =($lista[$k] -split'-')[0]
        $i_height   =($lista[$k] -split'-')[1]
        $i_size     =($lista[$k] -split'-')[2]
        $i_name     =($lista[$k] -split'-')[3]
        $lista[$k] = "    <Page Image=""$k"" ImageHeight=""$i_with""  ImageWith=""$i_height""  ImageSize=""$i_size"" Type="" ""/>"
        write-output $lista[$k] | out-file -filepath $comicinfo_filepath -Encoding utf8 -Append 
    }
    write-output "  </Pages>" | out-file -filepath $comicinfo_filepath -Encoding utf8 -Append 
}

<#$lista = (& magick identify -format "\<Page Type=\"" \"" ImageHeight=\""%w\""  ImageWith=\""%h\""  ImageSize=\""%B\""  Image=\""%t\""\/\> \n" "$comic_final_dir\*.jpg" ) 

    $Pages = $comicinfo_xml.CreateNode('element', 'Pages', '') 

    for ( $k=0 ; $k -lt (get-childitem "$comic_final_dir\*.jpg").count ; $k++) {
        $fichero = (get-childitem -literalpath $comic_final_dir -include *.jpg -file)[0].fullname
        # $lista[$k] = (& magick identify -format "\<Page Type=\"" \"" ImageHeight=\""%w\""  ImageWith=\""%h\""  ImageSize=\""%B\""  Image=\""%t\""\/\> \n\r" $fichero)
        $lista[$k] = (& magick identify -format "%w-%h-%B-%t" $fichero)
        $i_with     =($lista[$k] -split'-')[0]
        $i_height   =($lista[$k] -split'-')[1]
        $i_size     =($lista[$k] -split'-')[2]
        $i_name     =($lista[$k] -split'-')[3]
        $lista[$k] = "    <Page Type="" "" ImageHeight=""$i_with""  ImageWith=""$i_height""  ImageSize=""$i_size""  Image=""$i_name""\>"
        $datos = $lista[$k] + "`r`n"
        $data = $comicinfo_xml.CreateTextNode($datos)  
        [void]$Pages.AppendChild($data)    
    }

    $node = $comicinfo_xml.SelectSingleNode("//ISBN") 
    [void]$node.ParentNode.InsertBefore($Pages, $node)  #>