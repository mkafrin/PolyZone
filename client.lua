PolyZone = {}

local function _drawPoly(shape, opt)
  opt = opt or {}
  local zDrawDist = 75.0
  local plyPed = PlayerPedId()
  local plyPos = GetEntityCoords(plyPed)
  local minZ = shape.minZ or plyPos.z - zDrawDist
  local maxZ = shape.maxZ or plyPos.z + zDrawDist
  for i=1, #shape.points do
    DrawLine(shape.points[i].x, shape.points[i].y, minZ, shape.points[i].x, shape.points[i].y, maxZ, 255, 0, 0, 255)
    if i < #shape.points then
      for j = minZ, maxZ, opt.lineSepDist or 5.0 do
        DrawLine(shape.points[i].x, shape.points[i].y, j, shape.points[i+1].x, shape.points[i+1].y, j, 0, 255, 0, 255)
      end
    end
  end

  if #shape.points > 2 then
    for j = minZ, maxZ, opt.lineSepDist or 5.0 do
      DrawLine(shape.points[#shape.points].x, shape.points[#shape.points].y, j, shape.points[1].x, shape.points[1].y, j, 0, 255, 0, 255)
    end
  end
end


function PolyZone.draw(shape, opt)
  _drawPoly(shape, opt)
end

-- Debug drawing all grid cells that are completly within the polygon
local function _drawGrid(poly)
  local minZ = poly.minZ
  local maxZ = poly.maxZ
  if not minZ or not maxZ then
    local plyPed = PlayerPedId()
    local plyPos = GetEntityCoords(plyPed)
    local zBool, zGround = GetGroundZFor_3dCoord(plyPos.x, plyPos.y, plyPos.z, 1)
    if zBool then
      minZ = zGround
      maxZ = zGround + 50.0
    else
      minZ = plyPos.z - 75.0
      maxZ = plyPos.z + 75.0
    end
  end

  local gridCellsInsidePoly = poly.gridCellsInsidePoly
  for i=1,#gridCellsInsidePoly do
    local shape = gridCellsInsidePoly[i]
    shape.minZ = minZ
    shape.maxZ = maxZ
    _drawPoly(shape, {lineSepDist = 0.0})
  end
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


local function _pointInPoly(point, poly)
  local minZ = poly.minZ
  local maxZ = poly.maxZ
  if minZ and maxZ and (point.z < minZ or point.z > maxZ) then
    return false
  end

  local x = point.x
  local y = point.y
  local min = poly.min
  local max = poly.max

  -- Checks if point is within the bounding circle of the polygon before proceeding
  if x < min.x or
     x > max.x or
     y < min.y or
     y > max.y then
      return false
  end

  -- Returns true if the grid cell associated with the point is entirely inside the poly
  if poly.useGrid then
    local gridDivisions = poly.gridDivisions
    local size = poly.size
    local gridPosX = x - min.x
    local gridPosY = y - min.y
    local gridCellX = (gridPosX * gridDivisions) // size.x
    local gridCellY = (gridPosY * gridDivisions) // size.y
    if (poly.grid[gridCellY + 1][gridCellX + 1]) then return true end
  end

  return _windingNumber(point, poly.points)
end

-- Detects intersection between two lines
local function _isIntersecting(a, b, c, d)
  local denominator = ((b.x - a.x) * (d.y - c.y)) - ((b.y - a.y) * (d.x - c.x))
  local numerator1 = ((a.y - c.y) * (d.x - c.x)) - ((a.x - c.x) * (d.y - c.y))
  local numerator2 = ((a.y - c.y) * (b.x - a.x)) - ((a.x - c.x) * (b.y - a.y))

  -- Detect coincident lines
  if denominator == 0 then return numerator1 == 0 and numerator2 == 0 end

  local r = numerator1 / denominator
  local s = numerator2 / denominator

  return (r >= 0 and r <= 1) and (s >= 0 and s <= 1)
end


-- Calculates the points of the rectangle that make up the grid cell at grid position (cellX, cellY)
local function _calculateGridCellPoints(cellX, cellY, poly)
  local gridCellWidth = poly.size.x / poly.gridDivisions
  local gridCellHeight = poly.size.y / poly.gridDivisions
  local x = cellX * gridCellWidth
  local y = cellY * gridCellHeight
  -- poly.min must be added to all the points, in order to shift the grid cell to poly's starting position
  return {
    vector2(x, y) + poly.min,
    vector2(x + gridCellWidth, y) + poly.min,
    vector2(x + gridCellWidth, y + gridCellHeight) + poly.min,
    vector2(x, y + gridCellHeight) + poly.min,
    vector2(x, y) + poly.min
  }
end


local function _isGridCellInsidePoly(cellX, cellY, poly)
  gridCellPoints = _calculateGridCellPoints(cellX, cellY, poly)
  local polyPoints = {table.unpack(poly.points)}
  -- Connect the polygon to its starting point
  polyPoints[#polyPoints + 1] = polyPoints[1]

  -- If none of the points of the grid cell are in the polygon, the grid cell can't be in it
  local isOnePointInPoly = false
  for i=1, #gridCellPoints do
    if _windingNumber(gridCellPoints[i], poly.points) then
      isOnePointInPoly = true
      break
    end
  end
  if isOnePointInPoly == false then
    return false
  end

  -- If any of the grid cell's lines intersects with any of the polygon's lines
  -- then the grid cell is not completely within the poly
  for i=1, #polyPoints - 1 do
    for j=1, #gridCellPoints - 1 do
      if _isIntersecting(polyPoints[i], polyPoints[i+1], gridCellPoints[j], gridCellPoints[j+1]) then
        return false
      end
    end
  end
  if poly.gridCellsInsidePoly then
    poly.gridCellsInsidePoly[#poly.gridCellsInsidePoly + 1] = {points = gridCellPoints}
  end
  return true
end


-- Calculate for each grid cell whether it is entirely inside the polygon, and store if true
local function _createGrid(shape)
  local isInside = {};
  local gridCellWidth = shape.size.x / shape.gridDivisions
  local gridCellHeight = shape.size.y / shape.gridDivisions
  for y=1, shape.gridDivisions do
    isInside[y] = {}
    for x=1, shape.gridDivisions do
      if _isGridCellInsidePoly(x-1, y-1, shape) then
        shape.gridArea = shape.gridArea + gridCellWidth * gridCellHeight
        isInside[y][x] = true
      end
    end
  end
  return isInside
end


-- https://rosettacode.org/wiki/Shoelace_formula_for_polygonal_area#Lua
function _calculatePolygonArea(ps)
  local function det2(i,j)
    return ps[i].x*ps[j].y-ps[j].x*ps[i].y
  end
  local sum = #ps>2 and det2(#ps,1) or 0
  for i=1,#ps-1 do sum = sum + det2(i,i+1)end
  return math.abs(0.5 * sum)
end


local function _calculateShape(shape, options)
  local totalX = 0.0
  local totalY = 0.0
  local maxX
  local maxY
  local minX
  local minY
  for i, p in ipairs(shape.points) do
    if not maxX or p.x > maxX then
      maxX = p.x
    end
    if not maxY or p.y > maxY then
      maxY = p.y
    end
    if not minX or p.x < minX then
      minX = p.x
    end
    if not minY or p.y < minY then
      minY = p.y
    end

    totalX = totalX + p.x
    totalY = totalY + p.y
  end

  shape.max = vector2(maxX, maxY)
  shape.min = vector2(minX, minY)
  shape.size = shape.max - shape.min
  shape.center = (shape.max + shape.min) / 2
  shape.area = _calculatePolygonArea(shape.points)
  if shape.useGrid then
    shape.grid = _createGrid(shape)
    shape.gridCoverage = shape.gridArea / shape.area;
    print(shape.gridCoverage)
  end
end


function _initDebug(shape, options)
  if options.debugPoly then
    Citizen.CreateThread(function()
      while true do
        _drawPoly(shape)
        Citizen.Wait(0)
      end
    end)
  end
  if options.debugGrid and shape.useGrid then
    Citizen.CreateThread(function()
      while true do
        _drawGrid(shape)
        Citizen.Wait(0)
      end
    end)
  end
end


function PolyZone:Create(points, options)
  if not points or #points <= 2 then
    return
  end

  options = options or {}
  local shape = {
    name = tostring(options.name) or nil,
    points = points,
    center = vector2(0, 0),
    size = vector2(0, 0),
    max = vector2(0, 0),
    min = vector2(0, 0),
    minZ = tonumber(options.minZ) or nil,
    maxZ = tonumber(options.maxZ) or nil,
    useGrid = options.useGrid or true,
    gridDivisions = tonumber(options.gridDivisions) or 30,
    gridCellsInsidePoly = (options.debugGrid and shape.useGrid) and {} or nil,
    gridArea = 0.0
  }
  _calculateShape(shape, options)
  _initDebug(shape, options)
  setmetatable(shape, self)
  self.__index = self
  return shape
end

function PolyZone:isInside(point)
  return _pointInPoly(point, self)
end
