# Contributing to Sunk Cost

Contributions are welcome. This is a plain Swift Package — no Xcode
project to fight with, just the Swift toolchain that ships with Xcode.

```
git clone https://github.com/lisajill/sunk-cost.git
cd sunk-cost
swift test                    # run the test suite
./AppPackaging/build_app.sh   # build and package Sunk Cost.app
```

Read [CLAUDE.md](CLAUDE.md) before diving in — it covers the
architecture, non-obvious gotchas already hit once, and the reasoning
behind some deliberate design choices (like why there's no networking
code anywhere in the app, on purpose).

## Sending a pull request

`main` requires changes to come in through a pull request rather than a
direct push:

1. Fork the repo, or create a branch if you have write access.
2. Make your change, with tests if it touches `SunkCostCore` (the
   testable logic layer — see CLAUDE.md's architecture section for what
   belongs there vs. the SwiftUI layer).
3. Run `swift test` and make sure everything still passes.
4. Open a pull request against `main` describing what changed and why.

Small, focused PRs are easier to review than big ones. For a large
change, opening an issue first to talk it through is a good idea before
writing a lot of code.

## Bugs, questions, ideas

[Open an issue](https://github.com/lisajill/sunk-cost/issues/new) — that's
the one place everything gets tracked.

See also the full [user documentation](https://lisajill.github.io/sunk-cost/)
for how the app itself works.
