# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Sunk Cost — a native macOS app (SwiftUI, Swift 6, macOS 14+) for tracking
what a house costs: one-time items (furniture, upgrades), the home's current
value, and equity once the mortgage is factored in. Local-first and private
by design: data is a plain JSON file, local by default, with an
opt-in "point storage at any folder you choose" option — no iCloud
container, no backend, no network calls anywhere in the app.

There is no Xcode project. This is a plain Swift Package; `AppPackaging/`
hand-assembles a real, double-clickable `.app` bundle from the SPM build
output (see "Packaging" below) because that's simpler than fighting Xcode
project generation for a two-target package, and it makes the whole build
scriptable/non-interactive.

## Commands

```
swift build                          # debug build
swift test                           # whole suite: SunkCostCore + a narrow SunkCostTests (no view tests)
swift test --filter SuiteName        # run one suite, e.g. `swift test --filter CSVCodecTests`
swift test --filter "SuiteName/testMethodName"   # run one test
./AppPackaging/build_app.sh          # release build + assemble build/"Sunk Cost.app"
```

There's no lint step. No Xcode project to open — `swift build`/`swift test`
are the whole loop. First-time setup on a machine that's never run Xcode
needs `sudo xcodebuild -license` accepted once (interactive; can't be
scripted).

To actually run the built app and check for crashes/errors without a
display:

```
open "build/Sunk Cost.app"
sleep 3
pgrep -fl SunkCost                                    # confirm it's running
log show --predicate 'process == "SunkCost"' --last 1m --style compact | grep -iE "error|fault|crash"
```

Always confirm only one instance is running before/after a rebuild
(`pgrep -fl SunkCost`) — a stale instance left running from a previous build
can silently overwrite on-disk data with its stale in-memory state the next
time anything triggers a save in it.

## Architecture

**Two targets, deliberately split by testability.** `Sources/SunkCostCore/`
is pure Foundation logic (no SwiftUI/AppKit imports) — the data model,
totals/equity math, filtering/sorting, CSV codec, hashtag parsing. It's
fully unit tested (`Tests/SunkCostCoreTests/`). `Sources/SunkCost/` is the
SwiftUI app: views, the `AppStore` observable, storage/appearance/text-size
plumbing. When adding logic, ask whether it belongs in Core (if it can be
expressed as a pure function over `Item`/`AppData`, it almost always
should) — that's what makes it testable without a UI harness.

`Tests/SunkCostTests/` is a deliberately narrow exception: it covers only
the non-view `AppStore` logic that has actually had bugs — the
storage-folder-switch state machine and the save/rollback/`apply`
plumbing — via `AppStore(storageOverrideForTesting:)` pointed at a temp
dir. No view tests. New app-target logic still belongs in Core if it can;
this suite is for the parts that genuinely can't be.

**`AppStore` is the single source of truth**, an `@Observable @MainActor`
class constructed once in `SunkCostApp` and injected via `.environment(store)`.
It draws a hard line between two kinds of state:
- Domain data (`items`, `homeValue`, mortgage fields) lives in the on-disk
  `AppData` JSON file and is written via `ItemStore.save` on every mutating
  method (`addItem`, `updateItem`, `deleteItem`, `setMortgage`, etc.) — no
  explicit save action anywhere in the UI.
- View preferences (`textSizeIndex`, `appearanceMode`, `sortOption`) live in
  `UserDefaults`, independent of the data file, so switching data files or
  storage folders doesn't touch them.

Every domain-data mutation goes through `mutate { ... }`, which snapshots
the pre-change state, runs the closure, calls `save()`, and rolls the
in-memory state back via `apply(_:)` if the write fails — so the UI never
shows data that isn't on disk (`ItemStore.save` is atomic, so a failed
save leaves the old file intact and the rollback fully reconciles the
two). Don't hand-write `field = x; save()` in a new mutator; wrap it.
Keep the guard (`firstIndex` etc.) *outside* the closure so a no-op
mutation doesn't trigger a pointless save.

`apply(_:)` (AppData → store) and `currentAppData()` (store → AppData) are
a matched pair listing every domain field; `load()`, import, and rollback
all route through `apply`, and `resetToEmpty()` is `apply(AppData())`.
When you add a field to `AppData`, update *both* — they sit adjacent for
that reason. A load failure calls `resetToEmpty()` so nothing lingers
from a previously-loaded file.

`save()` snapshots the *existing* on-disk file into the daily backup
*before* `ItemStore.save` overwrites it (`BackupManager.snapshot` is
best-effort and swallows its own errors). Order matters: snapshotting
after the write would make the day's backup mirror that write, defeating
the "undo the whole day" recovery path. Don't reorder it.
`BackupManager`'s daily filename uses **local** time (`TimeZone.current`),
so "one backup per day" tracks the user's calendar day and the Restore
menu shows the right date — a UTC formatter rolled the day over mid-evening.

**Storage location** (`Storage/StorageLocation.swift`): defaults to a folder
inside the app's own sandboxed Application Support directory, no prompts.
The user can instead point it at literally any folder via `NSOpenPanel`,
persisted as a security-scoped bookmark (`UserDefaults`) so access survives
relaunch — this is what makes "put it in an iCloud Drive folder for free
sync" work without any app-specific sync code. This was a deliberate choice
over Apple's iCloud-container API: a container is invisible/hard to find in
Finder and ties the data to one specific app identity, whereas a
user-chosen folder is ordinary and portable.

Switching folders is **two-phase and transactional** (same confirm-first
shape as `pickFileToImport` → `applyImportedData`), because the naive
version silently overwrote whatever data was already in the destination
*and* committed the switch before the load/save succeeded.
`StorageLocation.pickFolder()` only shows the panel;
`makeBookmark`/`persistBookmark` are split so the fallible step (building
the security-scoped bookmark) happens before anything is committed.
`AppStore.pickNewStorageFolder()` / `prepareResetToDefaultStorageFolder()`
return a `PendingStorageChange` describing the target; the UI then calls
`adoptStorageFolder` (re-reads the target now, then switches + `apply`s)
or `replaceDataAtStorageFolder` (re-inspects the target, builds the
bookmark, writes to the *candidate* URL, and only then commits via
`finishStorageSwitch`). Any failure leaves the store pointed exactly
where it was. `replaceDataAtStorageFolder` re-reads the destination right
before writing and *returns a fresh `PendingStorageChange`* if it no
longer matches what the user was shown (an iCloud folder can sync a file
in after inspection) — the caller re-confirms rather than overwrite it.
Unreadable target file aborts; empty target → straight to replace, no
prompt; "Use Default Location" is disabled when already there
(`isUsingDefaultStorageFolder`).

**Sell scenario / long-term projections** (`SunkCostCore`,
`AppStore+Comparison.swift`): `SellScenario.netProfitOrLoss` is
`homeValue − sellingCosts − totalInvested` — **mortgage-independent** on
purpose. The payoff is already netted out of `netProceeds`; subtracting a
gross purchase-price basis from a post-payoff figure double-counts the
loan. `projectStayingNetWorth` amortizes forward from a *current* balance
(passed in), not a reconstructed schedule, so a hand-updated
`mortgageBalance` is respected; `AppStore.stayingBalanceBasis` (a
`UserDefaults` view pref) picks recorded vs. modeled, and the UI only
offers the choice when the two disagree by more than $1. A zero starting
balance short-circuits to just the appreciated home value (no rate or
payment needed). `outsideCashUsed(netProceeds:committed:)` is the shared
rule for cash that has to come from savings — an underwater sale, or
deposits/down-payment beyond the sale's usable proceeds — carried as a
compounding negative balance in the Rent/Buy projections. It's surfaced
explicitly (`rentingOutsideCashFromSavings` /
`buyingElsewhereOutsideCashFromSavings`, shown in the plain-English notes
and a table footnote) rather than left as a silently lower number. An
inferred down payment is clamped to `[0, price]`.

**Theming (`Theme.swift`)**: no asset catalog (there's no Xcode project to
hold one), so colors are built by hand via
`NSColor(name: nil) { appearance in ... }` dynamic providers wrapped in
SwiftUI `Color`. The palette is deliberately colorblind-safe: `positive`
(a blue-*leaning* violet — not blue itself since the 2026-08-24 redesign,
but still not red-leaning, which is what would actually be risky) vs
`gold` (a deep amber, not orange — renamed from `terracotta` in the same
redesign) vs `taupe` (gray) for Owned/Planned/Gone, since a same-warmth
orange-vs-red pairing (or, worse, green-vs-red) is a real confusion risk
for red-green color blindness — status is also never conveyed by color
alone, every status has a text label too.

Three layered variants of that same palette exist for three different
jobs, and mixing them up is the mistake to avoid: `positive`/`gold`/
`taupe`/`ledgerRed` are for plain text/icons on the page background
(adaptive per light/dark mode); `*Fill` (`positiveFill` etc.) are deep,
*non-adaptive* solid colors for a badge with white text on top of it
(too dark to use as plain text against the dark-mode background — you'd
get ~1:1 contrast); `chart*` (`chartPositive` etc.) are for a graphic
*element* directly on the page background, like a chart ring or a
legend icon — brighter than `*Fill` (checked against WCAG's 3:1
graphical-object minimum, not text's 4.5:1) since neither of the other
two sets is visible/appropriate there. All three were reasoned through
by hand against actual relative-luminance math during the redesign, not
eyeballed — if you add a fourth accent color, work out which bucket it
belongs to rather than guessing.

**Font scaling does NOT use SwiftUI's Dynamic Type.** An earlier attempt
wired `\.dynamicTypeSize` through the view hierarchy; it did not visibly
resize anything on macOS despite being "correct" by the API. It was ripped
out in favor of `Theme.scaledFont(baseSize, scale:)` — every font in the
app is `baseSize * store.textScale` via a plain `CGFloat` multiplier
(`TextSizeControl`, custom `\.appTextScale` environment key). If you're
tempted to reach for `\.dynamicTypeSize` again here, don't — it's a dead
end that was already tried.

**Light/Dark toggle staleness**: the custom `NSColor(dynamicProvider:)`
colors above, and native `Picker`s backed by `NSPopUpButton`, can both
render with stale (sometimes near-invisible) colors for one frame right
after `.preferredColorScheme` flips live. The fix in place is
`.id(store.appearanceMode)` on the affected subviews (`SummaryHeaderView`,
`FilterBarView`, the item `List`, `SettingsView`), forcing a full rebuild
rather than an in-place update. This is deliberately *not* applied to
`ContentView` itself, which owns sheet-presentation state
(`isShowingAddForm`/`editingItem`) — resetting that on every appearance
toggle would dismiss an open Add/Edit sheet out from under the user.

**CSV codec (`CSVCodec.swift`)** is a hand-rolled RFC4180-ish parser, not a
library. The one non-obvious gotcha already hit once: Swift's `Character`
(grapheme cluster) model treats `"\r\n"` as a *single* `Character`, not two
— a naive per-character switch on `'\r'`/`'\n'` silently fails to split
rows on Windows-style line endings. The parser normalizes line endings to
`"\n"` first before iterating characters. `Notes`, `Type`, `Disposition`,
and `Amount Recovered` are all optional (not in the `required` column
list) so older exports still import fine; each optional cell is
bounds-checked per row. The column map is built by hand, not with
`Dictionary(uniqueKeysWithValues:)` — that *traps* on a duplicate header;
decode throws `CSVCodecError.duplicateColumns` instead. Rows must have a
cell at every *required* column index (`row.count > maxRequiredIndex`, not
`>= required.count`) or a reordered short row indexes out of bounds.
Dates are **local** calendar days (`TimeZone.current`), matching how the
app stores/shows `dateAdded` (a CSV exported by an older UTC-formatter
build may carry an already-shifted day — unfixable without a tz marker).
`decode` is lenient (skips too-short rows, defaults unknown enums, blanks
unparseable numbers/dates); `decodeReporting` returns the same items plus
`skippedRowCount` / `coercedValueCount` so the import dialog can say what
was lost rather than replacing the list silently.

**Item dates and costs are both optional** (`Decimal?`, `Date?`), and
consistently sort last regardless of direction (see `SortOption.swift`'s
`blankLastOrder` helper) — there's no meaningful "highest cost" or "newest"
for a value that isn't set. Don't backfill a fabricated default (e.g.
"today") when one is missing; the spreadsheet-import script and one
production data-cleanup already had to walk that back once.

**Return key in sheet forms**: `Button(...).keyboardShortcut(.defaultAction)`
alone does not reliably submit a form when a `TextField` in the same sheet
has focus — pressing Return can silently do nothing. Every save/add sheet
(`ItemFormView`, the Maintenance category/payment sheets, the Settings
Purchase Price and Mortgage sections) also has `.onSubmit { save() }` on
the containing view, which is what actually wires Return to the save
action; the button's `.keyboardShortcut(.defaultAction)` is still kept so
Return works even when nothing has focus yet. Since `.onSubmit` bypasses
whatever `.disabled(...)` condition guards the button, each `save()`
re-checks that same condition (e.g. name/category non-empty) and returns
early instead of saving invalid state.

**Sidebar navigation (`ContentView.swift`)**: the main window uses
`NavigationSplitView` with a hand-rolled sidebar — a plain `VStack` of
`Button`s that set `@State private var selectedSection` directly in
their action closure, deliberately *not* `List(MainSection.allCases,
selection: $selectedSection)`. That was tried first and silently failed
to register clicks: every sidebar click left the detail pane on
Overview no matter what was selected, so three of the four sections
were completely unreachable for several iterations before the cause was
found. If you're tempted to use `List(selection:)` for a
`NavigationSplitView` sidebar again, actually click through it after
building — it compiles and looks correct with nothing indicating the
selection binding isn't firing.

**Packaging (`AppPackaging/`)**: `build_app.sh` does `swift build -c
release`, copies the resulting binary + `Info.plist` + `AppIcon.icns` into
a hand-built `.app` bundle skeleton, then codesigns ad-hoc
(`--sign -`) with `SunkCost.entitlements` (App Sandbox +
user-selected-file read/write — no other entitlements, no iCloud
container). Four places have to agree on names or the bundle silently
breaks: the Package.swift executable target name, `Info.plist`'s
`CFBundleExecutable`, the binary name `build_app.sh` copies, and the
entitlements filename it references.

**Import script (`scripts/import_spreadsheet.py`)** is a one-off,
not-part-of-the-app converter for turning the original tracking
spreadsheet into a seed `items.json`. It's a pure-stdlib `zipfile`/`xml`
reader (no `openpyxl`) since `.xlsx` is just a zip of XML — reuse that
approach if you ever need to read another `.xlsx` without adding a
dependency.
