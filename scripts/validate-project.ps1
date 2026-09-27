$ErrorActionPreference = 'Stop'

$requiredPaths = @(
  'sfdx-project.json',
  'README.md',
  'docs/architecture.md',
  'docs/security.md',
  'docs/ai-design.md',
  'docs/demo-scenarios.md',
  'force-app/main/default/classes/AICaseService.cls',
  'force-app/main/default/classes/AIOrchestrator.cls',
  'force-app/main/default/classes/AIRequestQueueable.cls',
  'force-app/main/default/classes/AIResponseService.cls',
  'force-app/main/default/lwc/aiCaseAssistant/aiCaseAssistant.js',
  'ai-service/src/server.js',
  'ai-service/test/orchestrator.test.js'
)

foreach ($path in $requiredPaths) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Missing required path: $path"
  }
}

$apexFiles = Get-ChildItem -LiteralPath 'force-app/main/default/classes' -Filter '*.cls' -Recurse
foreach ($file in $apexFiles) {
  $content = Get-Content -LiteralPath $file.FullName -Raw
  if ($content -match 'TODO|FIXME|sk_test_|AIza|OPENAI_API_KEY') {
    throw "Unsafe placeholder or secret-like token found in $($file.FullName)"
  }
}

Write-Host "Project structure validation passed."
