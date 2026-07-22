# SecureChat Test Suite — Local Runner
# Runs all 2000 test cases locally with HTML reports
# Usage: .\run_tests.ps1
# Usage (quick): .\run_tests.ps1 -Suite selenium

param(
    [string]$Suite = "all",
    [switch]$SkipInstall,
    [switch]$ShowReport
)

$ErrorActionPreference = "Stop"
$ROOT = $PSScriptRoot
$REPORTS = "$ROOT\reports"

# ── Colors ─────────────────────────────────────────────────────────────────
function Write-Header  { param($msg) Write-Host "`n━━━ $msg ━━━" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "  ❌ $msg" -ForegroundColor Red }
function Write-Info    { param($msg) Write-Host "  ℹ️  $msg" -ForegroundColor White }

Write-Host @"

╔═══════════════════════════════════════════════════════╗
║       SecureChat — 2000 Test Suite Runner             ║
║  Backend Load | Selenium | Mobile | Vulnerability     ║
╚═══════════════════════════════════════════════════════╝
"@ -ForegroundColor Magenta

# ── Create reports directory ────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $REPORTS | Out-Null

# ── Install dependencies ────────────────────────────────────────────────────
if (-not $SkipInstall) {
    Write-Header "Installing Dependencies"
    try {
        pip install -r "$ROOT\requirements.txt" -q --upgrade
        pip install pytest-html websockets -q
        Write-Success "Dependencies installed"
    } catch {
        Write-Err "Failed to install dependencies: $_"
        exit 1
    }
}

# ── Check Python and Chrome ─────────────────────────────────────────────────
Write-Header "Environment Check"
try {
    $pyVer = python --version 2>&1
    Write-Success "Python: $pyVer"
} catch {
    Write-Err "Python not found. Please install Python 3.9+"
    exit 1
}

# ── Start HTTP server ────────────────────────────────────────────────────────
Write-Header "Starting Local HTTP Server (port 8765)"
$httpJob = Start-Job -ScriptBlock {
    param($appDir)
    Set-Location $appDir
    python -m http.server 8765
} -ArgumentList "$ROOT\app"
Start-Sleep 2
Write-Success "HTTP server started on http://localhost:8765"

# ── Start Mock WebSocket server ─────────────────────────────────────────────
Write-Header "Starting Mock WebSocket Server (port 8766)"
$wsJob = Start-Job -ScriptBlock {
    param($scriptDir)
    python "$scriptDir\backend-load\mock_ws_server.py" --port 8766
} -ArgumentList $ROOT
Start-Sleep 2
Write-Success "Mock WS server started on ws://localhost:8766"

# ── Test runner function ─────────────────────────────────────────────────────
$Results = @{}

function Run-Suite {
    param($name, $path, $marker, $reportName, $timeout)

    Write-Header "Running $name"
    Write-Info "Target: 500 test cases"

    $reportHtml = "$REPORTS\$reportName-report.html"
    $reportXml  = "$REPORTS\$reportName-results.xml"

    $args = @(
        $path,
        "-v",
        "--tb=short",
        "--timeout=$timeout",
        "--junit-xml=$reportXml",
        "--html=$reportHtml",
        "--self-contained-html"
    )
    if ($marker) {
        $args += "-m"
        $args += $marker
    }

    $start = Get-Date
    try {
        $output = & python -m pytest @args 2>&1
        $exitCode = $LASTEXITCODE
        $duration = [math]::Round(((Get-Date) - $start).TotalSeconds, 1)

        # Parse results
        $passLine = $output | Select-String "passed"
        Write-Info "Duration: ${duration}s"
        if ($passLine) {
            Write-Info "Results: $($passLine[-1])"
        }

        if ($exitCode -eq 0) {
            Write-Success "$name PASSED"
            $Results[$name] = "PASSED"
        } elseif ($exitCode -eq 5) {
            Write-Warn "$name — No tests collected (check markers)"
            $Results[$name] = "NO TESTS"
        } else {
            Write-Warn "$name completed with some failures (exit $exitCode)"
            $Results[$name] = "PARTIAL"
        }
    } catch {
        Write-Err "$name FAILED: $_"
        $Results[$name] = "FAILED"
    }

    if (Test-Path $reportHtml) {
        Write-Success "Report: $reportHtml"
    }
}

# ── Run selected suites ─────────────────────────────────────────────────────
try {
    switch ($Suite.ToLower()) {
        "selenium" {
            Run-Suite "Selenium UI Tests (500)" "$ROOT\selenium" "selenium" "selenium" 60
        }
        "mobile" {
            Run-Suite "Mobile Chrome Tests (500)" "$ROOT\mobile" "mobile" "mobile" 60
        }
        "vulnerability" {
            Run-Suite "Vulnerability Tests (500)" "$ROOT\vulnerability" "vulnerability" "vulnerability" 60
        }
        "load" {
            Run-Suite "Backend Load Tests (500)" "$ROOT\backend-load" "load" "load" 120
        }
        "locust" {
            Write-Header "Running Locust Load Test (60 seconds)"
            locust -f "$ROOT\backend-load\locustfile.py" `
                   --headless `
                   --host=http://localhost:8765 `
                   -u 20 -r 5 `
                   --run-time 60s `
                   --html="$REPORTS\locust-report.html" `
                   --csv="$REPORTS\locust" 2>&1
            Write-Success "Locust report: $REPORTS\locust-report.html"
        }
        default {
            # Run all suites
            Run-Suite "Selenium UI Tests (500)"    "$ROOT\selenium"      "selenium"      "selenium"      60
            Run-Suite "Mobile Chrome Tests (500)"  "$ROOT\mobile"        "mobile"        "mobile"        60
            Run-Suite "Vulnerability Tests (500)"  "$ROOT\vulnerability" "vulnerability" "vulnerability" 60
            Run-Suite "Backend Load Tests (500)"   "$ROOT\backend-load"  "load"          "load"          120

            # Locust
            Write-Header "Running Locust Load Scenario"
            try {
                locust -f "$ROOT\backend-load\locustfile.py" `
                       --headless `
                       --host=http://localhost:8765 `
                       -u 10 -r 2 `
                       --run-time 30s `
                       --html="$REPORTS\locust-report.html" 2>&1
                Write-Success "Locust done"
            } catch {
                Write-Warn "Locust not installed or failed — skipping"
            }
        }
    }
} finally {
    # ── Stop servers ─────────────────────────────────────────────────────────
    Write-Header "Stopping Servers"
    Stop-Job $httpJob -ErrorAction SilentlyContinue
    Stop-Job $wsJob   -ErrorAction SilentlyContinue
    Remove-Job $httpJob -ErrorAction SilentlyContinue
    Remove-Job $wsJob   -ErrorAction SilentlyContinue
    Write-Success "Servers stopped"
}

# ── Summary ─────────────────────────────────────────────────────────────────
Write-Host @"

╔═══════════════════════════════════════════════════════╗
║                   TEST SUMMARY                        ║
╚═══════════════════════════════════════════════════════╝
"@ -ForegroundColor Magenta

foreach ($suite in $Results.Keys) {
    $status = $Results[$suite]
    $color  = if ($status -eq "PASSED") { "Green" }
              elseif ($status -eq "PARTIAL") { "Yellow" }
              else { "Red" }
    Write-Host "  $suite : $status" -ForegroundColor $color
}

Write-Host "`n📁 Reports saved to: $REPORTS" -ForegroundColor Cyan

# Open reports if requested
if ($ShowReport) {
    Get-ChildItem "$REPORTS\*.html" | ForEach-Object {
        Start-Process $_.FullName
    }
}

Write-Host ""
