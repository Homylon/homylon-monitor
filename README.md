# Homylon Monitor

**Homylon** is a home automation language and engine you can read: plain-text scenes that say how a
house should behave. Downloads (also this Monitor, ready to run on a Mac), the manual and the Homylon
engine: **[homylon.org](https://www.homylon.org)**.

Shows what your Homylon engine is doing, live: every message, warning and change, in colour.
One Xcode project, three apps:

| Target | For | Minimum |
|---|---|---|
| HomylonMonitor3 | iPhone and iPad | iOS 12 |
| HomylonMonitorMac | Mac (Intel and Apple Silicon) | macOS 11.7 |
| HomylonMonitorTV | Apple TV | tvOS 12 |

## How it works

1. **Find the engine:** Bonjour (`_homylon._tcp`) first; when that finds nothing (over a VPN,
   from another network), the last engine that answered; then the address from Settings.
2. **Register:** it tells the engine where to send its messages (`RegisterMonitor`).
3. **Heartbeat:** it registers again every 3 seconds while it is in front, so the engine stops
   sending when the app is closed or the device is locked.
4. **Receive:** the engine's messages arrive over TCP and are shown as they come.

All network code comes from [HomylonKit](https://github.com/Homylon/homylon-kit-swift); the
messages themselves are described in [homylon-protocol](https://github.com/Homylon/homylon-protocol).
The Monitor is a complete example of an app that talks to the engine: start reading in
`Shared/MonitorLink.swift`.

## Build

Open `HomylonMonitor3.xcodeproj` in Xcode (15.4 is what it is built with). Xcode fetches
HomylonKit from GitHub by itself. Choose a target and your own team under Signing, and run it on
your device. A free Apple ID is enough to put it on your own iPhone or iPad.

## Licence

MIT, see LICENSE. Homylon apps and agents are "beta forever": they keep improving as people
use them. More at homylon.org.
