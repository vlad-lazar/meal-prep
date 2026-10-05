#!/usr/bin/env python3
"""Fetches candidate dish photos for review: Openverse (Flickr/rawpixel/StockSnap, free licences) plus
TheMealDB where it has the exact dish.

Usage: scripts/photo-candidates.py OUT_DIR [OVERRIDES_JSON]
OVERRIDES_JSON ({"recipe-id": "new search"}) re-fetches just those recipes with a different query.
Writes OUT_DIR/<recipe-id>/<n>.jpg and OUT_DIR/candidates.json (title, creator, licence, source page)
so a human can pick one photo per recipe. Resumable; uses curl because the system Python may lack
SSL certificates.
"""
import json, os, subprocess, sys, time, urllib.parse

QUERIES = {
    "chicken-curry": "chicken curry rice", "chili-con-carne": "chili con carne",
    "frikadeller": "frikadeller", "pasta-bolognese": "spaghetti bolognese",
    "teriyaki-salmon": "teriyaki salmon rice", "red-lentil-dal": "red lentil dal",
    "chicken-burrito-bowl": "chicken burrito bowl", "chicken-shawarma": "chicken shawarma plate",
    "overnight-oats": "overnight oats jar", "pork-stir-fry": "pork stir fry noodles",
    "veggie-lasagne": "vegetable lasagna", "thai-green-curry": "thai green curry",
    "meatballs-tomato": "meatballs tomato sauce spaghetti", "chicken-sweet-potato-traybake": "chicken sweet potato traybake",
    "tuna-pasta-salad": "tuna pasta salad", "beef-lasagne": "beef lasagna",
    "butter-chicken": "butter chicken", "chickpea-spinach-curry": "chickpea spinach curry",
    "cod-potatoes-peas": "baked cod potatoes", "morbrad-mushroom": "pork tenderloin mushroom cream sauce",
    "hakkeboef": "hakkebøf", "burning-love": "brændende kærlighed",
    "egg-fried-rice": "egg fried rice", "peanut-chicken-noodles": "peanut noodles",
    "chicken-fajita-wraps": "chicken fajita", "bean-sweet-potato-chili": "sweet potato chili",
    "shakshuka": "shakshuka", "greek-chicken-rice": "greek chicken rice tzatziki",
    "beef-goulash": "beef goulash", "salmon-broccoli-pasta": "salmon broccoli pasta",
    "shrimp-coconut-curry": "shrimp coconut curry", "spinach-feta-muffins": "egg muffins",
    "mushroom-risotto": "mushroom risotto", "chicken-noodle-soup": "chicken noodle soup",
    "stuffed-peppers": "stuffed peppers", "cashew-chicken": "cashew chicken",
    "chicken-pasta-bake": "chicken pasta bake", "fiskefrikadeller": "fiskefrikadeller",
    "pasta-carbonara": "spaghetti carbonara", "breakfast-burritos": "breakfast burrito",
    "barbacoa-tacos": "barbacoa tacos",
}
# TheMealDB dishes that match a recipe exactly.
MEALDB = {
    "frikadeller": "Frikadeller", "pasta-bolognese": "Spaghetti Bolognese", "teriyaki-salmon": "Honey Teriyaki Salmon",
    "red-lentil-dal": "Dal fry", "thai-green-curry": "Thai Green Curry", "beef-lasagne": "Lasagne",
    "shakshuka": "Shakshuka", "pasta-carbonara": "Spaghetti alla Carbonara", "egg-fried-rice": "Chicken Fried Rice",
    "chicken-curry": "Nutty Chicken Curry", "chicken-shawarma": "Shawarma", "beef-goulash": "Traditional Croatian Goulash",
}
UA = "MealPrepPersonalApp/1.0 (personal, non-commercial)"
PER_RECIPE = 6


def curl(url, out=None):
    cmd = ["curl", "-sL", "-m", "40", "-A", UA, url] + (["-o", out] if out else [])
    return subprocess.run(cmd, capture_output=True, check=True).stdout


def get_json(url, attempts=4):
    for attempt in range(attempts):
        try:
            data = json.loads(curl(url))
            if "results" in data or "meals" in data:
                return data
        except json.JSONDecodeError:
            pass
        time.sleep(8 * (attempt + 1))  # throttled: back off
    return {}


out_dir = sys.argv[1]
os.makedirs(out_dir, exist_ok=True)
index = f"{out_dir}/candidates.json"
result = json.load(open(index)) if os.path.exists(index) else {}
if len(sys.argv) > 2:
    overrides = json.load(open(sys.argv[2]))
    QUERIES.update(overrides)
    for rid in overrides:
        result.pop(rid, None)
        for name in os.listdir(f"{out_dir}/{rid}") if os.path.isdir(f"{out_dir}/{rid}") else []:
            os.remove(f"{out_dir}/{rid}/{name}")
for rid, query in QUERIES.items():
    if result.get(rid):
        continue
    os.makedirs(f"{out_dir}/{rid}", exist_ok=True)
    picks = []
    if rid in MEALDB:
        data = get_json("https://www.themealdb.com/api/json/v1/1/search.php?" + urllib.parse.urlencode({"s": MEALDB[rid]}))
        meal = next((m for m in data.get("meals") or [] if m["strMeal"] == MEALDB[rid]), None)
        if meal:
            curl(meal["strMealThumb"], f"{out_dir}/{rid}/0.jpg")
            picks.append({"file": f"{rid}/0.jpg", "title": meal["strMeal"], "creator": "TheMealDB",
                          "license": "TheMealDB", "page": f"https://www.themealdb.com/meal/{meal['idMeal']}"})
    params = urllib.parse.urlencode({"q": query, "license": "cc0,by,by-sa,pdm", "source": os.environ.get("OPENVERSE_SOURCES", "flickr,rawpixel,stocksnap"),
                                     "aspect_ratio": "wide", "page_size": 20})
    for item in get_json(f"https://api.openverse.org/v1/images/?{params}").get("results", []):
        if (item.get("width") or 0) < 900 or len(picks) >= PER_RECIPE:
            continue
        n = len(picks)
        try:
            curl(item["url"], f"{out_dir}/{rid}/{n}.jpg")
        except subprocess.CalledProcessError:
            continue
        picks.append({"file": f"{rid}/{n}.jpg", "title": item["title"], "creator": item.get("creator") or "",
                      "license": f"{item['license'].upper()} {item.get('license_version') or ''}".strip(),
                      "page": item.get("foreign_landing_url") or item["url"]})
    result[rid] = picks
    json.dump(result, open(index, "w"), ensure_ascii=False, indent=1)
    print(f"{rid:32} {len(picks)} candidates", flush=True)
    time.sleep(3)
