games {'gta5'}

fx_version 'bodacious'

description 'Define polygonal zones and test whether a point is inside or outside of the zone'
version '2.1.0'

client_scripts {
  'client.lua',
  'BoxZone.lua',
  'EntityZone.lua',
  'CircleZone.lua',
  'ComboZone.lua',
  'creation/*.lua'
}

server_scripts {
  'server.lua'
}
