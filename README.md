# PolyZone
PolyZone is a FiveM mod to define polygonal zones and test whether a point is inside or outside of the zone

![PolyZone around the prison](https://i.imgur.com/InKNaoL.jpg)

### Using PolyZone in a Script
In order to use PolyZone in your script, you must include PolyZone's client.lua directly in your __resource.lua. You can do that by using FiveM's @ syntax for including resources:

```lua
client_scripts {
    '@PolyZone/client.lua',
    'your_scripts_client.lua',
}
```

### Creating a PolyZone Instance
A PolyZone is created by invoking the Create method, and passing in a table of vector2s and a table of options:

```lua
local pinkcage = PolyZone:Create({
    vector2(328.41662597656, -189.42219543457),
    vector2(347.90512084961, -196.81504821777),
    vector2(336.11190795898, -227.95924377441),
    vector2(306.11798095703, -216.42715454102),
    vector2(314.41293334961, -194.19380187988),
    vector2(324.84567260742, -198.19834899902)
}, {
    name="pink_cage",
    minZ=51.0,
    maxZ=62.0,
    debugGrid=false,
    gridDivisions=25
})
```
Note: The points MUST be in sequential order. You could write down the points yourself, but PolyZone comes with a creation script that will auto-generate the code for you. Just use the commands `/polystart`, `/polyadd`, and `/polyfinish` to create a new PolyZone, and see the points you are adding in game! If you mess up a point, you can use `/polyundo`, and if you want to cancel the whole thing, just use `/polycancel`.

### Options for a PolyZone Instance

| Property            | Type    | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Default&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Required | Description                                                                                                                                                                                                                                                         |
|---------------------|---------|---------------------------------------------------------------------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name                | String  | nil                                                                             | false    | Name of the zone                                                                                                                                                                                                                                                    |
| minZ                | Float   | nil                                                                             | false    | Minimum height of the zone                                                                                                                                                                                                                                          |
| maxZ                | Float   | nil                                                                             | false    | Maximum height of the zone                                                                                                                                                                                                                                          |
| gridDivisions       | Integer | 30                                                                              | false    | Number of times the optimization grid is divided. The higher this number, the higher the grid coverage. 80-90% grid coverage is optimal, and setting debugGrid=true will print the zone's coverage. The default of 30 will achieve 80-90% coverage with most zones. |
| debugGrid           | Boolean | false                                                                           | false    | Debug drawing of the optimization grid. Setting this to true also sets debugPoly to true                                                                                                                                                                            |
| debugPoly           | Boolean | false                                                                           | false    | Debug drawing of the polygon                                                                                                                                                                                                                                        |
| debugColors         | Table   | see below                                                                       | false    | Used to customize the colors of the debug drawing in rgb format. Each color is a table with three integers between 0 and 255 representing red, green, and blue. See below for all the colors you can change                                                         |
| debugColors.walls   | Table   | {0, 255, 0}                                                                     | false    | Color of the walls that connect the zone's points together                                                                                                                                                                                                          |
| debugColors.outline | Table   | {255, 0, 0}                                                                     | false    | Color of the outline of the zone's walls                                                                                                                                                                                                                            |
| debugColors.grid    | Table   | {255, 255, 255}                                                                 | false    | Color of the zone's optimization grid                                                                                                                                                                                                                               |

### Creating a PolyZone Instance Around an Entity
An "Entity Zone" is created by invoking the CreateAroundEntity method, and passing in an entity (Ped, Vehicle, etc) and a table of options:

```lua
local vehicle = GetVehiclePedIsIn(PlayerPedId())
local entityZone = PolyZone:CreateAroundEntity(vehicle, {
    name="entity_zone",
    useZ=false,
    offset={0.0, 0.0, 0.0},
    scale={1.0, 1.0, 1.0},
    debugPoly=false,
})
```
Note: Entity zones follow the position and rotation of the entity. Entity zones don't use the grid optimization, since all entity zones are simple bounding boxes. Because of this, use the `debugPoly` option to enable debug drawing, instead of `debugGrid`. Any option that can be passed into regular PolyZones can be passed into entity zones, though any grid related options and minZ/maxZ are ignored. There are a few additional options for entity zones, seen in the table below.

### Options for a PolyZone Instance Around an Entity

| Property | Type    | &nbsp;&nbsp;&nbsp;&nbsp;Default&nbsp;&nbsp;&nbsp;&nbsp; | Required | Description                                                                                                                                                                                                                                                                        |
|----------|---------|---------------------------------------------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| useZ     | Boolean | false                                                   | false    | You can't specify a minZ or maxZ for entity zones. Instead, they will be automatically calculated if you set this option to true                                                                                                                                                   |
| offset   | Table   | {0.0, 0.0, 0.0}                                         | false    | A table of numbers to offset the entity zone by an absolute amount. This table can either contain 6 numbers, with the layout being {forward, back, left, right, up, down}, or 3 numbers if you want symmetrical offsets, with the layout being {forward/back, left/right, up/down} |
| scale    | Table   | {1.0, 1.0, 1.0}                                         | false    | Same as the offset option, but scales the entity zone, instead of offsetting it                                                                                                                                                                                                    |

Note: An entity zone is scaled before it is offset. Therefore a direction's length is calculated as `directionLength * directionScale + directionOffset`



### Testing a Point with PolyZone
There is two ways to test whether a point is inside the zone. There is a more manual way, which includes directly using the isPointInside method on a particular zone, and then there is a helper function which remove some of that boilerplate.

Assuming we are using the "pinkcage" zone from above, the manual way to check if a point is inside the zone is as follows:

```lua
local insidePinkCage = false
Citizen.CreateThread(function()
    while true do
        local plyPed = PlayerPedId()
	local coord = GetEntityCoords(plyPed)
	insidePinkCage = pinkcage:isPointInside(coord)
	Citizen.Wait(500)
    end
end)    
```
"insidePinkCage" will be updated every 500 ms with whether the player's position is inside or outside the zone

The way to do this with the helper function is as follows:
```lua
local insidePinkCage = false
pinkcage:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
    insidePinkCage = isPointInside
end)
```
`onPointInOut` is the helper function we're using here, and it will trigger the callback function we passed in `function(isPointInside, point)` every time the point enters or exits the zone

The point we are testing for is computed using the first thing we pass to `onPointInOut`. `PolyZone.getPlayerPosition` is a premade function that just returns the player's current position

A similar function, `PolyZone.getPlayerHeadPosition` exists, that returns the position of the player's head. This can be useful if your server has crouch and/or prone enabled, and you want players to be able to go underneath a zone.

The nice thing about `onPointInOut` is that the `isPointInside` parameter of the callback function will always represent whether the point has JUST entered or exited the zone.

```lua
pinkcage:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
    if isPointInside then
	-- Point has just entered the zone
    else
	-- Point has just left the zone
    end
end)
```

An optional third argument exists for `onPointInOut` that controls the number of milliseconds between each point check. The default for this is 500 ms, but you can change it to any amount

```lua
local msBetweenPointCheck = 100
pinkcage:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
    -- This function will now check every 100 ms whether the point has entered or exited the zone
end, msBetweenPointCheck)
```

Also, if the `PolyZone.getPlayerPosition` or `PolyZone.getPlayerHeadPosition` helpers don't work for what you are doing, you can use a custom callback for getting the point to test:

```lua
local insidePinkCage = false
pinkcage:onPointInOut(function()
    return GetEntityCoords(GetVehiclePedIsIn(PlayerPedId(), false))
end, function(isPointInside, point)
    insidePinkCage = isPointInside
end)
```
Here we pass in the following custom callback that returns the point to check:
```lua
function()
    return GetEntityCoords(GetVehiclePedIsIn(PlayerPedId(), false))
end
```
This function will return the position of the vehicle the player is currently in. Note that this is just an example, and in reality, `PolyZone.getPlayerPosition` will do this anyways.

### Destroying a PolyZone Instance
Destroying a PolyZone instance will stop any threads associated with that zone, including debug drawing, onPointInOut helpers, etc. It will also set a `destroyed` flag on the zone to true. This probably makes more sense to use on an entity zone, but it can be used for any PolyZone instance:

```lua
pinkcage:destroy()
```
Note: If you try to call `isPointInside` on a destroyed zone, it will return false, and emit a warning.

### onEntityDamaged Helper
It may be useful to know when the entity associated with an entity zone is damaged or is destroyed/dies, and do something with that info. The `onEntityDamaged` helper can provide this information. `onEntityDamaged` takes a callback function that is run anytime the entity associated with an entity zone is damaged, and passes some additional information to the callback. It is used as follows:

```lua
entity_zone:onEntityDamaged(function(entityDied, attacker, weaponHash, isMelee)
    -- Do stuff here!
    -- You could destroy the zone when the entity is destroyed for example:
    if entityDied then entity_zone:destroy() end
end)
```
Note: This is event-based and therefore does not run per-frame or at any regular interval. It will trigger the moment any damage to the entity occurs. This helper can only be used on entity zones and will trigger an error if used on a non entity zone.

### Additional Helper Functions
Lastly, there are a few additional helper functions that expose some internal variables, in case you might have a use for them. These functions are all based on the bounding box that surrounds the zone and are:

`getBoundingBoxMin()` - Minimum x and y of the bounding box \
`getBoundingBoxMax()` - Maximum x and y of the bounding box \
`getBoundingBoxSize()` - Size of the bounding box (max - min) \
`getBoundingBoxCenter()` - Center of the bounding box
