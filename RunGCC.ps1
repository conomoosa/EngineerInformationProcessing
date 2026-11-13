param(
    [string]$CFile,
    [string[]]$ProgramArgs = @()
)

$ErrorActionPreference = "Stop"

# 1. C 파일 선택
if ([string]::IsNullOrWhiteSpace($CFile)) {
    $CFiles = @(Get-ChildItem -Path (Get-Location) -Filter "*.c" -File -Recurse)

    if ($CFiles.Count -eq 0) {
        Write-Host "현재 폴더에서 C 파일을 찾을 수 없습니다." -ForegroundColor Red
        return
    }
    elseif ($CFiles.Count -eq 1) {
        $CFile = $CFiles[0].FullName
    }
    else {
        Write-Host "컴파일할 C 파일을 선택하세요.`n"

        for ($i = 0; $i -lt $CFiles.Count; $i++) {
            Write-Host "[$($i + 1)] $($CFiles[$i].FullName)"
        }

        $Selection = Read-Host "`n번호 입력"

        if ($Selection -notmatch '^\d+$' -or
            [int]$Selection -lt 1 -or
            [int]$Selection -gt $CFiles.Count) {
            Write-Host "잘못된 선택입니다." -ForegroundColor Red
            return
        }

        $CFile = $CFiles[[int]$Selection - 1].FullName
    }
}

# 2. C 파일 경로 확인
$CFile = (Resolve-Path -LiteralPath $CFile).Path

if ([IO.Path]::GetExtension($CFile) -ne ".c") {
    Write-Host "C 파일(.c)이 아닙니다." -ForegroundColor Red
    return
}

$SourceDirectory = Split-Path -Parent $CFile
$FileName = [IO.Path]::GetFileNameWithoutExtension($CFile)

# 3. GCC 명령 확인
if (-not (Get-Command gcc -ErrorAction SilentlyContinue)) {
    Write-Host "gcc 명령을 찾을 수 없습니다. MinGW PATH를 확인하세요." -ForegroundColor Red
    return
}

# 4. 컴파일 출력 폴더
$BuildDirectory = Join-Path $SourceDirectory ".gcc-build"

if (-not (Test-Path $BuildDirectory)) {
    New-Item -ItemType Directory -Path $BuildDirectory | Out-Null
}

$ExeFile = Join-Path $BuildDirectory "$FileName.exe"

# 5. 컴파일 시작
# Write-Host "========================================" -ForegroundColor Cyan
# Write-Host " GCC 컴파일 시작" -ForegroundColor Cyan
# Write-Host "========================================" -ForegroundColor Cyan
# Write-Host "파일: $CFile"

& gcc -Wall -Wextra -std=c11 -o $ExeFile $CFile

# if ($LASTEXITCODE -ne 0) {
#     Write-Host "컴파일에 실패했습니다." -ForegroundColor Red
#     return
# }

# Write-Host "컴파일 성공!" -ForegroundColor Green

# 6. 실행 시작
# Write-Host "========================================" -ForegroundColor Cyan
# Write-Host " C 프로그램 실행 시작" -ForegroundColor Cyan
# Write-Host "========================================" -ForegroundColor Cyan

& $ExeFile @ProgramArgs

# if ($LASTEXITCODE -ne 0) {
#     Write-Host "프로그램 실행 중 오류가 발생했습니다." -ForegroundColor Red
# }
# else {
#     Write-Host "프로그램 실행 완료." -ForegroundColor Green
# }

Write-Host ""