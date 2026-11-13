param(
    [string]$SqlText,
    [string]$SqlFile
)

$ErrorActionPreference = "Stop"

# 1. SQL 실행 내용 결정
if (-not [string]::IsNullOrWhiteSpace($SqlText)) {
    # 선택 영역이 있으면 선택한 SQL만 실행
    $SqlText = $SqlText.Trim()
    $ExecutionMode = "선택한 SQL 실행"
}
else {
    # 선택 영역이 없으면 현재 SQL 파일 전체 실행
    if ([string]::IsNullOrWhiteSpace($SqlFile)) {
        Write-Host "SQL 파일 경로를 전달받지 못했습니다." -ForegroundColor Red
        return
    }

    if (-not (Test-Path -LiteralPath $SqlFile -PathType Leaf)) {
        Write-Host "SQL 파일을 찾을 수 없습니다." -ForegroundColor Red
        Write-Host "경로: $SqlFile" -ForegroundColor Yellow
        return
    }

    $SqlFile = (Resolve-Path -LiteralPath $SqlFile).Path

    if ([IO.Path]::GetExtension($SqlFile) -ne ".sql") {
        Write-Host "SQL 파일(.sql)이 아닙니다." -ForegroundColor Red
        return
    }

    try {
        $SqlText = [System.IO.File]::ReadAllText(
            $SqlFile,
            [System.Text.Encoding]::UTF8
        )
    }
    catch {
        Write-Host "SQL 파일을 읽을 수 없습니다." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrWhiteSpace($SqlText)) {
        Write-Host "SQL 파일에 실행할 내용이 없습니다." -ForegroundColor Yellow
        return
    }

    $ExecutionMode = "SQL 파일 전체 실행"
}

# 2. SQLite 명령 확인
$SqliteCommand = Get-Command sqlite3 -CommandType Application -ErrorAction SilentlyContinue

if (-not $SqliteCommand) {
    Write-Host "sqlite3.exe를 찾을 수 없습니다. PATH를 확인하세요." -ForegroundColor Red
    return
}

# 3. 데이터베이스 경로 지정
$DatabaseFile = Join-Path $PSScriptRoot "02.실기\04.SQL\00.DatabaseFile\study.db"

if (-not (Test-Path -LiteralPath $DatabaseFile -PathType Leaf)) {
    Write-Host "데이터베이스 파일을 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "경로: $DatabaseFile" -ForegroundColor Yellow
    return
}

# 4. 실행 정보 출력
# Write-Host "========================================" -ForegroundColor Cyan
# Write-Host " SQLite SQL 실행" -ForegroundColor Cyan
# Write-Host "========================================" -ForegroundColor Cyan
# Write-Host "실행 방식: $ExecutionMode"
# Write-Host "DB 파일: $DatabaseFile"

# if (-not [string]::IsNullOrWhiteSpace($SqlFile)) {
#     Write-Host "SQL 파일: $SqlFile"
# }

Write-Host "[실행 쿼리]" -ForegroundColor Green
Write-Host ""
Write-Host $SqlText
Write-Host ""
Write-Host "[실행 결과]" -ForegroundColor Green
Write-Host ""

# 5. SQLite 프로세스 설정
$ProcessInfo = [System.Diagnostics.ProcessStartInfo]::new()

$ProcessInfo.FileName = $SqliteCommand.Source
$ProcessInfo.UseShellExecute = $false
$ProcessInfo.CreateNoWindow = $true
$ProcessInfo.RedirectStandardInput = $true
$ProcessInfo.RedirectStandardOutput = $true
$ProcessInfo.RedirectStandardError = $true

# UTF-8 입출력 설정
$Utf8Encoding = [System.Text.UTF8Encoding]::new($false)

$ProcessInfo.StandardInputEncoding = $Utf8Encoding
$ProcessInfo.StandardOutputEncoding = $Utf8Encoding
$ProcessInfo.StandardErrorEncoding = $Utf8Encoding

# SQLite 옵션
$ProcessInfo.ArgumentList.Add("-batch")
$ProcessInfo.ArgumentList.Add("-bail")
$ProcessInfo.ArgumentList.Add("-header")
$ProcessInfo.ArgumentList.Add("-column")
$ProcessInfo.ArgumentList.Add("-cmd")
$ProcessInfo.ArgumentList.Add(".timeout 5000")
$ProcessInfo.ArgumentList.Add($DatabaseFile)

# 6. SQLite 실행
$Process = [System.Diagnostics.Process]::new()
$Process.StartInfo = $ProcessInfo

try {
    [void]$Process.Start()

    # 출력 및 오류 스트림 비동기 읽기
    $OutputTask = $Process.StandardOutput.ReadToEndAsync()
    $ErrorTask = $Process.StandardError.ReadToEndAsync()

    # SQL 전달
    $Process.StandardInput.WriteLine($SqlText)
    $Process.StandardInput.Close()

    $Process.WaitForExit()

    $OutputText = $OutputTask.Result
    $ErrorText = $ErrorTask.Result
    $ExitCode = $Process.ExitCode

    # 7. 실행 결과 출력
    if (-not [string]::IsNullOrWhiteSpace($OutputText)) {
        Write-Host $OutputText
    }

    if (-not [string]::IsNullOrWhiteSpace($ErrorText)) {
        Write-Host $ErrorText -ForegroundColor Red
    }

    if ($ExitCode -ne 0) {
        Write-Host "SQL 실행 실패 (Exit Code: $ExitCode)" -ForegroundColor Red
    }
    else {
        Write-Host "SQL 실행 완료" -ForegroundColor Green
    }
}
catch {
    Write-Host "SQLite 실행 중 오류 발생" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    if ($Process) {
        $Process.Dispose()
    }
}

Write-Host ""