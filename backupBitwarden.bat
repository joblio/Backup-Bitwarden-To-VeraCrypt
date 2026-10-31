@echo off
setlocal DisableDelayedExpansion

:: Configuration - CHANGE THESE VALUES BEFORE RUNNING
set VC_PATH="C:\Program Files\VeraCrypt\VeraCrypt.exe"
set VC_VOLUME="CHANGE_ME_C:\Path\To\Your\VeraCrypt\Volume.hc"
set MOUNT_LETTER=V
set BW_PATH=bw
set BW_EMAIL=CHANGE_ME_your.email@example.com
:: Personal settings live in backupBitwarden.local.bat (not tracked by git) and
:: override the values above. See backupBitwarden.local.example.bat.
if exist "%~dp0backupBitwarden.local.bat" call "%~dp0backupBitwarden.local.bat"

set EXPORT_FILE=%MOUNT_LETTER%:\
:: This script requires that you have your bitwarden password in a single-line
:: text file in your VeraCrypt volume.
set PASSWORD_FILE=%MOUNT_LETTER%:\password.txt
:: An empty file in the root of the VeraCrypt volume. It proves that the drive
:: letter really is your backup volume and not some other drive.
set MARKER_FILE=%MOUNT_LETTER%:\.backup-volume

set EXIT_CODE=0
set MOUNTED_BY_SCRIPT=0
:: Never reuse a session key inherited from the environment.
set BW_SESSION=

:: Refuse to run with unconfigured placeholder values
echo %VC_VOLUME% %BW_EMAIL%| findstr /c:"CHANGE_ME" >nul
if not errorlevel 1 (
    echo ERROR: Configuration still contains CHANGE_ME placeholders.
    echo Copy backupBitwarden.local.example.bat to backupBitwarden.local.bat and edit it.
    pause
    exit /b 1
)

:: Check if VeraCrypt executable exists
if not exist %VC_PATH% (
    echo ERROR: VeraCrypt not found at %VC_PATH%
    echo Please install VeraCrypt or update VC_PATH in the configuration.
    pause
    exit /b 1
)

:: Check if Bitwarden CLI is available
call %BW_PATH% --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Bitwarden CLI not found or not in PATH.
    echo Please install Bitwarden CLI or update BW_PATH in the configuration.
    pause
    exit /b 1
)

:: Check if VeraCrypt volume is already mounted
if not exist %MOUNT_LETTER%:\ goto :mount
if exist "%MARKER_FILE%" (
    echo VeraCrypt volume is already mounted.
    goto :mounted
)
echo ERROR: Drive %MOUNT_LETTER%: exists but is not the backup volume.
echo        Create an empty file named .backup-volume in the root of your VeraCrypt volume,
echo        or change MOUNT_LETTER to a free drive letter.
set EXIT_CODE=1
goto :cleanup

:mount
echo VeraCrypt volume is not mounted. Mounting now...
set "VC_PASSWORD="
for /f "usebackq eol= delims=" %%p in (`powershell -NoProfile -Command "$s = Read-Host 'Enter VeraCrypt password' -AsSecureString; [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s))"`) do set "VC_PASSWORD=%%p"
:: VeraCrypt.exe is a GUI program, so cmd only waits for it with start /wait.
start /wait "" %VC_PATH% /q /s /v %VC_VOLUME% /l %MOUNT_LETTER% /p "%VC_PASSWORD%"
set MOUNT_RC=%ERRORLEVEL%
set "VC_PASSWORD="
if not "%MOUNT_RC%"=="0" (
    echo Failed to mount VeraCrypt volume (Error code: %MOUNT_RC%^).
    set EXIT_CODE=1
    goto :cleanup
)
set MOUNTED_BY_SCRIPT=1

:: Give Windows a moment to make the drive letter available
for /l %%i in (1,1,15) do if not exist "%MARKER_FILE%" timeout /t 1 /nobreak >nul
if not exist "%MARKER_FILE%" (
    echo ERROR: Volume mounted, but %MARKER_FILE% was not found.
    echo Create an empty file named .backup-volume in the root of your VeraCrypt volume.
    set EXIT_CODE=1
    goto :cleanup
)

:mounted
:: Verify password file exists
if not exist "%PASSWORD_FILE%" (
    echo Error: Password file not found at %PASSWORD_FILE%.
    set EXIT_CODE=1
    goto :cleanup
)

:: Log in if needed. This runs without capturing output so that a two-step
:: login prompt (2FA code) is visible and can be answered.
call %BW_PATH% login --check >nul 2>&1
if %ERRORLEVEL% equ 0 goto :unlock
call %BW_PATH% login %BW_EMAIL% --passwordfile "%PASSWORD_FILE%"
if errorlevel 1 (
    echo Failed to log into Bitwarden.
    set EXIT_CODE=1
    goto :cleanup
)

:unlock
:: Unlock the vault and retrieve the session key
for /f "usebackq delims=" %%s in (`call %BW_PATH% unlock --raw --passwordfile "%PASSWORD_FILE%"`) do set "BW_SESSION=%%s"
if not defined BW_SESSION (
    echo Failed to retrieve Bitwarden session.
    set EXIT_CODE=1
    goto :cleanup
)

:: Sync the Bitwarden vault (this also fails if the session key is bad)
echo.
echo Syncing Bitwarden vault...
call %BW_PATH% sync --session "%BW_SESSION%"
set SYNC_RC=%ERRORLEVEL%
if not "%SYNC_RC%"=="0" (
    echo.
    echo Failed to sync Bitwarden vault (Error code: %SYNC_RC%^).
    set EXIT_CODE=1
    goto :cleanup
)
echo.
echo Sync completed successfully.

:: Export the vault in unencrypted JSON format
echo.
echo Exporting vault to %EXPORT_FILE%...
call %BW_PATH% export --format json --output %EXPORT_FILE% --session "%BW_SESSION%"
set EXPORT_RC=%ERRORLEVEL%
if not "%EXPORT_RC%"=="0" (
    echo.
    echo Failed to export Bitwarden vault (Error code: %EXPORT_RC%^).
    echo.
    echo Possible causes:
    echo - VeraCrypt volume may be full (check disk space^)
    echo - Insufficient permissions to write to %EXPORT_FILE%
    echo - Network/volume connectivity issues
    echo.
    set EXIT_CODE=1
    goto :cleanup
)
echo Export completed successfully.
echo.
echo Bitwarden vault exported successfully to %EXPORT_FILE%.

:cleanup
:: Lock the vault and clear the session key
call %BW_PATH% lock >nul 2>&1
set BW_SESSION=

:: Only dismount a volume that this script mounted
if "%MOUNTED_BY_SCRIPT%"=="1" (
    echo Dismounting VeraCrypt volume...
    start /wait "" %VC_PATH% /q /s /d %MOUNT_LETTER%
    if errorlevel 1 echo WARNING: Failed to dismount %MOUNT_LETTER%: - dismount it manually.
)

pause
exit /b %EXIT_CODE%
