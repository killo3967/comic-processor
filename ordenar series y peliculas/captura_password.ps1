# Sacamos la lista de directorios que hay en "D:\PUBLIC\INCOMING\tv-sonarr"
clear-host

$base_direcotry = 'D:\PUBLIC\INCOMING\tv-sonarr'
$7z = 'C:\Program Files\7-Zip\7z.exe'

get-childitem -literalpath "$base_direcotry" -recurse -directory | foreach-object {

        # Inicializo variables
        $password = ""
        $url_password = ""
        $HTML = ""

        # Primero hay que buscar el fichero rar. Si existe hay que ver con la siguiente orden si tiene contraseña
        $ruta = $_.fullname

        $file_compress = (get-childitem -literalpath $ruta | where-object { $_.name -like "*.rar" }).fullname

        # Compruebo que haya ficheros comprimidos
        if ( $null -ne $file_compress ) {       

                # Testeo el fichero a ver si esta encriptado con contraseña
                $file_password = (& $7z l -slt -- $file_compress) | select-string -pattern "Encrypted = +" 

                # Si lo devuelto no es null es que esta encriptado con contraseña.
                # Cuando se ejecuta lo anterior y devuelve en una linea "Encrypted = +", entonces procedemos a buscar el fichero de contraseñas. Sacamos la url que contiene y
                # decodificamos la web para extraer la contraseña y entonces descomprimimos el fichero
                if ( $null -ne $file_password ) { 
                        
                        # Busco el fichero que contiene la web donde esta la contraseña que suele tener en el nombre la palabra CONTRASEÑA en PCTRELOAD
                        $url = (get-childitem -literalpath $ruta | where-object { $_.name -like "*CONTRASEÑA*" }).fullname
                        $compress_file = (get-childitem -literalpath $ruta | where-object { ($_.name -like "*.rar") -or ($_.name -like "*.zip") }).fullname

                        if ( $null -ne $url ) {
                                # Extraigo la contraseña de la pagina web
                                $url_password = (((get-content -literalpath $url | select-string -pattern 'URL').tostring().split('='))[1])
                                $url_password = $url_password -replace ( 'maxitorrent.com' , 'atomixhq.com' )
                                $HTML = Invoke-WebRequest $url_password
                                $password = (($HTML.content.split("<") | select-string "txt_password")[0] -split '"')[9]
                                write-host "Password encontrado: $password"
                                
                                # aqui se tiene que extraer el fichero
                                write-host "Descomprimir: $compress_file"
                                $result = (& $7z  x $compress_file -p"$password" -y -o"$base_direcotry")
                                
                                # Compruebo si se ha descomprimido bien
                                if ($result[17] -eq "Everything is Ok") {
                                        write-host "Extraccion correcta"
                                }
                                else {
                                        write-host "Ha fallado la extracion"
                                }
                        }
                        else {
                                write-host "Fichero de contraseñas no encontrado"
                        }

                }
                else {
                        # Si no tiene contraseña se extrae normalmente 
                        write-host "Descomprimir $compress_file sin contraseña"
                        # Lo descomrimo en el directorio anterior por lo que no hace falta moverlo
                        $result = (& $7z x $compress_file -y -o"$base_direcotry")
                        if ($result[17] -eq "Everything is Ok") {
                                write-host "Extraccion correcta" 

                        }
                        else {
                                write-host "Ha fallado la extracion"
                        }
                }  
                write-host "================================================================================================================================================"
                # continue
        }
        else {
                # No hay ficheros comprimidos
                write-host "No hay ficheros comprimidos, moviendo el fichero"
                $file_compress = (get-childitem -literalpath $ruta | where-object { $_.name -like "*.mkv" -or $_.name -like "*.avi" }).fullname
                move-item -LiteralPath $file_compress -Destination "$base_direcotry" -Force -ErrorAction SilentlyContinue -Verbose
        }

}