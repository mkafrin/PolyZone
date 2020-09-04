local mapMinX, mapMinY, mapMaxX, mapMaxY = -3700, -4400, 4500, 8000
local xDivisions = 34
local yDivisions = 50
local xDelta = (mapMaxX - mapMinX) / xDivisions
local yDelta = (mapMaxY - mapMinY) / yDivisions

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

local function _circleRectCollide(circleX, circleY, radius, rectX, rectY, rectWidth, rectLength)
  -- temporary variables to set edges for testing
  local testX = circleX
  local testY = circleY

  -- which edge is closest?
  if circleX < rectX then testX = rectX      					                    -- test left edge
  elseif circleX > rectX + rectWidth then testX = rectX + rectWidth end   -- right edge
  if circleY < rectY then testY = rectY     		                          -- top edge
  elseif circleY > rectY + rectLength then testY = rectY + rectLength end -- bottom edge

  -- get distance from closest edges
  local distX = circleX - testX
  local distY = circleY - testY

	return distX * distX + distY * distY < radius * radius
end

local function _addZoneToRows(rows, zone)
  local radius = zone.radius or zone.boundingRadius
  local minY = (zone.center.y - radius - mapMinY) // yDelta
  local maxY = (zone.center.y + radius - mapMinY) // yDelta
  for i=minY, maxY do
    local row = rows[i] or {}
    row[#row+1] = zone
    rows[i] = row
  end
end

local function _zonesInGridCell(x, y, zones)
  local zonesInCell = {}
  local startX = mapMinX + xDelta * x
  local startY = mapMinY + yDelta * y
  for _, zone in ipairs(zones) do
    -- For each zone, append to zonesInCell IF it is inside the grid cell at x,y
    local zoneCenter = zone.center
    local radius = zone.radius or zone.boundingRadius
    if _circleRectCollide(zoneCenter.x, zoneCenter.y, radius, startX, startY, xDelta, yDelta) then
      zonesInCell[#zonesInCell+1] = zone
    end
  end
  return zonesInCell
end

local function _getGridCell(pos)
  local x = (pos.x - mapMinX) // xDelta
  local y = (pos.y - mapMinY) // yDelta
  return x, y
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
  local rows = {}
  -- Add a unique id for each zone in the ComboZone and add to rows cache
  for i=1, #zones do
    local zone = zones[i]
    if zone then
      zone.id = i
    end
    _addZoneToRows(rows, zone)
  end

  local useGrid = options.useGrid
  if useGrid == nil and #zones >= 25 then
    useGrid = true
  end
  local zone = {
    name = tostring(options.name) or nil,
    zones = zones,
    useGrid = useGrid,
    rows = rows,
    grid = {},
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

function ComboZone:getZones(point)
  if not self.useGrid then
    return self.zones
  end
  
  local grid = self.grid
  local gridX, gridY = _getGridCell(point)
  local row = grid[gridY]
  if row == nil then
    row = {}
  end
  if row[gridX] == nil then
    local zonesInCell = _zonesInGridCell(gridX, gridY, self.rows[gridY])
    row[gridX] = zonesInCell
    grid[gridY] = row
  end
  return grid[gridY][gridX]
end

function ComboZone:AddZone(zone)
  local zones = self.zones
  local newIndex = #zones+1
  zone.id = newIndex
  zones[newIndex] = zone
  self.grid = {}
  _addZoneToRows(self.rows, zone)
  if self.useGrid == nil and newIndex >= 25 then
    self.useGrid = true
  end
end

function ComboZone:isPointInside(point)
  if self.destroyed then
    print("[PolyZone] Warning: Called isPointInside on destroyed zone {name=" .. self.name .. "}")
    return false, {}
  end

  local zones = self:getZones(point)
  if #zones == 0 then return false end

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

  local zones = self:getZones(point)
  if #zones == 0 then return false end
  local insideZones = {}
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
