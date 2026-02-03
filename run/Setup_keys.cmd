@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ==========================================================
REM  KIT_GPG - Setup Chiavi (Wizard)
REM  Versione CRISTALLIZZATA (algoritmi stabili)
REM
REM  PUNTI CHIAVE:
REM   1) Parsing chiavi = "come il vecchio":
REM      - gpg --list-secret-keys --with-colons --fingerprint
REM      - estrazione fpr: e uid: su file separati
REM      - estrazione email con tokens=2 delims=<> (robusta)
REM   2) Multi-key: lista + selezione
REM   3) Delete: BACKUP HOME prima + delete-secret-and-public-key
REM   4) Generazione: PREPARE_AGENT_PINENTRY (fix "No pinentry")
REM   5) Colori ANSI + output in italiano (ASCII-friendly)
REM ==========================================================

REM ----------------------------------------------------------
REM COLORI ANSI (ESC) via PowerShell (ASCII-safe)
REM ----------------------------------------------------------
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "[char]27"`) do set "ESC=%%A"
set "C_RST=%ESC%[0m"
set "C_RED=%ESC%[31m"
set "C_GRN=%ESC%[32m"
set "C_YEL=%ESC%[33m"
set "C_CYA=%ESC%[36m"
set "C_DIM=%ESC%[2m"

echo.
echo %C_CYA%==================================================%C_RST%
echo %C_CYA%  GPG Portable - Setup Chiavi (DEBUG)%C_RST%
echo %C_CYA%==================================================%C_RST%
echo.

REM ----------------------------------------------------------
REM PATHS (NORMALIZZATI)
REM ----------------------------------------------------------
for %%I in ("%~dp0..") do set "BASE_DIR=%%~fI"
set "BIN=%BASE_DIR%\bin"
set "HOME=%BASE_DIR%\home"
set "REPORT_DIR=%BASE_DIR%\reports"
set "REPORT_FILE=%REPORT_DIR%\setup_keys.log"
set "BACKUP_DIR=%BASE_DIR%\backups"

REM ----------------------------------------------------------
REM VAR DUMP (DEBUG)
REM ----------------------------------------------------------
echo %C_DIM%[VAR]%C_RST% ScriptName  = %~nx0
echo %C_DIM%[VAR]%C_RST% ScriptDir   = %~dp0
echo %C_DIM%[VAR]%C_RST% BASE_DIR    = %BASE_DIR%
echo %C_DIM%[VAR]%C_RST% BIN         = %BIN%
echo %C_DIM%[VAR]%C_RST% HOME        = %HOME%
echo %C_DIM%[VAR]%C_RST% REPORT_DIR  = %REPORT_DIR%
echo %C_DIM%[VAR]%C_RST% REPORT_FILE = %REPORT_FILE%
echo %C_DIM%[VAR]%C_RST% BACKUP_DIR  = %BACKUP_DIR%
echo %C_DIM%[VAR]%C_RST% TEMP        = %TEMP%
echo.

REM ----------------------------------------------------------
REM CONTROLLI BASE
REM ----------------------------------------------------------
if not exist "%BIN%\gpg.exe" (
  echo %C_RED%[FATALE]%C_RST% gpg.exe non trovato: %BIN%\gpg.exe
  pause
  exit /b 1
)
if not exist "%HOME%" (
  echo %C_RED%[FATALE]%C_RST% HOME non trovata: %HOME%
  pause
  exit /b 1
)
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%" >nul 2>&1
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1

REM ----------------------------------------------------------
REM Kill agent (solo se gpgconf esiste) + pulizia lock
REM ----------------------------------------------------------
if exist "%BIN%\gpgconf.exe" (
  echo %C_CYA%[INFO]%C_RST% Arresto gpg-agent (gpgconf --kill all)
  "%BIN%\gpgconf.exe" --kill all >nul 2>&1
  echo %C_DIM%[DBG]%C_RST% RC gpgconf kill = %ERRORLEVEL%
) else (
  echo %C_YEL%[WARN]%C_RST% gpgconf.exe non trovato: %BIN%\gpgconf.exe
)

echo %C_CYA%[INFO]%C_RST% Pulizia file lock
del /q "%HOME%\*.lock" 2>nul
if exist "%HOME%\private-keys-v1.d" del /q "%HOME%\private-keys-v1.d\*.lock" 2>nul
echo.

REM ==========================================================
REM STEP 0 - SANITY
REM ==========================================================
echo %C_CYA%================== STEP 0 ==================%C_RST%
"%BIN%\gpg.exe" --homedir "%HOME%" --list-secret-keys >nul 2>&1
echo %C_DIM%[DBG]%C_RST% RC gpg --list-secret-keys = %ERRORLEVEL%
echo.

REM ==========================================================
REM STEP 1 - BUILD KEY LIST (CRISTALLIZZATO)
REM ==========================================================
call :BUILD_KEY_LIST
if errorlevel 1 (
  echo %C_RED%[FATALE]%C_RST% Errore costruzione lista chiavi.
  pause
  goto END
)

if "%KEY_COUNT%"=="0" (
  echo %C_YEL%[INFO]%C_RST% Nessuna chiave trovata. Avvio generazione.
  goto GEN_KEY
)

if "%KEY_COUNT%"=="1" (
  set "FOUND_EMAIL=!K_EMAIL[1]!"
  set "FOUND_FPR=!K_FPR[1]!"
  goto MENU_KEY
)

goto SELECT_KEY

:SELECT_KEY
echo %C_CYA%================== SELEZIONE CHIAVE ==================%C_RST%
echo Trovate %KEY_COUNT% chiavi segrete.
echo.

for /L %%I in (1,1,%KEY_COUNT%) do (
  echo   [%C_GRN%%%I%C_RST%] !K_EMAIL[%%I]!  -  !K_FPR[%%I]!
)

echo.
set "SEL="
set /p SEL=Seleziona numero chiave (1-%KEY_COUNT%) oppure [G] per generare una nuova:

if /i "%SEL%"=="G" goto GEN_KEY

echo %SEL%| "%SystemRoot%\System32\findstr.exe" /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
  echo %C_YEL%[WARN]%C_RST% Selezione non valida.
  echo.
  goto SELECT_KEY
)

if %SEL% LSS 1 goto SELECT_KEY
if %SEL% GTR %KEY_COUNT% goto SELECT_KEY

set "FOUND_EMAIL=!K_EMAIL[%SEL%]!"
set "FOUND_FPR=!K_FPR[%SEL%]!"
goto MENU_KEY

:MENU_KEY
echo %C_CYA%================== MENU ==================%C_RST%
echo Chiave selezionata:
echo   Email       : %C_GRN%%FOUND_EMAIL%%C_RST%
echo   Fingerprint : %C_GRN%%FOUND_FPR%%C_RST%
echo.
echo  [U] Usa questa chiave (export pubblica)
echo  [D] Cancella questa chiave (BACKUP HOME prima) e aggiorna lista
echo  [S] Cambia chiave (torna alla selezione)
echo  [L] Lista chiavi (output gpg)
echo  [Q] Esci
echo.

set "CHOICE="
set /p CHOICE=Scelta (U/D/S/L/Q):

if /i "%CHOICE%"=="U" goto EXPORT_PUB
if /i "%CHOICE%"=="D" goto DELETE_KEY
if /i "%CHOICE%"=="S" goto SELECT_KEY
if /i "%CHOICE%"=="L" goto LIST_KEYS
if /i "%CHOICE%"=="Q" goto END

echo %C_YEL%[WARN]%C_RST% Scelta non valida.
echo.
goto MENU_KEY

:LIST_KEYS
echo.
echo %C_CYA%================== LISTA CHIAVI ==================%C_RST%
"%BIN%\gpg.exe" --homedir "%HOME%" --list-secret-keys --keyid-format LONG
echo.
pause
goto MENU_KEY

:DELETE_KEY
echo.
echo %C_CYA%================== CANCELLAZIONE ==================%C_RST%
set "CONF="
set /p CONF=Confermi cancellazione chiave selezionata? (S/N):

if /i not "%CONF%"=="S" (
  echo %C_YEL%[INFO]%C_RST% Cancellazione annullata.
  echo.
  goto MENU_KEY
)

call :BACKUP_HOME
if errorlevel 1 (
  echo %C_RED%[FATALE]%C_RST% Backup fallito. Cancellazione annullata.
  pause
  goto MENU_KEY
)

set "TMP_DEL=%TEMP%\gpg_delete_%RANDOM%_%RANDOM%.txt"
"%BIN%\gpg.exe" --homedir "%HOME%" --batch --yes --delete-secret-and-public-key "%FOUND_FPR%" >"%TMP_DEL%" 2>&1
set "RC=%ERRORLEVEL%"
echo %C_DIM%[DBG]%C_RST% RC delete = %RC%

if not "%RC%"=="0" (
  echo %C_RED%[ERRORE]%C_RST% Cancellazione fallita. Output:
  type "%TMP_DEL%"
  del /q "%TMP_DEL%" 2>nul
  pause
  goto MENU_KEY
)

del /q "%TMP_DEL%" 2>nul
echo %C_GRN%[OK]%C_RST% Chiave cancellata.
echo.

call :BUILD_KEY_LIST
if "%KEY_COUNT%"=="0" goto GEN_KEY
goto SELECT_KEY

REM ==========================================================
REM GENERAZIONE CHIAVE (con fix pinentry)
REM ==========================================================
:GEN_KEY
echo %C_CYA%================== GENERAZIONE CHIAVE ==================%C_RST%
set /p REALNAME=Nome e Cognome (o Ufficio):
set /p EMAIL=Email istituzionale:
set /p COMMENT=Commento (es. Ufficio):

call :PREPARE_AGENT_PINENTRY
if errorlevel 1 (
  echo %C_RED%[FATALE]%C_RST% Preflight pinentry fallito. Generazione annullata.
  pause
  goto END
)

echo %C_CYA%[INFO]%C_RST% Generazione chiave... (potrebbe comparire pinentry)
echo %C_DIM%[DBG]%C_RST% CMD GEN = "%BIN%\gpg.exe" --homedir "%HOME%" --quick-generate-key "%REALNAME% (%COMMENT%) ^<%EMAIL%^>" rsa3072 sign,encrypt 3y

"%BIN%\gpg.exe" --homedir "%HOME%" --quick-generate-key "%REALNAME% (%COMMENT%) <%EMAIL%>" rsa3072 sign,encrypt 3y
set "RC=%ERRORLEVEL%"
echo %C_DIM%[DBG]%C_RST% RC generate = %RC%

if not "%RC%"=="0" (
  echo %C_RED%[FATALE]%C_RST% Generazione fallita (RC=%RC%)
  pause
  goto END
)

call :BUILD_KEY_LIST
goto SELECT_KEY

REM ==========================================================
REM EXPORT CHIAVE PUBBLICA
REM ==========================================================
:EXPORT_PUB
echo %C_CYA%================== EXPORT ==================%C_RST%
set "PUBKEY_FILE=%BASE_DIR%\public_key_%FOUND_EMAIL%.asc"
echo %C_CYA%[INFO]%C_RST% Export chiave pubblica in: %PUBKEY_FILE%

"%BIN%\gpg.exe" --homedir "%HOME%" --armor --export "%FOUND_FPR%" >"%PUBKEY_FILE%"
set "RC=%ERRORLEVEL%"
echo %C_DIM%[DBG]%C_RST% RC export = %RC%

if exist "%PUBKEY_FILE%" (
  echo %C_GRN%[OK]%C_RST% Export completato: %PUBKEY_FILE%
) else (
  echo %C_RED%[ERRORE]%C_RST% Export fallito (file non creato).
)

pause
goto END

REM ==========================================================
REM BUILD_KEY_LIST (CRISTALLIZZATO: come vecchio)
REM ==========================================================
:BUILD_KEY_LIST
set "KEY_COUNT=0"
for /L %%I in (1,1,50) do (
  set "K_FPR[%%I]="
  set "K_EMAIL[%%I]="
)

set "TMP_ALL=%TEMP%\gpg_all_%RANDOM%_%RANDOM%.txt"
set "TMP_FPRS=%TEMP%\gpg_fprs_%RANDOM%_%RANDOM%.txt"
set "TMP_UIDS=%TEMP%\gpg_uids_%RANDOM%_%RANDOM%.txt"

"%BIN%\gpg.exe" --homedir "%HOME%" --list-secret-keys --with-colons --fingerprint >"%TMP_ALL%" 2>&1
set "RC=%ERRORLEVEL%"
echo %C_DIM%[DBG]%C_RST% RC gpg colons+fpr = %RC%
if not "%RC%"=="0" (
  echo %C_RED%[ERRORE]%C_RST% gpg output fallito. Output:
  type "%TMP_ALL%"
  del /q "%TMP_ALL%" "%TMP_FPRS%" "%TMP_UIDS%" 2>nul
  exit /b 1
)

"%SystemRoot%\System32\findstr.exe" /b "fpr:" "%TMP_ALL%" >"%TMP_FPRS%"
"%SystemRoot%\System32\findstr.exe" /b "uid:" "%TMP_ALL%" >"%TMP_UIDS%"

REM fingerprints
set "I=0"
for /f "usebackq delims=" %%L in ("%TMP_FPRS%") do (
  set /a I+=1
  set "ONE_FPR="
  for /f "tokens=2 delims=:" %%F in ("%%L") do set "ONE_FPR=%%F"
  set "K_FPR[!I!]=!ONE_FPR!"
)
set "KEY_COUNT=%I%"

REM emails (tokens=2 delims=<>)
set "I=0"
for /f "usebackq delims=" %%L in ("%TMP_UIDS%") do (
  set /a I+=1
  if !I! GTR %KEY_COUNT% goto :EMAIL_DONE

  set "ONE_EMAIL="
  for /f "tokens=2 delims=<>" %%E in ("%%L") do set "ONE_EMAIL=%%E"

  echo !ONE_EMAIL! | "%SystemRoot%\System32\findstr.exe" /i "@" >nul
  if errorlevel 1 (
    if not "!ONE_EMAIL!"=="" (
      set "K_EMAIL[!I!]=(no email: !ONE_EMAIL!)"
    ) else (
      set "K_EMAIL[!I!]=(no email)"
    )
  ) else (
    set "K_EMAIL[!I!]=!ONE_EMAIL!"
  )
)

:EMAIL_DONE
del /q "%TMP_ALL%" "%TMP_FPRS%" "%TMP_UIDS%" 2>nul
exit /b 0

REM ==========================================================
REM BACKUP HOME
REM ==========================================================
:BACKUP_HOME
set "TS="
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss')"`) do set "TS=%%T"
if not defined TS exit /b 1

set "BK=%BACKUP_DIR%\home_backup_%TS%"
echo %C_CYA%[INFO]%C_RST% Backup HOME in: %BK%
mkdir "%BK%" >nul 2>&1

where robocopy >nul 2>&1
if errorlevel 1 (
  echo %C_RED%[ERRORE]%C_RST% robocopy non trovato.
  exit /b 1
)

robocopy "%HOME%" "%BK%" /E /R:1 /W:1 /NFL /NDL /NJH /NJS >nul
set "RC=%ERRORLEVEL%"
echo %C_DIM%[DBG]%C_RST% RC robocopy = %RC%
if %RC% GEQ 8 exit /b 1

echo %C_GRN%[OK]%C_RST% Backup completato.
exit /b 0

REM ==========================================================
REM PREPARE_AGENT_PINENTRY (fix "No pinentry")
REM ==========================================================
:PREPARE_AGENT_PINENTRY
setlocal EnableExtensions EnableDelayedExpansion

REM Allinea gpg e agent sulla stessa HOME
set "GNUPGHOME=%HOME%"

REM Assicura risoluzione binari del KIT
set "PATH=%BIN%;%PATH%"

REM Directory richieste
if not exist "%HOME%\private-keys-v1.d" mkdir "%HOME%\private-keys-v1.d" >nul 2>&1
if not exist "%HOME%\openpgp-revocs.d" mkdir "%HOME%\openpgp-revocs.d" >nul 2>&1

REM Pinentry del KIT
set "PINENTRY=%BIN%\pinentry-w32.exe"
if not exist "%PINENTRY%" set "PINENTRY=%BIN%\pinentry.exe"

if not exist "%PINENTRY%" (
  endlocal & exit /b 2
)

set "AGENT_CONF=%HOME%\gpg-agent.conf"

REM Se gia presente pinentry-program, non duplico
if exist "%AGENT_CONF%" (
  "%SystemRoot%\System32\findstr.exe" /i /c:"pinentry-program" "%AGENT_CONF%" >nul 2>&1
  if not errorlevel 1 (
    taskkill /F /IM gpg-agent.exe >nul 2>&1
    endlocal & exit /b 0
  )
)

>>"%AGENT_CONF%" echo pinentry-program "%PINENTRY%"

REM Riavvio agent (best-effort) per rileggere config
taskkill /F /IM gpg-agent.exe >nul 2>&1

endlocal & exit /b 0

:END
endlocal
