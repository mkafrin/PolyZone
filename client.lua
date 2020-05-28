PolyZone = {}

-- Utility functions
local rad, cos, sin, deg, abs, atan2 = math.rad, math.cos, math.sin, math.deg, math.abs, math.atan2
local function rotate(origin, point, theta)
  if theta == 0.0 then return point end

  local p = point - origin
  theta = rad(theta)
  local cosTheta = cos(theta)
  local sinTheta = sin(theta)
  local x = p.x * cosTheta - p.y * sinTheta
  local y = p.x * sinTheta + p.y * cosTheta
  return vector2(x, y) + origin
end

local function GetRotation(entity)
  local fwdVector = GetEntityForwardVector(entity)
  return deg(atan2(fwdVector.y, fwdVector.x))
end

local function _isLeft(p0, p1, p2)
  local p0x = p0.x
  local p0y = p0.y
  return ((p1.x - p0x) * (p2.y - p0y)) - ((p2.x - p0x) * (p1.y - p0y))
end

local function _wn_inner_loop(p0, p1, p2, wn)
  local p2y = p2.y
  if (p0.y <= p2y) then
    if (p1.y > p2y) then
      if (_isLeft(p0, p1, p2) > 0) then
        return wn + 1
      end
    end
  else
    if (p1.y <= p2y) then
      if (_isLeft(p0, p1, p2) < 0) then
        return wn - 1
      end
    end
  end
  return wn
end

-- Winding Number Algorithm - http://geomalgorithms.com/a03-_inclusion.html
local function _windingNumber(point, poly)
  local wn = 0 -- winding number counter

  -- loop through all edges of the polygon
  for i = 1, #poly - 1 do
    wn = _wn_inner_loop(poly[i], poly[i + 1], point, wn)
  end
  -- test last point to first point, completing the polygon
  wn = _wn_inner_loop(poly[#poly], poly[1], point, wn)

  -- the point is outside only when this winding number wn===0, otherwise it's inside
  return wn ~= 0
end

-- Detects intersection between two lines
local function _isIntersecting(a, b, c, d)
  -- Store calculations in local variables for performance
  local ax_minus_cx = a.x - c.x
  local bx_minus_ax = b.x - a.x
  local dx_minus_cx = d.x - c.x
  local ay_minus_cy = a.y - c.y
  local by_minus_ay = b.y - a.y
  local dy_minus_cy = d.y - c.y
  local denominator = ((bx_minus_ax) * (dy_minus_cy)) - ((by_minus_ay) * (dx_minus_cx))
  local numerator1 = ((ay_minus_cy) * (dx_minus_cx)) - ((ax_minus_cx) * (dy_minus_cy))
  local numerator2 = ((ay_minus_cy) * (bx_minus_ax)) - ((ax_minus_cx) * (by_minus_ay))

  -- Detect coincident lines
  if denominator == 0 then return numerator1 == 0 and numerator2 == 0 end

  local r = numerator1 / denominator
  local s = numerator2 / denominator

  return (r >= 0 and r <= 1) and (s >= 0 and s <= 1)
end

-- https://rosettacode.org/wiki/Shoelace_formula_for_polygonal_area#Lua
local function _calculatePolygonArea(points)
  local function det2(i,j)
    return points[i].x*points[j].y-points[j].x*points[i].y
  end
  local sum = #points>2 and det2(#points,1) or 0
  for i=1,#points-1 do sum = sum + det2(i,i+1)end
  return abs(0.5 * sum)
end

function _calculateMinAndMaxZ(entity, dimensions, scaleZ, offsetZ, pos)
  local min, max = dimensions[1], dimensions[2]
  local minX, minY, minZ, maxX, maxY, maxZ = min.x, min.y, min.z, max.x, max.y, max.z

  -- Bottom vertices
  local p1 = GetOffsetFromEntityInWorldCoords(entity, minX, minY, minZ).z
  local p2 = GetOffsetFromEntityInWorldCoords(entity, maxX, minY, minZ).z
  local p3 = GetOffsetFromEntityInWorldCoords(entity, maxX, maxY, minZ).z
  local p4 = GetOffsetFromEntityInWorldCoords(entity, minX, maxY, minZ).z

  -- Top vertices
  local p5 = GetOffsetFromEntityInWorldCoords(entity, minX, minY, maxZ).z
  local p6 = GetOffsetFromEntityInWorldCoords(entity, maxX, minY, maxZ).z
  local p7 = GetOffsetFromEntityInWorldCoords(entity, maxX, maxY, maxZ).z
  local p8 = GetOffsetFromEntityInWorldCoords(entity, minX, maxY, maxZ).z
  local minZ = pos.z - math.min(p1, p2, p3, p4, p5, p6, p7, p8)
  minZ = minZ * scaleZ[1] - offsetZ[1]
  local maxZ = math.max(p1, p2, p3, p4, p5, p6, p7, p8) - pos.z
  maxZ = maxZ * scaleZ[2] + offsetZ[2]
  return pos.z - minZ, pos.z + maxZ
end

function _calculateScaleAndOffset(options)
  -- Scale and offset tables are both formatted as {forward, back, left, right, up, down}
  -- or if symmetrical {forward/back, left/right, up/down}
  local scale = options.scale or {1.0, 1.0, 1.0, 1.0, 1.0, 1.0}
  local offset = options.offset or {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}
  assert(#scale == 3 or #scale == 6, "Scale must be of length 3 or 6")
  assert(#offset == 3 or #offset == 6, "Offset must be of length 3 or 6")
  if #scale == 3 then
    scale = {scale[1], scale[1], scale[2], scale[2], scale[3], scale[3]}
  end
  if #offset == 3 then
    offset = {offset[1], offset[1], offset[2], offset[2], offset[3], offset[3]}
  end
  local minOffset = vector3(offset[3], offset[2], offset[6])
  local maxOffset = vector3(offset[4], offset[1], offset[5])
  local minScale = vector3(scale[3], scale[2], scale[6])
  local maxScale = vector3(scale[4], scale[1], scale[5])
  return minOffset, maxOffset, minScale, maxScale
end


-- Debug drawing functions
local function _drawWall(p1, p2, minZ, maxZ, r, g, b, a)
  local bottomLeft = vector3(p1.x, p1.y, minZ)
  local topLeft = vector3(p1.x, p1.y, maxZ)
  local bottomRight = vector3(p2.x, p2.y, minZ)
  local topRight = vector3(p2.x, p2.y, maxZ)
  
  DrawPoly(bottomLeft,topLeft,bottomRight,r,g,b,a)
  DrawPoly(topLeft,topRight,bottomRight,r,g,b,a)
  DrawPoly(bottomRight,topRight,topLeft,r,g,b,a)
  DrawPoly(bottomRight,topLeft,bottomLeft,r,g,b,a)
end

local function _drawPoly(poly, isEntityZone)
  local zDrawDist = 45.0
  local oColor = poly.debugColors.outline
  local oR, oG, oB = oColor[1], oColor[2], oColor[3]
  local wColor = poly.debugColors.walls
  local wR, wG, wB = wColor[1], wColor[2], wColor[3]
  local plyPed = PlayerPedId()
  local plyPos = GetEntityCoords(plyPed)
  local offsetPos = poly.offsetPos
  local minZ = poly.minZ or plyPos.z - zDrawDist
  local maxZ = poly.maxZ or plyPos.z + zDrawDist
  local origin = poly.startPos
  local theta = poly.offsetRot
  
  local points = poly.points
  for i=1, #points do
    local point = points[i]
    if isEntityZone then point = rotate(origin, point, theta) + offsetPos end
    DrawLine(point.x, point.y, minZ, point.x, point.y, maxZ, oR, oG, oB, 164)

    if i < #points then
      local p2 = points[i+1]
      if isEntityZone then p2 = rotate(origin, p2, theta) + offsetPos end
      DrawLine(point.x, point.y, maxZ, p2.x, p2.y, maxZ, oR, oG, oB, 184)
      _drawWall(point, p2, minZ, maxZ, wR, wG, wB, 48)
    end
  end

  if #points > 2 then
    local firstPoint = points[1]
    if isEntityZone then firstPoint = rotate(origin, firstPoint, theta) + offsetPos end
    local lastPoint = points[#points]
    if isEntityZone then lastPoint = rotate(origin, lastPoint, theta) + offsetPos end
    DrawLine(firstPoint.x, firstPoint.y, maxZ, lastPoint.x, lastPoint.y, maxZ, oR, oG, oB, 184)
    _drawWall(firstPoint, lastPoint, minZ, maxZ, wR, wG, wB, 48)
  end
end


function PolyZone.drawPoly(poly)
  _drawPoly(poly, false)
end

-- Debug drawing all grid cells that are completly within the polygon
local function _drawGrid(poly)
  local minZ = poly.minZ
  local maxZ = poly.maxZ
  if not minZ or not maxZ then
    local plyPed = PlayerPedId()
    local plyPos = GetEntityCoords(plyPed)
    minZ = plyPos.z - 46.0
    maxZ = plyPos.z - 45.0
  end

  local lines = poly.lines
  local color = poly.debugColors.grid
  local r, g, b = color[1], color[2], color[3]
  for i=1, #lines do
    local line = lines[i]
    local min = line.min
    local max = line.max
    DrawLine(min.x + 0.0, min.y + 0.0, maxZ + 0.0, max.x + 0.0, max.y + 0.0, maxZ + 0.0, r, g, b, 196)
  end
end


local function _pointInPoly(point, poly)
  local x = point.x
  local y = point.y
  local min = poly.min
  local minX = min.x
  local minY = min.y
  local max = poly.max

  -- Checks if point is within the polygon's bounding box
  if x < minX or
     x > max.x or
     y < minY or
     y > max.y then
      return false
  end

  -- Checks if point is within the polygon's height bounds
  local minZ = poly.minZ
  local maxZ = poly.maxZ
  local z = point.z
  if (minZ and z < minZ) or (maxZ and z > maxZ) then
    return false
  end

  -- Returns true if the grid cell associated with the point is entirely inside the poly
  if poly.grid then
    local gridDivisions = poly.gridDivisions
    local size = poly.size
    local gridPosX = x - minX
    local gridPosY = y - minY
    local gridCellX = (gridPosX * gridDivisions) // size.x
    local gridCellY = (gridPosY * gridDivisions) // size.y
    if (poly.grid[gridCellY + 1][gridCellX + 1]) then return true end
  end

  return _windingNumber(point, poly.points)
end


-- Grid creation functions
-- Calculates the points of the rectangle that make up the grid cell at grid position (cellX, cellY)
local function _calculateGridCellPoints(cellX, cellY, poly)
  local gridCellWidth = poly.gridCellWidth
  local gridCellHeight = poly.gridCellHeight
  local min = poly.min
  -- min added to initial point, in order to shift the grid cells to the poly's starting position
  local x = cellX * gridCellWidth + min.x
  local y = cellY * gridCellHeight + min.y
  return {
    vector2(x, y),
    vector2(x + gridCellWidth, y),
    vector2(x + gridCellWidth, y + gridCellHeight),
    vector2(x, y + gridCellHeight),
    vector2(x, y)
  }
end


local function _isGridCellInsidePoly(cellX, cellY, poly)
  gridCellPoints = _calculateGridCellPoints(cellX, cellY, poly)
  local polyPoints = {table.unpack(poly.points)}
  -- Connect the polygon to its starting point
  polyPoints[#polyPoints + 1] = polyPoints[1]

  -- If none of the points of the grid cell are in the polygon, the grid cell can't be in it
  local isOnePointInPoly = false
  for i=1, #gridCellPoints - 1 do
    local cellPoint = gridCellPoints[i]
    local x = cellPoint.x
    local y = cellPoint.y
    if _windingNumber(cellPoint, poly.points) then
      isOnePointInPoly = true
      -- If we are drawing the grid (poly.lines ~= nil), we need to go through all the points,
      -- and therefore can't break out of the loop early
      if poly.lines then
        if not poly.gridXPoints[x] then poly.gridXPoints[x] = {} end
        if not poly.gridYPoints[y] then poly.gridYPoints[y] = {} end
        poly.gridXPoints[x][y] = true
        poly.gridYPoints[y][x] = true
      else break end
    end
  end
  if isOnePointInPoly == false then
    return false
  end

  -- If any of the grid cell's lines intersects with any of the polygon's lines
  -- then the grid cell is not completely within the poly
  for i=1, #gridCellPoints - 1 do
    local gridCellP1 = gridCellPoints[i]
    local gridCellP2 = gridCellPoints[i+1]
    for j=1, #polyPoints - 1 do
      if _isIntersecting(gridCellP1, gridCellP2, polyPoints[j], polyPoints[j+1]) then
        return false
      end
    end
  end
  
  return true
end


local function _calculateLinesForDrawingGrid(poly)
  local lines = {}
  for x, tbl in pairs(poly.gridXPoints) do
    local yValues = {}
    -- Turn dict/set of values into array
    for y, _ in pairs(tbl) do yValues[#yValues + 1] = y end
    if #yValues >= 2 then
      table.sort(yValues)
      local minY = yValues[1]
      local lastY = yValues[1]
      for i=1, #yValues do
        local y = yValues[i]
        -- Checks for breaks in the grid. If the distance between the last value and the current one
        -- is greater than the size of a grid cell, that means the line between them must go outside the polygon.
        -- Therefore, a line must be created between minY and the lastY, and a new line started at the current y
        if y - lastY > poly.gridCellHeight + 0.01 then
          lines[#lines+1] = {min=vector2(x, minY), max=vector2(x, lastY)}
          minY = y
        elseif i == #yValues then
          -- If at the last point, create a line between minY and the last point
          lines[#lines+1] = {min=vector2(x, minY), max=vector2(x, y)}
        end
        lastY = y
      end
    end
  end
  -- Setting nil to allow the GC to clear it out of memory, since we no longer need this
  poly.gridXPoints = nil

  -- Same as above, but for gridYPoints instead of gridXPoints
  for y, tbl in pairs(poly.gridYPoints) do
    local xValues = {}
    for x, _ in pairs(tbl) do xValues[#xValues + 1] = x end
    if #xValues >= 2 then
      table.sort(xValues)
      local minX = xValues[1]
      local lastX = xValues[1]
      for i=1, #xValues do
        local x = xValues[i]
        if x - lastX > poly.gridCellWidth + 0.01 then
          lines[#lines+1] = {min=vector2(minX, y), max=vector2(lastX, y)}
          minX = x
        elseif i == #xValues then
          lines[#lines+1] = {min=vector2(minX, y), max=vector2(x, y)}
        end
        lastX = x
      end
    end
  end
  poly.gridYPoints = nil
  return lines
end


-- Calculate for each grid cell whether it is entirely inside the polygon, and store if true
local function _createGrid(poly, options)
  Citizen.CreateThread(function()
    -- Calculate all grid cells that are entirely inside the polygon
    local isInside = {}
    local gridCellArea = poly.gridCellWidth * poly.gridCellHeight
    for y=1, poly.gridDivisions do
      Citizen.Wait(0)
      isInside[y] = {}
      for x=1, poly.gridDivisions do
        if _isGridCellInsidePoly(x-1, y-1, poly) then
          poly.gridArea = poly.gridArea + gridCellArea
          isInside[y][x] = true
        end
      end
    end
    poly.grid = isInside
    poly.gridCoverage = poly.gridArea / poly.area
    -- A lot of memory is used by this pre-calc. Force a gc collect after to clear it out
    collectgarbage("collect")

    if options.debugGrid then
      local coverage = string.format("%.2f", poly.gridCoverage * 100)
      print("[PolyZone] Debug: Grid Coverage at " .. coverage .. "% with " .. poly.gridDivisions
      .. " divisions. Optimal coverage for memory usage and startup time is 80-90%")

      Citizen.CreateThread(function()
        poly.lines = _calculateLinesForDrawingGrid(poly)
        -- A lot of memory is used by this pre-calc. Force a gc collect after to clear it out
        collectgarbage("collect")
      end)
    end
  end)
end


-- Initialization functions
local function _calculatePoly(poly, options)
  local minX, minY = math.maxinteger, math.maxinteger
  local maxX, maxY = math.mininteger, math.mininteger
  for _, p in ipairs(poly.points) do
    minX = math.min(minX, p.x)
    minY = math.min(minY, p.y)
    maxX = math.max(maxX, p.x)
    maxY = math.max(maxY, p.y)
  end

  poly.max = vector2(maxX, maxY)
  poly.min = vector2(minX, minY)
  poly.size = poly.max - poly.min
  poly.center = (poly.max + poly.min) / 2
  poly.area = _calculatePolygonArea(poly.points)
  if poly.useGrid then
    if options.debugGrid then
      poly.gridXPoints = {}
      poly.gridYPoints = {}
      poly.lines = {}
    end
    poly.gridArea = 0.0
    poly.gridCellWidth = poly.size.x / poly.gridDivisions
    poly.gridCellHeight = poly.size.y / poly.gridDivisions
    _createGrid(poly, options)
  else
    collectgarbage("collect")
  end
end


function _initDebug(poly, options)
  local debugEnabled = options.debugPoly or options.debugGrid
  if not debugEnabled then
    return
  end
  
  Citizen.CreateThread(function()
    local entity = poly.entity
    local isEntityZone = entity ~= nil
    while not poly.destroyed do
      if isEntityZone then UpdateOffsets(entity, poly) end
      _drawPoly(poly, isEntityZone)
      if not isEntityZone and options.debugGrid and poly.lines then
        _drawGrid(poly)
      end
      Citizen.Wait(0)
    end
  end)
end


function PolyZone:Create(points, options)
  if not points or #points <= 2 then
    return
  end

  options = options or {}
  local colors = options.debugColors or {}
  local useGrid = options.useGrid
  if useGrid == nil then useGrid = true end
  local poly = {
    name = tostring(options.name) or nil,
    points = points,
    center = vector2(0, 0),
    size = vector2(0, 0),
    max = vector2(0, 0),
    min = vector2(0, 0),
    minZ = tonumber(options.minZ) or nil,
    maxZ = tonumber(options.maxZ) or nil,
    useGrid = useGrid,
    gridDivisions = tonumber(options.gridDivisions) or 30,
    debugColors = {
      walls = colors.walls or {0, 255, 0},
      outline = colors.outline or {255, 0, 0},
      grid = colors.grid or {255, 255, 255}
    },
    debugPoly = options.debugPoly or false,
    debugGrid = options.debugGrid or false,
    startPos = vector2(0.0, 0.0),
    offsetPos = vector2(0.0, 0.0),
    offsetRot = 0.0
  }
  _calculatePoly(poly, options)
  _initDebug(poly, options)
  setmetatable(poly, self)
  self.__index = self
  return poly
end

function PolyZone:CreateAroundEntity(entity, options)
  assert(DoesEntityExist(entity), "Entity does not exist")

  local min, max = GetModelDimensions(GetEntityModel(entity))
  local dimensions = {min, max}
  local minLength = math.min(min.x, min.y, min.z)
  local maxLength = math.max(max.x, max.y, max.z)
  

  local pos = GetEntityCoords(entity)
  local minOffset, maxOffset, minScale, maxScale = _calculateScaleAndOffset(options)
  local scaleZ, offsetZ = {minScale.z, maxScale.z}, {minOffset.z, maxOffset.z}
  
  min = min * minScale - minOffset
  max = max * maxScale + maxOffset

  -- Bottom vertices
  local p1 = pos.xy + vector2(min.x, min.y)
  local p2 = pos.xy + vector2(max.x, min.y)
  local p3 = pos.xy + vector2(max.x, max.y)
  local p4 = pos.xy + vector2(min.x, max.y)
  local points = {p1, p2, p3, p4}

  if options.useZ == true then
    options.minZ, options.maxZ = _calculateMinAndMaxZ(entity, dimensions, scaleZ, offsetZ, pos)
  else
    options.minZ = nil
    options.maxZ = nil
  end

  options.useGrid = false
  local poly = PolyZone:Create(points, options)
  poly.startPos = GetEntityCoords(entity).xy
  poly.entity = entity
  poly.dimensions = dimensions
  poly.useZ = options.useZ
  poly.scaleZ, poly.offsetZ = scaleZ, offsetZ
  return poly
end

function UpdateOffsets(entity, poly)
  local pos = GetEntityCoords(entity)
  local rot = GetRotation(entity)
  poly.offsetPos = pos.xy - poly.startPos
  poly.offsetRot = rot - 90.0

  if poly.useZ then
    poly.minZ, poly.maxZ = _calculateMinAndMaxZ(entity, poly.dimensions, poly.scaleZ, poly.offsetZ, pos)
  end
end

function PolyZone:isPointInside(point)
  if self.destroyed then
    print("[PolyZone] Warning: Called isPointInside on destroyed zone {name=" .. self.name .. "}")
    return false 
  end

  local entity = self.entity
  if entity then
    UpdateOffsets(entity, self)
    local rotatedPoint = rotate(self.startPos, point.xy - self.offsetPos, -self.offsetRot)
    local pX, pY, pZ = rotatedPoint.x, rotatedPoint.y, point.z
    local min, max = self.min, self.max
    local minX, minY, maxX, maxY = min.x, min.y, max.x, max.y
    local minZ, maxZ = self.minZ, self.maxZ
    if pX < minX or pX > maxX or pY < minY or pY > maxY then
      return false
    end
    if (minZ and pZ < minZ) or (maxZ and pZ > maxZ) then
      return false
    end
    return true
  end

  return _pointInPoly(point, self)
end

function PolyZone:destroy()
  self.destroyed = true
  if self.debugPoly or self.debugGrid then
    print("[PolyZone] Debug: Destroying zone {name=" .. self.name .. "}")
  end
end


-- Helper functions
function PolyZone.getPlayerPosition()
  return GetEntityCoords(PlayerPedId())
end

local HeadBone = 0x796e;
function PolyZone.getPlayerHeadPosition()
  return GetPedBoneCoords(PlayerPedId(), HeadBone);
end

function PolyZone:onPointInOut(getPointCb, onPointInOutCb, waitInMS)
  -- Localize the waitInMS value for performance reasons (default of 500 ms)
  local _waitInMS = 500
  if waitInMS ~= nil then _waitInMS = waitInMS end

  Citizen.CreateThread(function()
    local isInside = nil
    while not self.destroyed do
      local point = getPointCb()
      local newIsInside = self:isPointInside(point)
      if newIsInside ~= isInside then
        onPointInOutCb(newIsInside, point)
        isInside = newIsInside
      end
      Citizen.Wait(_waitInMS)
    end
  end)
end

function PolyZone:onEntityDamaged(onDamagedCb)
  local entity = self.entity
  if not entity then
    print("[PolyZone] Error: Called onEntityDamage on non entity zone {name=" .. self.name .. "}")
    return
  end

  AddEventHandler('gameEventTriggered', function (name, args)
    if name == 'CEventNetworkEntityDamage' then
      local victim, attacker, victimDied, weaponHash, isMelee = args[1], args[2], args[4], args[5], args[10]
      --print(entity, victim, attacker, victimDied, weaponHash, isMelee)
      if victim ~= entity then return end
      onDamagedCb(victimDied == 1, attacker, weaponHash, isMelee == 1)
    end
  end)
end

function PolyZone:getBoundingBoxMin()
  return self.min
end

function PolyZone:getBoundingBoxMax()
  return self.max
end

function PolyZone:getBoundingBoxSize()
  return self.size
end

function PolyZone:getBoundingBoxCenter()
  return self.center
end