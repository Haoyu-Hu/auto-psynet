---
command: consent
description: Configure the consent form (default PsyNet MainConsent) — separate file? class/function to import? how to use it?
allowed-tools: Bash, Read, AskUserQuestion
---

# apsy:consent — consent configuration

The default consent is PsyNet `MainConsent`. To set a **custom** consent, ask the three questions and
record the answers to `.apsy/state.json` under `consent` (read by `apsy:wire-timeline`):

1. **Separate file?** If yes, the path (e.g. `consent_science_of_learning.py`); if no, skip.
2. **Which class/function to import** (e.g. `consent_cococo_science_of_learning`).
3. **How to use it** — instantiation + placement (e.g. `consent_x(DURATION=.., PAYMENT=..)`, first in the
   timeline).

Write via `bin/apsy-state.sh set consent.<key> <value>`. Point it at your institution's IRB-approved consent module (a `(Module, Consent)` subclass).
