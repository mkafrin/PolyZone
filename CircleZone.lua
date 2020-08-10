CircleZone = {}

function CircleZone:draw()
  local center = self.center
  local debugColor = self.debugColor
  local r, g, b = debugColor[1], debugColor[2], debugColor[3]
  if self.useZ then
    local radius = self.radius
    DrawMarker(28, center.x, center.y, center.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius, radius, radius, r, g, b, 48, false, false, 2, nil, nil, false)
  else
    local diameter = self.diameter
    DrawMarker(1, center.x, center.y, -200.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, diameter, diameter, 400.0, r, g, b, 96, false, false, 2, nil, nil, false)
  end
end


local function _initDebug(zone, options)
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
    radius = radius,
    diameter = radius * 2,
    useZ = options.useZ or false,
    debugPoly = options.debugPoly or false,
    debugColor = options.debugColor or {0, 255, 0}
  }
  if zone.useZ then
    assert(type(zone.center) == "vector3", "Center must be vector3 if useZ is true {center=" .. center .. "}")
  end
  if not zone.useZ then
    zone.center = zone.center.xy
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

  local center = self.center
  local radius = self.radius

  if self.useZ then
    return #(point - center) < radius
  else
    return #(point.xy - center) < radius
  end
end

function CircleZone:destroy()
  PolyZone.destroy(self)
end

function CircleZone:onPointInOut(getPointCb, onPointInOutCb, waitInMS)
  PolyZone.onPointInOut(self, getPointCb, onPointInOutCb, waitInMS)
end
