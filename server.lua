local eventPrefix = '__PolyZone__:'

function triggerZoneEvent(eventName, ...)
  TriggerClientEvent(eventPrefix .. eventName, -1, ...)
end

RegisterNetEvent("PolyZone:TriggerZoneEvent")
AddEventHandler("PolyZone:TriggerZoneEvent", triggerZoneEvent)

exports("TriggerZoneEvent", triggerZoneEvent)