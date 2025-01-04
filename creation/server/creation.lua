local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function printoutHeader(name)
  return "--Name: " .. name .. " | " .. os.date("!%Y-%m-%dT%H:%M:%SZ\n")
end

function parsePoly(zone)
  if Config.ConfigFormatEnabled then
    local printout = printoutHeader(zone.name)
    printout = printout .. "points = {\n"
    for i = 1, #zone.points do
      if i ~= #zone.points then
        printout = printout .. "  vector2(" .. tostring(zone.points[i].x) .. ", " .. tostring(zone.points[i].y) .."),\n"
      else
        printout = printout .. "  vector2(" .. tostring(zone.points[i].x) .. ", " .. tostring(zone.points[i].y) ..")\n"
      end
    end
    printout = printout .. "},\nname = \"" .. zone.name .. "\",\n--minZ = " .. zone.minZ .. ",\n--maxZ = " .. zone.maxZ .. ",\n--debugPoly = true\n"
    return printout
  else
    local printout = printoutHeader(zone.name)
    printout = printout .. "PolyZone:Create({\n"
    for i = 1, #zone.points do
      if i ~= #zone.points then
        printout = printout .. "  vector2(" .. tostring(zone.points[i].x) .. ", " .. tostring(zone.points[i].y) .."),\n"
      else
        printout = printout .. "  vector2(" .. tostring(zone.points[i].x) .. ", " .. tostring(zone.points[i].y) ..")\n"
      end
    end
    printout = printout .. "}, {\n  name = \"" .. zone.name .. "\",\n  --minZ = " .. zone.minZ .. ",\n  --maxZ = " .. zone.maxZ .. "\n})\n"
    return printout
  end
end

function parseCircle(zone)
  if Config.ConfigFormatEnabled then
    local printout = printoutHeader(zone.name)
    printout = printout .. "coords = "
    printout = printout .. "vector3(" .. tostring(round(zone.center.x, 2)) .. ", " .. tostring(round(zone.center.y, 2))  .. ", " .. tostring(round(zone.center.z, 2)) .."),\n"
    printout = printout .. "radius = " .. tostring(zone.radius) .. ",\n"
    printout = printout .. "name = \"" .. zone.name .. "\",\nuseZ = " .. tostring(zone.useZ) .. ",\n--debugPoly = true\n"
    return printout
  else
    local printout = printoutHeader(zone.name)
    printout = printout .. "CircleZone:Create("
    printout = printout .. "vector3(" .. tostring(round(zone.center.x, 2)) .. ", " .. tostring(round(zone.center.y, 2))  .. ", " .. tostring(round(zone.center.z, 2)) .."), "
    printout = printout .. tostring(zone.radius) .. ", "
    printout = printout .. "{\n  name = \"" .. zone.name .. "\",\n  useZ = " .. tostring(zone.useZ) .. ",\n  --debugPoly = true\n})\n"
    return printout
  end
end

function parseBox(zone)
  if Config.ConfigFormatEnabled then
    local printout = printoutHeader(zone.name)
    printout = printout .. "coords = "
    printout = printout .. "vector3(" .. tostring(round(zone.center.x, 2)) .. ", " .. tostring(round(zone.center.y, 2))  .. ", " .. tostring(round(zone.center.z, 2)) .."),\n"
    printout = printout .. "length = " .. tostring(zone.length) .. ",\n"
    printout = printout .. "width = " .. tostring(zone.width) .. ",\n"
    printout = printout .. "name = \"" .. zone.name .. "\",\nheading = " .. zone.heading .. ",\n--debugPoly = true"
    if zone.minZ then
      printout = printout .. ",\nminZ = " .. tostring(round(zone.minZ, 2))
    end
    if zone.maxZ then
      printout = printout .. ",\nmaxZ = " .. tostring(round(zone.maxZ, 2))
    end
    printout = printout .. "\n"
    return printout
  else
    local printout = printoutHeader(zone.name)
    printout = printout .. "BoxZone:Create("
    printout = printout .. "vector3(" .. tostring(round(zone.center.x, 2)) .. ", " .. tostring(round(zone.center.y, 2))  .. ", " .. tostring(round(zone.center.z, 2)) .."), "
    printout = printout .. tostring(zone.length) .. ", "
    printout = printout .. tostring(zone.width) .. ", "
    printout = printout .. "{\n  name = \"" .. zone.name .. "\",\n  heading = " .. zone.heading .. ",\n  --debugPoly = true"
    if zone.minZ then
      printout = printout .. ",\n  minZ = " .. tostring(round(zone.minZ, 2))
    end
    if zone.maxZ then
      printout = printout .. ",\n  maxZ = " .. tostring(round(zone.maxZ, 2))
    end
    printout = printout .. "\n})\n"
    return printout
  end
end

local function writeFile(path, data)
  local file = io.open(path, "a+")
  if not file then
    return
  end
  file:write(data)
  file:write("\n")
  file:close()
end

RegisterNetEvent("polyzone:printPoly")
AddEventHandler("polyzone:printPoly", function(zone)
  local output = parsePoly(zone)
  writeFile("polyzone_created_zones.txt", output)
end)

RegisterNetEvent("polyzone:printCircle")
AddEventHandler("polyzone:printCircle", function(zone)
  local output = parseCircle(zone)
  writeFile("polyzone_created_zones.txt", output)
end)

RegisterNetEvent("polyzone:printBox")
AddEventHandler("polyzone:printBox", function(zone)
  local output = parseBox(zone)
  writeFile("polyzone_created_zones.txt", output)
end)