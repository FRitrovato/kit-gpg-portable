@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul 2>&1

REM ==============================================================================
REM  GPG PORTABLE - SETUP CHIAVI (Wizard unico) - Output "umano" + colori CMD-only
REM ==============================================================================
REM  Autore/Curatore:   - Francesco Ritrovato
REM
REM  Descrizione: Sostituire XXX con il nome dell'organizzazione/ente/persona che deve cifrare i file.
REM
REM  COSA FA QUESTO WIZARD (in parole semplici):
REM   1) Prende dal kit la chiave pubblica di   xxx e la importa (così potrai cifrare per   xxx)
REM   2) Crea la tua coppia di chiavi (pubblica + privata)
REM        - la PRIVATA resta nel kit e NON deve uscire dal tuo PC/chiavetta
REM        - la PUBBLICA è quella che invierai a   xxx
REM   3) Esporta la tua chiave pubblica in out\ così la trovi subito pronta da inviare
REM   4) Scrive un report e un riepilogo nel kit per audit e troubleshooting
REM
REM  SICUREZZA (regole d'oro):
REM   - NON inviare mai la chiave privata.
REM   - La passphrase deve essere lunga e non riutilizzata.
REM   - Se il fingerprint della chiave   xxx non combacia, fermati.
REM
REM  COLORI:
REM   - 0B (cyan): passi del wizard
REM   - 0A (verde): OK / completato
REM   - 0E (giallo): avvisi
REM   - 0C (rosso): errori/blocchi
REM   - 07 (neutro): info / percorsi
REM ==============================================================================

REM DEBUG: 1 = mostra righe [DBG] a video e su log, 0 = output pulito
set "DEBUG=0"

REM ---------------------------
REM Percorsi base (lo script sta in \run)
REM ---------------------------
set "BASEDIR=%~dp0.."
for %%I in ("%BASEDIR%") do set "BASEDIR=%%~fI"

set "BIN=%BASEDIR%\bin"
set "HOME=%BASEDIR%\home"
set "OUT=%BASEDIR%\out"
set "TRUST=%BASEDIR%\trust"
set "REPORTS=%BASEDIR%\reports"

set "LOG=%REPORTS%\setup_keys.log"
set "REPORT=%REPORTS%\setup_keys_report.txt"
set "KIT_STATUS=%TRUST%\kit_keys_status.txt"

set "  xxx_KEYFILE=%TRUST%\  xxx_publickey.asc"
set "  xxx_FPRFILE=%TRUST%\fingerprint_  xxx.txt"

REM ---------------------------
REM Benvenuto
REM ---------------------------
call :CE 0B "=========================================================="
call :CE 0B " GPG Portable - Setup chiavi (wizard unico)"
call :CE 0B " Autore/Curatore: Francesco Ritrovato (  xxx)"
call :CE 0B "=========================================================="
echo.
call :CE 07 "Ciao. Ti guido passo-passo."
call :CE 07 "Alla fine avrai un file pronto da inviare a   xxx (la tua chiave pubblica)."
call :CE 0E "Importante: la chiave PRIVATA resta qui e non va mai inviata."
echo.
call :CE 07 "Premi un tasto per iniziare."
pause >nul

REM ---------------------------
REM [STEP 1] Prepara cartelle e controlla che gli eseguibili esistano
REM ---------------------------
echo.
call :CE 0B "[1/8] Preparazione del kit (cartelle e componenti)..."
call :CE 07 "Sto controllando che nel kit ci siano gli strumenti necessari."

if not exist "%HOME%"    mkdir "%HOME%"    >nul 2>&1
if not exist "%OUT%"     mkdir "%OUT%"     >nul 2>&1
if not exist "%TRUST%"   mkdir "%TRUST%"   >nul 2>&1
if not exist "%REPORTS%" mkdir "%REPORTS%" >nul 2>&1

if not exist "%HOME%"    call :Fail "Non riesco a creare la cartella: %HOME%"
if not exist "%OUT%"     call :Fail "Non riesco a creare la cartella: %OUT%"
if not exist "%TRUST%"   call :Fail "Non riesco a creare la cartella: %TRUST%"
if not exist "%REPORTS%" call :Fail "Non riesco a creare la cartella: %REPORTS%"

REM Modalit portable: il portachiavi GPG resta dentro al kit
set "GNUPGHOME=%HOME%"
set "PATH=%BIN%;%PATH%"

REM Log di avvio (utile se qualcosa va storto)
echo.>> "%LOG%"
echo =============================================================================>> "%LOG%"
echo [%DATE% %TIME%] setup_keys.cmd - Avvio (Francesco Ritrovato)>> "%LOG%"
echo BASEDIR=%BASEDIR%>> "%LOG%"
echo BIN=%BIN%>> "%LOG%"
echo GNUPGHOME=%GNUPGHOME%>> "%LOG%"

call :DBG "BASEDIR=%BASEDIR%"
call :DBG "BIN=%BIN%"
call :DBG "GNUPGHOME=%GNUPGHOME%"

REM Controllo binari minimi
if not exist "%BIN%\gpg.exe"          call :Fail "Manca gpg.exe in: %BIN%"
if not exist "%BIN%\gpg-agent.exe"    call :Fail "Manca gpg-agent.exe in: %BIN%"
if not exist "%BIN%\pinentry-w32.exe" call :Fail "Manca pinentry-w32.exe in: %BIN%"

REM Forzo pinentry-w32 (evita pinentry sbagliati)
> "%GNUPGHOME%\gpg-agent.conf" (
  echo pinentry-program "%BIN%\pinentry-w32.exe"
)

REM Verifica rapida: GPG parte?
"%BIN%\gpg.exe" --version >> "%LOG%" 2>&1
if errorlevel 1 call :Fail "GPG non si avvia. Controlla il log: %LOG%"

call :CE 0A "[OK] Kit pronto."

REM ---------------------------
REM [STEP 2] Import chiave pubblica   xxx + (se presente) verifica fingerprint
REM ---------------------------
echo.
call :CE 0B "[2/8] Chiave pubblica di   xxx: import e controllo..."
call :CE 07 "Questo passaggio serve a mettere nel kit la chiave pubblica di   xxx."
call :CE 07 "In questo modo potrai cifrare i file destinati a   xxx."

set "  xxx_IMPORTED_FPR="
set "  xxx_FPR_TMP="
set "  xxx_FPR_CHECK=SKIPPED"
set "  xxx_EXPECTED_FPR="

if not exist "%  xxx_KEYFILE%" (
  call :CE 0E "[WARN] Non trovo la chiave pubblica di   xxx nel kit:"
  call :CE 07 "  %  xxx_KEYFILE%"
  call :CE 0E "[WARN] Salto l'import. Aggiungi il file e rilancia lo script."
  echo [%DATE% %TIME%] WARN:   xxx keyfile mancante: %  xxx_KEYFILE%>> "%LOG%"
  goto :After  xxxImport
)

call :CE 07 "[INFO] File chiave pubblica   xxx:"
call :CE 07 "  %  xxx_KEYFILE%"

"%BIN%\gpg.exe" --import "%  xxx_KEYFILE%" >> "%LOG%" 2>&1
if errorlevel 1 call :Fail "Import della chiave pubblica   xxx fallito. Vedi log: %LOG%"
call :CE 0A "[OK] Chiave pubblica   xxx importata."

REM Estrazione fingerprint dal file (show-only) su output colons
set "TMP_SHOW=%REPORTS%\_  xxx_showonly_colons.txt"
"%BIN%\gpg.exe" --with-colons --import-options show-only --import "%  xxx_KEYFILE%" > "%TMP_SHOW%" 2>> "%LOG%"
if not exist "%TMP_SHOW%" call :Fail "Non riesco a generare: %TMP_SHOW%"

REM Parsing fingerprint (prende la prima riga fpr)
set "TMP_FPR=%TMP_SHOW%"
set "line="
set "fingerprint="

call :DBG "TMP_FPR(  xxx)=%TMP_FPR%"
call :DBG "Dump fpr (  xxx):"
call :DBG "----------------"

call :CE 07 " "
call :CE 07 "[INFO] Controllo identita' chiave   xxx (fingerprint)..."
for /f "tokens=*" %%i in ('findstr /b "fpr" "%TMP_FPR%"') do (
  if not defined   xxx_FPR_TMP (
    set "line=%%i"
    set "fingerprint=!line:fpr:=!"
    set "fingerprint=!fingerprint::=!"
    set "fingerprint=!fingerprint: =!"
    set "  xxx_FPR_TMP=!fingerprint!"
  )
)

if not defined   xxx_FPR_TMP call :Fail "Non riesco a leggere il fingerprint   xxx dal file. Vedi %TMP_FPR% e %LOG%."
set "  xxx_IMPORTED_FPR=%  xxx_FPR_TMP%"

call :CE 0A "[OK] Fingerprint   xxx (letto dal file):"
call :CE 07 "  %  xxx_IMPORTED_FPR%"

REM Se nel kit c fingerprint_  xxx.txt, faccio confronto (massima sicurezza)
if exist "%  xxx_FPRFILE%" (
  for /f "usebackq delims=" %%A in ("%  xxx_FPRFILE%") do (
    if not defined   xxx_EXPECTED_FPR (
      if not "%%A"=="" set "  xxx_EXPECTED_FPR=%%A"
    )
  )

  if defined   xxx_EXPECTED_FPR (
    set "A=%  xxx_EXPECTED_FPR: =%"
    set "B=%  xxx_IMPORTED_FPR: =%"
    call :CE 07 "[INFO] Fingerprint atteso (dal kit):"
    call :CE 07 "  %A%"

    if /I "%A%"=="%B%" (
      set "  xxx_FPR_CHECK=OK"
      call :CE 0A "[SUCCESS] Verifica fingerprint   xxx: OK."
    ) else (
      set "  xxx_FPR_CHECK=FAIL"
      call :CE 0C "[ALERT] Fingerprint   xxx NON combacia con quello atteso."
      call :CE 0C "        Consiglio: FERMARE qui e segnalare."
      choice /C AN /M "Vuoi ANNULLARE ora? (A=Annulla, N=Continua comunque)"
      if errorlevel 2 (
        echo [%DATE% %TIME%] WARNING: fingerprint mismatch, user continued>> "%LOG%"
        call :CE 0E "[WARN] Hai scelto di continuare nonostante il mismatch."
      ) else (
        echo [%DATE% %TIME%] ABORT: user cancelled due to mismatch>> "%LOG%"
        call :Fail "Operazione annullata: fingerprint   xxx non conforme."
      )
    )
  ) else (
    call :CE 0E "[WARN] fingerprint_  xxx.txt presente ma vuoto/non leggibile."
    echo [%DATE% %TIME%] WARN: fingerprint atteso vuoto>> "%LOG%"
  )
) else (
  call :CE 0E "[WARN] Nel kit non c' fingerprint_  xxx.txt: verifica manuale consigliata."
  echo [%DATE% %TIME%] WARN: fingerprint atteso non presente>> "%LOG%"
)

:After  xxxImport

REM ---------------------------
REM [STEP 3] Chiedo i dati per creare la tua chiave
REM ---------------------------
echo.
call :CE 0B "[3/8] Dati della tua chiave..."
call :CE 07 " "
call :CE 07 "Ora creiamo la TUA chiave. Questi dati finiscono nella chiave pubblica."
call :CE 07 "Non sono segreti, servono solo per riconoscerla."
call :CE 07 "" 
set /p "REALNAME=Nome e Cognome (o Ufficio): "
if "%REALNAME%"=="" call :Fail "Nome/Ufficio non inserito."

set /p "EMAIL=Email istituzionale (anche generica): "
if "%EMAIL%"=="" call :Fail "Email non inserita."

set /p "COMMENT=Commento (opzionale, es. Reparto/Ente): "
set "EXPIRE=2y"

echo.
call :CE 07 "Riepilogo (quello che stai per creare):"
call :CE 07 "  Nome/Ufficio : %REALNAME%"
call :CE 07 "  Email        : %EMAIL%"
if not "%COMMENT%"=="" call :CE 07 "  Commento     : %COMMENT%"
call :CE 07 "  Scadenza     : %EXPIRE%"
echo.
call :CE 0E "[ATTENZIONE] Tra poco ti verra' chiesta una PASSPHRASE."
call :CE 0E "           Deve essere lunga e non riutilizzata."
choice /C SN /M "Procedo con la generazione della chiave? (S/N)"
if errorlevel 2 call :Fail "Operazione annullata dall'utente."

REM ---------------------------
REM [STEP 4] Genero la chiave (GPG far comparire il prompt passphrase)
REM ---------------------------
echo.
call :CE 0B "[4/8] Generazione della tua chiave..."
call :CE 07 "Tra poco comparira' una finestra (o prompt) per inserire la passphrase."
call :CE 07 "Non chiuderla: e' normale."

set "BATCH=%REPORTS%\_keyparams.tmp"
> "%BATCH%" (
  echo Key-Type: RSA
  echo Key-Length: 3072
  echo Subkey-Type: RSA
  echo Subkey-Length: 3072
  echo Name-Real: %REALNAME%
  if not "%COMMENT%"=="" echo Name-Comment: %COMMENT%
  echo Name-Email: %EMAIL%
  echo Expire-Date: %EXPIRE%
  echo %%commit
)

"%BIN%\gpg.exe" --batch --pinentry-mode default --full-generate-key "%BATCH%" >> "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"
del /f /q "%BATCH%" >nul 2>&1
if not "%RC%"=="0" call :Fail "Generazione chiave fallita (RC=%RC%). Controlla log: %LOG%"

call :CE 0A "[OK] Chiave creata."

REM ---------------------------
REM [STEP 5] Recupero fingerprint della tua chiave (serve per export)
REM ---------------------------
echo.
call :CE 0B "[5/8] Identifico la tua chiave (fingerprint)..."
call :CE 07 "Ora leggo il fingerprint della tua chiave per esportare la pubblica."

set "MY_FPR="
set "MY_FPR_TMP="
set "TMP_MY=%REPORTS%\_my_fpr_colons.txt"

"%BIN%\gpg.exe" --with-colons --list-secret-keys --fingerprint "%EMAIL%" > "%TMP_MY%" 2>> "%LOG%"
if not exist "%TMP_MY%" call :Fail "Non riesco a generare: %TMP_MY%"

set "TMP_FPR=%TMP_MY%"
set "line="
set "fingerprint="

for /f "tokens=*" %%i in ('findstr /b "fpr" "%TMP_FPR%"') do (
  if not defined MY_FPR_TMP (
    set "line=%%i"
    set "fingerprint=!line:fpr:=!"
    set "fingerprint=!fingerprint::=!"
    set "fingerprint=!fingerprint: =!"
    set "MY_FPR_TMP=!fingerprint!"
  )
)

if not defined MY_FPR_TMP call :Fail "Non trovo il fingerprint della tua chiave. Controlla log: %LOG%"
set "MY_FPR=%MY_FPR_TMP%"

call :CE 0A "[OK] Fingerprint della tua chiave:"
call :CE 07 "  %MY_FPR%"

REM ---------------------------
REM [STEP 6] Export chiave pubblica da inviare a   xxx
REM ---------------------------
echo.
call :CE 0B "[6/8] Creo il file da inviare a   xxx (chiave pubblica)..."
call :CE 07 "Questo e' l'unico file che devi inviare a   xxx."

set "MY_PUBOUT=%OUT%\public_key_%MY_FPR%.asc"
"%BIN%\gpg.exe" --armor --output "%MY_PUBOUT%" --export "%MY_FPR%" >> "%LOG%" 2>&1
if errorlevel 1 call :Fail "Export chiave pubblica fallito. Controlla log: %LOG%"

call :CE 0A "[OK] File chiave pubblica creato:"
call :CE 07 "  %MY_PUBOUT%"

REM ---------------------------
REM [STEP 7] Report e riepilogo (NO blocchi IF con parentesi: parser-safe)
REM ---------------------------
echo.
call :CE 0B "[7/8] Creo i documenti di riepilogo nel kit..."
call :CE 07 "Servono per avere traccia di cosa e' stato fatto e dove trovare i file."

REM === REPORT ===
> "%REPORT%"  echo ==========================================================
>>"%REPORT%"  echo  GPG Portable - Setup chiavi (report)
>>"%REPORT%"  echo  Autore/Curatore kit: Francesco Ritrovato (  xxx)
>>"%REPORT%"  echo ==========================================================
>>"%REPORT%"  echo Data/Ora: %DATE% %TIME%
>>"%REPORT%"  echo.
>>"%REPORT%"  echo --- AMBIENTE PORTABLE ---
>>"%REPORT%"  echo GNUPGHOME:
>>"%REPORT%"  echo   %GNUPGHOME%
>>"%REPORT%"  echo.
>>"%REPORT%"  echo --- CHIAVE   xxx (PUBBLICA) ---

if exist "%  xxx_KEYFILE%"  >>"%REPORT%" echo File: %  xxx_KEYFILE%
if not exist "%  xxx_KEYFILE%" >>"%REPORT%" echo File: NON PRESENTE

if exist "%  xxx_KEYFILE%"  >>"%REPORT%" echo Fingerprint (da file): %  xxx_IMPORTED_FPR%
if exist "%  xxx_KEYFILE%"  >>"%REPORT%" echo Verifica fingerprint: %  xxx_FPR_CHECK%

if exist "%  xxx_FPRFILE%"  >>"%REPORT%" echo Fingerprint atteso: %  xxx_EXPECTED_FPR%
if not exist "%  xxx_FPRFILE%" >>"%REPORT%" echo Fingerprint atteso: NON PRESENTE

>>"%REPORT%"  echo.
>>"%REPORT%"  echo --- TUA CHIAVE (COPPIA) ---
>>"%REPORT%"  echo Fingerprint: %MY_FPR%
>>"%REPORT%"  echo Nome/Ufficio: %REALNAME%
>>"%REPORT%"  echo Email: %EMAIL%
if not "%COMMENT%"=="" >>"%REPORT%" echo Commento: %COMMENT%
>>"%REPORT%"  echo Scadenza: %EXPIRE%
>>"%REPORT%"  echo.
>>"%REPORT%"  echo File TUA chiave pubblica (DA INVIARE A   xxx):
>>"%REPORT%"  echo   %MY_PUBOUT%
>>"%REPORT%"  echo ==========================================================

REM === KIT STATUS ===
> "%KIT_STATUS%" echo ==========================================================
>>"%KIT_STATUS%" echo  KIT GPG - RIEPILOGO CHIAVI
>>"%KIT_STATUS%" echo ==========================================================
>>"%KIT_STATUS%" echo Aggiornato: %DATE% %TIME%
>>"%KIT_STATUS%" echo.
>>"%KIT_STATUS%" echo [TUA CHIAVE]
>>"%KIT_STATUS%" echo Fingerprint: %MY_FPR%
>>"%KIT_STATUS%" echo Pubblica (da inviare a   xxx): %MY_PUBOUT%
>>"%KIT_STATUS%" echo Privata: presente in home\ (GNUPGHOME) - NON esportata
>>"%KIT_STATUS%" echo.
>>"%KIT_STATUS%" echo [CHIAVE   xxx]

if exist "%  xxx_KEYFILE%"  >>"%KIT_STATUS%" echo File: %  xxx_KEYFILE%
if not exist "%  xxx_KEYFILE%" >>"%KIT_STATUS%" echo File: NON PRESENTE (trust\  xxx_publickey.asc)

if exist "%  xxx_KEYFILE%"  >>"%KIT_STATUS%" echo Fingerprint (da file): %  xxx_IMPORTED_FPR%
if exist "%  xxx_KEYFILE%"  >>"%KIT_STATUS%" echo Verifica fingerprint: %  xxx_FPR_CHECK%

>>"%KIT_STATUS%" echo.
>>"%KIT_STATUS%" echo Log: %LOG%
>>"%KIT_STATUS%" echo Report: %REPORT%
>>"%KIT_STATUS%" echo ==========================================================

call :CE 0A "[OK] Report creati."


REM ---------------------------
REM [STEP 8] Fine
REM ---------------------------
echo.
call :CE 0B "=========================================================="
call :CE 0A " SETUP COMPLETATO"
call :CE 07 "Ora fai SOLO questa cosa:"
call :CE 0A "1) Invia a   xxx questo file (chiave pubblica):"
call :CE 07 "   %MY_PUBOUT%"
call :CE 0E "2) NON inviare la chiave privata. Resta nel kit qui:"
call :CE 07 "   %GNUPGHOME%"
call :CE 0B "=========================================================="
echo.
call :CE 07 "Premi un tasto per chiudere."
pause >nul
exit /b 0

REM ==============================================================================
REM Funzioni di utilit
REM ==============================================================================

:DBG
REM Scrive su log sempre, a video solo se DEBUG=1
if not "%LOG%"=="" echo [%DATE% %TIME%] DBG: %~1>> "%LOG%"
if "%DEBUG%"=="1" echo [DBG] %~1
exit /b 0

:CE
REM :CE <ATTR> <TEXT>
REM Stampa una riga colorata usando sequenze di escape ANSI native
setlocal EnableExtensions EnableDelayedExpansion
set "ATTR=%~1"
set "TEXT=%~2"

REM Definizione del carattere ESC (ASCII 27)
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

REM Mappatura colori (0B=Cyan, 0A=Verde, 0E=Giallo, 0C=Rosso, 07=Reset)
if /I "!ATTR!"=="0B" set "COLOR=36"
if /I "!ATTR!"=="0A" set "COLOR=32"
if /I "!ATTR!"=="0E" set "COLOR=33"
if /I "!ATTR!"=="0C" set "COLOR=31"
if /I "!ATTR!"=="07" set "COLOR=0"

REM Stampa effettiva: ESC[codice m TESTO ESC[0m
echo !ESC![!COLOR!m!TEXT!!ESC![0m
endlocal
exit /b 0

:Fail
REM Uscita controllata con messaggio chiaro e log
set "MSG=%~1"
echo.
call :CE 0C "=========================================================="
call :CE 0C " ERRORE - Setup non completato"
call :CE 0C "=========================================================="
call :CE 0C "%MSG%"
echo.
if not "%LOG%"=="" echo [%DATE% %TIME%] ERRORE: %MSG%>> "%LOG%"
call :CE 07 "Log: %LOG%"
echo.
pause >nul
exit /b 1

