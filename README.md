# SecureChat — Automated Test Suite

This repository contains an exhaustive 2,000-case automated test suite for the SecureChat application.

## Overview

The tests are organized into four major categories (500 tests each), covering all critical aspects of functionality, performance, and security.

### Test Suites
1. **Selenium UI Tests (`/selenium`)**
   - End-to-end interactions on desktop Chrome.
   - Comprehensive test cases covering page loads, modal behavior, key management, message exchanging, and edge cases.

2. **Mobile Chrome Emulation (`/mobile`)**
   - Responsive design validations on 10 different device profiles.
   - Touch interactions, virtual keyboard inputs, scroll behaviors, and responsive layouts.
   - Powered by Selenium's `mobileEmulation` feature.

3. **Vulnerability & Security (`/vulnerability`)**
   - Cross-Site Scripting (XSS) payload injection across all inputs.
   - SQLi, SSRF, command injection, and path traversal vectors.
   - Cryptographic validation of the Forge.js RSA/AES-CBC implementation (key sizes, entropy, hardcoded keys).
   - WebSocket URL validations and HTTP headers.
   - Resource exhaustion and Denial of Service (DoS).

4. **Backend Load Tests (`/backend-load`)**
   - Simulated stress using `pytest`, `requests`, and concurrent threads.
   - WebSocket performance using `websockets`.
   - Locust integration (`locustfile.py`) with 500 varied HTTP scenarios to simulate 50+ concurrent users with realistic interactions.

## Prerequisites
- **Python 3.9+**
- **Google Chrome** (Must be installed locally for Selenium and Mobile tests)
- **PowerShell** (For Windows runner script)

## Running Tests Locally

Use the `run_tests.ps1` orchestration script to handle dependencies, server execution, and suite execution.

```powershell
# Run the entire 2000-case suite (will take 5-10 minutes)
.\run_tests.ps1

# Run a specific suite
.\run_tests.ps1 -Suite selenium
.\run_tests.ps1 -Suite mobile
.\run_tests.ps1 -Suite vulnerability
.\run_tests.ps1 -Suite load
.\run_tests.ps1 -Suite locust

# Automatically open HTML reports upon completion
.\run_tests.ps1 -ShowReport
```

## Continuous Integration
A GitHub Actions workflow is provided (`.github/workflows/test-suite.yml`). It is triggered on any `push` or `pull_request` to run all 2000 tests across Ubuntu latest runners, utilizing `browser-actions/setup-chrome`. Test reports (JUnit XML and HTML) are automatically uploaded as workflow artifacts.
