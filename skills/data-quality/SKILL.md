---
name: data-quality
description: "ANALYZE gate G5 — screen the data for quality: completion, attention/manipulation checks, the preregistered exclusions, duplicates/bots, and target-N. Produces the clean analysis dataset."
---

# apsy:data-quality — gate G5 (Data Quality)

> EXECUTION CONTRACT. Apply the **data-analyst** lens. **Apply the PREREGISTERED exclusion rules (§6) —
> not post-hoc ones.**

## STEP 1 — Generic screen
Run `bin/apsy-data-quality.py <export_dir> --target-n <N>` (N from `recruitment.target_n`). Review the
JSON: completion rate, failed count, duplicates, attention-check columns, target-N met.

## STEP 2 — Preregistered exclusions
Apply the exclusion rules exactly as locked in §6 / G1. **Any new or post-hoc exclusion is a deviation** —
log it with justification in `.apsy/decisions.md`. Record N before and after exclusions.

## STEP 3 — Clean dataset
Produce the clean analysis dataset the `analyze` step will consume.

## STEP 4 — Verdict
- **PASS** — exclusions applied; target N met (or the shortfall acknowledged). `bin/apsy-state.sh set
  gate_statuses.G5 pass`.
- If under target N → recommend extending recruitment (Track B) or flag the reduced power.

**Validation gate:** exclusions match the prereg (deviations logged); clean N recorded.
