$version = '5.2.2'
$id = 'zabbix-agent'
$title = 'Zabbix Agent'

$configDir = Join-Path $env:PROGRAMDATA 'zabbix'
$zabbixConf = Join-Path $configDir 'zabbix_agentd.conf'

$installDir = Join-Path $env:PROGRAMFILES $title
$zabbixAgentd = Join-Path $installDir 'zabbix_agentd.exe'

$tempDir = Join-Path $env:TEMP 'chocolatey\zabbix'
$binDir = Join-Path $tempDir 'bin'
$binFiles = @('zabbix_agentd.exe', 'zabbix_get.exe', 'zabbix_sender.exe')
$sampleConfig = Join-Path $tempDir 'conf\zabbix_agentd.conf'

$is64bit = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture) -match '64'
$service = Get-WmiObject -Class Win32_Service -Filter "Name=`'$title`'"

try {
  if ($service) {
    $service.StopService()
  }

  if (!(Test-Path $configDir)) {
    New-Item $configDir -type directory
  }

  if (!(Test-Path $installDir)) {
    New-Item $installDir -type directory
  }

  if (!(Test-Path $tempDir)) {
    New-Item $tempDir -type directory
  }

  $toolsDir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)

  if ($is64bit) {
    $zipFile = Join-Path $toolsDir "zabbix_agent-$version-windows-amd64-openssl.zip"
  }
  else {
    $zipFile = Join-Path $toolsDir "zabbix_agent-$version-windows-i386-openssl.zip"
  }

  Write-Host $zipFile 
  Write-Host $tempDir

  Get-ChocolateyUnzip  $zipFile $tempDir

  foreach ($executable in $binFiles ) {
    $file = Join-Path $binDir $executable
    Move-Item $file $installDir -Force
  }

  if (Test-Path "$installDir\zabbix_agentd.conf") {
    if ($service) {
      $service.Delete()
      Clear-Variable -Name $service
    }

    Move-Item "$installDir\zabbix_agentd.conf" "$configDir\zabbix_agentd.conf" -Force

  }
  elseif (Test-Path "$configDir\zabbix_agentd.conf") {
    $configFile = "$configDir\zabbix_agentd-$version.conf"
    Move-Item $sampleConfig $configFile -Force

  }
  else {
    $configFile = "$configDir\zabbix_agentd.conf"
    Move-Item $sampleConfig $configFile

  }

  if (!($service)) {
    Start-ChocolateyProcessAsAdmin "--config `"$zabbixConf`" --install" "$zabbixAgentd"
  }

  Start-Service -Name $title

  Install-ChocolateyPath $installDir 'Machine'

}
catch {
  Write-Host 'Error installing Zabbix Agent'
  throw $_.Exception
}
