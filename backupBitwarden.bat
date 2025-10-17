@echo off
setlocal EnableDelayedExpansion

:: Configuration - CHANGE THESE VALUES BEFORE RUNNING
set VC_PATH="C:\Program Files\VeraCrypt\VeraCrypt.exe"
set VC_VOLUME="CHANGE_ME_C:\Path\To\Your\VeraCrypt\Volume.hc"
set MOUNT_LETTER=V
set BW_PATH=bw
set BW_EMAIL=CHANGE_ME_your.email@example.com
set EXPORT_FILE=%MOUNT_LETTER%:\
:: This script requires that you have your bitwarden password in a single-line 
:: text file in your VeraCrypt volume.
set PASSWORD_FILE=%MOUNT_LETTER%:\password.txt

:: Check if VeraCrypt executable exists
if not exist %VC_PATH% (
    echo ERROR: VeraCrypt not found at %VC_PATH%
    echo Please install VeraCrypt or update VC_PATH in the configuration.
    pause
    exit /b 1
)

:: Check if Bitwarden CLI is available
%BW_PATH% --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Bitwarden CLI not found or not in PATH.
    echo Please install Bitwarden CLI or update BW_PATH in the configuration.
    pause
    exit /b 1
)

:: Check if VeraCrypt volume is already mounted
if exist %MOUNT_LETTER%:\ (
    echo VeraCrypt volume is already mounted.
) else (
    echo VeraCrypt volume is not mounted. Mounting now...
    set /p VC_PASSWORD="Enter VeraCrypt password: "
    %VC_PATH% /q /v %VC_VOLUME% /l %MOUNT_LETTER% /p !VC_PASSWORD! /a /b
    if %ERRORLEVEL% neq 0 (
        echo Failed to mount VeraCrypt volume.
        pause
        exit /b 1
    )
    set VC_PASSWORD=
)

:: Verify password file exists
if not exist "%PASSWORD_FILE%" (
    echo Error: Password file not found at %PASSWORD_FILE%.
    pause
    exit /b 1
)

:: Log into Bitwarden and retrieve session key
for /f "delims=" %%s in ('%BW_PATH% login --raw %BW_EMAIL% ^< "%PASSWORD_FILE%"') do set BW_SESSION=%%s

:: Verify login success
if not defined BW_SESSION (
	for /f "delims=" %%s in ('%BW_PATH% unlock --raw ^< "%PASSWORD_FILE%"') do set BW_SESSION=%%s
	if not defined BW_SESSION (
		echo Failed to retrieve Bitwarden session.
		pause
		exit /b 1
	)
)

:: Sync the Bitwarden vault
echo.
echo Syncing Bitwarden vault...
%BW_PATH% sync --session "%BW_SESSION%"
if %ERRORLEVEL% neq 0 (
    echo.
    echo Failed to sync Bitwarden vault (Error code: %ERRORLEVEL%^).
    set BW_SESSION=
    pause
    exit /b 1
)
echo.
echo Sync completed successfully.

:: Export the vault in unencrypted JSON format
echo.
echo Exporting vault to %EXPORT_FILE%...
%BW_PATH% export --format json --output %EXPORT_FILE% --session "%BW_SESSION%"
if %ERRORLEVEL% neq 0 (
    echo.
    echo Failed to export Bitwarden vault (Error code: %ERRORLEVEL%^).
    echo.
    echo Possible causes:
    echo - VeraCrypt volume may be full (check disk space^)
    echo - Insufficient permissions to write to %EXPORT_FILE%
    echo - Network/volume connectivity issues
    echo.
    set BW_SESSION=
    pause
    exit /b 1
)
echo Export completed successfully.

:: Clear the session key
set BW_SESSION=

echo Bitwarden vault exported successfully to %EXPORT_FILE%.
pause