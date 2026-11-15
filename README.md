<div align="center">
  <br>
  <a href="https://nxtcoreee3.online"><img src="https://github.com/jailbreakdotparty/Erosion/blob/main/PreviewIcon.png?raw=true" alt="App Icon" width="150"></a>
  <br>
  <h1>Terrain</h1>
  <p>iOS customization toolbox using the <a href="https://github.com/forcequitOS/worse_query">worse_query</a> sandbox escape. Fork of <a href="https://github.com/jailbreakdotparty/Erosion">Erosion</a> by <a href="https://github.com/nxtcoreee3">nxtcoreee3</a>.</p>
  <p>Supports iOS 26.0 - 26.7.2 & iOS 27.0 - 27.2.1.</p>
 
### About this fork
Terrain is a community fork of [Erosion](https://github.com/jailbreakdotparty/Erosion), originally created and maintained by the Erosion contributors. This fork is maintained by [nxtcoreee3](https://github.com/nxtcoreee3) and keeps Erosion's core project while developing Terrain-specific changes separately.

Compared with upstream Erosion, Terrain is rebranded and adds an entire tendies collection right inside the app, so you can browse and find the perfect wallpaper for your device.

For the original project and its upstream documentation, see [jailbreakdotparty/Erosion](https://github.com/jailbreakdotparty/Erosion).

### Before you begin...
- Please create a backup of your device before usage! While Erosion has been extensively tested, there is still a possibility that you could lose your data by using this tool.
- If a tweak doesn't work how you were expecting, **do not open an issue or ask for support regarding it!** All tweaks are reliant on your device cooperating properly, and in some cases this can even involve Apple's servers. We'll be unable to help you.

### Supported Versions
>[!NOTE]
>If your version doesn't show up on this list, your device is not supported. **Do not ask us for any support regarding extending version support!** Exploits that apps like these rely on are very rare to come by, so there's nothing we can do if your device isn't supported.
- iOS/iPadOS 26.0 - 26.6.2 **(limited functionality, e.g. no gestalt tweaks)**
- iOS/iPadOS 27.0 - 27.2.1
- iOS/iPadOS 27.3 beta 1 (24C5037i)

At the time of writing (2026-11-08), worse_query has not been patched in any new software releases by Apple, so it works on all available versions.

Expect that to change in the short future.

### FAQ
1. **Why can't I use MobileGestalt tweaks on iOS 26?** The exploit that Erosion relies on, `worse_query`, is *not* capable of writing to MobileGestalt on iOS 26, therefore those tweaks do not work.
2. **Why aren't PosterBoard wallpapers showing up?** Sometimes, you'll have to reset Collections, which can be done in-app. If the wallpaper still doesn't show up after that, then it's likely a wallpaper-based issue rather than something that Erosion can solve.
3. **Where can I get dialer themes and custom wallpapers?** Check out https://cowabun.ga/wallpapers for these features.
4. **Why does the app hang when opening Custom Wallpapers or Dialer Themer?** When you open these tweaks for the first time, Erosion starts automatically detecting the app container paths. Unfortunately, the method currently used to detect these is annoyingly slow. It should complete in ~30 seconds, and this setup is only required once.

### Credits
- [nxtcoreee3](https://github.com/nxtcoreee3) - Erosion fork (Terrain).
- [lunginspector](https://github.com/lunginspector) - Primary developer and maintainer.
- [forcequit](https://github.com/forcequitOS) - worse_query sandbox escape and container enumeration strategy.
- [0xjohnny](https://github.com/0xjohnnydev) - worse_query sandbox escape.
- [Skadz](https://github.com/skadz108) - Exploit implementation, backend functions, and project maintainer.
- [rooootdev](https://github.com/rooootdev) - Various backend components.
- [neonmodder123](https://github.com/neonmodder123) - Developed WebView respring method.
