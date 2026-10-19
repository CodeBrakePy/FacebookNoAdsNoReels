# FacebookNoReels

A small SwiftUI app that opens Facebook in a WKWebView and removes Reels.

## Setup (needs Xcode on a Mac)
1. Xcode > File > New > Project > iOS > App. Name it `FacebookNoReels`, Interface: SwiftUI, Language: Swift.
2. Delete the generated `FacebookNoReelsApp.swift` and `ContentView.swift`.
3. Drag the four `.swift` files from this folder into the project (tick "Copy items if needed").
4. Set the deployment target to iOS 16 or later, pick your iPhone, and press Run.
5. Log in to Facebook inside the app. Your session is kept between launches.

## What it blocks
- Navigation to /reel/, /reels, /share/r/, /watch/reels and /<profile>/reels (native check plus in-page check)
- Reels links and tabs (hidden with CSS)
- Reels posts in the feed and the "Reels and short videos" shelf
- Sponsored posts in the feed (best effort)

## Known limits
- Selectors can break when Facebook changes its markup; edit `ReelBlocker.swift`.
- Reels shared as plain /watch/?v=... or /videos/ links can't be told apart from normal videos.
- No push notifications (it's the website). Free Apple IDs need re-signing every 7 days.
