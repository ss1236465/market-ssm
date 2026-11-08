param([switch]$SkipBuild, [switch]$NoBrowser)
$ErrorActionPreference = 'Stop'
$marketConfig = Get-Content -LiteralPath (Join-Path $PSScriptRoot '.local\runtime.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$marketProject = $marketConfig.projectRoot
$marketLocal = Join-Path $marketProject '.local'
$marketJava = Join-Path $marketConfig.javaHome 'bin\java.exe'
$env:JAVA_HOME = $marketConfig.javaHome
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

function Test-MarketProcess([string]$PidFile, [string]$ExpectedArgument) {
    if (-not (Test-Path -LiteralPath $PidFile)) { return $false }
    $marketProcessId = [int](Get-Content -LiteralPath $PidFile -Raw)
    $marketProcess = Get-CimInstance Win32_Process -Filter "ProcessId=$marketProcessId" -ErrorAction SilentlyContinue
    return ($null -ne $marketProcess -and $marketProcess.CommandLine -like "*$ExpectedArgument*")
}

if (-not (Test-MarketProcess (Join-Path $marketLocal 'mysql.pid') 'mysql.ini')) {
    $marketMysqlIni = Join-Path $marketLocal 'mysql.ini'
    $marketMysqlProcess = Start-Process -FilePath (Join-Path $marketConfig.mysqlHome 'bin\mysqld.exe') -ArgumentList "--defaults-file=`"$marketMysqlIni`"" -WorkingDirectory $marketProject -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $marketLocal 'logs\mysql-stdout.log') -RedirectStandardError (Join-Path $marketLocal 'logs\mysql-stderr.log')
    Set-Content -LiteralPath (Join-Path $marketLocal 'mysql.pid') -Value $marketMysqlProcess.Id -Encoding ASCII
}

if (Test-MarketProcess (Join-Path $marketLocal 'tomcat.pid') $marketConfig.tomcatBase) {
    Write-Output "Already running: $($marketConfig.url)"
    if (-not $NoBrowser) { Start-Process $marketConfig.url }
    exit 0
}

Push-Location $marketProject
try {
    if (-not $SkipBuild) {
        Write-Output 'Building the Java project...'
        $marketMavenArgs = @('-B', '-ntp', '-DskipTests', 'package')
        $marketMavenSettings = Join-Path $marketLocal 'maven-settings.xml'
        if (Test-Path -LiteralPath $marketMavenSettings) { $marketMavenArgs = @('-s', $marketMavenSettings) + $marketMavenArgs }
        & $marketConfig.mavenCmd @marketMavenArgs *> (Join-Path $marketLocal 'logs\build.log')
        if ($LASTEXITCODE -ne 0) {
            Get-Content -LiteralPath (Join-Path $marketLocal 'logs\build.log') -Tail 45
            throw 'Build failed. See .local\logs\build.log.'
        }
    }
    $marketAppDirectory = Join-Path $marketProject 'target\chaoshi'
    if (-not (Test-Path -LiteralPath $marketAppDirectory)) { throw 'Build the project before using -SkipBuild.' }
    Copy-Item -LiteralPath (Join-Path $marketLocal 'db.properties') -Destination (Join-Path $marketAppDirectory 'WEB-INF\classes\db.properties') -Force
    $marketClassPath = (Join-Path $marketConfig.tomcatHome 'bin\bootstrap.jar') + ';' + (Join-Path $marketConfig.tomcatHome 'bin\tomcat-juli.jar')
    $marketJavaArgs = @('-Xms128m', '-Xmx512m', '-Dfile.encoding=UTF-8', '-Duser.timezone=Asia/Shanghai', "-Dcatalina.home=`"$($marketConfig.tomcatHome)`"", "-Dcatalina.base=`"$($marketConfig.tomcatBase)`"", "-Djava.io.tmpdir=`"$(Join-Path $marketConfig.tomcatBase 'temp')`"", "-Djava.util.logging.config.file=`"$(Join-Path $marketConfig.tomcatBase 'conf\logging.properties')`"", '-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager', '-classpath', "`"$marketClassPath`"", 'org.apache.catalina.startup.Bootstrap', 'start')
    $marketTomcatProcess = Start-Process -FilePath $marketJava -ArgumentList $marketJavaArgs -WorkingDirectory $marketProject -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $marketLocal 'logs\tomcat-stdout.log') -RedirectStandardError (Join-Path $marketLocal 'logs\tomcat-stderr.log')
    Set-Content -LiteralPath (Join-Path $marketLocal 'tomcat.pid') -Value $marketTomcatProcess.Id -Encoding ASCII
    for ($marketAttempt = 0; $marketAttempt -lt 120; $marketAttempt++) {
        Start-Sleep -Milliseconds 500
        if ($marketTomcatProcess.HasExited) { throw 'Tomcat stopped. See .local\logs\tomcat-stderr.log.' }
        try {
            $marketResponse = Invoke-WebRequest -Uri $marketConfig.url -UseBasicParsing -TimeoutSec 2
            if ($marketResponse.StatusCode -eq 200) {
                Write-Output "Running: $($marketConfig.url)"
                if (-not $NoBrowser) { Start-Process $marketConfig.url }
                exit 0
            }
        } catch { }
    }
    throw 'The application did not become ready. See .local\logs\tomcat-stderr.log.'
} finally {
    Pop-Location
}
