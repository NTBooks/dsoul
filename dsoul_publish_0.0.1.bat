@echo off
REM dsoul publish script v0.0.1 — review and run manually.
REM Requires: dsoul CLI (diamond-soul-downloader), DSOUL_USER/DSOUL_TOKEN or DSOUL_APPLICATION_KEY for non-interactive use.
REM Skills to publish: dsoul-agent, dsoul-analyze, dsoul-cli, dsoul-publish

setlocal enabledelayedexpansion
set "ROOT=%~dp0"
cd /d "%ROOT%"

echo === Register (once) ===
dsoul register
if errorlevel 1 goto :error

echo === Balance (before) ===
dsoul balance
if errorlevel 1 goto :error

echo === Package each skill ===
dsoul package "%ROOT%.cursor\skills\dsoul-agent"
if errorlevel 1 goto :error
dsoul package "%ROOT%.cursor\skills\dsoul-analyze"
if errorlevel 1 goto :error
dsoul package "%ROOT%.cursor\skills\dsoul-cli"
if errorlevel 1 goto :error
dsoul package "%ROOT%.cursor\skills\dsoul-publish"
if errorlevel 1 goto :error

set "VERSION=0.0.1"
mkdir ".publish-history" 2>nul
mkdir ".publish-history\dsoul-agent" 2>nul
mkdir ".publish-history\dsoul-analyze" 2>nul
mkdir ".publish-history\dsoul-cli" 2>nul
mkdir ".publish-history\dsoul-publish" 2>nul

echo === Freeze (see output for CIDs) ===
for %%S in (dsoul-agent dsoul-analyze dsoul-cli dsoul-publish) do (
  set "ZIP=%ROOT%.cursor\skills\%%S.zip"
  if exist "!ZIP!" (
    echo Freezing %%S...
    dsoul freeze "!ZIP!" --shortname=%%S --version=%VERSION% --tags=skill,dsoul
    if errorlevel 1 goto :error
    copy /Y "!ZIP!" ".publish-history\%%S\%VERSION%.zip" >nul
  )
)

echo === Balance (after) ===
dsoul balance
if errorlevel 1 goto :error

echo Done. Packaged 4 skills, froze 4 zips. Check dsoul freeze output for CIDs and, if desired, write them into .publish-history\SHORTCODE\%VERSION%.cid.txt.
goto :eof

:error
echo Failed with errorlevel %errorlevel%.
exit /b %errorlevel%

