# AllinOne Music Player

AllinOne Music Player is a native macOS music shell built with Swift, AppKit, and WKWebView. It hosts YouTube Music, Spotify, and NetEase Cloud Music in one desktop window while keeping each service's normal web login, playback, library, and recommendation experience intact.

## Features

- Native macOS window with persistent sessions for all supported platforms.
- Fast switching between YouTube Music, Spotify, and NetEase Cloud Music.
- Unified playback controls in the app, menu bar, keyboard shortcuts, and system media commands.
- Now-playing detection through Media Session metadata with DOM fallbacks.
- Compact menu bar display with marquee scrolling for long track titles.
- Persistent active platform and window position using UserDefaults.

## Requirements

- macOS 13 Ventura or newer.
- Xcode 15 or newer.
- XcodeGen, if you want to regenerate the Xcode project from `project.yml`.

## Build

Generate the project after changing `project.yml`:

```bash
xcodegen generate
```

Build from the command line:

```bash
xcodebuild -project AllinOneMusicPlayer.xcodeproj -scheme AllinOneMusicPlayer -destination 'platform=macOS' build
```

You can also open `AllinOneMusicPlayer.xcodeproj` in Xcode, select the `AllinOneMusicPlayer` scheme, and run it with the toolbar play button.

## Notes

This app does not use official music platform APIs, API keys, or OAuth developer credentials. It embeds each platform's own web app through WKWebView, so user accounts and playback behavior remain owned by the original services.
