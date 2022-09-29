$v_comics = get-childitem -literalpath "J:\comics" -file -recurse -exclude "UNIVERSO" -include *.cbr,*.cbz,*.pdf
write-host "Lectura de comics finalizada. Procediendo a la comparacion"
for ($i=1; $i -lt $v_comics.count ; $i++) {
    $v_comic_name = $v_comics[$i].BaseName + $v_comics[$i].extension
    if ( ($v_comics -match $v_comic_name).count -gt 1 ) {
        write-output ($v_comics -match "^$v_comic_name$").fullname | format-table | Out-File c:\comic-duplicados.txt -append
        write-output "======================================================================================================================================="| Out-File c:\comic-duplicados.txt -append
    }
}

