# Auto-PsyNet — Scientific-Integrity & Ethics Policy

> This is the policy the plugin **enforces** (decision D7). It is the single source of truth that the
> **G1** (plan-verification) and **G4** (human-deployment) gates read. It is config-as-data: edit it to
> change what the gates enforce, without touching skill logic. At Phase-0 scaffolding this file ships at
> `config/ethics-policy.md` and seeds the machine-readable rubrics `config/gates/G1.yaml` + `G4.yaml`.

**Accountability:** the plugin *proposes and verifies*; it is **not** a substitute for an IRB. The human
researcher remains accountable for ethics and for every scientific claim.

**Applicability:** the **scientific-integrity** rules (§2) bind on *every* study, including Track A
(LLM-pilot / in-silico). The **research-ethics** rules (§1) bind on **Track B** (real human
participants) and are enforced hard at the G4 deploy gate.

**Enforcement levels:**
- 🛑 **HARD BLOCK** — cannot proceed (to build at G1, or to human deployment at G4); never auto-passed at
  any autonomy level.
- ⚠️ **ADVISORY** — flagged at the gate, requires explicit acknowledgement, logged in `decisions.md`.

---

## 1. Research ethics (human participants) — enforced at G1 + G4

| # | Rule | Level |
|---|------|-------|
| 1.1 | **Informed consent present.** A consent module is the first timeline element; describes task, duration, risks; voluntary; right to withdraw. Default = PsyNet `MainConsent`; override via `apsy:consent`. | 🛑 HARD BLOCK if absent |
| 1.2 | **IRB approval/exemption.** Before any real human deployment, the researcher must **attest** that Cornell IRB approval or exemption exists. The plugin records the attestation in `deployment-log.md`; it does not grant approval. | 🛑 HARD BLOCK at G4 without attestation |
| 1.3 | **Fair compensation.** Target pay must meet the **wage floor (default $10/hour = `wage_per_hour`)**. G4 blocks if configured `base_payment` + expected bonus over the time-estimate implies below the floor. Adjust via `apsy:prolific` / `apsy:lucid` / `apsy:mturk`. | 🛑 HARD BLOCK below floor |
| 1.4 | **Deception requires justification + debrief.** Any deception is justified in the plan and followed by a debrief page. | 🛑 HARD BLOCK if deception without debrief |
| 1.5 | **Vulnerable populations.** Minors or vulnerable groups trigger extra scrutiny. | 🛑 HARD BLOCK without explicit extra approval |
| 1.6 | **Data privacy / PII.** Minimize PII; use PsyNet's anonymized export; for EU/global samples, GDPR-aware handling (relevant to cross-cultural studies). | ⚠️ ADVISORY (flag + acknowledge) |
| 1.7 | **Debrief provided** where appropriate (sensitive content, deception). | ⚠️ ADVISORY → required when 1.4 triggers |

## 2. Scientific integrity — enforced at G1 + G6 (all studies)

| # | Rule | Level |
|---|------|-------|
| 2.1 | **Preregistration / no p-hacking.** Analysis is locked at G1 and held like a holdout; G6 verifies the analysis matched the plan; deviations are logged, never silent. | 🛑 HARD (confirmatory claims blocked without a locked plan) |
| 2.2 | **No HARKing.** Hypotheses stated before data; post-hoc analyses labeled exploratory. | ⚠️ ADVISORY (G1/G6 flag) |
| 2.3 | **Adequate power.** G1 requires a power justification for confirmatory claims. | ⚠️ ADVISORY (strong warning; underpowered design flagged, not blocked) |
| 2.4 | **No fabrication.** Numbers come only from executed analyses; LLM-pilot / synthetic data is **never** presented as human data. | 🛑 HARD GUARDRAIL |
| 2.5 | **LLM-subject honesty.** In-silico results are labeled, caveated, and never passed off as human evidence. | 🛑 HARD GUARDRAIL |
| 2.6 | **Multiplicity & reporting.** Correct for multiple comparisons; report effect sizes + uncertainty, not just p-values. | ⚠️ ADVISORY (G6 flag) |
| 2.7 | **AI-involvement disclosure.** Generated papers must disclose that AI assisted the research (design/build/analysis). | 🛑 HARD (required in the paper) |
| 2.8 | **Reproducibility.** Bundle code + data + analysis + preregistration (the repro-package). | Stage 5 deliverable |

## 3. Enforcement mechanics

- **G1 (plan-review)** scores the plan against §1 + §2, consulting the blind-spot library; HARD items
  block the build, ADVISORY items flag + require acknowledgement.
- **G4 (deploy)** is a HARD gate at **every** autonomy level: requires (a) explicit human approval, (b) an
  IRB attestation (1.2), and (c) a configured spend cap; the `spend-gate` PreToolUse hook intercepts
  `psynet deploy …` / recruiter API / payment actions and blocks unless all three are present.
- **Autonomy never softens HARD items.** `semi_autonomous` / `autonomous` may auto-advance ADVISORY
  acknowledgements but cannot auto-pass any 🛑 item.

## 4. Consent default

- **Default:** PsyNet `MainConsent` (`psynet.consent.MainConsent`), placed first in the timeline.
- **Custom / institutional consent:** register your institution's IRB-approved consent — a
  `(Module, Consent)` subclass (taking `DURATION`/`PAYMENT`, i18n-ready, with your IRB contacts) — via
  `apsy:consent`.
- **Override:** `apsy:consent` records (1) the separate-file path (if any), (2) the class/function to
  import, and (3) how to instantiate/place it in the timeline.

## 5. Compensation floor

- **Default floor:** `wage_per_hour = $10` (matches the lab convention seen in the examples).
- Set per study via `apsy:prolific` (also `base_payment`, `prolific_estimated_completion_minutes`,
  `prolific_recruitment_config`), or `apsy:lucid` / `apsy:mturk` for those recruiters.
- G4 blocks deployment whose expected pay-per-hour falls below the floor (rule 1.3).

## 6. Decision provenance

Resolved 2026-05-26 (D7): consent default = `MainConsent` (configurable); wage floor = $10/hour;
enforcement = hard-block for §1.1–1.5 + §2.4/2.5/2.7; IRB attestation **required** before real
deployment; AI-involvement disclosure **required**. See `project-plan/05-roadmap.md` §5.4.
