$film_folder = "v:"

# list all files with extension mkv in root_folder
get-childitem -recurse $film_folder -filter "*.mkv" | foreach-object {
    $v_json = mkvmerge.exe -J $_.FullName 

    $json = $v_json.tracks[0]
    

    # Search in json for audio in "es" or "spa"
    if ($v_json -match "audio_tracks.*es") {
        $v_json_audio = "es"
    } elseif ($v_json -match "audio_tracks.*spa") {
        $v_json_audio = "spa"
    } else {
        $v_json_audio = "none"
    }

    # Search in json for audio in "es" or "spa"
    

}