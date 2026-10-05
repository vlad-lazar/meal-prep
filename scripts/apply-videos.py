#!/usr/bin/env python3
"""Adds chosen videos to recipes.json.

Usage: scripts/apply-videos.py CANDIDATES_JSON PICKS_JSON
PICKS_JSON maps recipe id → candidate index (from scripts/video-candidates.py), or null to remove a video.
"""
import json, os, sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
path = f"{root}/Core/Sources/MealPrepCore/Resources/recipes.json"
recipes = json.load(open(path))
candidates = json.load(open(sys.argv[1]))
picks = json.load(open(sys.argv[2]))
for recipe in recipes:
    if recipe["id"] not in picks:
        continue
    index = picks[recipe["id"]]
    if index is None:
        recipe.pop("video", None)
        continue
    c = candidates[recipe["id"]][index]
    recipe["video"] = {"id": c["id"], "title": c["title"], "author": c["author"], "seconds": c["seconds"]}
    print(f"{recipe['id']:30} {c['seconds']:>3}s  {c['title'][:60]}")
with open(path, "w") as f:
    json.dump(recipes, f, ensure_ascii=False, indent=1)
    f.write("\n")
