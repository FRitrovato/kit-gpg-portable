Manuale Operativo Kit GPG Portable 

1. Scopo del kit 
* Il Kit GPG Portable consente di leggere (decifrare) file cifrati con GPG (OpenPGP) in modo semplice e controllato, senza installare software sul computer.
* È pensato per ricevere file riservati.
* Permette di usare una chiavetta USB o una cartella locale.
* Consente di operare anche su PC dove non si hanno privilegi di amministratore.
* Il kit non è un servizio online e non richiede configurazioni di sistema permanenti.

2. Cosa fa 
Il kit permette di:
* Utilizzare GPG in modalità portable, senza bisogno di installare pacchetti.
* Importare e gestire chiavi crittografiche all’interno del kit.
* Decifrare file cifrati con estensione .gpg o .asc.
* Verificare il fingerprint delle chiavi.
* Guidare l’utente con appositi messaggi a video.

3. Cosa NON fa 
* Il kit non protegge un computer compromesso.
* Non è un software antivirus.
* Non impedisce errori commessi dall'utente.
* Non garantisce automaticamente la conformità normativa.
* La cifratura protegge i file, non l’ambiente circostante.

4. Requisiti 
* Sistema operativo Windows 10 o Windows 11.
* Possibilità di eseguire file con estensione .cmd.
* Il kit include tutto ciò che serve per funzionare in modalità portable.
* Non è richiesta alcuna installazione di software sul sistema.

5. Struttura del kit 
La cartella del kit contiene:
* File eseguibili (.cmd).
* Configurazioni GPG.
* Cartelle di lavoro per i file in ingresso e in uscita.
* Una cartella dedicata specificamente alle chiavi.
* Tutto il contenuto rimane all'interno del perimetro del kit.

6. Prima esecuzione 

1. Avvia lo script principale indicato nel kit.
2. Il kit inizializza l’ambiente GPG locale.
3. Viene richiesto di importare la chiave pubblica necessaria.
4. Viene mostrato il fingerprint della chiave per la verifica.
5. Il fingerprint è l’identificativo univoco della chiave.
6. Se il fingerprint non coincide con quello fornito dal mittente, non bisogna proseguire e l'operazione va interrotta.
7. Decifrare un file 
    Il flusso tipico delle operazioni è:
    1. Copiare il file cifrato nella cartella prevista dal kit.
    2. Avviare lo script di decifratura.
    3. Inserire la passphrase quando richiesta.
    4. Attendere l’esito dell'operazione.
    5. Il file decifrato viene salvato nella cartella di output prevista.
8. Passphrase 
* La passphrase protegge la chiave privata.
* Viene richiesta solo al momento dell’effettivo utilizzo.
* Non viene salvata né registrata dal sistema.
* È responsabilità dell’utente conservarla in modo sicuro.

9. Errori comuni 

**Passphrase errata**: La decifratura fallisce, ma nessun file viene danneggiato.
**Fingerprint errato**: L'operazione deve essere interrotta e bisogna richiedere una verifica al mittente.
**Firma non verificabile**: Il file può essere comunque decifrato, ma l’autenticità del mittente non è garantita.

10. File decifrati 
Dopo la decifratura, i file:
* Sono "in chiaro".
* Vanno gestiti come dati sensibili.
* Devono essere conservati o eliminati secondo le regole aziendali o normative previste.

11. Sicurezza dell’ambiente 
Il kit presuppone che:
* Il PC utilizzato sia affidabile.
* L’utente che lo utilizza sia autorizzato.
* La chiavetta o la cartella del kit sia costantemente sotto controllo.
* Se il sistema è compromesso, la sicurezza complessiva non è garantita.

12. Supporto e utilizzo consapevole 
* Il kit è uno strumento operativo semplice, trasparente e verificabile.
* Il suo corretto utilizzo dipende dalle procedure adottate e dall’attenzione prestata dall’utente.


* Per dubbi operativi, è possibile consultare anche le FAQ.
