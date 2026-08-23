# The Money Pit

A native macOS app for tracking what a house actually costs: money put into
furniture and upgrades, what the house is worth, and the equity that leaves
behind once the mortgage is accounted for.

Local-first and private by design: your data lives in a plain JSON file on
your own Mac by default (nothing is ever sent anywhere), and you can point
storage at any folder you choose instead — including one that syncs via
iCloud Drive, Dropbox, etc. — if you want that.

## Running it

Grab (or build, see below) `The Money Pit.app` and double-click it — no
Xcode required to run a built app. Since it's not notarized with a paid
Apple Developer account, macOS Gatekeeper will likely flag it as being from
an "unidentified developer" the first time; right-click the app and choose
**Open** once to get past that.

## Building from source

Requires Xcode (for the Swift toolchain and code signing tools).

```
git clone <this repo>
cd HomeRenoApp
swift test              # run the test suite
./AppPackaging/build_app.sh   # builds and packages build/"The Money Pit.app"
```

## Project layout

- `Sources/TheMoneyPitCore/` — data model and business logic (items, totals,
  equity, mortgage math, CSV import/export), fully unit tested with no
  UI dependencies.
- `Sources/TheMoneyPit/` — the SwiftUI app itself.
- `Tests/TheMoneyPitCoreTests/` — the test suite for `TheMoneyPitCore`.
- `AppPackaging/` — Info.plist, entitlements, app icon, and the build script
  that assembles a real `.app` bundle from the Swift Package build output.
- `SampleData/sample-data.json` — fake placeholder data you can load via
  Settings → Import Data to see the app populated without using real numbers.
- `scripts/import_spreadsheet.py` — a one-off converter for importing an
  existing spreadsheet's data (not part of the app itself).

## License

MIT — see [LICENSE](LICENSE).
