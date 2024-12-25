local parse = {
  poly = function(zone)
    local points = {}
    for i = 1, #zone.points do
      points[#points + 1] = ('\t\tvector2(%s, %s),\n'):format(zone.points[i].x, zone.points[i].y)
    end

    return table.concat({
      'PolyZone:Create({\n',
      table.concat(points),
      '}, {\n',
      ('\tname = "%s",\n'):format(zone.name),
      ('\tminZ = %s,\n'):format(zone.minZ),
      ('\tmaxZ = %s,\n'):format(zone.maxZ),
      '})\n\n'
    })
  end,
  circle = function(zone)
    return table.concat({
      'CircleZone:Create(\n',
      ('\tvector3(%s, %s, %s),\n'):format(zone.center.x, zone.center.y, zone.center.z),
      ('\t%s,\n'):format(zone.radius),
      '{\n',
      ('\tname = "%s",\n'):format(zone.name),
      ('\tuseZ = %s,\n'):format(zone.useZ),
      '})\n\n'
    })
  end,
  box = function(zone)
    return table.concat({
      'BoxZone:Create(\n',
      ('\tvector3(%s, %s, %s),\n'):format(zone.center.x, zone.center.y, zone.center.z),
      ('\t%s, %s,\n'):format(zone.length, zone.width),
      '{\n',
      ('\tname = "%s",\n'):format(zone.name),
      ('\theading = %s,\n'):format(zone.heading),
      ('\tminZ = %s,\n'):format(zone.minZ),
      ('\tmaxZ = %s,\n'):format(zone.maxZ),
      '})\n\n'
    })
  end
}

RegisterNetEvent("polyzone:printPoly")
AddEventHandler("polyzone:printPoly", function(zone)
  local output = parse.poly(zone)
  local existingContent = LoadResourceFile(GetCurrentResourceName(), 'polyzone_created_zones.txt') or ''
  SaveResourceFile(GetCurrentResourceName(), 'polyzone_created_zones.txt', existingContent .. output, -1)
end)

RegisterNetEvent("polyzone:printCircle")
AddEventHandler("polyzone:printCircle", function(zone)
  local output = parse.circle(zone)
  local existingContent = LoadResourceFile(GetCurrentResourceName(), 'polyzone_created_zones.txt') or ''
  SaveResourceFile(GetCurrentResourceName(), 'polyzone_created_zones.txt', existingContent .. output, -1)
end)

RegisterNetEvent("polyzone:printBox")
AddEventHandler("polyzone:printBox", function(zone)
  local output = parse.box(zone)
  local existingContent = LoadResourceFile(GetCurrentResourceName(), 'polyzone_created_zones.txt') or ''
  SaveResourceFile(GetCurrentResourceName(), 'polyzone_created_zones.txt', existingContent .. output, -1)
end)