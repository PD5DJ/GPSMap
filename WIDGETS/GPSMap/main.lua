---- ##########################################################################################################
---- #                                                                                                        #
---- # GPS Widget for FrSky Horus 			                                                                      #
-----#                                                                                                        #
---- # License GPLv3: http://www.gnu.org/licenses/gpl-3.0.html                                                #
---- #                                                                                                        #
---- # This program is free software; you can redistribute it and/or modify                                   #
---- # it under the terms of the GNU General Public License version 3 as                                      #
---- # published by the Free Software Foundation.                                                             #
---- #                                                                                                        #
---- # Original idea and credits goes to Tonnie Oostbeek (Tonnie78)       	                                  #
---- #                                                                                                        #
---- # Revised by Björn Pasteuning / Hobby4life 2019                                                          #
---- #            Phaedra Degreef - polygon shaped no-fly zone detection added                                #
---- #                                                                                                        #
---- # Changelog:                                                                                             #
---- #                                                                                                        #
---- # v1.6 - Added RSSI detect for noFlyzone alarm function                                                  #
---- # v1.7 - Added posibility to select maps with GV8                                                        #
---- # v1.8 - Added posibolity to select Heading/Bearing input with GV7                                       #
---- #        0 = Calculate, 1 = Use Sensor input                                                             #
---- # v1.9 - Added Reset function from a Source to reset all max values                                      #
---- # v1.9a- Small fix in reset function                                                                     #
---- # v2.0 - Added Satellite indicator                                                                       #
---- # v2.1 - 1) HomePoint indicator / will show after a sat fix...                                           #
---- #        2) Line of sight line added, can be turned on and off in widget settings                        #
---- #        3) NoFlyZone line color is fixed to RED                                                         #
---- #        4) PlaneColor is fixed to YELLOW                                                                #
---- #        5) Map now selectable from Widget Settings page                                                 #
---- # v2.3 - Cleaned up code, fixed NIL issue in LCD draw routines                                           #
---- # v2.4 - Added LoS distance in middle of LoSLine, and added bearing indicator from home to plane         #
---- # v2.5 - Distance is now calculated from 2 coordinates                                                   #
---- # v2.6 - Heading is now only calculated from 2 upfollowing coordinates                                   #
---- # v2.7 - Automatic detection of Altitude sensor, Vario Altimeter or GPS Altimeter                        #
---- #        Vario Altimeter has priority over GPS Altimeter                                                 #
---- # v2.8 - 1) If Plane is outside view of maps, "OUT OF RANGE" Message will appear                         #
---- #        2) If HomePoint is outside zoom level, HomePoint is not visible (fix)                           #
---- # v2.9   Changed Layout and masked bottom area due new map download function                             #
---- #        Maps can now be generated and downloaded from: https://www.hobby4life.nl/mapgen.htm             #
---- # v3.0   Now creating maps is much easier, 5 maps are now used                                           #
---- #        File structure changed!, remove GPSmap widget, and reinstall widget..                           #
---- #        Sometimes it looks like no map is loaded.                                                       #
---- #        Go to widget settings -> MapSelect and toggle between 0 and another map and back to 0           #
---- #        then close widget and restart radio to take effect.                                             #
---- # v3.1   Added a no-fly zone polygon                                                                     #
---- #        Added polygon definition array to map definitions                                               #
---- #        Added checking of model position inside polygon, and callout in all flight modes used           #
---- # v3.2   Changed the plane symbol into a more visible triangular shape                                   #
---- #        Added Satellite count fix for openxsensor sensors                                               #
---- # v3.2a  Changed the Triangular shape into Arrow                                                         #
---- #                                                                                                        #
---- #                                                                                                        #
---- #                                                                                                        #
---- ##########################################################################################################

local Version     = "v3.2a"  -- Current version
  
TotalMaps   =  2       -- Enter the amount of maps loaded, starts with 0 !!!! (Toggle between 0 and 1 are 2 maps)


local options = {
  { "ResetAll"  , SOURCE  , 1     },  --Define a source for trigger a reset of al max values
  { "Imperial"  , VALUE   , 0,0,1 },  --Toggle between Metric or Imperial notation, note that correct settings have to be set on the sensor page too!
  { "LosLine"   , VALUE   , 0,0,1 },  --Enable / Disable line of sight line between Home point and plane. 0 = off, 1 = on
  { "MapSelect" , VALUE   , 0,0,TotalMaps },  --Selects Map to load, needs model change or power cycle to take effect, 0 correnspondents to map0small.png, map0medium.png and map0large.png etc...
  { "ArrowClr"  , COLOR   , COLOR  , GREEN },
}


-- in the create function you add all shared variables to the array containing the widget data ('thisWidget')
local function create(zone, options)
  
  local thisWidget  = {zone=zone, options=options}
  local LoadMap     = thisWidget.options.MapSelect or 0

-- Declaration and preset of Global Widget Variables used in the entire scope --
  HomeLat     = 0 
  HomeLong    = 0
  HomeSet     = 1
  DrawSock    = 0
  MaxDistance = 0
  MaxSpeed    = 0
  MaxAltitude = 0
  LoSDistance = 0
  MaxLoS      = 0
  TempLat     = 0 
  TempLong    = 0
  HomePosx    = 0
  HomePosy    = 0
  HomeVisible = 1
  
  PlaneVisible= 0
  
  --create array containing all sensor ID's used for quicker retrieval
  local ID = {}
  ID.GPS        = getFieldInfo("GPS")  and getFieldInfo("GPS").id	 or 0
  ID.GSpd       = getFieldInfo("GSpd") and getFieldInfo("GSpd").id or 0
  ID.Altimeter  = (getFieldInfo("Alt") and getFieldInfo("Alt").id) or (getFieldInfo("GAlt") and getFieldInfo("GAlt").id) or 0  -- Vario Altimeter has priority over GPS Altimeter
  ID.RSSI       = getFieldInfo("RSSI") and getFieldInfo("RSSI").id or 0
  ID.Tmp1       = getFieldInfo("Tmp1") and getFieldInfo("Tmp1").id or 0 -- used with OpenXsenor or sallites in view indicator
  ID.Hdg        = getFieldInfo("Hdg")  and getFieldInfo("Hdg").id  or 0
  
  --add ID to thisWidget
  thisWidget.ID = ID	

  --create array containing all map info per map size
  local map = {North={},South={},West={},East={}, poly={}}
--  local map = {North={},South={},West={},East={},wx={},wy={},zx={},zy={}}
--LoadMap = 1

if LoadMap == 0 then
  
-- PEGASUS

-- coordinates for the extra small map.
map.North.xsmall = 52.732983
map.South.xsmall = 52.732099
map.West.xsmall = 5.274066
map.East.xsmall = 5.27664
-- No Fly Zone screen coordinates for extra small map--
map.poly.xsmall = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}


-- coordinates for the small map.
map.North.small = 52.733425
map.South.small = 52.731657
map.West.small = 5.272778
map.East.small = 5.277928
-- No Fly Zone screen coordinates for small map--
map.poly.small = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}


-- coordinates for the medium map.
map.North.medium = 52.734308
map.South.medium = 52.730774
map.West.medium = 5.270203
map.East.medium = 5.280503
-- No Fly Zone screen coordinates for medium map--
map.poly.medium = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}


-- coordinates for the large map.
map.North.large = 52.736075
map.South.large = 52.729007
map.West.large = 5.265053
map.East.large = 5.285653
-- No Fly Zone screen coordinates for large map--
map.poly.large = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}


-- coordinates for the extra large map.
map.North.xlarge = 52.739609
map.South.xlarge = 52.725473
map.West.xlarge = 5.254754
map.East.xlarge = 5.295952
-- No Fly Zone screen coordinates for extra large map--
map.poly.xlarge = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}


elseif LoadMap == 1 then


--AVENHORN
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

elseif LoadMap == 2 then

-- PEGASUS ZOOM

-- coordinates for the extra small map.
map.North.xsmall = 52.732762
map.South.xsmall = 52.73232
map.West.xsmall = 5.274709
map.East.xsmall = 5.275997
-- No Fly Zone screen coordinates for extra small map--
map.poly.xsmall = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}


-- coordinates for the small map.
map.North.small = 52.732983
map.South.small = 52.732099
map.West.small = 5.274066
map.East.small = 5.27664
-- No Fly Zone screen coordinates for small map--
map.poly.small = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}


-- coordinates for the medium map.
map.North.medium = 52.733425
map.South.medium = 52.731657
map.West.medium = 5.272778
map.East.medium = 5.277928
-- No Fly Zone screen coordinates for medium map--
map.poly.medium = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}


-- coordinates for the large map.
map.North.large = 52.734308
map.South.large = 52.730774
map.West.large = 5.270203
map.East.large = 5.280503
-- No Fly Zone screen coordinates for large map--
map.poly.large = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}


-- coordinates for the extra large map.
map.North.xlarge = 52.736075
map.South.xlarge = 52.729007
map.West.xlarge = 5.265053
map.East.xlarge = 5.285653
-- No Fly Zone screen coordinates for extra large map--
map.poly.xlarge = {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}

end

    --add one bitmap per map size and set current map size
  map.bmp={}
  map.bmp.xsmall  = Bitmap.open("/widgets/GPSMap/maps/map"..LoadMap.."xsmall.png")
  map.bmp.small   = Bitmap.open("/widgets/GPSMap/maps/map"..LoadMap.."small.png")
  map.bmp.medium  = Bitmap.open("/widgets/GPSMap/maps/map"..LoadMap.."medium.png")
  map.bmp.large   = Bitmap.open("/widgets/GPSMap/maps/map"..LoadMap.."large.png")
  map.bmp.xlarge  = Bitmap.open("/widgets/GPSMap/maps/map"..LoadMap.."xlarge.png")

  WindSock = Bitmap.open("/widgets/GPSMap/icons/windsock.png")
  --HomeIcon = Bitmap.open("/widgets/GPSMap/home.png")
  
  --set current size
  map.current = "large"

  --add the map array to thisWidget
  thisWidget.map = map	
  
  --return the thisWidget array to the opentx API, containing all data to be shared across functions
  return thisWidget
  
end


--***********************************************************************
--*                           NO-FLY DETECTION FUNCTION                          *
--***********************************************************************
local function insidePolygon(polygon, planex, planey)
--  local polygon = thisWidget.map.poly[thisWidget.map.current]
    local oddNodes = false
    local j = #polygon 
    for i = 1, #polygon do
        if (polygon[i][2] < planey and polygon[j][2] >= planey or polygon[j][2] < planey and polygon[i][2] >= planey) then
            if (polygon[i][1] + ( planey - polygon[i][2] ) / (polygon[j][2] - polygon[i][2]) * (polygon[j][1] - polygon[i][1]) < planex) then
                oddNodes = not oddNodes;
            end
        end
        j = i;
    end
	
   return oddNodes 
end


--***********************************************************************
--*                        BACKGROUND FUNCTION                          *
--***********************************************************************
local function background(thisWidget)
  
  ImperialSet = thisWidget.options.Imperial or 0
  --ExtHeadingSensor = thisWidget.options.ExtHdg or 0
  LosLineSet = thisWidget.options.LosLine or 0

  
  thisWidget.gpsLatLong = getValue(thisWidget.ID.GPS)
  if  (type(thisWidget.gpsLatLong) ~= "table") then
    thisWidget.ID.GPS       = getFieldInfo("GPS")  and getFieldInfo("GPS").id	 or 0
    thisWidget.ID.GSpd      = getFieldInfo("GSpd") and getFieldInfo("GSpd").id or 0
    thisWidget.ID.Altimeter = (getFieldInfo("Alt") and getFieldInfo("Alt").id) or (getFieldInfo("GAlt") and getFieldInfo("GAlt").id) or 0
    thisWidget.ID.RSSI      = getFieldInfo("RSSI") and getFieldInfo("RSSI").id or 0
    thisWidget.ID.Tmp1      = getFieldInfo("Tmp1") and getFieldInfo("Tmp1").id or 0
    thisWidget.ID.Hdg       = getFieldInfo("Hdg")  and getFieldInfo("Hdg").id  or 0
    model.setGlobalVariable(8,0,0)
    return
  end
  
  thisWidget.Speed      = getValue(thisWidget.ID.GSpd)
  thisWidget.Altitude   = getValue(thisWidget.ID.Altimeter)
  thisWidget.Rssi       = getValue(thisWidget.ID.RSSI)
  thisWidget.Sats       = getValue(thisWidget.ID.Tmp1)
  thisWidget.Hdg        = getValue(thisWidget.ID.Hdg)

  
  thisWidget.gpsLat     = thisWidget.gpsLatLong.lat
  thisWidget.gpsLong    = thisWidget.gpsLatLong.lon
  
  -- Part for loading the correct zoomlevel of the map

-- coordinates for the smallest map. These can be found by placing the image back into Google Earth and looking at the overlay
-- parameters

  local North = thisWidget.map.North
  local South = thisWidget.map.South
  local East  = thisWidget.map.East
  local West  = thisWidget.map.West
    
  ------ Checks if Plane is visible in any map, otherwise disable plane view ------
  if thisWidget.gpsLat < North.xsmall and thisWidget.gpsLat > South.xsmall and thisWidget.gpsLong < East.xsmall and thisWidget.gpsLong > West.xsmall then
    thisWidget.map.current = "xsmall"
    PlaneVisible = 1
  elseif thisWidget.gpsLat < North.small and thisWidget.gpsLat > South.small and thisWidget.gpsLong < East.small and thisWidget.gpsLong > West.small then
    thisWidget.map.current = "small"
    PlaneVisible = 1
  elseif thisWidget.gpsLat < North.medium and thisWidget.gpsLat > South.medium and thisWidget.gpsLong < East.medium and thisWidget.gpsLong > West.medium then    
    thisWidget.map.current = "medium"
    PlaneVisible = 1
  elseif thisWidget.gpsLat < North.large and thisWidget.gpsLat > South.large and thisWidget.gpsLong < East.large and thisWidget.gpsLong > West.large then    
    thisWidget.map.current = "large"
    PlaneVisible = 1
  elseif thisWidget.gpsLat < North.xlarge and thisWidget.gpsLat > South.xlarge and thisWidget.gpsLong < East.xlarge and thisWidget.gpsLong > West.xlarge then    
    thisWidget.map.current = "xlarge"
    PlaneVisible = 1    
  else
    thisWidget.map.current = "large"
    PlaneVisible = 0  
  end

-- Part for setting the correct zoomlevel ends here.
  North = North[thisWidget.map.current]
  South = South[thisWidget.map.current]
  East  = East[thisWidget.map.current]
  West  = West[thisWidget.map.current]

  thisWidget.x  = math.floor(480*((thisWidget.gpsLong - West)/(East - West)))
  thisWidget.y  = math.floor(272*((North - thisWidget.gpsLat)/(North - South)))
  thisWidget.x  = math.max(10,thisWidget.x)
  thisWidget.x  = math.min(thisWidget.x,470)
  thisWidget.y  = math.max(10,thisWidget.y)
  thisWidget.y  = math.min(thisWidget.y,262)

-- Calculate  home position in relation to map.  
 
  if thisWidget.gpsLat ~= 0 and thisWidget.gpsLong ~= 0 then
    if HomeSet == 1 then
        HomeLat = thisWidget.gpsLat
        HomeLong = thisWidget.gpsLong
        HomeSet = 0
        DrawSock = 1
    end
      HomePosx = math.floor(480*((HomeLong - West)/(East - West)))
      HomePosy = math.floor(272*((North - HomeLat)/(North - South)))
      HomePosx = math.max(10,HomePosx)
      HomePosx = math.min(HomePosx,470)
      HomePosy = math.max(10,HomePosy)
      HomePosy = math.min(HomePosy,262)   
  end    

------ Checks if Homepoint is visible on the map otherwise disable view -------
  if HomeLat < North and HomeLat > South and HomeLong < East and HomeLong > West then
    HomeVisible = 1
  else
    HomeVisible = 0  
  end

-------------------- Checks if plane crossed the nofly zone line and toggles GV9 Variable -------------- 

-- ********************************************
-- no-fly polygon update
-- if a valid GPS position is received, and RSSI is valid, and position is inside polygon, set GVAR 9 to 1
-- This is to avoid the alarm when receiver or GPS sensor is not ready
-- *******************************************************************************************************
local testpolygon = thisWidget.map.poly[thisWidget.map.current]
  if (PlaneVisible == 1) then
    if ((insidePolygon(testpolygon,thisWidget.x,thisWidget.y) == false) and (thisWidget.Rssi > 0) and
        (type(thisWidget.gpsLatLong) == "table") ) then
      	-- set this GVAR in every flight mode that is used (in this case 3 flight modes are used)
      model.setGlobalVariable(8,0,1)
      model.setGlobalVariable(8,1,1)
      model.setGlobalVariable(8,2,1)
    else
      model.setGlobalVariable(8,0,0)
      model.setGlobalVariable(8,1,0)
      model.setGlobalVariable(8,2,0)
    end
  end

-- ********************************************
-- END OF no-fly polygon update
-- ********************************************

end
---------------------------------------------------------------------------------------------------------

--***********************************************************************
--*                          SPECIAL FUNCTIONS                          *
--***********************************************************************

----------------------- Function to calculated bearing angle between 2 coordinates ----------------------
function CalcBearing(PrevLat,PrevLong,NewLat,NewLong)
  local yCalc = math.sin(math.rad(NewLong)-math.rad(PrevLong)) * math.cos(math.rad(NewLat))
  local xCalc = math.cos(math.rad(PrevLat)) * math.sin(math.rad(NewLat)) - math.sin(math.rad(PrevLat)) * math.cos(math.rad(NewLat)) * math.cos(math.rad(NewLat) - math.rad(PrevLat))
  local Bearing = math.deg(math.atan2(yCalc,xCalc))
  if Bearing < 0 then
    Bearing = 360 + Bearing
  end  
  return Bearing
end

----------------------- Function to calculate distance between 2 coordinates -----------------------------
function CalcDistance(PrevLat,PrevLong,NewLat,NewLong)
  local earthRadius = 0
  if ImperialSet == 1 then
    earthRadius = 20902000  --feet  --3958.8 miles
  else
    earthRadius = 6371000   --meters
  end
  local dLat = math.rad(NewLat-PrevLat)
  local dLon = math.rad(NewLong-PrevLong)
  PrevLat = math.rad(PrevLat)
  NewLat = math.rad(NewLat)
  local a = math.sin(dLat/2) * math.sin(dLat/2) + math.sin(dLon/2) * math.sin(dLon/2) * math.cos(PrevLat) * math.cos(NewLat) 
  local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
  return (earthRadius * c)
end    

function drawNoFly(thisWidget)
-- do not draw the lines that are on any edge of the screen (but they are detected)
-- draw polygon--
	lcd.setColor(CUSTOM_COLOR, lcd.RGB(255,0,0))
	local tmp = thisWidget.map.poly[thisWidget.map.current]
	for i = 1, #thisWidget.map.poly[thisWidget.map.current]-1  do
	    if (tmp[i][1] < 479 or tmp[i+1][1] < 479) and (tmp[i][2] > 0 or tmp[i+1][2] > 0) then
		  lcd.drawLine(tmp[i][1],tmp[i][2],tmp[i+1][1],tmp[i+1][2], SOLID, CUSTOM_COLOR)
		end
	end
-- For some reason, the last segment must be drawn separately....
	local k = #thisWidget.map.poly[thisWidget.map.current]
	lcd.drawLine(tmp[k][1],tmp[k][2],tmp[1][1],tmp[1][2], SOLID, CUSTOM_COLOR)
end


--***********************************************************************
--*                            UPDATE FUNCTION                          *
--***********************************************************************
local function update(thisWidget, options)
  thisWidget.options = options
end

--***********************************************************************
--*                           REFRESH FUNCTION                          *
--***********************************************************************
local function refresh(thisWidget)
  
  local NS        = ""
  local EW        = ""
  local FM        = ""
  local SPD       = ""
  local LCD_Lat   = thisWidget.gpsLat or 0
  local LCD_Long  = thisWidget.gpsLong or 0 
  local LCD_Speed = thisWidget.Speed or 0
  local LCD_Alt   = thisWidget.Altitude or 0
  local LCD_Sats  = thisWidget.Sats or 0  
        if LCD_Sats  ~= nil or LCD_Sats > 0 then
          LCD_Sats = LCD_Sats - 100
        end
  local LCD_Hdg   = thisWidget.Hdg or 0  
  local xvalues   = { }
  local yvalues   = { }
  local x         = thisWidget.x or 0
  local y         = thisWidget.y or 0
  
	background(thisWidget)
  
  ------------------------------------------------------------------------------------------------------------
  RstAll = getValue(thisWidget.options.ResetAll) or 0
    
  if RstAll > 1000 then
    MaxDistance   = 0
    MaxSpeed      = 0
    MaxAltitude   = 0
    MaxLoS        = 0
    HomeSet       = 1
    DrawSock      = 0
    HomeLat       = thisWidget.gpsLat or 0
    HomeLong      = thisWidget.gpsLong or 0
  end  
  
   ------------ Calculates Heading and Distance from Home to Plane position -------------------------------------------
  local HomeToPlaneBearing = CalcBearing(HomeLat,HomeLong,LCD_Lat,LCD_Long) or 0
  local HomeToPlaneDistance = CalcDistance(HomeLat,HomeLong,LCD_Lat,LCD_Long) or 0
  --- Temporary fix for overflow HomeToPlaneDistance variable.. on Reset it sometimes overflows
  if HomeToPlaneDistance > 100000 then -- When overflowing with 100
    HomeToPlaneDistance = 0
  end
----------------------------------------- Calculates max Ground Distance ----------------------------------
	if (HomeToPlaneDistance > MaxDistance) then
			MaxDistance = HomeToPlaneDistance
  end
-----------------------------------------------------------------------------------------------------------

------------------------------------------- Calculates max Speed ------------------------------------------
	if (LCD_Speed > MaxSpeed) then
		MaxSpeed = LCD_Speed
	end
----------------------------------------------------------------------------------------------------------

---------------------------------------- Calculates max Altitude -----------------------------------------
	if (LCD_Alt > MaxAltitude) then
		MaxAltitude = LCD_Alt
	end
-------------------------------------------------------------------------------------------------------------

-------------------------------- Calculates (max) Line Of Sight Distance ---------------------------------
	local a = math.floor(LCD_Alt)
	local b = math.floor(HomeToPlaneDistance)
	LoSDistance = math.floor(math.sqrt((a * a) + (b * b)))
	if LoSDistance > MaxLoS then
		MaxLoS = LoSDistance
	end

------------------------------ Checks if valid GPS data is received -------------------------------------  
 if  (type(thisWidget.gpsLatLong) ~= "table") then
	lcd.drawBitmap(thisWidget.map.bmp.xlarge, thisWidget.zone.x -10, thisWidget.zone.y -10)
	--drawNoFly(thisWidget)
	lcd.setColor(CUSTOM_COLOR, lcd.RGB(255,0,0))
    lcd.drawFilledRectangle(0, 239, 480, 33, SOLID)    
	lcd.drawText( 120, 236, "No GPS SIGNAL", DBLSIZE + CUSTOM_COLOR + SHADOWED)
    lcd.drawText(470, 0, Version , CUSTOM_COLOR + SMLSIZE + RIGHT + SHADOWED)
	return
end

------------ Calculates Heading Bearing from previous and new location of the plane ----------------------
  if (LCD_Lat ~= TempLat) and (LCD_Long ~= TempLong) then
    Bearing = CalcBearing(TempLat,TempLong,LCD_Lat,LCD_Long)
    TempLat = LCD_Lat
    TempLong = LCD_Long
  end
  headingDeg = Bearing or 0
  --headingDeg = LCD_Hdg or 0

-----------------------------------------LCD ROUTINES --------------------------------------------------	

  --                          A
  --                         /|\
  --                        / | \
  --                       /  |  \
  --                      /   |   \
  --                     /    |     \
  --                    /     |      \
  --                   /      |       \
  --                  /       +        \
  --                 /        |         \
  --                /         |          \
  --               /          |           \
  --              /           |            \
  --             /            |             \
  --            /             |              \
  --           /______________|_______________\
  --          B C D E F G H I J K L M N O P Q R
  --           
  
  -- Front of arrow
  xvalues.ax = x + (10 * math.sin(math.rad(headingDeg)))
  yvalues.ay = y - (10 * math.cos(math.rad(headingDeg)))

  
  -- Center rear of arrow
  xvalues.jx = x - (10 * math.sin(math.rad(headingDeg)))
  yvalues.jy = y + (10 * math.cos(math.rad(headingDeg)))
 
  
  
  
  -- Left Outer side of arrow
  xvalues.bx = xvalues.jx - (8 * math.sin(math.rad(headingDeg - 90)))
  yvalues.by = yvalues.jy + (8 * math.cos(math.rad(headingDeg - 90)))

 
  -- Left part of arrow
  xvalues.cx = xvalues.jx - (7 * math.sin(math.rad(headingDeg - 90)))
  yvalues.cy = yvalues.jy + (7 * math.cos(math.rad(headingDeg - 90)))
  xvalues.dx = xvalues.jx - (6 * math.sin(math.rad(headingDeg - 90)))
  yvalues.dy = yvalues.jy + (6 * math.cos(math.rad(headingDeg - 90)))
  xvalues.ex = xvalues.jx - (5 * math.sin(math.rad(headingDeg - 90)))
  yvalues.ey = yvalues.jy + (5 * math.cos(math.rad(headingDeg - 90)))
  xvalues.fx = xvalues.jx - (4 * math.sin(math.rad(headingDeg - 90)))
  yvalues.fy = yvalues.jy + (4 * math.cos(math.rad(headingDeg - 90)))
  
  -- Right part of arrow
  xvalues.nx = xvalues.jx - (4 * math.sin(math.rad(headingDeg + 90)))
  yvalues.ny = yvalues.jy + (4 * math.cos(math.rad(headingDeg + 90)))
  xvalues.ox = xvalues.jx - (5 * math.sin(math.rad(headingDeg + 90)))
  yvalues.oy = yvalues.jy + (5 * math.cos(math.rad(headingDeg + 90)))
  xvalues.px = xvalues.jx - (6 * math.sin(math.rad(headingDeg + 90)))
  yvalues.py = yvalues.jy + (6 * math.cos(math.rad(headingDeg + 90)))
  xvalues.qx = xvalues.jx - (7 * math.sin(math.rad(headingDeg + 90)))
  yvalues.qy = yvalues.jy + (7 * math.cos(math.rad(headingDeg + 90)))

  -- Right Outer side of arrow
  xvalues.rx = xvalues.jx - (8 * math.sin(math.rad(headingDeg + 90)))
  yvalues.ry = yvalues.jy + (8 * math.cos(math.rad(headingDeg + 90)))

  
  
--draw background  
  lcd.drawBitmap(thisWidget.map.bmp[thisWidget.map.current], thisWidget.zone.x -10, thisWidget.zone.y -10)

  lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,0,0))
  if PlaneVisible == 1 then
  -- Draw nofly zone polygon -- in RED color
    drawNoFly(thisWidget)
  -- Draws plane --
    lcd.setColor(CUSTOM_COLOR, thisWidget.options.ArrowClr)
    
    -- Left side
    lcd.drawLine(xvalues.bx, yvalues.by, xvalues.ax, yvalues.ay, SOLID, CUSTOM_COLOR)
    lcd.drawLine(xvalues.cx, yvalues.cy, xvalues.ax, yvalues.ay, SOLID, CUSTOM_COLOR)
    lcd.drawLine(xvalues.dx, yvalues.dy, xvalues.ax, yvalues.ay, SOLID, CUSTOM_COLOR)
    lcd.drawLine(xvalues.ex, yvalues.ey, xvalues.ax, yvalues.ay, SOLID, CUSTOM_COLOR)
    lcd.drawLine(xvalues.fx, yvalues.fy, xvalues.ax, yvalues.ay, SOLID, CUSTOM_COLOR)
  
    -- Right side
    lcd.drawLine(xvalues.nx, yvalues.ny, xvalues.ax, yvalues.ay, SOLID, CUSTOM_COLOR)
    lcd.drawLine(xvalues.ox, yvalues.oy, xvalues.ax, yvalues.ay, SOLID, CUSTOM_COLOR)
    lcd.drawLine(xvalues.px, yvalues.py, xvalues.ax, yvalues.ay, SOLID, CUSTOM_COLOR)
    lcd.drawLine(xvalues.qx, yvalues.qy, xvalues.ax, yvalues.ay, SOLID, CUSTOM_COLOR)
    lcd.drawLine(xvalues.rx, yvalues.ry, xvalues.ax, yvalues.ay, SOLID, CUSTOM_COLOR)
  end

-- Preset info
	if LCD_Lat > 0 then
		NS = "N" 
	else
		NS = "S"
	end

	if LCD_Long > 0 then
		EW = "E"
	else
		EW = "W" 
	end
	
	if ImperialSet == 1 then
		FM  = "ft"
		SPD = "mph"
	else
		FM  = "m"
		SPD = "km/h"
	end  

-- Draws the Windsock as Homepoint & display Plane direction angle from Homepoint
  if HomeVisible == 1 then
    if DrawSock == 1 then
      lcd.drawBitmap(WindSock, HomePosx-16, HomePosy-16, 50)
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,0,248))
      local SockFlags = CUSTOM_COLOR + SMLSIZE + SHADOWED
      local SockX = HomePosx
      local SockY = HomePosy
      if SockX > 470 then
        SockFlags = SockFlags + RIGHT
      end
      if SockY < 10 then
        SockY = SockY + 10
      elseif SockY > 256 then
        SockY = SockY - 10
      end
      lcd.drawText(SockX, SockY, math.floor(HomeToPlaneBearing).."deg", SockFlags)
    end
  end 

  if PlaneVisible == 1 and HomeVisible == 1 then
  -- Enables a Line of Sight line when homeposition has been set, and enabled in Widget config menu
    if (HomeSet == 0) and (LosLineSet == 1) then
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(0, 252, 0))
      lcd.drawLine(x,y,HomePosx,HomePosy, DOTTED, CUSTOM_COLOR)
      local MidLosLineX = ((x + HomePosx)/2)
      local MidLosLineY = ((y + HomePosy)/2)
      local LosFlags = CUSTOM_COLOR + SMLSIZE + SHADOWED
      if MidLosLineX > 470 then
        LosFlags = LosFlags + RIGHT
      end
      if MidLosLineY < 10 then
        MidLosLineY = MidLosLineY + 10
      elseif MidLosLineY > 256 then
        MidLosLineY = MidLosLineY - 10
      end
      lcd.setColor(CUSTOM_COLOR, WHITE)
      lcd.drawText(MidLosLineX, MidLosLineY, math.floor(HomeToPlaneDistance)..FM , LosFlags)
    end
  else
    if PlaneVisible == 0 then
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(255,0,0))
      lcd.drawText( 120, 120, "OUT OF RANGE", DBLSIZE + CUSTOM_COLOR + SHADOWED)
      lcd.drawText(470, 0, Version , CUSTOM_COLOR + SMLSIZE + RIGHT + SHADOWED)
    end
  end  

  lcd.setColor(CUSTOM_COLOR, lcd.RGB(50,50,50))
  lcd.drawFilledRectangle(0, 239, 480, 33, CUSTOM_COLOR)
  
--  lcd.drawFilledRectangle(0, 239, 480, 33, GREY_DEFAULT)

-- Draws all flight information on screen -- 
 lcd.setColor(CUSTOM_COLOR, lcd.RGB(248,252,0))
-- lcd.setColor(CUSTOM_COLOR, lcd.RGB(255,0,0))

  lcd.drawText(10, 239, "Speed: "..math.floor(LCD_Speed)..SPD, CUSTOM_COLOR + SMLSIZE + SHADOWED)   
  lcd.drawText(10, 255, "Max: "..math.floor(MaxSpeed)..SPD , CUSTOM_COLOR + SMLSIZE + SHADOWED)   
  
  lcd.drawText(130, 239, "Alt: "..math.floor(LCD_Alt)..FM, CUSTOM_COLOR + SMLSIZE + SHADOWED)   
  lcd.drawText(130, 255, "Max: "..math.floor(MaxAltitude)..FM , CUSTOM_COLOR + SMLSIZE + SHADOWED)   
  
  lcd.drawText(240, 239, "Dist: "..math.floor(HomeToPlaneDistance)..FM, CUSTOM_COLOR + SMLSIZE + SHADOWED)
  lcd.drawText(240, 255, "Max: "..math.floor(MaxDistance)..FM , CUSTOM_COLOR + SMLSIZE + SHADOWED)
  
  lcd.drawText(360, 239, "LoS: "..math.floor(LoSDistance)..FM, CUSTOM_COLOR + SMLSIZE + SHADOWED)
  lcd.drawText(360, 255, "Max: "..math.floor(MaxLoS)..FM , CUSTOM_COLOR + SMLSIZE + SHADOWED)

  if LCD_Sats > 0  then
    lcd.drawText(10, 32, "Satellites: "..math.floor(LCD_Sats), CUSTOM_COLOR + SMLSIZE + SHADOWED)  
  end

  lcd.drawText(10, 16, "Heading: "..math.floor(headingDeg).."deg" , CUSTOM_COLOR + SMLSIZE + SHADOWED)  
  lcd.drawText(10, 0, "Lat: "..NS..math.abs(LCD_Lat).." / Lon: "..EW..math.abs(LCD_Long), CUSTOM_COLOR + SMLSIZE +SHADOWED)
  
  lcd.drawText(470, 0, Version , CUSTOM_COLOR + SMLSIZE + RIGHT + SHADOWED)

end
return { name="Map", options=options, create=create, update=update, background=background, refresh=refresh }