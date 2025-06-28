exports("BoxZone", function()
    return {
        Create = function(center, length, width, options)
            center = vector3(center.x, center.y, center.z or 0.0)
            local zone = BoxZone:Create(center, length, width, options)

            if options and options.onPlayerInOut then
                zone:onPlayerInOut(function(isInside, point)
                    options.onPlayerInOut(isInside, point)
                end)
            end

            return zone
        end,
    }
end)

exports("CircleZone", function()
    return {
        Create = function(center, radius, options)
            center = vector3(center.x, center.y, center.z or 0.0)
            local zone = CircleZone:Create(center, radius, options)

            if options and options.onPlayerInOut then
                zone:onPlayerInOut(function(isInside, point)
                    options.onPlayerInOut(isInside, point)
                end)
            end

            return zone
        end,
    }
end)