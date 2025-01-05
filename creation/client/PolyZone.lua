local minZ, maxZ = nil, nil

local function handleInput(center)
  local rot = GetGameplayCamRot(2)
  center = handleArrowInput(center, rot.z)
  return center
end

function handleZ(minZ, maxZ)
  local delta = 0.2

  if IsDisabledControlPressed(0, 36) then -- ctrl held down
    delta = 0.05
  end

  BlockWeaponWheelThisFrame()

  if IsDisabledControlJustPressed(0, 81) then -- scroll wheel down just pressed

    if IsDisabledControlPressed(0, 19) then -- alt held down
      return minZ - delta, maxZ
    end
    if IsDisabledControlPressed(0, 21) then -- shift held down
      return minZ, maxZ - delta
    end
    return minZ - delta, maxZ - delta
  end

  if IsDisabledControlJustPressed(0, 99) then -- scroll wheel up just pressed

    if IsDisabledControlPressed(0, 19) then -- alt held down
      return minZ + delta, maxZ
    end
    if IsDisabledControlPressed(0, 21) then -- shift held down
      return minZ, maxZ + delta
    end
    return minZ + delta, maxZ + delta
  end
  return minZ, maxZ
end


function polyStart(name)
  local coords = GetEntityCoords(PlayerPedId())
  -- Put the Polyzone Height as human sized
  minZ = coords.z - 1
  maxZ = coords.z + 1
  createdZone = PolyZone:Create({vector2(coords.x, coords.y)}, {name = tostring(name), minZ=minZ, maxZ=maxZ, useGrid=false})
  Citizen.CreateThread(function()
    while createdZone do
      -- Have to convert the point to a vector3 prior to calling handleInput,
      -- then convert it back to vector2 afterwards
      if IsDisabledControlJustPressed(0, 20) then -- Z pressed
        useZ = not useZ
        if useZ then
          createdZone.debugColors.walls = {255, 0, 0}
        else
          createdZone.debugColors.walls = {0, 255, 0}
        end
      end
      if useZ then
        minZ, maxZ = handleZ(minZ, maxZ)
        createdZone.minZ = minZ
        createdZone.maxZ = maxZ
      end
      lastPoint = createdZone.points[#createdZone.points]
      lastPoint = vector3(lastPoint.x, lastPoint.y, 0.0)
      lastPoint = handleInput(lastPoint)
      createdZone.points[#createdZone.points] = lastPoint.xy
      Wait(0)
    end
  end)
  minZ, maxZ = createdZone.minZ , createdZone.maxZ 
end

function polyFinish()
  TriggerServerEvent("polyzone:printPoly",
    {name=createdZone.name, points=createdZone.points, minZ=minZ, maxZ=maxZ})
end

RegisterNetEvent("polyzone:pzadd")
AddEventHandler("polyzone:pzadd", function()
  if createdZone == nil or createdZoneType ~= 'poly' then
    return
  end

  local coords = GetEntityCoords(PlayerPedId())

  if (coords.z > maxZ) then
    maxZ = coords.z
  end
  
  if (coords.z < minZ) then
    minZ = coords.z
  end

  createdZone.points[#createdZone.points + 1] = vector2(coords.x, coords.y)
end)

RegisterNetEvent("polyzone:pzundo")
AddEventHandler("polyzone:pzundo", function()
  if createdZone == nil or createdZoneType ~= 'poly' then
    return
  end

  createdZone.points[#createdZone.points] = nil
  if #createdZone.points == 0 then
    TriggerEvent("polyzone:pzcancel")
  end
end)