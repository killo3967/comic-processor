# Estructura de un fichero comicinfo.xml segun especificaciones proyecto ANASI
# https://github.com/anansi-project/comicinfo/blob/main/schema/v2.0/ComicInfo.xsd
# Este proyecto no incluye los campo especiales ISBN, comicvine_issue y comicvine_volume.
# Esto lo hago para futuro uso.
# Tampoco voy a incluir los datos de las paginas ya que en muchos casos no son relevantes.


function create_comicinfo{
$out_data1 = @(
"<?xml version=""1.0""?>",
"<ComicInfo xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema"">",
("  <Title>" + $comic.r.Title + "</Title>"),
("  <Series>" + $comic.r.Series + "</Series>"),
("  <Number>" + $comic.r.Number + "</Number>"),
("  <Count>" + $comic.r.Count + "</Count>"),
("  <Volume>" + $comic.r.Volume + "</Volume>"),
("  <Storyarc>" + $comic.r.Storyarc + "</Storyarc>"),
("  <Summary>" + $comic.r.Summary + "</Summary>"),
("  <Notes>" + $comic.r.Notes + "</Notes>"),
("  <Year>" + $comic.r.Year + "</Year>"),
("  <Month>" + $comic.r.month + "</Month>"),
("  <Day>" + $comic.r.day + "</Day>"),
("  <Writer>" + $comic.r.Writer + "</Writer>"),
("  <Penciller>" + $comic.r.penciller + "</Penciller>"),
("  <Inker>" + $comic.r.inker + "</Inker>"),
("  <Colorist>" + $comic.r.colorist + "</Colorist>"),
("  <Letterer>" + $comic.r.letterer + "</Letterer>"),
("  <CoverArtist>" + $comic.r.CoverArtist + "</CoverArtist>"),
("  <Editor>" + $comic.r.editor + "</Editor>"),
("  <Publisher>" + $comic.r.Publisher + "</Publisher>"),
("  <Web>" + $comic.r.Web + "</Web>"),
("  <PageCount>" + $comic.r.PageCount + "</PageCount>"),
("  <Characters>" + $comic.r.Characters + "</Characters>"),
("  <Teams>" + $comic.r.Teams + "</Teams>"),
("  <Locations>" + $comic.r.Locations + "</Locations>")
)
$out_data2 = @(
("  <ISBN>" + $comic.r.isbn + "</ISBN>"),
("  <comicvine_issue_id>" + $comic.r.comicvine_issue_id + "</comicvine_issue_id>"),
("  <comicvine_volume_id>" + $comic.r.comicvine_volume_id + "</comicvine_volume_id>"),
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

