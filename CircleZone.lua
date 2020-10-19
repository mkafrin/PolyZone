CircleZone = {}
-- Inherits from PolyZone
setmetatable(CircleZone, { __index = PolyZone })

local cylinderDrawOverlapFactor = 0.75

function CircleZone:draw()
  local center = self.center
  local debugColor = self.debugColor
  local r, g, b = debugColor[1], debugColor[2], debugColor[3]
  if self.useZ then
    local radius = self.radius
    DrawMarker(28, center.x, center.y, center.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius, radius, radius, r, g, b, 48, false, false, 2, nil, nil, false)
  else
    local diameter = self.diameter
    local minZ, maxZ = self.minZ, self.maxZ
    local z = minZ ~= nil and minZ or -200.0
    local height = (minZ ~= nil and maxZ ~= nil) and (maxZ - minZ) or 400.0
    local overlapHeight = height * cylinderDrawOverlapFactor
    DrawMarker(1, center.x, center.y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, diameter, diameter, overlapHeight, r, g, b, 96, false, false, 2, nil, nil, false)
    DrawMarker(1, center.x, center.y, z + height, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, diameter, diameter, -overlapHeight, r, g, b, 96, false, false, 2, nil, nil, false)
  end
end


local function _initDebug(zone, options)
  if options.debugBlip then zone:addDebugBlip() end
  if not options.debugPoly then
    return
  end
  
  Citizen.CreateThread(function()
    while not zone.destroyed do
      zone:draw()
      Citizen.Wait(0)
    end
  end)
end

function CircleZone:new(center, radius, options)
  options = options or {}
  local zone = {
    name = tostring(options.name) or nil,
    center = center,
    radius = radius + 0.0,
    diameter = radius * 2.0,
    useZ = options.useZ or false,
    minZ = tonumber(options.minZ) or nil,
    maxZ = tonumber(options.maxZ) or nil,
    debugPoly = options.debugPoly or false,
    debugColor = options.debugColor or {0, 255, 0},
    data = options.data or {},
    isCircleZone = true,
  }
  if zone.useZ then
    assert(type(zone.center) == "vector3", "Center must be vector3 if useZ is true {center=" .. center .. "}")
  end
  setmetatable(zone, self)
  self.__index = self
  return zone
end

function CircleZone:Create(center, radius, options)
  local zone = CircleZone:new(center, radius, options)
  _initDebug(zone, options)
  return zone
end

function CircleZone:isPointInside(point)
  if self.destroyed then
    print("[PolyZone] Warning: Called isPointInside on destroyed zone {name=" .. self.name .. "}")
    return false
  end

  local minZ, maxZ = self.minZ, self.maxZ
  local center = self.center
  local radius = self.radius

  if self.useZ then
    return #(point - center) < radius
  elseif minZ and maxZ then
    local z = point.z
    return z >= minZ and z <= maxZ and #(point.xy - center.xy) < radius
  else
    return #(point.xy - center.xy) < radius
  end
end

function CircleZone:getRadius()
  return self.radius
end

function CircleZone:setRadius(radius)
  if not radius or radius == self.radius then
    return
  end
  self.radius = radius
  self.diameter = radius * 2.0
end

function CircleZone:getCenter()
  return self.center
end

function CircleZone:setCenter(center)
  if not center or center == self.center then
    return
  end
  self.center = center
end
