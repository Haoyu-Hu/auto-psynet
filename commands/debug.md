---
command: debug
description: Run the current experiment for debugging — pick local (psynet debug local) or a provisioned EC2 instance.
allowed-tools: Bash, Read, AskUserQuestion
---

# apsy:debug — run the experiment (local or EC2)

1. Confirm the current directory is a PsyNet experiment (`experiment.py` + `config.txt`) with an `.apsy/`
   state dir. If not, tell the user to scaffold first (`/apsy:build`) and stop.
2. Use `AskUserQuestion` to choose the **target**:
   - **local** — `bin/apsy-debug.sh local` → `psynet debug local` (needs Docker; fast, free).
   - **ec2** — `bin/apsy-debug.sh ec2` → provision/refresh a Dallinger EC2 instance
     (`{username}.{study}.{host}`, region + `m7i.{N}xlarge` from config) and run there. Use this when
     local Docker is unavailable.
3. Run the chosen target via the engine, surface the participant URL + logs, and append the action to
   `.apsy/deployment-log.md`.

**This is debug only — it does NOT enable real recruitment.** Real human data collection is `/apsy:deploy`,
which is gated by **G4** (human approval + IRB attestation + spend cap).
