@echo off
setlocal EnableDelayedExpansion

:: Configuration
set VC_PATH="C:\Program Files\VeraCrypt\VeraCrypt.exe"
set VC_VOLUME="C:\Users\Path\To\Your\Encrypted\volume.hc"
set MOUNT_LETTER=V
set BW_PATH=bw
set BW_EMAIL=yourBitWardenEmail@domain.co
set EXPORT_FILE=%MOUNT_LETTER%:\
:: This script requires that you have your bitwarden password in a single-line 
:: text file in your VeraCrypt volume.
set PASSWORD_FILE=%MOUNT_LETTER%:\password.txt

:: Check if VeraCrypt volume is already mounted
if exist %MOUNT_LETTER%:\ (
    echo VeraCrypt volume is already mounted.
) else (
    echo VeraCrypt volume is not mounted. Mounting now...
    set /p VC_PASSWORD="Enter VeraCrypt password: "
    "%VC_PATH%" /q /v %VC_VOLUME% /l %MOUNT_LETTER% /p !VC_PASSWORD! /a /b
    if %ERRORLEVEL% neq 0 (
        echo Failed to mount VeraCrypt volume.
        exit /b 1
    )
    set VC_PASSWORD=
)

:: Verify password file exists
if not exist "%PASSWORD_FILE%" (
    echo Error: Password file not found at %PASSWORD_FILE%.
    exit /b 1
)

:: Log into Bitwarden and retrieve session key
for /f "delims=" %%s in ('%BW_PATH% login --raw %BW_EMAIL% ^< "%PASSWORD_FILE%"') do set BW_SESSION=%%s

:: Verify login success
if not defined BW_SESSION (
    echo Failed to retrieve Bitwarden session.
    exit /b 1
)

:: Sync the Bitwarden vault
%BW_PATH% sync --session %BW_SESSION%

:: Export the vault in unencrypted JSON format
%BW_PATH% export --format json --output %EXPORT_FILE% --session %BW_SESSION%

:: Clear the session key
set BW_SESSION=

echo Bitwarden vault exported successfully to %EXPORT_FILE%.
