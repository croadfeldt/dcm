#!/usr/bin/env python3
"""UC persona-vocabulary gate (mirror of udlm's PER-001). Every use case's
scenario.actor.persona must resolve to the canonical persona set in
dav/use-cases/PERSONAS.yaml (a canonical id or a folded alias). See the udlm copy for the full
rationale — the persona a UC is written from was a free string that had drifted to 12 values."""
import glob, os, sys, yaml
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VOCAB = os.path.join(ROOT, "dav", "use-cases", "PERSONAS.yaml")

def main():
    spec = yaml.safe_load(open(VOCAB, encoding="utf-8"))
    resolvable = {p["id"] for p in spec["personas"]} | set(spec.get("folded_aliases") or {})
    fails, n = [], 0
    for path in sorted(glob.glob(os.path.join(ROOT, "dav", "use-cases", "**", "*.yaml"), recursive=True)):
        doc = yaml.safe_load(open(path, encoding="utf-8")) or {}
        persona = (((doc.get("scenario") or {}).get("actor")) or {}).get("persona")
        if persona is None:
            continue  # not a use-case file (README, vocabulary, taxonomy)
        n += 1
        rel = os.path.relpath(path, ROOT)
        if str(persona) not in resolvable:
            fails.append(f"{rel}: persona={persona!r} off-vocabulary — add to PERSONAS.yaml (persona or alias) first")
    for f in fails: print("FAIL [PER-001] " + f)
    print(f"{n} use case(s) checked, {len(fails)} off-vocabulary persona(s)")
    return 1 if fails else 0

if __name__ == "__main__":
    sys.exit(main())
