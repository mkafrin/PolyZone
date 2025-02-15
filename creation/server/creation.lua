RegisterNetEvent("polyzone:printPoly")
AddEventHandler("polyzone:printPoly", function(zone)
  local fileName = "polyzone_created_zones.txt"
  local created_zones = LoadResourceFile(GetCurrentResourceName(), fileName) or ""
  local formattedDate = os.date("%Y-%m-%dT%H:%M:%S")
  local header = "-- Name: " .. zone.name .. " | " .. formattedDate
  local points = ""
  for _, point in ipairs(zone.points) do
    points = points .. "  vector2(" .. point.x .. ", " .. point.y .. "),\n"
  end
  local polyData = header .. "\n" ..
  "PolyZone:Create({\n" ..
  points ..
  "},)\n" ..
  "---------------------------------------------------------\n"  -- Ajouter un séparateur après la zone
  created_zones = created_zones .. polyData
  SaveResourceFile(GetCurrentResourceName(), fileName, created_zones, -1)
end)

RegisterNetEvent("polyzone:printCircle")
AddEventHandler("polyzone:printCircle", function(zone)
  local fileName = "polyzone_created_zones.txt"
  local created_zones = LoadResourceFile(GetCurrentResourceName(), fileName) or ""
  local formattedDate = os.date("%Y-%m-%dT%H:%M:%S")
  local header = "-- Name: " .. zone.name .. " | " .. formattedDate
  local center = "vector3(" .. zone.center.x .. ", " .. zone.center.y .. ", " .. zone.center.z .. ")"
  local radius = zone.radius or 0
  local options = {
    "name = \"" .. zone.name .. "\"",
    "useZ = " .. (zone.useZ ~= nil and tostring(zone.useZ) or "true"),
    "--debugPoly = true"
  }
  local options_str = table.concat(options, ",\n  ")
  local circleData = header .. "\n" ..
  "CircleZone:Create(" .. center .. ", " .. radius .. ", {\n" ..
  "  " .. options_str .. "\n" ..
  "})\n" ..
  "---------------------------------------------------------\n"  -- Ajouter un séparateur après la zone
  created_zones = created_zones .. circleData
  SaveResourceFile(GetCurrentResourceName(), fileName, created_zones, -1)
end)

RegisterNetEvent("polyzone:printBox")
AddEventHandler("polyzone:printBox", function(zone)
  local fileName = "polyzone_created_zones.txt"
  local created_zones = LoadResourceFile(GetCurrentResourceName(), fileName) or ""
  local formattedDate = os.date("%Y-%m-%dT%H:%M:%S")
  local header = "-- Name: " .. zone.name .. " | " .. formattedDate
  local minZ = zone.minZ
  local maxZ = zone.maxZ
  local minZ_str = minZ and "minZ = " .. minZ or "--minZ = aucun,"
  local maxZ_str = maxZ and "maxZ = " .. maxZ or "--maxZ = aucun,"
  local boxData = header .. "\n" ..
  "BoxZone:Create(vector3(" .. zone.center.x .. ", " .. zone.center.y .. ", " .. zone.center.z .. "), " ..
  zone.length .. ", " .. zone.width .. ", {\n" ..
  "  name = \"" .. zone.name .. "\",\n" ..
  "  heading = " .. zone.heading .. ",\n" ..
  "  " .. minZ_str .. "\n" ..
  "  " .. maxZ_str .. "\n" ..
  "})\n" ..
  "---------------------------------------------------------\n"  -- Ajouter un séparateur après la zone
  created_zones = created_zones .. boxData
  SaveResourceFile(GetCurrentResourceName(), fileName, created_zones, -1)
end)
