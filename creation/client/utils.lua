-- GetUserInput function inspired by vMenu (https://github.com/TomGrobbe/vMenu/blob/master/vMenu/CommonFunctions.cs)
function GetUserInput(windowTitle, defaultText, maxInputLength)
  -- Create the window title string.
  local resourceName = string.upper(GetCurrentResourceName())
  local textEntry = resourceName .. "_WINDOW_TITLE"
  if windowTitle == nil then
    windowTitle = "Enter:"
  end
  AddTextEntry(textEntry, windowTitle)

  -- Display the input box.
  DisplayOnscreenKeyboard(1, textEntry, "", defaultText or "", "", "", "", maxInputLength or 30)
  Wait(0)
  -- Wait for a result.
  while true do
    local keyboardStatus = UpdateOnscreenKeyboard();
    if keyboardStatus == 3 then -- not displaying input field anymore somehow
      return nil
    elseif keyboardStatus == 2 then -- cancelled
      return nil
    elseif keyboardStatus == 1 then -- finished editing
      return GetOnscreenKeyboardResult()
    else
      Wait(0)
    end
  end
end

function handleArrowInput(center, heading)
  delta = 0.05

  if IsDisabledControlPressed(0, 36) then -- ctrl held down
    delta = 0.01
  end

  if IsDisabledControlPressed(0, 172) then -- arrow up
    local newCenter =  PolyZone.rotate(center.xy, vector2(center.x, center.y + delta), heading)
    return vector3(newCenter.x, newCenter.y, center.z)
  end

  if IsDisabledControlPressed(0, 173) then -- arrow down
    local newCenter =  PolyZone.rotate(center.xy, vector2(center.x, center.y - delta), heading)
    return vector3(newCenter.x, newCenter.y, center.z)
  end

  if IsDisabledControlPressed(0, 174) then -- arrow left
    local newCenter =  PolyZone.rotate(center.xy, vector2(center.x - delta, center.y), heading)
    return vector3(newCenter.x, newCenter.y, center.z)
  end

  if IsDisabledControlPressed(0, 175) then -- arrow right
    local newCenter =  PolyZone.rotate(center.xy, vector2(center.x + delta, center.y), heading)
    return vector3(newCenter.x, newCenter.y, center.z)
  end

  return center
end

function disableControlKeyInput()
  Citizen.CreateThread(function()
    while drawZone do
      DisableControlAction(0, 36, true)   -- Ctrl
      DisableControlAction(0, 19, true)   -- Alt
      DisableControlAction(0, 20, true)   -- 'Z'
      DisableControlAction(0, 21, true)   -- Shift
      DisableControlAction(0, 81, true)   -- Scroll Wheel Down
      DisableControlAction(0, 99, true)   -- Scroll Wheel Up
      DisableControlAction(0, 172, true)  -- Arrow Up
      DisableControlAction(0, 173, true)  -- Arrow Down
      DisableControlAction(0, 174, true)  -- Arrow Left
      DisableControlAction(0, 175, true)  -- Arrow Right
      Wait(0)
    end
  end)
end