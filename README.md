# PolyZone
PolyZone is a FiveM mod to define zones of different shapes and test whether a point is inside or outside of the zone

![PolyZone around the prison](https://i.imgur.com/InKNaoL.jpg)

## Download

Click [here](https://github.com/mkafrin/PolyZone/releases) to go to the releases page and download the latest release

## Using PolyZone in a Script

In order to use PolyZone in your script, you must _at least_ include PolyZone's client.lua directly in your __resource.lua or fxmanifest.lua. You can do that by using FiveM's @ syntax for importing resource files:

```lua
client_scripts {
    '@PolyZone/client.lua',
    'your_scripts_client.lua',
}
```

This will allow you to create PolyZones in your script, but will not import other zones, such as CircleZone, BoxZone, etc. All the other zones are extra, and require their own explicit imports. Here is a `client_scripts` value that will include all the zones. Note the relative order of these imports, as the ordering is necessary! Many zones rely on each other, for example EntityZone inherits from BoxZone, and all zones inherit from PolyZone (client.lua).

```lua
client_scripts {
  '@PolyZone/client.lua',
  '@PolyZone/BoxZone.lua',
  '@PolyZone/EntityZone.lua',
  '@PolyZone/CircleZone.lua',
  '@PolyZone/ComboZone.lua',
  'your_scripts_client.lua'
}
```

## Documentation
For additional information on how to use PolyZone, please take a look at the [wiki](https://github.com/mkafrin/PolyZone/wiki)

## Troubleshooting and Support
For help troubleshooting issues you've encountered (that aren't in the FAQ), or to suggest new features, use the [issues page](https://github.com/mkafrin/PolyZone/issues). Just a reminder though, I do this in my free time and so there is no guarantee an issue will be fixed or a feature will be added. In lieu of my limited time, I will prioritize issues and bugs over features. 

## FAQ - Frequently Asked Questions
**I'm getting the error `attempt to index a nil value` when creating a zone, what's wrong?**
> Did you include all the necessary scripts in your \_\_resource.lua or fxmanifest.lua? Remember some zones require other zones, like EntityZone.lua requires BoxZone.lua and BoxZone.lua requires client.lua.

**I'm getting no errors, but I can't see my zone in the right place when I turn on debug drawing**
> If you are using them, is minZ and maxZ set correctly? Or if you are using a CircleZone with useZ=true, is your center's Z value correct? If using a PolyZone, did you manually select all your points, or use the creation script? If you did it manually, the ordering of the points could be causing issues. Are you using the correct option to enable debug drawing? For PolyZones, you can use `debugPoly` and `debugGrid`, but for other zones, `debugPoly` is the only one that works.

## License
**Please see the LICENSE file. That file will always overrule anything mentioned in the README.md or wiki**
