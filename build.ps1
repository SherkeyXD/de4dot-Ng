$ErrorActionPreference = 'Stop'

dotnet publish -c Release -f net10.0 -o publish-net10.0 de4dot
if ($LASTEXITCODE) { exit $LASTEXITCODE }
Remove-Item publish-net10.0\*.pdb, publish-net10.0\*.xml

dotnet publish -c Release -f net10.0 -o publish-net10.0-mcp de4dot.mcp
if ($LASTEXITCODE) { exit $LASTEXITCODE }
Remove-Item publish-net10.0-mcp\*.pdb, publish-net10.0-mcp\*.xml
