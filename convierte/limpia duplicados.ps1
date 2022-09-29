get-childitem -literalpath "J:\comics" -directory -recurse -exclude ".yacreaderlibrary","covers"| foreach-object { 
    
    $m_dir = $_.fullname
    # $m_dir = (get-childitem -literalpath "J:\COMICS\EDITORIAL - Soleil, Delcourt, Le Lombard\Cartago (De G Lassabliere Y De M Luca)(Ed Soleil)(2010-11)").fullname
    
    # write-host "BUSCANDO EN DIRECTORIO: "$m_dir
    get-childitem -literalpath $m_dir -file | foreach-object {
        $v_dir = $_.DirectoryName
        $v_name = $_.BaseName -replace  "(\[|\])" , "*" 
        $v_ext = $_.Extension
        $v_ficheros = get-childitem -literalpath $v_dir -include $v_name
        $v_duplicados = $v_ficheros.count
        # write-host "COMPROBANDO FICHERO: " $v_dir " | " $v_name " | " $v_ficheros " | " $V_duplicados

        if ( ($v_duplicados -gt 1) -and ($v_ext -eq ".cbr") ) {
            write-host "ENCONTRADO DUPLICADO: "$_.fullname -ForegroundColor red
            remove-item  -literalpath $_.fullname -verbose -force 
        }
    } 
}