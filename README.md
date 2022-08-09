# qremote norns mod

This repo contains a mod for the monome norns that will allow you to control the 
norns using midi cc commands. 

Using this mod will let you use a controller like the Midi Fighter Twister or
the OMX-27 to remotely control your norns. This is useful if your norns is placed
far away and it's difficult to access the buttons and encoders. 

For button CC's you should send a 127 for button on and 0 for button off. 
For encoder CC's you should send a 65 for CW and a 63 for CCW

The default midi channel is 10

The default cc's for the encoders are 58, 62, & 63

The default cc's for the buttons are 85, 87, & 88

You can change these in the parameter menu. Or edit the script to change the defaults. 