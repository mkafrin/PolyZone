RegisterCommand("pzcreate", function(src, args)
  local zoneType = args[1]
  if zoneType == nil then
    TriggerEvent('chat:addMessage', {
      color = { 255, 0, 0},
      multiline = true,
      args = {"Me", "Please add zone type to create (poly, circle, box)!"}
    })
    return
  end
  if zoneType ~= 'poly' and zoneType ~= 'circle' and zoneType ~= 'box' then
    TriggerEvent('chat:addMessage', {
      color = { 255, 0, 0},
      multiline = true,
      args = {"Me", "Zone type must be one of: poly, circle, box"}
    })
    return
  end
  local name = GetUserInput("Enter name of zone:")
  if name == nil or name == "" then
    TriggerEvent('chat:addMessage', {
      color = { 255, 0, 0},
      multiline = true,
      args = {"Me", "Please add a name!"}
    })
    return
  end
  TriggerEvent("polyzone:pzcreate", zoneType, name)
end)

RegisterCommand("pzadd", function(src, args)
  TriggerEvent("polyzone:pzadd")
end)

RegisterCommand("pzundo", function(src, args)
  TriggerEvent("polyzone:pzundo")
end)

RegisterCommand("pzfinish", function(src, args)
  TriggerEvent("polyzone:pzfinish")
end)

RegisterCommand("pzlast", function(src, args)
  TriggerEvent("polyzone:pzlast")
end)

RegisterCommand("pzcancel", function(src, args)
  TriggerEvent("polyzone:pzcancel")
end)

Citizen.CreateThread(function()
  TriggerEvent('chat:addSuggestion', '/pzcreate', 'Starts creation of a zone for PolyZone of one of the available types: circle, box, poly', {
    {name="zoneType", help="Zone Type (required)"},
  })

  TriggerEvent('chat:addSuggestion', '/pzadd', 'Adds point to zone.', {})
  TriggerEvent('chat:addSuggestion', '/pzundo', 'Undoes the last point added.', {})
  TriggerEvent('chat:addSuggestion', '/pzfinish', 'Finishes and prints zone.', {})
  TriggerEvent('chat:addSuggestion', '/pzlast', 'Starts creation of the last zone you finished (only works on BoxZone and CircleZone)', {})
  TriggerEvent('chat:addSuggestion', '/pzcancel', 'Cencel zone creation.', {})
end)