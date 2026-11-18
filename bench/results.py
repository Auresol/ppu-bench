#!/usr/bin/env python3
"""The benchmark table: python3 -I bench/results.py [results dir]

Reads bench/build/results/<version>/<workload>.json (written by the one-frame tests, test-suite/ppu_bench/ppu_bench.go) and
prints, as Markdown:
  1. per workload and version: pass, or the late pixels
  2. per version: its capacity on the two ladders (the last depth_N and bw_N step it passes) and the counters of busy_screen
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORDER = ["base", "slots16", "slots24", "tex64", "tex128", "slots24-tex64"]


def load(d):
    res = {}
    for v in sorted(os.listdir(d)):
        for f in sorted(os.listdir(os.path.join(d, v))):
            if f.endswith(".json"):
                r = json.load(open(os.path.join(d, v, f)))
                res[(v, r["workload"])] = r
    return res


def key(w):
    m = re.match(r"(depth|bw)_(\d+)$", w)
    return (1, m.group(1), int(m.group(2))) if m else (0, w, 0)


def main():
    d = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "bench", "build", "results")
    res = load(d)
    versions = [v for v in ORDER if any(k[0] == v for k in res)] + sorted({k[0] for k in res} - set(ORDER))
    workloads = sorted({k[1] for k in res}, key=key)

    print("| workload | depth | " + " | ".join(versions) + " |")
    print("|---|---|" + "---|" * len(versions))
    for w in workloads:
        depth = next((r["load"]["max_depth"] for (v, ww), r in res.items() if ww == w), "")
        cells = []
        for v in versions:
            r = res.get((v, w))
            cells.append("" if r is None else ("pass" if r["pass"] else f"{r['late_pixels']} late"))
        print(f"| {w} | {depth} | " + " | ".join(cells) + " |")

    print()
    print("| version | depth capacity | bw capacity | busy_screen: tex busy | main busy | adm slack px | depth seen |")
    print("|---|---|---|---|---|---|---|")
    for v in versions:
        def cap(kind):
            ok = [int(w.split("_")[1]) for (vv, w), r in res.items() if vv == v and w.startswith(kind + "_") and r["pass"]]
            return max(ok) if ok else "-"
        b = res.get((v, "busy_screen"))
        if b:
            p = b["perf"]
            pct = lambda n: f"{100 * n / max(p['frame_cycles'], 1):.1f}%"
            slack = "never trailed" if p["adm_slack_pixels"] == 0x7FFF else p["adm_slack_pixels"]
            tail = f"{pct(p['tex_busy_cycles'])} | {pct(p['main_busy_cycles'])} | {slack} | {p['slots_peak']}"
        else:
            tail = " | | | "
        print(f"| {v} | {cap('depth')} | {cap('bw')} | {tail} |")


if __name__ == "__main__":
    main()
