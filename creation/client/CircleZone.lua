local function handleInput(radius, center, useZ)
  local delta = 0.05
  BlockWeaponWheelThisFrame()

  if IsDisabledControlPressed(0, 36) then -- ctrl held down
    delta = 0.01
  end

  if IsDisabledControlJustPressed(0, 81) then -- scroll wheel down just pressed

    if IsDisabledControlPressed(0, 19) then -- alt held down
      return radius, vector3(center.x, center.y, center.z - delta), useZ
    end
    return math.max(0.0, radius - delta), center, useZ
  end


  if IsDisabledControlJustPressed(0, 99) then -- scroll wheel up just pressed

    if IsDisabledControlPressed(0, 19) then -- alt held down
      return radius, vector3(center.x, center.y, center.z + delta), useZ
    end
    return radius + delta, center, useZ
  end

  if IsDisabledControlJustPressed(0, 20) then -- Z pressed
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