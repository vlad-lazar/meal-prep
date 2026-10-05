#!/usr/bin/env python3
"""Finds short recipe videos (YouTube Shorts, ≤ 120 s, embeddable) for each recipe, for human review.

Usage: scripts/video-candidates.py OUT_JSON [recipe-id ...]
For each recipe: searches "<query> #shorts", takes the most-viewed results, then checks each video's
watch page for its length and whether embedding is allowed. Writes up to 3 passing candidates per
recipe (most viewed first) to OUT_JSON. Resumable. Uses curl because the system Python may lack SSL
certificates.
"""
import json, os, re, subprocess, sys, time, urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECIPES = json.load(open(f"{ROOT}/Core/Sources/MealPrepCore/Resources/recipes.json"))
# Better search phrases where the recipe name is long or localised.
QUERY_OVERRIDES = {
    "zeama": "zeama moldoveneasca", "ciorba-perisoare": "ciorba de perisoare", "parjoale": "parjoale",
    "tocanita-mamaliga": "tocanita cu mamaliga", "placinte-branza": "placinte cu branza",
    "burning-love": "brændende kærlighed", "hakkeboef": "hakkebøf", "frikadeller": "frikadeller",
    "fiskefrikadeller": "fiskefrikadeller", "morbrad-mushroom": "pork tenderloin mushroom sauce",
    "barbacoa-tacos": "beef barbacoa tacos", "spinach-feta-muffins": "spinach feta egg muffins",
}
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
MAX_SECONDS = 120


def fetch(url):
    cmd = ["curl", "-sL", "-m", "30", "-A", UA, "-H", "Accept-Language: en-US", url]
    return subprocess.run(cmd, capture_output=True, check=True).stdout.decode("utf-8", "replace")


def views(text):
    m = re.match(r"([\d.,]+)\s*([KMB]?)", (text or "").replace(",", ""))
    if not m:
        return 0
    return float(m.group(1)) * {"": 1, "K": 1e3, "M": 1e6, "B": 1e9}[m.group(2)]


def search(query):
    html = fetch("https://www.youtube.com/results?" + urllib.parse.urlencode({"search_query": f"{query} recipe #shorts"}))
    m = re.search(r"var ytInitialData = (\{.*?\});</script>", html)
    if not m:
        return []
    found = []

    def walk(o):
        if isinstance(o, dict):
            lockup = o.get("shortsLockupViewModel")
            if lockup:
                vid = lockup.get("onTap", {}).get("innertubeCommand", {}).get("reelWatchEndpoint", {}).get("videoId")
                meta = lockup.get("overlayMetadata", {})
                if vid:
                    found.append({"id": vid, "title": meta.get("primaryText", {}).get("content", ""),
                                  "views": views(meta.get("secondaryText", {}).get("content"))})
            renderer = o.get("videoRenderer")
            if renderer:
                found.append({"id": renderer["videoId"], "title": renderer["title"]["runs"][0]["text"],
                              "views": views(renderer.get("viewCountText", {}).get("simpleText"))})
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)

    walk(json.loads(m.group(1)))
    unique = {c["id"]: c for c in found}
    return sorted(unique.values(), key=lambda c: -c["views"])


def details(video_id):
    """Length in seconds, embeddability and channel name from the watch page."""
    html = fetch(f"https://www.youtube.com/watch?v={video_id}")
    length = re.search(r'"lengthSeconds":"(\d+)"', html)
    embeddable = re.search(r'"playableInEmbed":(true|false)', html)
    author = re.search(r'"ownerChannelName":"([^"]*)"', html)
    return (int(length.group(1)) if length else None,
            embeddable is not None and embeddable.group(1) == "true",
            author.group(1) if author else "")


out_path = sys.argv[1]
only = set(sys.argv[2:])
result = json.load(open(out_path)) if os.path.exists(out_path) else {}
for recipe in RECIPES:
    rid = recipe["id"]
    if (only and rid not in only) or (not only and rid in result):
        continue
    query = QUERY_OVERRIDES.get(rid, re.sub(r"\s*\(.*\)", "", recipe["name"]))
    picks = []
    for cand in search(query)[:8]:
        seconds, embeddable, author = details(cand["id"])
        if seconds and seconds <= MAX_SECONDS and embeddable:
            picks.append({**cand, "seconds": seconds, "author": author})
        if len(picks) == 3:
            break
        time.sleep(0.5)
    result[rid] = picks
    json.dump(result, open(out_path, "w"), ensure_ascii=False, indent=1)
    best = picks[0] if picks else None
    print(f"{rid:30} {len(picks)} | " + (f"{best['seconds']}s {int(best['views']):>9} {best['title'][:50]}" if best else "-"), flush=True)
    time.sleep(1)
