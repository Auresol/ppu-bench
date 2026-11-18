#!/usr/bin/env python3
"""The benchmark table: python3 -I bench/results.py [results dir]

Reads bench/build/results/<version>/<workload>.json (local runs of the one-frame tests, test-suite/ppu_bench/ppu_bench.go)
or, given version/base/test-suite/build/rtl-stat-jobs, the summary.json of every fetched rtl-stat job, and prints, as Markdown:
  1. per workload and version: pass, or the late pixels
  2. per version: its capacity on the two ladders (the last depth_N and bw_N step it passes) and the counters of busy_screen
"""

import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORDER = ["base", "slots16", "slots24", "tex64", "tex128", "slots24-tex64"]


def load(d):
    """bench/build/results/<version>/<workload>.json of local runs, or the summary.json of rtl-stat jobs (fetched by
    `rtl-stat-job report <job>` into test-suite/build/rtl-stat-jobs/<job>/rtl-stat/): both become the same record."""
    res = {}
    for f in sorted(glob.glob(os.path.join(d, "*", "*.json"))):
        r = json.load(open(f))
        res[(r["version"], r["workload"])] = r
    for f in sorted(glob.glob(os.path.join(d, "*", "rtl-stat", "summary.json"))):
        s = json.load(open(f))
        version = s.get("chip_version") or "base"
        for m in s.get("modules", []):
            for c in m.get("cases", []):
                met = {k: v["max"] for k, v in c.get("metrics", {}).items()}
                if "late_pixels" not in met:
                    continue
                res[(version, c["name"])] = {
                    "pass": c["status"] == "pass", "late_pixels": met["late_pixels"],
                    "load": {"max_depth": met.get("load_max_depth")},
                    "perf": {"frame_cycles": 10000, "tex_busy_cycles": met.get("tex_busy_pct_x100", 0),
                             "main_busy_cycles": met.get("main_busy_pct_x100", 0),
                             "adm_slack_pixels": met.get("adm_slack_pixels", 0x7FFF), "slots_peak": met.get("slots_peak")},
                }
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
