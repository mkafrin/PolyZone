PolyZone = {}

local function _isLeft(p0, p1, p2)
  return ((p1.x - p0.x) * (p2.y - p0.y)) - ((p2.x - p0.x) * (p1.y - p0.y))
end

local function _wn_inner_loop(p0, p1, p2, wn)
  if (p0.y <= p2.y) then
    if (p1.y > p2.y) then
      if (_isLeft(p0, p1, p2) > 0) then
        return wn + 1
      end
    end
  else
    if (p1.y <= p2.y) then
      if (_isLeft(p0, p1, p2) < 0) then
        return wn - 1
      end
    end
  end
  return wn
end

-- Winding Number Algorithm - http://geomalgorithms.com/a03-_inclusion.html
local function _pointInPoly(point, poly)
  if poly.minZ and poly.maxZ and (point.z < poly.minZ or point.z >= poly.maxZ) then
    return false
  end

  -- Checks if point is within the bounding circle of the polygon before proceeding
  if (point.x > poly.min.x and 
      point.x < poly.max.x and
      point.y > poly.min.y and
      point.y < poly.max.y) == false then
    return false
  end

  poly = poly.points
  local n = #poly
  local wn = 0 -- winding number counter

  -- loop through all edges of the polygon
  for i = 1, n - 1 do
    wn = _wn_inner_loop(poly[i], poly[i + 1], point, wn)
  end
  -- test last point to first point, completing the polygon
  wn = _wn_inner_loop(poly[#poly], poly[1], point, wn)

  -- the point is outside only when this winding number wn===0, otherwise it's inside
  return wn ~= 0
end

local function _calculateShape(shape)
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
    maxZ = tonumber(options.maxZ) or nil
  }
  _calculateShape(shape)
  setmetatable(shape, self)
  self.__index = self

  return shape
end

function PolyZone:isInside(point)
  return _pointInPoly(point, self)
end
