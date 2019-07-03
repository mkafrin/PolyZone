local createdShape
local drawShape = false

RegisterCommand("pz_startshape", function(src, args)
  if args[1] == nil then
    TriggerEvent('chat:addMessage', {
      color = { 255, 0, 0},
      multiline = true,
      args = {"Me", "Please add a name!"}
    })
    return
  elseif createdShape ~= nil then
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
    options = {name = tostring(args[1])}
  }

  drawShape = true
  drawThread()
end)

RegisterCommand("pz_addpoint", function(src, args)
  local coords = GetEntityCoords(PlayerPedId())

  createdShape.points[#createdShape.points + 1] = vector2(coords.x, coords.y)
end)

RegisterCommand("pz_endshape", function(src, args)
  TriggerServerEvent("polyzone:printShape", createdShape)

  TriggerEvent('chat:addMessage', {
    color = { 0, 255, 0},
    multiline = true,
    args = {"Me", "Check your server root folder for polyzone_created_shapes.txt to get the shape!"}
  })

  drawShape = false
  createdShape = nil
end)

Citizen.CreateThread(function()
  TriggerEvent('chat:addSuggestion', '/pz_startshape', 'Starts creation of a shape for PolyZone.', {
    { name="name", help="Shape Name (required)" },
  })

  TriggerEvent('chat:addSuggestion', '/pz_addpoint', 'Adds point to shape.', {})

  TriggerEvent('chat:addSuggestion', '/pz_endshape', 'Closes and prints shape.', {})
end)

-- Drawing
function drawThread()
  Citizen.CreateThread(function()
    while drawShape do
      PolyZone.drawPoly(createdShape, {drawPoints=true})
      Citizen.Wait(1)
    end
  end)
end