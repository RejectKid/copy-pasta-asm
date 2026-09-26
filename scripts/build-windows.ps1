param([switch]$Test,[switch]$Run)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    New-Item -ItemType Directory -Force build | Out-Null
    $nasm = Get-Command nasm -ErrorAction SilentlyContinue
    if ($nasm) { $nasm = $nasm.Source } else { $nasm = Join-Path $root 'tools\nasm-3.02\nasm.exe' }
    if (!(Test-Path $nasm)) {
        New-Item -ItemType Directory -Force tools | Out-Null
        Invoke-WebRequest 'https://www.nasm.us/pub/nasm/releasebuilds/3.02/win64/nasm-3.02-win64.zip' -OutFile tools\nasm.zip
        Expand-Archive tools\nasm.zip tools -Force
    }
    $vs = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft Visual Studio", "$env:ProgramFiles\Microsoft Visual Studio" -Filter link.exe -Recurse -ErrorAction SilentlyContinue |
        Where-Object FullName -match 'Hostx64\\x64\\link.exe$' | Sort-Object FullName -Descending | Select-Object -First 1
    if (!$vs) { throw 'Install Visual Studio C++ Build Tools and the Windows SDK.' }
    $sdk = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\Lib" -Directory | Sort-Object Name -Descending | Select-Object -First 1
    $lib = Join-Path $sdk.FullName 'um\x64'
    $libexe = Join-Path $vs.DirectoryName 'lib.exe'
    & $libexe /nologo /machine:x64 /def:scripts\msvcrt.def /out:build\msvcrt.lib
    if ($LASTEXITCODE) { throw 'CRT import library failed' }
    & $nasm -f win64 -g -I src/ -o build\copy-pasta.obj src\windows.s
    if ($LASTEXITCODE) { throw 'Assembly failed' }
    & $vs.FullName /nologo /entry:start /subsystem:windows /largeaddressaware /dynamicbase /nxcompat /debug /out:build\copy-pasta-asm.exe build\copy-pasta.obj build\msvcrt.lib "/libpath:$lib" kernel32.lib user32.lib gdi32.lib ole32.lib oleaut32.lib shell32.lib comctl32.lib
    if ($LASTEXITCODE) { throw 'Link failed' }
    if ($Test) {
        $old = $env:COPY_PASTA_HISTORY
        try {
            $env:COPY_PASTA_HISTORY = Join-Path $root 'build\test-history.json'
            $p = Start-Process build\copy-pasta-asm.exe -ArgumentList '--self-test' -Wait -PassThru
            if ($p.ExitCode) { throw "Self-test failed: $($p.ExitCode)" }
            Write-Host 'Assembly self-test passed.'
        } finally { $env:COPY_PASTA_HISTORY = $old }
    }
    if ($Run) { Start-Process (Join-Path $root 'build\copy-pasta-asm.exe') }
} finally { Pop-Location }
