$start_time = Get-Date


$qtd = 2
$array = @{0 = 'http://download.windowsupdate.com/d/csa/csa/secu/2017/02/windowsserver2003-kb4012598-x64-custom-enu_f24d8723f246145524b9030e4752c96430981211.exe', 'ms17-012.msu'
1 = 'http://download.windowsupdate.com/d/msdownload/update/software/secu/2017/02/windows6.1-kb4012212-x64_2decefaa02e2058dcd965702509a992d8c4e92b3.msu', 'ms17-010.msu'
}


for($i=0; $i -lt $qtd; $i++){
$dictArray = $array[$i]
$wc = New-Object System.Net.WebClient
$path = "C:\Users\$env:username\"+$dictArray[1]
Write-Output "Baixando no diretorio: $path"
$wc.DownloadFile($dictArray[0], $path)

}


$dir = (Get-Item -Path ".\" -Verbose).FullName
foreach($item in (ls $dir *.msu -Name))
{
echo "Instalando: $item"
$item = $dir + "\" + $item
wusa $item

}

echo "Deletando arquivos .msu "
rm $dir\*.msu