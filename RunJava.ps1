
param(
    [string]$JavaFile,
    [string[]]$ProgramArgs = @()
)

$ErrorActionPreference = "Stop"

# 1. Java 파일 선택
if ([string]::IsNullOrWhiteSpace($JavaFile)) {
    $JavaFiles = @(Get-ChildItem -Path (Get-Location) -Filter "*.java" -File -Recurse)

    if ($JavaFiles.Count -eq 0) {
        Write-Host "현재 폴더에서 Java 파일을 찾을 수 없습니다." -ForegroundColor Red
        return
    }
    elseif ($JavaFiles.Count -eq 1) {
        $JavaFile = $JavaFiles[0].FullName
    }
    else {
        Write-Host "실행할 Java 파일을 선택하세요."

        for ($i = 0; $i -lt $JavaFiles.Count; $i++) {
            Write-Host "[$($i + 1)] $($JavaFiles[$i].FullName)"
        }

        $Selection = Read-Host "번호 입력"

        if ($Selection -notmatch '^\d+$' -or
            [int]$Selection -lt 1 -or
            [int]$Selection -gt $JavaFiles.Count) {
            Write-Host "잘못된 선택입니다." -ForegroundColor Red
            return
        }

        $JavaFile = $JavaFiles[[int]$Selection - 1].FullName
    }
}

# 2. Java 파일 경로 확인
$JavaFile = (Resolve-Path -LiteralPath $JavaFile).Path

if ([IO.Path]::GetExtension($JavaFile) -ne ".java") {
    Write-Host "Java 파일(.java)이 아닙니다." -ForegroundColor Red
    return
}

$SourceDirectory = Split-Path -Parent $JavaFile
$ClassName = [IO.Path]::GetFileNameWithoutExtension($JavaFile)

# 3. JDK 명령 확인
if (-not (Get-Command javac -ErrorAction SilentlyContinue)) {
    Write-Host "javac 명령을 찾을 수 없습니다. PATH를 확인하세요." -ForegroundColor Red
    return
}

if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "java 명령을 찾을 수 없습니다. PATH를 확인하세요." -ForegroundColor Red
    return
}

# 4. package 선언 확인
$SourceText = Get-Content -LiteralPath $JavaFile -Raw -Encoding UTF8

$PackageMatch = [regex]::Match(
    $SourceText,
    '(?m)^\s*package\s+([\w.]+)\s*;'
)

if ($PackageMatch.Success) {
    $PackageName = $PackageMatch.Groups[1].Value
    $FullClassName = "$PackageName.$ClassName"
}
else {
    $FullClassName = $ClassName
}

# 5. 컴파일 출력 폴더
$BuildDirectory = Join-Path $SourceDirectory ".java-build"

if (-not (Test-Path $BuildDirectory)) {
    New-Item -ItemType Directory -Path $BuildDirectory | Out-Null
}

# Write-Host "========================================" -ForegroundColor Cyan
# Write-Host " Java 컴파일 시작" -ForegroundColor Cyan
# Write-Host "========================================" -ForegroundColor Cyan
# Write-Host "파일: $JavaFile"

# 6. Java 컴파일
& javac -encoding UTF-8 -d $BuildDirectory $JavaFile

# if ($LASTEXITCODE -ne 0) {
#     Write-Host "컴파일에 실패했습니다." -ForegroundColor Red
#     return
# }

# Write-Host "컴파일 성공!" -ForegroundColor Green

# 7. Java 실행
# Write-Host "========================================" -ForegroundColor Cyan
# Write-Host " Java 실행 시작" -ForegroundColor Cyan
# Write-Host "========================================" -ForegroundColor Cyan

Write-Host "[Java 코드 실행]" -ForegroundColor Green
Write-Host ""

& java -cp $BuildDirectory $FullClassName @ProgramArgs

Write-Host ""

if ($LASTEXITCODE -ne 0) {
    Write-Host "Java 코드 실행 중 오류 발생" -ForegroundColor Red
}
else {
    Write-Host "Java 코드 실행 완료" -ForegroundColor Green
}

Write-Host ""