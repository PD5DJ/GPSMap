# Frsky Horus GPS Map

Note:
Based on Tonnie78 (Tonnie Oostbeek) his Lua GPS Widget project https://github.com/Tonnie78/Lua-GPS-Widget





-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Creates a Horus Widget to show Plane location on a map that is placed on the screen as an image


![alt text](https://github.com/Hobby4life/GPSMap/blob/main/GPSMap.png)

https://youtu.be/QPWba8dwc1w

What's on the screen?

**Home Point** - A Windsock is visible when HomePoint is set, first time GPS lock will set HomePoint. HomePoint will also be set if a Reset is triggered. A the base of HomePoint there is also a True Bearing visible from HomePoint to Plane.

When the plane is outside visibility of the 3 Map zoom range, "OUT OF RANGE" message will apear.


**Speed/Max** - Is calculated from the **GSpd** sensor, select **km/h** or **mph** at the sensor page. And set **Imperial** in the widget settings screen accordingly

**Alt/Max** - Is calculated from the **Alt** sensor, select **m** or **ft** at the sensor page. And set **Imperial** in the widget settings screen accordingly

**Dist/Max** - Is calculated from GPS sensor itself it is realtime calculated when moving, select **m** or **ft** at the sensor page. And set **Imperial** in the widget settings screen accordingly

**LoS** - calculated from **Dist** and **Alt**

**Satellites** - Only visible if OpenXSensor is used with sensor **Tmp1** as satellites in view output

**Heading** - Is calculated from GPS sensor itself it is realtime calculated when moving

**Lat/Long** - Actual GPS coordinates in Decimal

**Version Number** - Firmware version


**-------------------- Description of usage: --------------------**

**1.** Create a fullscreen widget page, disable "Top Bar" and "Sliders"**

**2.** Load the GPSMap widget**

**3.** Setting up widget settings**

![alt text](https://github.com/Hobby4life/GPSMap/blob/main/widgetsettings.png)

 **ResetAll** - Define a source for trigger a reset of al max values and set new HomePoint
 
 **Imperial** - Toggle between Metric or Imperial notation, note that correct settings have to be set on the sensor page too!

 **LosLine** - Enable / Disable line of sight line between Home point and plane. 0 = off, 1 = on

 **MapSelect** - Select Map to load, needs model change or power cycle to take effect, 0 correnspondents to **map0xsmall.png**, **map0small.png**, **map0medium.png**, **map0large.png** and **map0xlarge.png** etc...

In the **main.lua** file

Look for the following lines:

```
Version     = "vx.x"  -- Current version
  
TotalMaps   = 4       -- Enter the amount of maps loaded, starts with 0 !!!!
```
At TotalMaps you see number 4, adjust it according maps that are located in the widget folder.

and in main.lua look for the following lines..

Copy and paste the generated coordinates here. add a if statement when adding new.

```
-- coordinates for the extra small map.

map.North.xsmall = 52.623582

map.South.xsmall = 52.622696

map.West.xsmall = 4.951764

map.East.xsmall = 4.954338

-- No Fly Zone screen coordinates for extra small map--

map.poly.xsmall = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}



-- coordinates for the small map.

map.North.small = 52.624025

map.South.small = 52.622253

map.West.small = 4.950476

map.East.small = 4.955626

-- No Fly Zone screen coordinates for small map--

map.poly.small = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}



-- coordinates for the medium map.

map.North.medium = 52.624911

map.South.medium = 52.621367

map.West.medium = 4.947901

map.East.medium = 4.958201

-- No Fly Zone screen coordinates for medium map--

map.poly.medium = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}



-- coordinates for the large map.

map.North.large = 52.626682

map.South.large = 52.619596

map.West.large = 4.942751

map.East.large = 4.963351

-- No Fly Zone screen coordinates for large map--

map.poly.large = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}



-- coordinates for the extra large map.

map.North.xlarge = 52.630225

map.South.xlarge = 52.616053

map.West.xlarge = 4.932452

map.East.xlarge = 4.97365

-- No Fly Zone screen coordinates for extra large map--

map.poly.xlarge = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}

```


For each new map, add a new "  elseif LoadMap == X then "


**------------GV9-----------**


**GV9** in OpentX acts as a Noflyzone indicator.

Toggles between 0 or 1 depends on the plane crossing wich side of the NoflyZone line.

You can use **GV9** to enable alarms etc.



