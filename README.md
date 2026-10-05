# Meal Prep 🥗

A personal iPhone app for budget meal prep in Denmark. Pick a meal by price per portion, cooking time and
difficulty; it ranks nearby grocery stores (Netto, REMA 1000, Lidl, føtex, Coop 365, …) by basket price using this
week's offers, gives you a shopping list, then walks you through cooking with timers. Nutrition per portion included.
Liquid Glass design (iOS 26).

Not on the App Store — you build and install it from your Mac.

## Requirements

- Mac with **Xcode 26+** and `brew install xcodegen`
- iPhone on **iOS 26+** with Developer Mode on (Settings → Privacy & Security → Developer Mode)
- A free Apple ID added in Xcode → Settings → Accounts (creates a "Personal Team")

## Install on your iPhone

1. `cp Config/Local.xcconfig.example Config/Local.xcconfig` and set `DEVELOPMENT_TEAM` to your Personal Team ID
   (`defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier` prints it) and `MEALPREP_BUNDLE_ID` to
   something unique like `dk.yourname.mealprep`.
2. Plug in and unlock the iPhone, then run `scripts/install-device.sh`. It generates the project, signs, installs and
   launches the app.
3. First install only: on the iPhone go to Settings → General → VPN & Device Management → your Apple ID → **Trust**.

With a free Apple ID the app expires after **7 days** — plug the phone in and run `scripts/install-device.sh` again.
(You can also open `MealPrep.xcodeproj` after `xcodegen` and press Run in Xcode.)

## Development

| Command | What it does |
|---|---|
| `scripts/test-core.sh` | Runs the logic tests (works even with only the Command Line Tools) |
| `cd Core && swift run mealprep-cli [lat] [lng]` | Live report of nearby stores, matched offers and recipe prices — use it to tune `searchTerms`/`excludeTerms` |
| `scripts/build-app.sh` | Generates the Xcode project and builds for the simulator |
| `scripts/run-sim.sh out.png -hasOnboarded YES` | Installs, launches (Copenhagen location) and screenshots the app in the simulator |
| `scripts/install-device.sh` | Builds, signs and installs on the connected iPhone |
| `scripts/photo-candidates.py DIR` / `scripts/install-photos.py DIR picks.json` | Fetch candidate dish photos, then install the chosen ones |

Layout: `Core/` is the `MealPrepCore` Swift package (models, pricing, Tjek client, caching, nutrition, bundled JSON
in `Core/Sources/MealPrepCore/Resources/`); `MealPrep/` is the SwiftUI app. Edit typical prices in
`ingredients.json` and recipes in `recipes.json` — the lint tests check everything stays consistent.

## Data sources

- Weekly offers and store locations: Tjek / eTilbudsavis public API (no key). Regular prices are estimates.
- Nutrition: approximate values from standard food composition tables.
- Dish photos: Flickr/Openverse (Creative Commons) and TheMealDB — creator and licence per photo in
  `MealPrep/Resources/photo-credits.json` and under each recipe's header in the app.
