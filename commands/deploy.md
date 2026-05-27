---
command: deploy
description: Deploy for REAL human data collection (gate G4) + recruit. HARD gate — human approval + IRB attestation + spend cap.
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, Task, Skill
---

# apsy:deploy — DEPLOY & RECRUIT (gate G4)

Run the **`apsy:deploy`** skill (gate **G4**), then **`apsy:recruit`**. **Requires G2 + G3 = pass.**

**G4 is a HARD gate, never auto-passed at any autonomy level:** explicit human approval + a Cornell IRB
approval/exemption attestation + a configured spend cap (`spend.cap_usd`) + green G2/G3. This is the
first real-money / real-people step (`config/ethics-policy.md` §1.2, §3).

After deployment, `apsy:recruit` launches recruitment (Prolific/Lucid/MTurk, configured via
`apsy:prolific` / `apsy:lucid` / `apsy:mturk`) **within the spend cap** and monitors live data quality.
Stop when the clean target N is met or the cap is approached.
