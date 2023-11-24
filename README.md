# Tasmota-coffee-machine-berry

[project intro]

Hardware requirement:
* Coffee machine Grimac Tube (manual: 1 switch to power on, 1 switch to coffee brewing. You can use every manual 2 switch coffee machine)
* Sonoff Dual R3 v2 Tasmotized

Tasmota Main Page:

![image](https://github.com/robertoamd90/Tasmota-coffee-machine-berry/assets/61760575/7f5eb327-3ae9-4894-8e8e-951ee539bc4c)


Features:

**Off delay**
Delay to power off the coffee machine, after inactivity period (no coffee brewing). The time of inactivity is configurad in the 'Off delay time' input.

**Coffee brewing**
Through the 'Shot coffee time' input you can setup your perfect Coffee brewing time.

**Last Coffee brewing**
Every coffee you made, the system store lasto coffee brewing time. Through the appropiate button, you can set the last Coffee brewing time into Shot coffee time.
You can use thiss function to calibrate your coffee machine as we will see later.

Calibration:

You need a precision scale.

1. Setup a too long 'Shot coffee time', like 30 seconds
2. Turn on your coffee machine, and wait until they become ready
3. Load your preferred coffee pods inside
4. Place the precision scale on the rack
5. Place your coffee cup on the precision scale and tare it
6. Start the Coffee brewing and turn off when the currect weight is rached
7. now you can set the last Coffee brewing time into the Shot coffee time thorougt the Set button.
