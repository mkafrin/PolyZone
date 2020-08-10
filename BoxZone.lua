BoxZone = {}
-- Inherits from PolyZone
setmetatable(BoxZone, { __index = PolyZone })

-- Utility functions
local rad, cos, sin = math.rad, math.cos, math.sin
function PolyZone.rotate(origin, point, theta)
  if theta == 0.0 then return point end

  local p = point - origin
  theta = rad(theta)
  local cosTheta = cos(theta)
  local sinTheta = sin(theta)
  local x = p.x * cosTheta - p.y * sinTheta
  local y = p.x * sinTheta + p.y * cosTheta
  return vector2(x, y) + origin
end

local function _calculateScaleAndOffset(options)
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
function BoxZone:TransformPoint(point)
  -- Overriding TransformPoint function to take into account rotation and position offset
  return PolyZone.rotate(self.startPos, point, self.offsetRot) + self.offsetPos
end


-- Initialization functions
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

function BoxZone:new(center, length, width, options)

  local halfLength, halfWidth = length / 2, width / 2
  local min = vector3(-halfWidth, -halfLength, 0.0)
  local max = vector3(halfWidth, halfLength, 0.0)

  local pos = center
  local minOffset, maxOffset, minScale, maxScale = _calculateScaleAndOffset(options)
  local scaleZ, offsetZ = {minScale.z, maxScale.z}, {minOffset.z, maxOffset.z}
  
  min = min * minScale - minOffset
  max = max * maxScale + maxOffset

  -- Box vertices
  local p1 = pos.xy + vector2(min.x, min.y)
  local p2 = pos.xy + vector2(max.x, min.y)
  local p3 = pos.xy + vector2(max.x, max.y)
  local p4 = pos.xy + vector2(min.x, max.y)
  local points = {p1, p2, p3, p4}

  -- Box Zones don't use the grid optimization because they are already rectangles/cubes
  options.useGrid = false
  local zone = PolyZone:new(points, options)
  zone.startPos = center.xy
  zone.offsetPos = vector2(0.0, 0.0)
  zone.offsetRot = options.heading or 0.0
  zone.scaleZ, zone.offsetZ = scaleZ, offsetZ

  setmetatable(zone, self)
  self.__index = self
  return zone
end

function BoxZone:Create(center, length, width, options)
  local zone = BoxZone:new(center, length, width, options)
  _initDebug(zone, options)
  return zone
end


-- Helper functions
function BoxZone:isPointInside(point)
  if self.destroyed then
    print("[PolyZone] Warning: Called isPointInside on destroyed zone {name=" .. self.name .. "}")
    return false 
  end

  local rotatedPoint = PolyZone.rotate(self.startPos, point.xy - self.offsetPos, -self.offsetRot)
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
