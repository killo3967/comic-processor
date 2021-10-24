$pattern = @(
    "Info",
    "SkyHookProxy",
    "IndexerException",
    "server is currently unavailable",
    "The SSL connection could not be established",
    "ExistingSubtitleImporter",
    "ExistingOtherExtraImporter",
    "ExistingExtraFileService",
    "DiskScanService"
    "ProcessDownloadDecisions"
    "DownloadMonitoringService"
    "An error occurred while processing indexer feed"
    "DownloadMonitoringService"
    "Unable to read data from the transport"
    "Failed to connect to qBittorrent"
    "Error occurred while executing task CheckHealth"
    "No se puede establecer una conexión ya que el equipo de destino"
    "Se ha forzado la interrupción de una conexión existente por el host remoto."
)


get-childitem "C:\ProgramData\Radarr\logs\radarr.*.txt" | foreach-object { 
    get-content $_.fullname | select-string -pattern "Access to the path"

} | out-gridview