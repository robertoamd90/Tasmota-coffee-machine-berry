# Tasmota-coffee-machine-berry

Welcome to the Coffee Machine Home Automation Project! This project is designed to turn your regular coffee machine into a smart, controllable device, allowing you to brew your favorite coffee with just a click.

The primary aim of this project is to provide an automated interface for your coffee machine, enabling remote power on/off functionality and coffee brewing via a mobile application.

The original project is based on esp8266 [Tasmota Scripting-Language](https://tasmota.github.io/docs/Scripting-Language/): [Tasmota-coffee-machine](https://github.com/robertoamd90/Tasmota-coffee-machine).

This project uses ESP32 and [Tasmota Berry](https://tasmota.github.io/docs/Berry/).

## Hardware requirement:

- Coffee machine Grimac Tube (manual: 1 switch to power on, 1 switch to coffee brewing. You can use any manual 2 switch coffee machine)
- [Sonoff Dual R3 v2](https://templates.blakadder.com/sonoff_DUALR3_v2.html) with Tasmota firmware

You need to replace the standard bistable switch of your coffee machine with the outputs of your Dual R. Output 1 for the Coffee machine power (coffee machine resistance) and the power 2 for the coffee brewing (the pump).
In the standard setup, the pump can be enabled only if the coffee machine is on, with the Dual R we can enable the 2 power independently, but we will replicate the original behavior via software.

I have replaced the switch with 2 buttons for the input 1 and 2 of the Dual R.

In my case, the Power on LED was inside the power switch. After I replaced this one with a button, I added a 220v green LED.

## Deployment

This project includes a convenient upload script to deploy your Berry files to the Tasmota device.

### Quick Upload

Use the included `upload-to-tasmota.sh` script to upload Berry files to your device:

```bash
# Upload all .be files in the directory
./upload-to-tasmota.sh 192.168.1.100

# Upload specific files
./upload-to-tasmota.sh 192.168.1.100 PowerMgmt.be InputMgmt.be

# Upload a single file
./upload-to-tasmota.sh 192.168.1.100 autoexec.be
```

The script provides:
- ✅ Batch upload support for multiple files
- ✅ Automatic detection of all .be files when no files specified
- ✅ Colored output with success/error indicators
- ✅ Upload summary with statistics
- ✅ Error handling and exit codes

## Preliminary Configuration

Before proceeding with initial setup, please note:

**SwitchMode Configuration**: As of Feature 1, the SwitchMode settings are automatically configured at runtime by the InputMgmt module. If you're upgrading from an older version, you can safely ignore the manual SwitchMode commands below. The device will auto-configure on startup.

**Legacy Manual Setup** (If needed for other configurations):
```bash
SwitchMode1 15
SwitchMode2 15
```

## Tasmota Main Page:

<img width="454" height="953" alt="image" src="https://github.com/user-attachments/assets/208f76f6-8786-4783-9840-27b1317ea8d5" />



## Home Assistant Device Page

<img width="329" height="341" alt="image" src="https://github.com/user-attachments/assets/46857bad-7f99-4467-a5c2-83b008481d05" /></br>
<img width="327" height="599" alt="image" src="https://github.com/user-attachments/assets/0052ff31-dd6d-48eb-8957-ba3ea96b1c23" />

## Features:

### Off delay
Delay to power off the coffee machine after an inactivity period (no coffee brewing). The time of inactivity is configurable in the 'Off delay time' input.

### Coffee brewing
Using the 'Shot coffee time' input, you can set up your perfect coffee brewing time.

### Last Coffee brewing
The system stores the last coffee brewing time. Using the appropriate button, you can set the last coffee brewing time as the 'Shot coffee time'. You can use this function to calibrate your coffee machine as we will see later.

### Auto start brewing
Are you tired of waiting for the coffee machine to be ready before brewing your coffee? With the auto-start function, you can load your preferred coffee pods and your coffee cup while the coffee machine is off. Simply press and hold the brewing button for 2.5 seconds, and the coffee machine will turn on in auto-start mode! Once the coffee machine is ready, the brewing process will start automatically!

### Multiple Coffee Profiles (Feature 1) ✨
This feature enables management of two independent coffee profiles (Coffee1 and Coffee2) with different brewing times.

#### Profile Selection & Control
- **Button 1**: Selects Coffee1 profile
- **Button 2**: Selects Coffee2 profile
- **Home Assistant**: Coffee Selection dropdown for remote profile switching

**Short-press** (< 2.5 seconds):
- If machine is **OFF**: Turns on only the heating element (Power1) - ready to brew manually
- If machine is **ON**: Toggles the pump (Power2) - useful for manual start brewing, purging lines or cleaning

**Long-press** (≥ 2.5 seconds):
- If machine is **OFF**: Triggers auto-start mode — once heated, automatically starts brewing with the selected profile's time
- If machine is **ON**: Activates **auto learning mode** — starts brewing with no timer (indefinitely). Press **the same button** to stop. If the brew lasted more than 5 seconds, the duration is automatically saved and applied to the selected profile's time

**Simultaneous press** (both buttons within 500ms of each other):
- Turns off the machine immediately (Power1 Off)
- All active timers are cancelled
- Works regardless of the current machine state

#### Independent Brewing Times & Learning Mode
Each profile has:
- Independent brew duration (Coffee1Time, Coffee2Time)
- **Manual learning**: Press "Set Last Coffee Time" to save the last measured brew duration to the selected profile
- **Auto learning**: Long-press a button while the machine is ON to start an untimed brew; stop it by pressing **the same button**. If the brew lasted more than 5 seconds, the duration is automatically saved and applied to the selected profile
- No cross-contamination: Only the selected profile's time is updated

#### Configuration Parameters
- **Off Delay** (minutes): Auto-shutdown after inactivity
- **Coffee 1 Time** (seconds): Brew duration for Coffee1
- **Coffee 2 Time** (seconds): Brew duration for Coffee2
- **Last Coffee Time** (seconds): Measured duration from last brew (read-only)

#### MQTT Entities
- `SelectedCoffee` (select): Choose between Coffee 1 and Coffee 2
- `Coffee1Time` (number): Coffee1 brew duration
- `Coffee2Time` (number): Coffee2 brew duration
- `OffDelay` (number): Auto-shutdown delay
- `SetLastCoffeeTime` (button): Apply measured time to selected profile
- `Mode` (sensor): Active function indicator — `Manual`, `Auto-start`, `Preload`, `Learning`

### Home Assistant integration
The custom parameters are now available on Home Assistant, allowing you to directly set up your coffee machine through it. I chose not to use the [haco](https://github.com/fmtr/haco) library because I prefer not to install unnecessary plugins on Home Assistant when a feature is natively supported. Instead, I've developed a small library, HaMqttMgmt.be, to handle the creation and bidirectional update of MQTT entities from Berry using Home Assistant's standard discovery MQTT protocol.

## Calibration:

You need a precision scale.

1. Set a too long 'Shot coffee time', like 30 seconds
2. Turn on your coffee machine and wait until it becomes ready
3. Load your preferred coffee pods inside
4. Place the precision scale on the rack
5. Place your coffee cup on the precision scale and tare it
6. Start the coffee brewing and turn it off when the current weight is reached
7. Now you can set the last coffee brewing time into the 'Shot coffee time' through the 'Set' button.

<details>
  <summary>Weight table</summary>
  
| Type | Weight brewing |
|---|---|
| General Rule | coffee weight * 2 |
| Short Coffee | 20g |
| Long Coffee | 22g |
</details>

<details>
  <summary>Calibration Images</summary>
  <img width="500" alt="image" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/b8a85765-e0f2-45bc-a4c2-2371dacff448"><br/>
  <img width="500" alt="image" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/4336f6fb-ceeb-4c4b-821e-e37d3322beef"><br/>
  <img width="500" alt="image" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/d34a4fab-184c-44b9-88c2-14c5b968332b"><br/>
</details>


# Progetto Tasmota-coffee-machine-berry

Benvenuto nel progetto di automazione domestica per la macchina da caffè! Questo progetto è progettato per trasformare la tua normale macchina da caffè in un dispositivo intelligente e controllabile, consentendoti di preparare il tuo caffè preferito con un semplice clic.

L'obiettivo principale di questo progetto è fornire un'interfaccia automatizzata per la tua macchina da caffè, consentendo la funzionalità di accensione/spegnimento remoto e la preparazione del caffè tramite un'applicazione mobile.

Il progetto originale si basa su esp8266 e sul linguaggio di scripting Tasmota: [Tasmota-coffee-machine](https://github.com/robertoamd90/Tasmota-coffee-machine).

Questo progetto utilizza ESP32 e Tasmota [Berry](https://tasmota.github.io/docs/Berry/).

## Requisiti hardware:

- Macchina da caffè Grimac Tube (manuale: 1 interruttore per l'accensione, 1 interruttore per la preparazione del caffè. È possibile utilizzare qualsiasi macchina da caffè manuale con 2 interruttori)
- [Sonoff Dual R3 v2](https://templates.blakadder.com/sonoff_DUALR3_v2.html) con firmware Tasmota

È necessario sostituire l'interruttore bistabile standard della tua macchina da caffè con le uscite del tuo Dual R. L'uscita 1 per l'alimentazione della macchina da caffè (resistenza della macchina da caffè) e l'uscita 2 per la preparazione del caffè (la pompa).
Nella configurazione standard, la pompa può essere attivata solo se la macchina da caffè è accesa, con il Dual R possiamo attivare le 2 alimentazioni indipendentemente, ma replicheremo il comportamento originale tramite il software.

Ho sostituito l'interruttore con 2 pulsanti per l'ingresso 1 e 2 del Dual R.

Nel mio caso, il led di accensione era all'interno dell'interruttore di accensione, dopo averlo sostituito con un pulsante, ho aggiunto un led verde da 220V.

## Configurazione Preliminare

Prima di procedere con la configurazione iniziale, si prega di notare:

**Configurazione SwitchMode**: A partire da Feature 1, le impostazioni SwitchMode vengono configurate automaticamente in fase di esecuzione dal modulo InputMgmt. Se stai aggiornando da una versione precedente, puoi tranquillamente ignorare i comandi SwitchMode manuali di seguito. Il dispositivo si auto-configurerà all'avvio.

**Setup manuale legacy** (Se necessario per altre configurazioni):
```bash
SwitchMode1 15
SwitchMode2 15
```

## Pagina principale di Tasmota:

<img width="454" height="953" alt="image" src="https://github.com/user-attachments/assets/208f76f6-8786-4783-9840-27b1317ea8d5" />

## Home Assistant Device Page

<img width="329" height="341" alt="image" src="https://github.com/user-attachments/assets/46857bad-7f99-4467-a5c2-83b008481d05" /></br>
<img width="327" height="599" alt="image" src="https://github.com/user-attachments/assets/0052ff31-dd6d-48eb-8957-ba3ea96b1c23" />

##

## Funzionalità:

### Ritardo di spegnimento

Ritardo per spegnere la macchina da caffè dopo un periodo di inattività (nessuna preparazione del caffè). Il tempo di inattività è configurato nell'input 'Off delay time'.

### Preparazione del caffè

Attraverso l'input 'Shot coffee time', puoi configurare il tempo perfetto per la preparazione del tuo caffè.

### Ultima preparazione del caffè

Ogni caffè che prepari, il sistema memorizza l'ultimo tempo di preparazione del caffè. Attraverso l'apposito pulsante, puoi impostare l'ultimo tempo di preparazione del caffè nell'input 'Shot coffee time'.
Puoi utilizzare questa funzione per calibrare la tua macchina da caffè come vedremo più avanti.

### Avvio automatico della preparazione

Sei stanco di aspettare che la macchina da caffè sia pronta prima di preparare il caffè? Con la funzione di avvio automatico, puoi caricare le tue cialde di caffè preferite e la tua tazza di caffè mentre la macchina da caffè è spenta. Basta premere e tenere premuto il pulsante di preparazione per 2,5 secondi e la macchina da caffè si accenderà in modalità di avvio automatico! Una volta pronta la macchina da caffè, il processo di preparazione del caffè inizierà automaticamente!

### Multiple Profili di Caffè (Feature 1) ✨

Questa funzionalità abilita la gestione di due profili di caffè indipendenti con diverse durate di estrazione.

#### Selezione e Controllo del Profilo

- **Pulsante 1**: Seleziona il profilo Caffè1
- **Pulsante 2**: Seleziona il profilo Caffè2
- **Home Assistant**: Dropdown Coffee Selection per cambio profilo remoto

**Pressione breve** (< 2,5 secondi):
- Se la macchina è **SPENTA**: Accende solo l'elemento riscaldante (Power1) - pronto per l'estrazione manuale
- Se la macchina è **ACCESA**: Attiva/disattiva la pompa (Power2) - utile per erogazione manuale, spurgo linee o pulizia

**Pressione lunga** (≥ 2,5 secondi):
- Se la macchina è **SPENTA**: Attiva la modalità auto-start — una volta riscaldata, avvia automaticamente l'estrazione con il tempo del profilo selezionato
- Se la macchina è **ACCESA**: Attiva la **modalità di apprendimento automatico** — avvia l'estrazione senza timer (a tempo indefinito). Premi **lo stesso pulsante** per fermarla. Se l'estrazione è durata più di 5 secondi, la durata viene automaticamente salvata e applicata al tempo del profilo selezionato

**Pressione simultanea** (entrambi i pulsanti entro 500ms l'uno dall'altro):
- Spegne immediatamente la macchina (Power1 Off)
- Tutti i timer attivi vengono cancellati
- Funziona indipendentemente dallo stato corrente della macchina

#### Durate di Estrazione Indipendenti e Modalità di Apprendimento

Ogni profilo ha:
- Durata di estrazione indipendente (Coffee1Time, Coffee2Time)
- **Apprendimento manuale**: Premi "Set Last Coffee Time" per salvare l'ultima durata di estrazione misurata nel profilo selezionato
- **Apprendimento automatico**: Tieni premuto un pulsante mentre la macchina è ACCESA per avviare un'estrazione senza timer; fermala premendo **lo stesso pulsante**. Se l'estrazione è durata più di 5 secondi, la durata viene automaticamente salvata e applicata al profilo selezionato
- Nessuna contaminazione tra profili: Solo il tempo del profilo selezionato viene aggiornato

#### Parametri di Configurazione

- **Off Delay** (minuti): Spegnimento automatico dopo inattività
- **Coffee 1 Time** (secondi): Durata estrazione per Caffè1
- **Coffee 2 Time** (secondi): Durata estrazione per Caffè2
- **Last Coffee Time** (secondi): Durata misurata dall'ultima estrazione (sola lettura)

#### Entità MQTT

- `SelectedCoffee` (select): Scegli tra Caffè 1 e Caffè 2
- `Coffee1Time` (number): Durata estrazione Caffè1
- `Coffee2Time` (number): Durata estrazione Caffè2
- `OffDelay` (number): Ritardo spegnimento automatico
- `SetLastCoffeeTime` (button): Applica durata misurata al profilo selezionato
- `Mode` (sensor): Indicatore della funzione attiva — `Manual`, `Auto-start`, `Preload`, `Learning`

### Integrazione con Home Assistant

Ora i parametri personalizzati sono disponibili su Home Assistant, consentendoti di configurare direttamente la tua macchina del caffè tramite HA. Ho scelto di non utilizzare la libreria [haco](https://github.com/fmtr/haco) perché preferisco non installare plugin non necessari su Home Assistant quando una funzionalità è supportata nativamente. Invece, ho sviluppato una piccola libreria, HaMqttMgmt.be, per gestire la creazione e l'aggiornamento bidirezionale delle entità MQTT da Berry utilizzando il protocollo MQTT standard di discovery di Home Assistant.

## Calibrazione:

Hai bisogno di una bilancia di precisione.

1. Imposta un tempo di 'Shot coffee' troppo lungo, come 30 secondi.
2. Accendi la macchina da caffè e attendi che sia pronta.
3. Inserisci le tue cialde di caffè preferite.
4. Posiziona la bilancia di precisione sul supporto.
5. Posiziona la tua tazza di caffè sulla bilancia di precisione e azzerala.
6. Avvia la preparazione del caffè e spegnila quando raggiungi il peso desiderato.
7. Ora puoi impostare l'ultimo tempo di preparazione del caffè nell'input 'Shot coffee time' attraverso il pulsante 'Set'.

<details>
  <summary>Tabella dei pesi</summary>
  
| Tipo | Peso preparazione |
|---|---|
| Regola generale | peso caffè * 2 |
| Caffè corto | 20g |
| Caffè lungo | 22g |
</details>

<details>
  <summary>Immagini di calibrazione</summary>
  <img width="500" alt="immagine" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/b8a85765-e0f2-45bc-a4c2-2371dacff448"><br/>
  <img width="500" alt="immagine" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/4336f6fb-ceeb-4c4b-821e-e37d3322beef"><br/>
  <img width="500" alt="immagine" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/d34a4fab-184c-44b9-88c2-14c5b968332b"><br/>
</details>

## Testing Feature 1 (Multiple Coffee Profiles)

### Test Checklist

1. **Physical Button Behavior**
   - [ ] Short-press Button 1/2 while machine is OFF → Only Power1 (resistenza) turns on
   - [ ] Short-press Button 1/2 while machine is ON → Power2 (pump) toggles
   - [ ] Long-press Button 1/2 → Machine enters auto-start mode, triggers after heat-up
   - [ ] Simultaneous press Button 1+2 → Machine turns off immediately
   - [ ] Press duration correctly differentiates between short (< 2.5s) and long (≥ 2.5s)

2. **MQTT Coffee Selection**
   - [ ] Coffee Selection dropdown is available in Home Assistant
   - [ ] Selecting Coffee 1 updates SelectedCoffee to "1"
   - [ ] Selecting Coffee 2 updates SelectedCoffee to "2"
   - [ ] Current selection is reflected in the UI
   - [ ] Selection persists after a short brew cycle

3. **Dual Coffee Profiles**
   - [ ] Coffee1Time can be set independently (e.g., 15 seconds)
   - [ ] Coffee2Time can be set independently (e.g., 25 seconds)
   - [ ] Brew time used matches the currently selected profile
   - [ ] Timer duration changes when switching profiles before brewing

4. **Learning Mode**
   - [ ] Brew Coffee1, press "Set Last Coffee Time" → Only Coffee1Time updates
   - [ ] Brew Coffee2, press "Set Last Coffee Time" → Only Coffee2Time updates
   - [ ] Other profile's time remains unchanged
   - [ ] Learning mode respects the currently selected profile

5. **Off Delay Timer**
   - [ ] Set Off Delay to 2 minutes via MQTT
   - [ ] Turn on machine, don't brew
   - [ ] After 2 minutes of inactivity, machine auto-shuts down
   - [ ] Off Delay resets when brewing occurs

### Troubleshooting

- **Button presses not detected**: Check GPIO connections on pins 32 and 33. Verify inverted logic (0=pressed, 1=released) in hardware.
- **MQTT entities not showing in HA**: Ensure Tasmota device has valid MQTT broker connection. Check Home Assistant's MQTT integration logs.
- **Wrong brewing time applied**: Verify current selection in `persist.SelectedCoffee` matches expected profile in MQTT logs.
- **Learning mode updates both profiles**: Check that only the selected profile's time is being written in logs.

---

## Test di Feature 1 (Multiple Profili di Caffè)

### Checklist di Test

1. **Comportamento dei Pulsanti Fisici**
   - [ ] Pressione breve Pulsante 1/2 mentre la macchina è SPENTA → Solo Power1 (resistenza) si accende
   - [ ] Pressione breve Pulsante 1/2 mentre la macchina è ACCESA → Power2 (pompa) attiva/disattiva
   - [ ] Pressione lunga Pulsante 1/2 → Macchina entra in modalità auto-start, attiva dopo riscaldamento
   - [ ] Pressione simultanea Pulsante 1+2 → Macchina si spegne immediatamente
   - [ ] La durata della pressione differenzia correttamente tra breve (< 2,5s) e lunga (≥ 2,5s)

2. **Selezione Caffè da MQTT**
   - [ ] Dropdown Coffee Selection è disponibile in Home Assistant
   - [ ] Selezionare Caffè 1 aggiorna SelectedCoffee a "1"
   - [ ] Selezionare Caffè 2 aggiorna SelectedCoffee a "2"
   - [ ] La selezione corrente è riflessa nell'interfaccia
   - [ ] La selezione persiste dopo un breve ciclo di estrazione

3. **Due Profili di Caffè**
   - [ ] Coffee1Time può essere impostato indipendentemente (ad es. 15 secondi)
   - [ ] Coffee2Time può essere impostato indipendentemente (ad es. 25 secondi)
   - [ ] Il tempo di estrazione utilizzato corrisponde al profilo attualmente selezionato
   - [ ] La durata del timer cambia quando si commutano i profili prima dell'estrazione

4. **Modalità di Apprendimento**
   - [ ] Estrai Caffè1, premi "Set Last Coffee Time" → Solo Coffee1Time viene aggiornato
   - [ ] Estrai Caffè2, premi "Set Last Coffee Time" → Solo Coffee2Time viene aggiornato
   - [ ] Il tempo dell'altro profilo rimane invariato
   - [ ] La modalità di apprendimento rispetta il profilo attualmente selezionato

5. **Timer Off Delay**
   - [ ] Imposta Off Delay a 2 minuti tramite MQTT
   - [ ] Accendi la macchina, non estrarre
   - [ ] Dopo 2 minuti di inattività, la macchina si spegne automaticamente
   - [ ] Off Delay si resetta quando si estrae

### Diagnosi dei Problemi

- **Le pressioni dei pulsanti non vengono rilevate**: Controlla i collegamenti GPIO sui pin 32 e 33. Verifica la logica invertita (0=premuto, 1=rilasciato) nell'hardware.
- **Le entità MQTT non appaiono in HA**: Assicurati che il dispositivo Tasmota abbia una connessione MQTT broker valida. Controlla i log di integrazione MQTT di Home Assistant.
- **Viene applicato il tempo di estrazione sbagliato**: Verifica che la selezione corrente in `persist.SelectedCoffee` corrisponda al profilo previsto nei log MQTT.
- **La modalità di apprendimento aggiorna entrambi i profili**: Controlla che nei log venga scritto solo il tempo del profilo selezionato.
