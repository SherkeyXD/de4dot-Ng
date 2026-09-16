param(
    [string]$Configuration = "Release",
    [string]$Framework = "net10.0",
    [switch]$SkipNative = $false
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
Push-Location $RepoRoot

try {
    $outDir = "build/publish-$Framework"
    $mcpOutDir = "build/publish-$Framework-mcp"

    dotnet publish -c $Configuration -f $Framework -o $outDir src/de4dot
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
    Remove-Item "$outDir\*.pdb", "$outDir\*.xml" -ErrorAction SilentlyContinue

    dotnet publish -c $Configuration -f $Framework -o $mcpOutDir src/de4dot.mcp
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
    Remove-Item "$mcpOutDir\*.pdb", "$mcpOutDir\*.xml" -ErrorAction SilentlyContinue

    if (-not $SkipNative) {
        if (Get-Command cmake -ErrorAction SilentlyContinue) {
            Write-Host "Building native BeaEngine library..."
            $buildDir = "build/native"
            cmake -S native/BeaEngine -B $buildDir -DCMAKE_BUILD_TYPE=$Configuration
            if ($LASTEXITCODE) { exit $LASTEXITCODE }
            cmake --build $buildDir --config $Configuration
            if ($LASTEXITCODE) { exit $LASTEXITCODE }

            # Copy native library to publish folder
            $nativeLib = Get-ChildItem -Path "$buildDir/bin" -Filter "*BeaEngine*" -File -Recurse | Select-Object -First 1
            if ($nativeLib) {
                Copy-Item $nativeLib.FullName -Destination $outDir
                Copy-Item $nativeLib.FullName -Destination $mcpOutDir
                Write-Host "Copied $($nativeLib.Name) to $outDir and $mcpOutDir"
            } else {
                Write-Warning "BeaEngine binary not found in $buildDir/bin"
            }
        } else {
            Write-Warning "cmake command not found. Skipping native BeaEngine build."
        }
    }
}
finally {
    Pop-Location
}
