# invert name of file with dash between them
$libros = Get-ChildItem -literalpath 'D:\PUBLIC\JDOWNLOADER\CliffordSimak By NPRS\' -include '*.doc'

$libros | ForEach-Object {
    $nombre = ($_.BaseName.split(' - '))[1]
    $autor = ($_.BaseName.split(' - '))[0]
    $new_base_name = $nombre + " - " + $autor
    $new_base_name
    $new_name = $_.DirectoryName + "\" + $new_base_name + $_.Extension

    Rename-Item -path $_.FullName -NewName $new_name 

    write-host =================================================================
}
