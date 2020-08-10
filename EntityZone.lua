EntityZone = {}
-- Inherits from PolyZone
setmetatable(EntityZone, { __index = PolyZone })

-- Utility functions
local rad, cos, sin, deg, atan2 = math.rad, math.cos, math.sin, math.deg, math.atan2
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

local function _calculateMinAndMaxZ(entity, dimensions, scaleZ, offsetZ, pos)
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
function EntityZone:TransformPoint(point)
  -- Overriding TransformPoint function to take into account rotation and position offset
  return rotate(self.startPos, point, self.offsetRot) + self.offsetPos
end


-- Initialization functions
local function _initDebug(zone, options)
  if not options.debugPoly then
    return
  end
  
  Citizen.CreateThread(function()
    local entity = zone.entity
    while not zone.destroyed do
      UpdateOffsets(entity, zone)
      zone:draw()
      Citizen.Wait(0)
    end
  end)
end

function EntityZone:new(entity, options)
  assert(DoesEntityExist(entity), "Entity does not exist")

  local min, max = GetModelDimensions(GetEntityModel(entity))
  local dimensions = {min, max}

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
  local zone = PolyZone:new(points, options)
  zone.startPos = GetEntityCoords(entity).xy
  zone.offsetPos = vector2(0.0, 0.0)
  zone.offsetRot = 0.0
  zone.entity = entity
  zone.dimensions = dimensions
  zone.useZ = options.useZ
  zone.scaleZ, zone.offsetZ = scaleZ, offsetZ
  zone.damageEventHandlers = {}

  setmetatable(zone, self)
  self.__index = self
  return zone
end

function EntityZone:Create(points, options)
  -- Entity Zones don't use the grid optimization because they are boxes
  options.useGrid = false
  local zone = EntityZone:new(points, options)
  _initDebug(zone, options)
  return zone
end

function UpdateOffsets(entity, zone)
  local pos = GetEntityCoords(entity)
  local rot = GetRotation(entity)
  zone.offsetPos = pos.xy - zone.startPos
  zone.offsetRot = rot - 90.0

  if zone.useZ then
    zone.minZ, zone.maxZ = _calculateMinAndMaxZ(entity, zone.dimensions, zone.scaleZ, zone.offsetZ, pos)
  end
end


-- Helper functions
function EntityZone:isPointInside(point)
  if self.destroyed then
    print("[PolyZone] Warning: Called isPointInside on destroyed zone {name=" .. self.name .. "}")
    return false 
  end

  local entity = self.entity
  if entity == nil then
    print("[PolyZone] Error: Called isPointInside on Entity zone with no entity {name=" .. self.name .. "}")
    return false
  end

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

function EntityZone:onEntityDamaged(onDamagedCb)
  local entity = self.entity
  if not entity then
    print("[PolyZone] Error: Called onEntityDamage on Entity Zone with no entity {name=" .. self.name .. "}")
    return
  end

  self.damageEventHandlers[#self.damageEventHandlers + 1] = AddEventHandler('gameEventTriggered', function (name, args)
    if self.destroyed then
      return
    end

    if name == 'CEventNetworkEntityDamage' then
      local victim, attacker, victimDied, weaponHash, isMelee = args[1], args[2], args[4], args[5], args[10]
      --print(entity, victim, attacker, victimDied, weaponHash, isMelee)
      if victim ~= entity then return end
      onDamagedCb(victimDied == 1, attacker, weaponHash, isMelee == 1)
    end
  end)
end

function EntityZone:destroy()
  for i=1, #self.damageEventHandlers do
    print("Destroying", self.damageEventHandlers[i])
    RemoveEventHandler(self.damageEventHandlers[i])
  end
  self.damageEventHandlers = {}
  PolyZone.destroy(self)
end
