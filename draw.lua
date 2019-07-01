local function _drawPoly(shape, opt)
  opt = opt or {}
  local zDrawDist = 75.0
  local plyPed = PlayerPedId()
  local plyPos = GetEntityCoords(plyPed)
  local minZ = shape.minZ ~= math.mininteger and shape.minZ or plyPos.z - zDrawDist
  local maxZ = shape.maxZ ~= math.maxinteger and shape.maxZ or plyPos.z + zDrawDist
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


-- Debug drawing all grid cells that are completly within the polygon
local function _drawGrid(poly)
  local minZ = poly.minZ
  local maxZ = poly.maxZ
  if minZ == math.mininteger or maxZ == math.maxinteger then
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
    PolyZone.drawPoly(shape, {lineSepDist = 0.0})
  end
end


function PolyZone.drawPoly(shape, opt)
  _drawPoly(shape, opt)
end


function startDrawPoly(shape)
  Citizen.CreateThread(function()
    while true do
      _drawPoly(shape)
      Citizen.Wait(0)
    end
  end)
end
AddEventHandler("PolyZone:startDrawPoly", startDrawPoly)


function startDrawGrid(shape)
  Citizen.CreateThread(function()
    while true do
      _drawGrid(shape)
      Citizen.Wait(0)
    end
  end)
end
AddEventHandler("PolyZone:startDrawGrid", startDrawGrid)