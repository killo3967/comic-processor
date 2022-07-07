function traduce_deepl {

    Param (
        [Parameter(Mandatory=$true)]
        [String] $nombre_serie
    )

# Esta es la api_key de deepl-api-free que permite 500.000 caracteres diarios y es gratis 
$deepl_api_key = "c614d9d4-54dc-f4dd-22b9-6d7daef47864:fx"

# Url para usar la api de deepl
$url = "https://api-free.deepl.com/v2/translate"
# Parametros para la api de deepl
$headers = @{
    'headers' = 'Content-Type: application/x-www-form-urlencoded'
}
$method = 'POST'
$body = @{
    'auth_key'=$deepl_api_key
    'text'=$nombre_serie
    'source_lang'='ES'
    'target_lang'="EN"
}

# &auth_key=$deepl_api_key&text=""$comic_serie""&""target_lang=EN"""
$result = Invoke-WebRequest -uri $url -headers $headers -method $method -body $body


$resultado = ($result.content | convertfrom-json).translations.text

return $resultado

}