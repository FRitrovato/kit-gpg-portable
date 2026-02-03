@echo off
REM ============================================================================
REM  decifra.cmd - Decrypt Wizard (drag&drop)
REM  Scopo: decifrare un file .gpg trascinato sopra questo script, salvando
REM         l'output nella stessa cartella del file di input (senza estensione .gpg)
REM         e producendo un report in: <RADICE_KIT>\reports\
REM ============================================================================

REM Isola le variabili d'ambiente: tutto cio' che "setti" qui dentro non sporca il sistema.
setlocal EnableExtensions EnableDelayedExpansion

REM Imposta la code page UTF-8 per gestire meglio caratteri speciali/accentate nei messaggi.
REM ">nul" serve a non stampare a video l'output del comando chcp.
chcp 65001 >nul


REM ============================================================================
REM 1) CALCOLO PERCORSI BASE - PUNTA ALLA RADICE DEL KIT (cartella padre di "run")
REM ============================================================================

REM %~dp0 = path (drive+directory) dove risiede questo script (tipicamente ...\KIT_GPG v.1.1\run\)
REM Aggiungendo ".." risali di un livello -> ...\KIT_GPG v.1.1\
set "BASEDIR=%~dp0.."

REM Normalizza/risolve il percorso in "full path" (assoluto), ripulendo eventuali ".."
for %%I in ("%BASEDIR%") do set "BASEDIR=%%~fI"

for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"

REM ============================================================================
REM 2) CONFIGURAZIONE GPG - HOME (portachiavi) + BINARIO gpg.exe
REM ============================================================================

REM GNUPGHOME: directory dove GnuPG cerca keyring, config e chiavi private/pubbliche.
REM Qui presumi la struttura del kit: <RADICE_KIT>\privata
set "GNUPGHOME=%BASEDIR%\privata"

REM Percorso al binario GPG del kit (se presente): <RADICE_KIT>\bin\gpg.exe
set "GPG_EXE=%BASEDIR%\bin\gpg.exe"

REM Compatibilit�: se la cartella "privata" non esiste, prova a usare "<RADICE_KIT>\home"
if not exist "%GNUPGHOME%" set "GNUPGHOME=%BASEDIR%\home"


REM ============================================================================
REM 3) REPORT - cartella reports + file di log con timestamp
REM ============================================================================

REM Directory report: richiesta utente -> dentro la root del kit, cartella "reports"
set "REPORT_DIR=%BASEDIR%\reports"

REM Crea la directory report se non esiste (mkdir non va in errore se esiste gia').
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"

REM Costruisce un timestamp "safe" usando %date% e %time% (formato locale) e sostituzioni
REM - rimuove spazi
REM - sostituisce "/" "-" ":" "," con "_"
set "TS=%date%_%time%"
set "TS=%TS: =%"
set "TS=%TS:/=-%"
set "TS=%TS::=-%"
set "TS=%TS:,=-%"

REM File report: nome univoco basato su timestamp
set "REPORT_FILE=%REPORT_DIR%\decrypt_report_%TS%.txt"


REM ============================================================================
REM 4) VALIDAZIONE INPUT - serve un file passato come primo argomento (%1)
REM    (tipico: trascina un file .gpg sopra lo script)
REM ============================================================================

REM Se non c'e' argomento (%1 vuoto), istruzioni e uscita controllata.
if "%~1"=="" (
    echo(%ESC%[31m[ERRORE] Trascina un file .gpg sopra questo script per decifrarlo%ESC%[0m
    echo [ERRORE] Trascina un file .gpg sopra questo script per decifrarlo.>>"%REPORT_FILE%"
    echo [INFO] BASEDIR=%BASEDIR%>>"%REPORT_FILE%"
    echo [INFO] GNUPGHOME=%GNUPGHOME%>>"%REPORT_FILE%"
    echo [INFO] GPG_EXE=%GPG_EXE%>>"%REPORT_FILE%"
    pause
    exit /b
)


REM ============================================================================
REM 5) HEADER A VIDEO + HEADER NEL REPORT
REM ============================================================================

REM Riga vuota a video per leggibilita'
echo.

REM Banner a video
echo ==========================================================
echo    DECRYPTION WIZARD - RICEZIONE FILE SICURO
echo ==========================================================
echo.

REM Info a video (utile per troubleshooting)
echo(%ESC%[32m[INFO] Percorso Kit: %BASEDIR%%ESC%[0m
echo(%ESC%[32m[INFO] Utilizzo portachiavi in: %GNUPGHOME%%ESC%[0m
echo(%ESC%[32m[INFO] Report: %REPORT_FILE%%ESC%[0m
echo(%ESC%[32m[INFO] File input: %~1%ESC%[0m

REM Header nel report (stesse info, persistenti)
echo ==========================================================>>"%REPORT_FILE%"
echo DECRYPTION WIZARD - REPORT OPERAZIONE>>"%REPORT_FILE%"
echo ==========================================================>>"%REPORT_FILE%"
echo Data/Ora (locale): %date% %time%>>"%REPORT_FILE%"
echo Percorso Kit (BASEDIR): %BASEDIR%>>"%REPORT_FILE%"
echo GNUPGHOME: %GNUPGHOME%>>"%REPORT_FILE%"
echo GPG_EXE: %GPG_EXE%>>"%REPORT_FILE%"
echo File input: %~1>>"%REPORT_FILE%"
echo ---------------------------------------------------------->>"%REPORT_FILE%"

REM ============================================================================
REM 6) CHECK PRESENZA gpg.exe
REM ============================================================================

REM Se il binario non esiste nel punto atteso, logga e interrompe.
if not exist "%GPG_EXE%" (
    echo(%ESC%[31m[ERRORE] Non trovo gpg.exe in %GPG_EXE% %ESC%[0m
    echo [ERRORE] Non trovo gpg.exe in %GPG_EXE%>>"%REPORT_FILE%"
    pause
    exit /b
)


REM ============================================================================
REM 6.1) IMPORT CHIAVE PUBBLICA (per verifica firma)
REM ============================================================================
set "TRUST_DIR=%BASEDIR%\trust"
set "PUBKEY_FILE=%TRUST_DIR%\sogei_publickey.asc"

echo [INFO] TRUST_DIR: %TRUST_DIR%>>"%REPORT_FILE%"
echo [INFO] PUBKEY_FILE: %PUBKEY_FILE%>>"%REPORT_FILE%"
echo [INFO] TRUST_DIR: %TRUST_DIR%
echo [INFO] PUBKEY_FILE: %PUBKEY_FILE%

if exist "%PUBKEY_FILE%" (
    echo ---------------------------------------------------------->>"%REPORT_FILE%"
    echo [INFO] Import public key per verifica firma...>>"%REPORT_FILE%"
    "%GPG_EXE%" --homedir "%GNUPGHOME%" --import "%PUBKEY_FILE%" >>"%REPORT_FILE%" 2>&1
    echo lanciato gpg 
    set "RC_IMPORT=%ERRORLEVEL%"
    echo [INFO] RC import: %RC_IMPORT%>>"%REPORT_FILE%"
    echo ---------------------------------------------------------->>"%REPORT_FILE%"
) else (
    echo ---------------------------------------------------------->>"%REPORT_FILE%"
    echo [WARN] Public key non trovata: %PUBKEY_FILE%>>"%REPORT_FILE%"
    REM Nota l'uso del carattere ^ davanti alle parentesi e al punto se necessario
    echo [WARN] La verifica firma potrebbe fallire ^(RC=2^).>>"%REPORT_FILE%"
    echo ---------------------------------------------------------->>"%REPORT_FILE%"
)

REM ============================================================================
REM 7) DECRITTAZIONE
REM ============================================================================

set "OUT_FILE=%~dp1%~n1"

echo Output atteso: %OUT_FILE%>>"%REPORT_FILE%"
echo ---------------------------------------------------------->>"%REPORT_FILE%"

REM --- ESEGUI GPG (RC va catturato SUBITO DOPO)
"%GPG_EXE%" --decrypt --output "%OUT_FILE%" "%~1" >>"%REPORT_FILE%" 2>&1

set "RC=%ERRORLEVEL%"
set "OUT_SIZE=0"
if exist "%OUT_FILE%" (
    for %%A in ("%OUT_FILE%") do set "OUT_SIZE=%%~zA"
)

REM ============================================================================
REM 8) ESITO - gestione robusta
REM ============================================================================

echo ---------------------------------------------------------->>"%REPORT_FILE%"
echo RC (gpg): %RC%
echo File output: %OUT_FILE%
echo Dimensione output (bytes): %OUT_SIZE%
echo RC (gpg): %RC%>>"%REPORT_FILE%"
echo File output: %OUT_FILE%>>"%REPORT_FILE%"
echo Dimensione output (bytes): %OUT_SIZE%>>"%REPORT_FILE%"
echo ---------------------------------------------------------->>"%REPORT_FILE%"

REM ------- Esito: Successi/avvisi vs errori
if "%RC%"=="0" goto :OK
if "%RC%"=="1" goto :OK_WARNING
if "%RC%"=="2" goto :OK_SIGNFAIL
if "%RC%"=="3" goto :KO_DECFAIL
if "%RC%"=="4" goto :KO_PASS
if "%RC%"=="5" goto :KO_NOKP
goto :ERRORE


:ERRORE
echo %ESC%[31m[ERRORE] Decifratura fallita (RC=%RC%)%ESC%[0m
echo [ERRORE] Esito: FALLITO (RC=%RC%) >>"%REPORT_FILE%"
echo.
echo [ERRORE] Esito: FALLITO (RC=%RC%)>>"%REPORT_FILE%"
echo Suggerimento: verificare chiavi private in "%GNUPGHOME%\private-keys-v1.d">>"%REPORT_FILE%"
goto :ESITO_END

:OK
echo [OK] File decifrato con successo (RC=%RC%)!
echo Lo trovi nella stessa cartella del file originale.
echo [OK] Esito: SUCCESSO (RC=%RC%)>>"%REPORT_FILE%"
echo File output: %OUT_FILE%>>"%REPORT_FILE%"
goto :ESITO_END

:OK_WARNING
echo.
echo [OK] File decifrato, ma con AVVISI. (RC=%RC%)
echo Controlla il report per i dettagli (firma/chiavi di firma).
echo Decrittazione OK, firma OK ma trust non validato
echo [WARN] Esito: SUCCESSO CON AVVISI (RC=%RC%)>>"%REPORT_FILE%"
echo File output: %OUT_FILE%>>"%REPORT_FILE%"
goto :ESITO_END

:OK_SIGNFAIL
echo.
echo [OK] File decifrato, ma VERIFICA FIRMA FALLITA / NON VERIFICATA. (RC=%RC%)
echo Controlla il report: import key / trust / mismatch firma.
echo [WARN] Esito: DECRITTAZIONE OK - FIRMA KO (RC=%RC%)>>"%REPORT_FILE%"
echo File output: %OUT_FILE%>>"%REPORT_FILE%"
goto :ESITO_END

:KO_DECFAIL
echo.
echo Decifratura fallita (RC=%RC%)
echo Controlla il report: import key / trust / mismatch firma.
echo [FAIL] Esito: DECRITTAZIONE KO - (RC=%RC%)>>"%REPORT_FILE%"
echo File output: %OUT_FILE%>>"%REPORT_FILE%"
goto :ESITO_END

:KO_PASS
echo.
echo Passprhase errata decifratura fallita (RC=%RC%)
echo Controlla il report: Sbagliata la passphrase
echo [FAIL] Esito: DECRITTAZIONE KO - No Passphrase- (RC=%RC%)>>"%REPORT_FILE%"
echo File output: %OUT_FILE%>>"%REPORT_FILE%"
goto :ESITO_END

:KO_NOKP
echo.
echo Manca chiave privata (RC=%RC%)
echo Controlla il report: no chiave privata
echo [FAIL] Esito: DECRITTAZIONE KO - No no chiave privata - (RC=%RC%)>>"%REPORT_FILE%"
echo File output: %OUT_FILE%>>"%REPORT_FILE%"
goto :ESITO_END

:ESITO_END
echo ---------------------------------------------------------->>"%REPORT_FILE%"
echo Fine operazione.(RC=%RC%)>>"%REPORT_FILE%"

REM ============================================================================
REM 9) CHIUSURA
REM ============================================================================

REM Riga vuota finale
echo.
pause

REM ============================================================================
REM  GPG EXIT CODES (RC) - INTERPRETAZIONE OPERATIVA
REM  Contesto: GnuPG 2.x - DECIFRAZIONE + VERIFICA FIRMA
REM
REM  NOTA IMPORTANTE:
REM  - GPG non garantisce una mappatura rigida RC -> causa
REM  - Gli RC vanno SEMPRE interpretati insieme a:
REM      * presenza/dimensione file di output
REM      * messaggi testuali nel report
REM
REM ----------------------------------------------------------------------------
REM  RC = 0
REM    - SUCCESSO PIENO
REM    - Decrittazione OK
REM    - Firma OK (se presente)
REM
REM ----------------------------------------------------------------------------
REM  RC = 1
REM    - WARNING
REM    - Decrittazione OK
REM    - Firma OK ma trust NON validato
REM    - Esempi:
REM        "WARNING: This key is not certified with a trusted signature"
REM
REM ----------------------------------------------------------------------------
REM  RC = 2
REM    - ERRORE NON FATALE
REM    - Decrittazione OK
REM    - Verifica firma FALLITA o NON VERIFICABILE
REM    - Cause tipiche:
REM        * public key non importata
REM        * firma con chiave diversa
REM        * firma corrotta
REM        * file cifrato ma non firmato
REM    - Se output esiste (>0 byte):
REM        -> SUCCESSO CON AVVISI (FIRMA KO)
REM
REM ----------------------------------------------------------------------------
REM  RC = 3
REM    - ERRORE FATALE
REM    - Decrittazione FALLITA
REM    - Esempio:
REM        "decryption failed"
REM
REM ----------------------------------------------------------------------------
REM  RC = 4
REM    - ERRORE FATALE
REM    - Passphrase errata
REM    - Esempio:
REM        "Bad passphrase"
REM
REM ----------------------------------------------------------------------------
REM  RC = 5
REM    - ERRORE FATALE
REM    - Chiave privata NON disponibile
REM    - Esempio:
REM        "No secret key"
REM
REM ----------------------------------------------------------------------------
REM  RC = 6
REM    - ERRORE FATALE
REM    - File di input NON valido (non OpenPGP)
REM    - Esempio:
REM        "no valid OpenPGP data found"
REM
REM ----------------------------------------------------------------------------
REM  RC = 7
REM    - ERRORE FATALE
REM    - File GPG danneggiato / corrotto
REM    - Esempio:
REM        "invalid packet"
REM
REM ----------------------------------------------------------------------------
REM  RC = 8
REM    - ERRORE FATALE
REM    - Algoritmo non supportato
REM    - Esempio:
REM        "unsupported algorithm"
REM
REM ----------------------------------------------------------------------------
REM  RC = 9
REM    - ERRORE FATALE
REM    - Firma malformata
REM    - Esempio:
REM        "invalid signature packet"
REM
REM ----------------------------------------------------------------------------
REM  RC = 10
REM    - WARNING
REM    - Chiave SCADUTA
REM    - Firma tecnicamente valida ma key expired
REM
REM ----------------------------------------------------------------------------
REM  RC = 11
REM    - WARNING
REM    - Chiave REVOCATA
REM    - Firma presente ma key non piu' valida
REM
REM ----------------------------------------------------------------------------
REM  RC = 12
REM    - ERRORE
REM    - Firma con chiave NON coerente
REM    - Esempio:
REM        "wrong key usage"
REM
REM ----------------------------------------------------------------------------
REM  RC = 13
REM    - ERRORE FATALE
REM    - Permessi negati / accesso file
REM    - Esempio:
REM        "permission denied"
REM
REM ----------------------------------------------------------------------------
REM  RC = 14
REM    - ERRORE FATALE
REM    - Keyring danneggiato
REM    - Esempio:
REM        "keybox corruption"
REM
REM ----------------------------------------------------------------------------
REM  RC = 15
REM    - ERRORE FATALE
REM    - TrustDB danneggiata
REM
REM ----------------------------------------------------------------------------
REM  RC = 16
REM    - ERRORE FATALE
REM    - Problema con gpg-agent
REM
REM ----------------------------------------------------------------------------
REM  RC = 17
REM    - ERRORE FATALE
REM    - Timeout operazione
REM
REM ----------------------------------------------------------------------------
REM  RC = 18
REM    - ERRORE FATALE
REM    - Memoria insufficiente
REM
REM ----------------------------------------------------------------------------
REM  RC = 19
REM    - ERRORE FATALE
REM    - Errore I/O (filesystem, path, disco)
REM
REM ----------------------------------------------------------------------------
REM  RC >= 20
REM    - ERRORE FATALE
REM    - Errori interni o stati non gestiti da GPG
REM    - Trattare come FALLIMENTO BLOCCANTE
REM ============================================================================
