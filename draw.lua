local function _draw(shape, opt)
  opt = opt or {}
  local zDrawDist = 75.0
  local plyPed = PlayerPedId()
  local plyPos = GetEntityCoords(plyPed)
  local minZ = shape.minZ or plyPos.z - zDrawDist
  local maxZ = shape.maxZ or plyPos.z + zDrawDist
  for i=1, #shape.points do
    DrawLine(shape.points[i].x, shape.points[i].y, minZ, shape.points[i].x, shape.points[i].y, maxZ, 255, 0, 0, 255)
    if #shape.points >= i+1 then
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

function PolyZone:draw(opt)
  _draw(self, opt)
end

function PolyZone.draw(shape, opt)
  _draw(shape, opt)
end