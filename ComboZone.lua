ComboZone = {}

local function _areInsideZonesTablesEqual(tblA, tblB)
  if tblA == nil or tblB == nil or #tblA ~= #tblB then
    return false
  end
  for i=1, #tblA do
    local a = tblA[i]
    local b = tblB[i]
    if a ~= nil and b ~= nil and a.id ~= b.id then
      return false
    end
  end
  return true
end

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
      zone:draw()
      Citizen.Wait(0)
    end
  end)
end

function ComboZone:new(zones, options)
  options = options or {}
  -- Add a unique id for each zone in the ComboZone
  for i=1, #zones do
    local zone = zones[i]
    if zone then
      zone.id = i
    end
  end
  local zone = {
    name = tostring(options.name) or nil,
    zones = zones,
    debugPoly = options.debugPoly or false,
    data = options.data or {}
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

function ComboZone:isPointInside(point)
  if self.destroyed then
    print("[PolyZone] Warning: Called isPointInside on destroyed zone {name=" .. self.name .. "}")
    return false, {}
  end

  local zones = self.zones
  for i=1, #zones do
    local zone = zones[i]
    if zone and zone:isPointInside(point) then
      return true, zone
    end
  end
  return false, nil
end

function ComboZone:isPointInsideExhaustive(point)
  if self.destroyed then
    print("[PolyZone] Warning: Called isPointInside on destroyed zone {name=" .. self.name .. "}")
    return false, {}
  end

  local insideZones = {}
  local zones = self.zones
  for i=1, #zones do
    local zone = zones[i]
    if zone and zone:isPointInside(point) then
      insideZones[#insideZones+1] = zone
    end
  end
  return #insideZones ~= 0, insideZones
end

function ComboZone:destroy()
  PolyZone.destroy(self)
  local zones = self.zones
  for i=1, #zones do
    local zone = zones[i]
    if zone and not zone.destroyed then
      zone:destroy()
    end
  end
end

function ComboZone:onPointInOut(getPointCb, onPointInOutCb, waitInMS)
  -- Localize the waitInMS value for performance reasons (default of 500 ms)
  local _waitInMS = 500
  if waitInMS ~= nil then _waitInMS = waitInMS end

  Citizen.CreateThread(function()
    local isInside = nil
    local insideZone = nil
    while not self.destroyed do
      if not self.paused then
        local point = getPointCb()
        local newIsInside, newInsideZone = self:isPointInside(point)
        if newIsInside ~= isInside then
          onPointInOutCb(newIsInside, point, newInsideZone or insideZone)
          isInside = newIsInside
          insideZone = newInsideZone
        end
      end
      Citizen.Wait(_waitInMS)
    end
  end)
end

function ComboZone:onPointInOutExhaustive(getPointCb, onPointInOutCb, waitInMS)
  -- Localize the waitInMS value for performance reasons (default of 500 ms)
  local _waitInMS = 500
  if waitInMS ~= nil then _waitInMS = waitInMS end

  Citizen.CreateThread(function()
    local isInside = nil
    local insideZones = {}
    while not self.destroyed do
      if not self.paused then
        local point = getPointCb()
        local newIsInside, newInsideZones = self:isPointInsideExhaustive(point)
        if newIsInside ~= isInside or not _areInsideZonesTablesEqual(insideZones, newInsideZones)  then
          onPointInOutCb(newIsInside, point, newInsideZones)
          isInside = newIsInside
          insideZones = newInsideZones
        end
      end
      Citizen.Wait(_waitInMS)
    end
  end)
end

function ComboZone:onPlayerInOut(onPointInOutCb, waitInMS)
  self:onPointInOut(PolyZone.getPlayerPosition, onPointInOutCb, waitInMS)
end

function ComboZone:onPlayerInOutExhaustive(onPointInOutCb, waitInMS)
  self:onPointInOutExhaustive(PolyZone.getPlayerPosition, onPointInOutCb, waitInMS)
end

function ComboZone:setPaused(paused)
  self.paused = paused
end

function ComboZone:isPaused()
  return self.paused
end
