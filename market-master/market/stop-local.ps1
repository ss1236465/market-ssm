$ErrorActionPreference = 'Stop'
$marketConfig = Get-Content -LiteralPath (Join-Path $PSScriptRoot '.local\runtime.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$marketLocal = Join-Path $marketConfig.projectRoot '.local'
$marketJava = Join-Path $marketConfig.javaHome 'bin\java.exe'
$marketClassPath = (Join-Path $marketConfig.tomcatHome 'bin\bootstrap.jar') + ';' + (Join-Path $marketConfig.tomcatHome 'bin\tomcat-juli.jar')
$marketTomcatPidFile = Join-Path $marketLocal 'tomcat.pid'
if (Test-Path -LiteralPath $marketTomcatPidFile) {
    $marketTomcatId = [int](Get-Content -LiteralPath $marketTomcatPidFile -Raw)
    $marketTomcatProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$marketTomcatId" -ErrorAction SilentlyContinue
    if ($marketTomcatProcess -and $marketTomcatProcess.CommandLine -like "*$($marketConfig.tomcatBase)*") {
        & $marketJava "-Dcatalina.home=$($marketConfig.tomcatHome)" "-Dcatalina.base=$($marketConfig.tomcatBase)" -classpath $marketClassPath org.apache.catalina.startup.Bootstrap stop
        Wait-Process -Id $marketTomcatId -Timeout 20 -ErrorAction SilentlyContinue
    }
}
$marketMysqlPidFile = Join-Path $marketLocal 'mysql.pid'
if (Test-Path -LiteralPath $marketMysqlPidFile) {
    $marketMysqlId = [int](Get-Content -LiteralPath $marketMysqlPidFile -Raw)
    $marketMysqlProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$marketMysqlId" -ErrorAction SilentlyContinue
    if ($marketMysqlProcess -and $marketMysqlProcess.CommandLine -like '*mysql.ini*') {
        & (Join-Path $marketConfig.mysqlHome 'bin\mysqladmin.exe') "--defaults-extra-file=$(Join-Path $marketLocal 'mysql-client.cnf')" --connect-timeout=5 shutdown
        if ($LASTEXITCODE -ne 0) { throw 'Could not shut down the project database.' }
    }
}
Write-Output 'Project stopped. Database contents were preserved.'
