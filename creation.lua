local createdShape
local drawShape = false

RegisterNetEvent("polyzone:polystart")
AddEventHandler("polyzone:polystart", function(name)
  if createdShape ~= nil then
    TriggerEvent('chat:addMessage', {
      color = { 255, 0, 0},
      multiline = true,
      args = {"Me", "A shape is already being created!"}
    })
    return
  end

  local coords = GetEntityCoords(PlayerPedId())

  createdShape = {
    points = {vector2(coords.x, coords.y)},
    options = {minZ = coords.z, maxZ = coords.z, name = tostring(name)},
    debugColors = {
      walls = {0, 255, 0},
      outline = {255, 0, 0},
      grid = {255, 255, 255}
    },
    startPos = vector2(0.0, 0.0),
    offsetPos = vector2(0.0, 0.0),
    offsetRot = 0.0
  }

  drawShape = true
  drawThread()
end)

RegisterNetEvent("polyzone:polyadd")
AddEventHandler("polyzone:polyadd", function()
  if createdShape == nil then
    return
  end

  local coords = GetEntityCoords(PlayerPedId())

  if (coords.z > createdShape.options.maxZ) then
    createdShape.options.maxZ = coords.z
  end

  if (coords.z < createdShape.options.minZ) then
    createdShape.options.minZ = coords.z
  end

  createdShape.points[#createdShape.points + 1] = vector2(coords.x, coords.y)
end)

RegisterNetEvent("polyzone:polyundo")
AddEventHandler("polyzone:polyundo", function()
  if createdShape == nil then
    return
  end

  createdShape.points[#createdShape.points] = nil
  if #createdShape.points == 0 then
    TriggerEvent("polyzone:polycancel")
  end
end)

RegisterNetEvent("polyzone:polyfinish")
AddEventHandler("polyzone:polyfinish", function()
  if createdShape == nil then
    return
  end

  TriggerServerEvent("polyzone:printShape", createdShape)

  TriggerEvent('chat:addMessage', {
    color = { 0, 255, 0},
    multiline = true,
    args = {"Me", "Check your server root folder for polyzone_created_shapes.txt to get the shape!"}
  })

  drawShape = false
  createdShape = nil
end)

RegisterNetEvent("polyzone:polycancel")
AddEventHandler("polyzone:polycancel", function()
  if createdShape == nil then
    return
  end

  TriggerEvent('chat:addMessage', {
    color = {255, 0, 0},
    multiline = true,
    args = {"Me", "Shape creation canceled!"}
  })

  drawShape = false
  createdShape = nil
end)

-- Drawing
function drawThread()
  Citizen.CreateThread(function()
    while drawShape do
      PolyZone.drawPoly(createdShape)
      Citizen.Wait(1)
    end
  end)
end