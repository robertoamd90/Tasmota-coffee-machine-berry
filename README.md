# Tasmota-coffee-machine-berry

Welcome to the Coffee Machine Home Automation Project! This project is designed to turn your regular coffee machine into a smart, controllable device, allowing you to brew your favorite coffee with just a click.

The primary aim of this project is to provide an automated interface for your coffee machine, enabling remote power on/off functionality and coffee brewing via a mobile application.

The original project is based on esp8266 and Tasmota [Scripting Language](https://tasmota.github.io/docs/Scripting-Language/): [Tasmota-coffee-machine](https://github.com/robertoamd90/Tasmota-coffee-machine).

This project use ESP32 and Tasmota [Berry](https://tasmota.github.io/docs/Berry/)

<h2>Hardware requirement:</h2>

* Coffee machine Grimac Tube (manual: 1 switch to power on, 1 switch to coffee brewing. You can use every manual 2 switch coffee machine)
* (Sonoff Dual R3 v2)[https://templates.blakadder.com/sonoff_DUALR3_v2.html] Tasmotized

You need to replace the standard bistable switch of your coffee machine with the outputs of your Dual R. The output 1 for the Coffee machine power (coffee machine resistance) and the power 2 for the  coffee brewing (the pump).
In the standard setup, the pump can be enabled only if the coffee machine in on, with the Dual R we can enable the 2 power independently, but we will replicate the original behavior via software.

I have repalaced the switch with 2 button for the input 1 and 2 of the Dual R.

In my case the Power on led was inside the power witch, adter i repalced this one with a button, i have added a 220v green led.

<h2>Tasmota Main Page:</h2>

![image](https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/7f5eb327-3ae9-4894-8e8e-951ee539bc4c)

<h2>Features:</h2>

<h3>Off delay</h3>
Delay to power off the coffee machine, after inactivity period (no coffee brewing). The time of inactivity is configurad in the 'Off delay time' input.

<h3>Coffee brewing</h3>
Through the 'Shot coffee time' input you can setup your perfect Coffee brewing time.

<h3>Last Coffee brewing</h3>
Every coffee you made, the system store lasto coffee brewing time. Through the appropiate button, you can set the last Coffee brewing time into Shot coffee time.
You can use thiss function to calibrate your coffee machine as we will see later.

<h3>Auto start brewing</h3>
Are you tired of waiting for the coffee machine to be ready before brewing your coffee? With the auto-start function, you can load your preferred coffee pods and your coffee cup while the coffee machine is off. Simply press and hold the brewing button for 2.5 seconds, and the coffee machine will turn on in auto-start mode! Once the coffee machine is ready, the brewing process will start automatically!

<h3>Multiple presets management</h3>
coming soon

<h2>Calibration:</h2>

You need a precision scale.

1. Setup a too long 'Shot coffee time', like 30 seconds
2. Turn on your coffee machine, and wait until they become ready
3. Load your preferred coffee pods inside
4. Place the precision scale on the rack
5. Place your coffee cup on the precision scale and tare it
6. Start the Coffee brewing and turn off when the currect weight is rached
7. now you can set the last Coffee brewing time into the Shot coffee time thorougt the Set button.

<details>
  <summary>Weight table</summary>
  
| Type | weight brewing |
|---|---|
| General Rule | coffee weight * 2 |
| Short Coffee | 20g |
| General Rule | 22g |
</details>

<details>
  <summary>Calibration Images</summary>
  <img width="527" alt="image" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/b8a85765-e0f2-45bc-a4c2-2371dacff448">
  <img width="509" alt="image" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/4336f6fb-ceeb-4c4b-821e-e37d3322beef">
  <img width="508" alt="image" src="https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/d34a4fab-184c-44b9-88c2-14c5b968332b">
</details>



