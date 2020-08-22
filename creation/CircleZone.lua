local function handleInput(radius, center, useZ)
  BlockWeaponWheelThisFrame()
  DisableControlAction(0, 36, true)
  DisableControlAction(0, 81, true)
  if IsDisabledControlJustPressed(0, 81) then
    if IsDisabledControlPressed(0, 36) then -- ctrl held down
      return math.max(0.0, radius - 0.1), center, useZ
    end
    return math.max(0.0, radius - 0.5), center, useZ
  end
  DisableControlAction(0, 99, true)
  if IsDisabledControlJustPressed(0, 99) then
    if IsDisabledControlPressed(0, 36) then -- ctrl held down
      return math.max(0.0, radius + 0.1), center, useZ
    end
    return math.max(0.0, radius + 0.5), center, useZ
  end

  if IsControlJustPressed(0, 20) then -- Z pressed
    return radius, center, not useZ
  end

  local rot = GetGameplayCamRot(2)
  center = handleArrowInput(center, rot.z)

  return radius, center, useZ
end

function circleStart(name, radius, useZ)
  local center = GetEntityCoords(PlayerPedId())
  useZ = useZ or false
  createdZone = CircleZone:Create(center, radius, {name = tostring(name), useZ = useZ})
  Citizen.CreateThread(function()
    while createdZone do
      radius, center, useZ = handleInput(radius, center, useZ)
      createdZone:setRadius(radius)
      createdZone:setCenter(center)
      createdZone.useZ = useZ
      Wait(0)
    end
  end)
end

function circleFinish()
  TriggerServerEvent("polyzone:printCircle",
    {name=createdZone.name, center=createdZone.center, radius=createdZone.radius, useZ=createdZone.useZ})
end