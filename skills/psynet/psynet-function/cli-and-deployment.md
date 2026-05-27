# PsyNet function: CLI & deployment

**CLI (`psynet ...`):** `debug local` (dev); `debug ssh|heroku` (cloud test, recruitment OFF);
`deploy ssh|heroku` (real); `export local|ssh|heroku`; `test local` (bots → gate G2); `estimate`;
`prepare`; `update-scripts` (regenerate boilerplate); `generate-constraints`; `experiment-variables`;
`db`; `lucid ...`; `translate`.

**Infra:** Docker + Postgres + Redis + a worker/clock; a public web endpoint for real recruitment.

**Recruiters (`config.txt` `recruiter =` / `Exp.config`):** `generic` (manual link; dev default),
`hotair` (test), `prolific`, `mturk`, `lucid-recruiter` (global panels), `cap-recruiter`. Adaptive
recruitment via `recruit_mode` (`n_participants` / `n_trials`) + `initial_recruitment_size`.

**How `apsy` wraps these:** `apsy-scaffold.sh` (→ `update-scripts`), `apsy-test.sh` (→ `test local`, G2),
`apsy-debug.sh` (local | ec2), `apsy-deploy.sh` (G4 gate → `deploy`), `apsy-export.sh` (→ `export`),
`apsy-pilot.sh` (LLM-participant `test local`).

**Gotchas:** pin the `psynet` version (`requirements.txt`); local debug needs Docker; the **`ec2`**
backend (Dallinger provisioning) sidesteps HPC Docker limits; real `deploy`/recruit is gated by **G4**
(`config/ethics-policy.md`).
