# Tasmota-coffee-machine-berry

Welcome to the Coffee Machine Home Automation Project! This project is designed to turn your regular coffee machine into a smart, controllable device, allowing you to brew your favorite coffee with just a click.

The primary aim of this project is to provide an automated interface for your coffee machine, enabling remote power on/off functionality and coffee brewing via a mobile application.

The original project is based on [esp8266](https://tasmota.github.io/docs/Scripting-Language/) and [Tasmota-coffee-machine](https://github.com/robertoamd90/Tasmota-coffee-machine).

This project uses ESP32 and [Tasmota Berry](https://tasmota.github.io/docs/Berry/).

## Hardware requirement:

- Coffee machine Grimac Tube (manual: 1 switch to power on, 1 switch to coffee brewing. You can use any manual 2 switch coffee machine)
- [Sonoff Dual R3 v2](https://templates.blakadder.com/sonoff_DUALR3_v2.html) with Tasmota firmware

You need to replace the standard bistable switch of your coffee machine with the outputs of your Dual R. Output 1 for the Coffee machine power (coffee machine resistance) and the power 2 for the coffee brewing (the pump).
In the standard setup, the pump can be enabled only if the coffee machine is on, with the Dual R we can enable the 2 power independently, but we will replicate the original behavior via software.

I have replaced the switch with 2 buttons for the input 1 and 2 of the Dual R.

In my case, the Power on LED was inside the power switch. After I replaced this one with a button, I added a 220v green LED.

## Preliminary Configuration

Before proceeding, ensure that you've accessed the Tasmota console for your Sonoff Dual R3 v2 device. Input the following commands in the Tasmota console to enable the necessary switch modes:

```bash
SwitchMode1 3
SwitchMode2 15
```

## Tasmota Main Page:

![image](https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/7f5eb327-3ae9-4894-8e8e-951ee539bc4c)

## Features:

### Off delay
Delay to power off the coffee machine after an inactivity period (no coffee brewing). The time of inactivity is configurable in the 'Off delay time' input.

### Coffee brewing
Using the 'Shot coffee time' input, you can set up your perfect coffee brewing time.

### Last Coffee brewing
The system stores the last coffee brewing time. Using the appropriate button, you can set the last coffee brewing time as the 'Shot coffee time'. You can use this function to calibrate your coffee machine as we will see later.

### Auto start brewing
Are you tired of waiting for the coffee machine to be ready before brewing your coffee? With the auto-start function, you can load your preferred coffee pods and your coffee cup while the coffee machine is off. Simply press and hold the brewing button for 2.5 seconds, and the coffee machine will turn on in auto-start mode! Once the coffee machine is ready, the brewing process will start automatically!

### Multiple presets management
Coming soon

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
| General Rule | 22g |
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

Prima di procedere, assicurati di aver accesso alla console di Tasmota per il tuo dispositivo Sonoff Dual R3 v2. Inserisci i seguenti comandi nella console di Tasmota per abilitare le modalità di interruttore necessarie:

```bash
SwitchMode1 3
SwitchMode2 15
```

## Pagina principale di Tasmota:

![immagine](https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/7f5eb327-3ae9-4894-8e8e-951ee539bc4c)

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

### Gestione di più impostazioni predefinite

Prossimamente disponibile

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
| Regola generale | 22g |
</details>

<details>
  <summary>Immagini di calibrazione</summary>
  <img width="500" alt="immagine" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/b8a85765-e0f2-45bc-a4c2-2371dacff448"><br/>
  <img width="500" alt="immagine" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/4336f6fb-ceeb-4c4b-821e-e37d3322beef"><br/>
  <img width="500" alt="immagine" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/d34a4fab-184c-44b9-88c2-14c5b968332b"><br/>
</details>
