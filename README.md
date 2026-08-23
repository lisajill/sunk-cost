# Sunk Cost

A native macOS app for tracking what a house actually costs: money put into
furniture and upgrades (split into Value, which stays with the house if
sold, and Moveable, which goes with you), what it costs to keep the house
running month to month, what the house is worth, and the equity that's left
once the mortgage is accounted for.

Local-first and private by design: your data lives in a plain JSON file on
your own Mac by default (nothing is ever sent anywhere), and you can point
storage at any folder you choose instead — including one that syncs via
iCloud Drive, Dropbox, etc. — if you want that.

## Running it

Grab (or build, see below) `Sunk Cost.app` and double-click it — no Xcode
required to run a built app. Since it's not notarized with a paid Apple
Developer account, macOS Gatekeeper will likely flag it as being from an
"unidentified developer" the first time; right-click the app and choose
**Open** once to get past that.

## Building from source

Requires Xcode (for the Swift toolchain and code signing tools).

```
git clone https://github.com/lisajill/sunk-cost.git
cd sunk-cost
swift test              # run the test suite
./AppPackaging/build_app.sh   # builds and packages build/"Sunk Cost.app"
```

## Project layout

- `Sources/SunkCostCore/` — data model and business logic (items, totals,
  equity, mortgage math, Maintenance categories/payments, CSV import/export),
  fully unit tested with no UI dependencies.
- `Sources/SunkCost/` — the SwiftUI app itself.
- `Tests/SunkCostCoreTests/` — the test suite for `SunkCostCore`.
- `AppPackaging/` — Info.plist, entitlements, app icon, and the build script
  that assembles a real `.app` bundle from the Swift Package build output.
- `SampleData/sample-data.json` — fake placeholder data you can load via
  Settings → Import Data to see the app populated without using real numbers.
- `scripts/import_spreadsheet.py` — a one-off converter for importing an
  existing spreadsheet's data (not part of the app itself).

## Future plans

The app tracks money already put into the house (one-time items, split into
Value and Moveable) and what it costs to keep it running (Maintenance
categories and payments, under the Maintenance tab). One more layer is
planned:

- **Cost to leave** — a sell-scenario calculator: given a purchase price,
  mortgage payoff balance, and assumed selling costs (realtor commission,
  closing costs), show whether selling today would be a loss, break-even,
  or profit — so staying can be weighed against selling-and-renting or
  selling-and-buying-elsewhere.

It's intentionally sequenced after the rest of the tracker (this repo)
rather than built all at once, so it gets designed against real usage
instead of a guess.

## License

MIT — see [LICENSE](LICENSE).
