local function handleScrollWheel(radius)
  BlockWeaponWheelThisFrame()
  DisableControlAction(0, 36, true)
  DisableControlAction(0, 81, true)
  if IsDisabledControlJustPressed(0, 81) then
    if IsDisabledControlPressed(0, 36) then -- ctrl held down
      return math.max(1.0, radius - 0.1)
    end
    return math.max(1.0, radius - 0.5)
  end
  DisableControlAction(0, 99, true)
  if IsDisabledControlJustPressed(0, 99) then
    if IsDisabledControlPressed(0, 36) then -- ctrl held down
      return math.max(1.0, radius + 0.1)
    end
    return math.max(1.0, radius + 0.5)
  end
  return radius
end

function circleStart(name, radius)
  local coords = GetEntityCoords(PlayerPedId())
  createdZone = CircleZone:Create(coords, radius, {name = tostring(name)})
  Citizen.CreateThread(function()
    while createdZone do
      local newRadius = handleScrollWheel(radius)
      if radius ~= newRadius then
        radius = newRadius
        createdZone:setRadius(newRadius)
      end
      Wait(0)
    end
  end)
end

function circleFinish()
  TriggerServerEvent("polyzone:printCircle",
    {name=createdZone.name, center=createdZone.center, radius=createdZone.radius})
end