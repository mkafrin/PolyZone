ComboZone = {}

function ComboZone:draw()
  local zones = self.zones
  for i=1, #zones do
    local zone = zones[i]
    if zone and not zone.destroyed then
      zone:draw()
    end
  end
end


local function _initDebug(zone, options)
  if not options.debugPoly then
    return
  end
  
  Citizen.CreateThread(function()
    while not zone.destroyed do
      local zones = zone.zones
      for i=1, #zones do
        local zoneToDraw = zones[i]
        if zoneToDraw then
          zoneToDraw:draw()
        end
      end
      Citizen.Wait(0)
    end
  end)
end

function ComboZone:new(zones, options)
  options = options or {}
  local zone = {
    name = tostring(options.name) or nil,
    zones = zones,
    debugPoly = options.debugPoly or false,
  }
  setmetatable(zone, self)
  self.__index = self
  return zone
end

function ComboZone:Create(zones, options)
  local zone = ComboZone:new(zones, options)
  _initDebug(zone, options)
  return zone
end

function ComboZone:isPointInside(point, exhaustive)
  if self.destroyed then
    print("[PolyZone] Warning: Called isPointInside on destroyed zone {name=" .. self.name .. "}")
    return false, {}
  end

  local isInside = false
  local insideZones = {}
  local zones = self.zones
  for i=1, #zones do
    local zone = zones[i]
    if zone and zone:isPointInside(point) then
      isInside = true
      insideZones[#insideZones+1] = zone
      if not exhaustive then
        break
      end
    end
  end
  return isInside, insideZones
end

function ComboZone:destroy()
  self.destroyed = true
  local zones = self.zones
  for i=1, #zones do
    local zone = zones[i]
    if zone and not zone.destroyed then
      zone:destroy()
    end
  end
end

function ComboZone:onPointInOut(getPointCb, onPointInOutCb, waitInMS, exhaustive)
  -- Localize the waitInMS value for performance reasons (default of 500 ms)
  local _waitInMS = 500
  if waitInMS ~= nil then _waitInMS = waitInMS end

  Citizen.CreateThread(function()
    local isInside = nil
    local insideZonesCount = 0
    while not self.destroyed do
      local point = getPointCb()
      local newIsInside, insideZones = self:isPointInside(point, exhaustive)
      local newInsideZonesCount = #insideZones
      if newIsInside ~= isInside or newInsideZonesCount ~= insideZonesCount then
        onPointInOutCb(newIsInside, point, insideZones)
        isInside = newIsInside
        insideZonesCount = newInsideZonesCount
      end
      Citizen.Wait(_waitInMS)
    end
  end)
end
