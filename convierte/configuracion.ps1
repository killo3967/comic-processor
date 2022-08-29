# Grupo de funciones para obtener la configuracion de un fichero de texto
function get-config {
    Foreach ($i in $(Get-Content script.conf)){
        $nombre_variable = $i.split("=")[0].trim()
        $valor_variable = $i.split("=",2)[1].trim() 
        if ( $nombre_variable -contains "perfil" ){
            # Ver como detectar el perfil activo y modificar los valores de las variables dentro del perfil.
            # Si el perfil no esta activo seguir hasta el fin del perfil <perfil> <\perfil>

        } else {
        Set-Variable -Name $nombre_variable -Value $valor_variable -Scope Global -verbose:$verbose
        }    
    }
}