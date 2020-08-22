local function handleInput(heading, length, width, center)
  BlockWeaponWheelThisFrame()
  DisableControlAction(0, 36, true)
  DisableControlAction(0, 81, true)
  if IsDisabledControlJustPressed(0, 81) then
    if IsControlPressed(0, 19) then -- alt held down
      return heading, length, math.max(0.0, width - 0.2), center
    end
    if IsControlPressed(0, 21) then -- shift held down
      return heading, math.max(0.0, length - 0.2), width, center
    end
    if IsDisabledControlPressed(0, 36) then -- ctrl held down
      return (heading - 1) % 360, length, width, center
    end
    return (heading - 5) % 360, length, width, center
  end
  
  DisableControlAction(0, 99, true)
  if IsDisabledControlJustPressed(0, 99) then
    if IsControlPressed(0, 19) then -- alt held down
      return heading, length, math.max(0.0, width + 0.2), center
    end
    if IsControlPressed(0, 21) then -- shift held down
      return heading, math.max(0.0, length + 0.2), width, center
    end
    if IsDisabledControlPressed(0, 36) then -- ctrl held down
      return (heading + 1) % 360, length, width, center
    end
    return (heading + 5) % 360, length, width, center
  end

  local rot = GetGameplayCamRot(2)
  center = handleArrowInput(center, rot.z)

  return heading, length, width, center
end

function boxStart(name, heading, length, width)
  local center = GetEntityCoords(PlayerPedId())
  createdZone = BoxZone:Create(center, length, width, {name = tostring(name)})
  Citizen.CreateThread(function()
    while createdZone do
      heading, length, width, center = handleInput(heading, length, width, center)
      createdZone:setLength(length)
      createdZone:setWidth(width)
      createdZone:setHeading(heading)
      createdZone:setCenter(center)
      Wait(0)
    end
  end)
end

function boxFinish()
  TriggerServerEvent("polyzone:printBox",
    {name=createdZone.name, center=createdZone.center, length=createdZone.length, width=createdZone.width, heading=createdZone.offsetRot})
end