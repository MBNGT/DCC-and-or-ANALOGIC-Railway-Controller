#DCC and/or ANALOGIC Railway Controller

Presentation

This work is based upon the Gregg E. Berman'works and Steve Massikker’works.
Thank you for yours works and sharing.

We all have old locomotives in our drawers.
Unfortunately, it is often difficult, if not impossible, to convert them with the new electronics and DCC drivers.
The objectives of this project were therefore to control these old analog locomotives (without DCC) and thus to complete the developments of Greeg E. Berman with new functionalities.
The first part of these developments was realized between 2021 AND 2022 by EMA (mbmngt@gmail.com).

They include:
1. - The design of a new circuit compatible with my railway installation:
1.1. - This installation is composed of 3 main circuits and 2 secondary circuits.
1.2. -  Some blocks “cantons” structure these circuits. Each main circuit is divided into 4 blocks. Each secondary circuit is divided into several blocks.
2. - Additional software functions:
2.1. - On Processing
2.1.1. - A visualization on the PC screen of the movements of the locomotives on the circuits.
2.1.2. - The control of old analog locomotives (without DCC equipment).
2.1.3. - Automatic locomotive control via current sensors
2.1.4. - Adding viewing windows for switches, traffic lights and accessories
2.2. - On Mega
2.2.1. - I2C communication with 5 Nano
2.3. - About Nano
2.3.1. - Direct control of locomotives.
3. - Complementary electronics
3.1. - Commands are supported by one Arduino Mega and 5 Arduino Nano
3.2. - The circuits are controlled by the Nano completed with L298 and ACS712
4. - The communications used are:
4.1. - Serial communication between Processing and Mega
4.2. - I2C communication between Mega and Nano

The next planned developments are:
1. - The complement of electronics to control the hands, railway traffic lights and accessories
2. - Software add-ons:
2.1. - Ordering needles from Processing and with Mega
2.2. -Rail traffic light control from Processing and with Mega
3. - Ordering accessories from Processing and with Mega and one of the Nanos
4. - The modification of the Autopilot function on Processing to adapt it to my railway installation.

Structure of the electronics
View File Railway Controller Elect Synoptic

Use
These developments can be adapted to all railway networks.
The structure of these networks must be defined in the “controllerConfig” sheet under Processing.
The controls of the electronics with the Mega and the Nano can be adapted to your peripherals.

Note
• In this project the Processing and Mega applications have been modified and supplemented.
• In the application under Processing, keyboard commands have been modified (see Help window) and in the "Main", the command "read operation track current function" has been deactivated.
• However, the initial functionalities using the DCCs have been retained.

It is therefore possible to control locomotives and other devices (switches, traffic lights, etc.) with the NMRA standard and the DCCs, but also in analogue, etc.

If these developments are useful to you, you can contact me here or on my email mbmngt@gmail.com.
