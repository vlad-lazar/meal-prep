#!/usr/bin/env python3
"""Installs chosen candidate photos into the app.

Usage: scripts/install-photos.py CANDIDATE_DIR PICKS_JSON
PICKS_JSON maps recipe id → candidate index, e.g. {"chili-con-carne": 2}.
Each pick is resized with `sips` to 1000 px on the long edge (JPEG ~80%) into
MealPrep/Assets.xcassets/RecipePhotos/photo-<id>.imageset, and its credit is written to
MealPrep/Resources/photo-credits.json (shown under the detail-screen header).
"""
import json, os, subprocess, sys

cand_dir, picks_path = sys.argv[1], sys.argv[2]
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
assets = f"{root}/MealPrep/Assets.xcassets/RecipePhotos"
os.makedirs(assets, exist_ok=True)
with open(f"{assets}/Contents.json", "w") as f:
    json.dump({"info": {"author": "xcode", "version": 1}}, f)

candidates = json.load(open(f"{cand_dir}/candidates.json"))
credits_path = f"{root}/MealPrep/Resources/photo-credits.json"
os.makedirs(os.path.dirname(credits_path), exist_ok=True)
credits = json.load(open(credits_path)) if os.path.exists(credits_path) else {}

for rid, index in json.load(open(picks_path)).items():
    cand = candidates[rid][index]
    imageset = f"{assets}/photo-{rid}.imageset"
    os.makedirs(imageset, exist_ok=True)
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "80", "-Z", "1000",
                    f"{cand_dir}/{cand['file']}", "--out", f"{imageset}/photo.jpg"], check=True, capture_output=True)
    with open(f"{imageset}/Contents.json", "w") as f:
        json.dump({"images": [{"filename": "photo.jpg", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}, f)
    credits[rid] = {"creator": cand["creator"], "license": cand["license"], "page": cand["page"]}
    print(f"{rid:32} ← {cand['file']}  ({cand['license']}, {cand['creator'][:30]})")

with open(credits_path, "w") as f:
    json.dump(dict(sorted(credits.items())), f, ensure_ascii=False, indent=1)
