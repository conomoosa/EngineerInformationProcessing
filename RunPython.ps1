param(
    [string]$PythonFile,
    [string[]]$ProgramArgs = @()
)

$ErrorActionPreference = "Stop"

# 1. Python 파일 선택
if ([string]::IsNullOrWhiteSpace($PythonFile)) {
    $PythonFiles = @(Get-ChildItem -Path (Get-Location) -Filter "*.py" -File -Recurse)

    if ($PythonFiles.Count -eq 0) {
        Write-Host "현재 폴더에서 Python 파일을 찾을 수 없습니다." -ForegroundColor Red
        return
    }
    elseif ($PythonFiles.Count -eq 1) {
        $PythonFile = $PythonFiles[0].FullName
    }
    else {
        Write-Host "실행할 Python 파일을 선택하세요."

        for ($i = 0; $i -lt $PythonFiles.Count; $i++) {
            Write-Host "[$($i + 1)] $($PythonFiles[$i].FullName)"
        }

        $Selection = Read-Host "번호 입력"

        if ($Selection -notmatch '^\d+$' -or
            [int]$Selection -lt 1 -or
            [int]$Selection -gt $PythonFiles.Count) {
            Write-Host "잘못된 선택입니다." -ForegroundColor Red
            return
        }

        $PythonFile = $PythonFiles[[int]$Selection - 1].FullName
    }
}

# 2. Python 파일 경로 확인
$PythonFile = (Resolve-Path -LiteralPath $PythonFile).Path

if ([IO.Path]::GetExtension($PythonFile) -ne ".py") {
    Write-Host "Python 파일(.py)이 아닙니다." -ForegroundColor Red
    return
}

# 3. Python 명령 확인
$PythonCommand = Get-Command python -ErrorAction SilentlyContinue

if (-not $PythonCommand) {
    $PythonCommand = Get-Command py -ErrorAction SilentlyContinue
}

if (-not $PythonCommand) {
    Write-Host "Python 명령을 찾을 수 없습니다. PATH를 확인하세요." -ForegroundColor Red
    return
}

# 4. 실행 시작
# Write-Host "========================================" -ForegroundColor Cyan
# Write-Host " Python 실행 시작" -ForegroundColor Cyan
# Write-Host "========================================" -ForegroundColor Cyan
# Write-Host "파일: $PythonFile"
# Write-Host "인터프리터: $($PythonCommand.Source)"

# 5. Python 실행
if ($PythonCommand.Name -eq "py.exe" -or $PythonCommand.Name -eq "py") {
    & $PythonCommand.Source -3 $PythonFile @ProgramArgs
}
else {
    & $PythonCommand.Source $PythonFile @ProgramArgs
}

# 6. 실행 결과 확인
# if ($LASTEXITCODE -ne 0) {
#     Write-Host "Python 프로그램 실행 중 오류가 발생했습니다." -ForegroundColor Red
# }
# else {
#     Write-Host "Python 프로그램 실행 완료." -ForegroundColor Green
# }

Write-Host ""