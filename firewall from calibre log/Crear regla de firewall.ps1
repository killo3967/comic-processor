# Crear regla de firewall debido a un intento de acceso a calibre
(get-content -path "C:\Users\server\AppData\Local\calibre-cache\server-access-log.txt" | select-string -notmatch "192.168.1","127.0.0.1") | foreach-object {
     ( $_ -split ' ' )[0] 
    } | sort-object -unique | foreach-object { 
        New-NetFirewallRule -DisplayName "BLOCK SCANNERS" -Direction Inbound -Action Block -Enabled 1 -RemoteAddress "$_" 
    }
