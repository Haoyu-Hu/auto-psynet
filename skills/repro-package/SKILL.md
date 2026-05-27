---
name: repro-package
description: "PUBLISH step — bundle an OSF-ready reproducibility package: code + locked preregistration + analysis scripts/results + anonymized data + manifest. Optional OSF push."
---

# apsy:repro-package — reproducibility package

> EXECUTION CONTRACT. **Privacy: anonymized data ONLY** (`config/ethics-policy.md` §1.6).

## STEP 1 — Assemble
Run `bin/apsy-repro.sh <experiment_dir> [out_dir] [anonymized_data_dir]`. Pass the PsyNet **`anonymous/`**
export as the data dir — **never** the `regular/` (PII) export. The script bundles code,
preregistration, analysis + results, the decision/iteration logs, and a manifest.

## STEP 2 — Verify
Confirm the package contains: `code/`, `preregistration/`, `analysis/` (with `results.json`), `docs/`,
and either anonymized `data/` or the data README pointer. **Confirm no non-anonymized data is present.**

## STEP 3 — (Optional) OSF push
If an OSF token is configured, create/update the OSF project and upload; otherwise leave the local
package for manual upload (do not push without explicit user confirmation).

**Validation gate:** package assembled; **no non-anonymized participant data included**.
