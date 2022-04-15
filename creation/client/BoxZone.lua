local function handleInput(useZ, heading, length, width, center)
  if not useZ then
    local scaleDelta, headingDelta = 0.2, 5
    BlockWeaponWheelThisFrame()

    if IsDisabledControlPressed(0, 36) then -- ctrl held down
      scaleDelta, headingDelta = 0.05, 1
    end

    if IsDisabledControlJustPressed(0, 81) then -- scroll wheel down just pressed

      if IsDisabledControlPressed(0, 19) then -- alt held down
        return heading, length, math.max(0.0, width - scaleDelta), center
      end
      if IsDisabledControlPressed(0, 21) then -- shift held down
        return heading, math.max(0.0, length - scaleDelta), width, center
      end
      return (heading - headingDelta) % 360, length, width, center
    end


    if IsDisabledControlJustPressed(0, 99) then -- scroll wheel up just pressed

      if IsDisabledControlPressed(0, 19) then -- alt held down
        return heading, length, math.max(0.0, width + scaleDelta), center
      end
      if IsDisabledControlPressed(0, 21) then -- shift held down
        return heading, math.max(0.0, length + scaleDelta), width, center
      end
      return (heading + headingDelta) % 360, length, width, center
    end
  end

  local rot = GetGameplayCamRot(2)
  center = handleArrowInput(center, rot.z)

  return heading, length, width, center
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

function boxStart(name, heading, length, width, minHeight, maxHeight)
  local center = GetEntityCoords(PlayerPedId())
  createdZone = BoxZone:Create(center, length, width, {name = tostring(name)})
  local useZ, minZ, maxZ = false, center.z - 1.0, center.z + 3.0
  if minHeight then
    minZ = center.z - minHeight
    createdZone.minZ = minZ
  end
  if maxHeight then
    maxZ = center.z + maxHeight
    createdZone.maxZ = maxZ
  end
  Citizen.CreateThread(function()
    while createdZone do
      if IsDisabledControlJustPressed(0, 20) then -- Z pressed
        useZ = not useZ
        if useZ then
          createdZone.debugColors.walls = {255, 0, 0}
        else
          createdZone.debugColors.walls = {0, 255, 0}
        end
      end
      heading, length, width, center = handleInput(useZ, heading, length, width, center)
      if useZ then
        minZ, maxZ = handleZ(minZ, maxZ)
        createdZone.minZ = minZ
        createdZone.maxZ = maxZ
      end
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
    {name=createdZone.name, center=createdZone.center, length=createdZone.length, width=createdZone.width, heading=createdZone.offsetRot, minZ=createdZone.minZ, maxZ=createdZone.maxZ})
end