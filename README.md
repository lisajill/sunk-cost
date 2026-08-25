# Sunk Cost

*100% vibe-coded with AI.*

A native macOS app for tracking what a house actually costs: money put into
furniture and upgrades (split into Value, which stays with the house if
sold, and Moveable, which goes with you), what it costs to keep the house
running month to month, what the house is worth, and the equity that's left
once the mortgage is accounted for.

Local-first and private by design: your data lives in a plain JSON file on
your own Mac by default (nothing is ever sent anywhere), and you can point
storage at any folder you choose instead — including one that syncs via
iCloud Drive, Dropbox, etc. — if you want that. The app also keeps its own
rolling 14-day local backup automatically, restorable from Settings if
something gets edited or deleted by mistake.

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
  equity, mortgage math, Maintenance categories, CSV import/export),
  fully unit tested with no UI dependencies.
- `Sources/SunkCost/` — the SwiftUI app itself.
- `Tests/SunkCostCoreTests/` — the test suite for `SunkCostCore`.
- `AppPackaging/` — Info.plist, entitlements, app icon, and the build script
  that assembles a real `.app` bundle from the Swift Package build output.
- `SampleData/sample-data.json` — fake placeholder data you can load via
  Settings → Import Data to see the app populated without using real numbers.
- `scripts/import_spreadsheet.py` — a one-off converter for importing an
  existing spreadsheet's data (not part of the app itself).

## What it tracks

Three layers, each sequenced after the last was actually used rather than
all built at once:

1. **Cost to improve** — one-time items (furniture, upgrades), split into
   Value (stays with the house if sold) and Moveable (goes with you).
2. **Cost to keep** — a recurring monthly amount per Maintenance category
   under the Maintenance tab, each marked Required or Optional so you can
   see what you'd actually save by cutting the discretionary ones. Set
   once and updated only when the rate changes, not a payment log.
3. **Cost to leave** — under the Sell Scenario tab: given Home Value,
   mortgage payoff balance, and assumed selling costs (realtor commission
   and closing costs, both editable percentages), shows Net Proceeds if
   sold today and the profit/loss against everything actually invested in
   the house. Below that, a multi-year **Compare: Stay vs. Rent vs. Buy
   Elsewhere** projection — a chosen time horizon, assumed home
   appreciation, assumed investment return on sale proceeds, and (for
   Buying Elsewhere) a new home price/down payment/mortgage — showing each
   scenario's projected ending net worth. Each scenario is computed
   independently; it doesn't additionally reinvest the month-to-month
   cash-flow *difference* between scenarios into each other (a real
   refinement some calculators add, left out of this pass) — Renting's
   ending number in particular only reflects investing today's sale
   proceeds, not what you spend on rent along the way.

   Property tax, insurance, and HOA dues are entered as real dollar
   amounts (with a toggle for monthly vs. annual on tax/insurance) rather
   than a percentage, since every real-world source for these numbers —
   listings, loan estimates, tax bills — quotes a dollar figure, not a
   rate. A **Paste from Listing** button on Buying Elsewhere reads a
   copy-pasted Redfin/Zillow payment-calculator box and fills in price,
   down payment, rate, term, tax, insurance, and HOA automatically —
   parsing text you already copied yourself, no network request of any
   kind. Renting also accounts for one-time move-in costs (security/pet
   deposits, which reduce what's actually left to invest) and ongoing
   pet rent.

   The Compare assumptions can be saved as a named scenario (with
   optional notes) and reloaded later — useful for flipping between a
   few different what-ifs without retyping. A toolbar **Copy Summary**
   button copies all the Sell Scenario and Compare numbers as plain text,
   for pasting into a spreadsheet or a chat to play with the numbers
   further, without the app itself ever making a network call.

### Someday / maybe

Not committed, no timeline — just ideas worth remembering:

- **Rich text (wysiwyg) notes** — editing notes as formatted text instead
  of typing markdown by hand. Feasible without a custom rich-text
  component (macOS 14 has a native SwiftUI editor for this), but the
  notes would still be *stored* as plain markdown, converting to/from
  rich text only for editing/display — keeps the JSON portable and
  human-readable, and keeps CSV export working.
- **File attachments** (receipts, photos) on items and Maintenance
  categories — feasible by storing files in an "Attachments" folder next
  to the data file and referencing them by name, but it's a real
  tradeoff: the data stops being one portable JSON file, and a backup or
  move to another Mac means copying the whole folder instead of one file.
- **Refinance modeling** — not something the current maintainer needs
  (her mortgage isn't going anywhere), but a plausible ask from someone
  else: comparing the current loan against a hypothetical refinance
  (new rate/term/closing costs) the way Compare already does for
  Stay/Rent/Buy Elsewhere.

## License

MIT — see [LICENSE](LICENSE).
