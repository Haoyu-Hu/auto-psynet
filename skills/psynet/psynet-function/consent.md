# PsyNet function: Consent

**What:** consent modules — placed **first** in the timeline; the recruiter validates their presence.

**Prebuilt (`psynet/consent`):** `MainConsent` (default), `NoConsent`, `DatabaseConsent`,
`AudiovisualConsent`, `OpenScienceConsent`, `PrincetonConsent`, `CAPRecruiterStandardConsent`,
`LucidConsent`, `VoluntaryWithNoCompensationConsent`.

**Custom pattern (`(Module, Consent)` subclass):** a `consent_text_template` (`Markup`, i18n via `_p`),
a consent page (`PushButtonControl(choices=["I consent","I do not consent"], bot_response="I consent")`),
and a `RejectedConsentPage` on decline; take `DURATION`/`PAYMENT` args to fill the text. Register your
institution's IRB-approved consent module via `apsy:consent` (it points the build at your file).

**Config:** default `MainConsent`; override via the `apsy:consent` command (recorded under
`.apsy/state.json` `consent.*`, read by `apsy:wire-timeline`).

**Gotchas:** consent is the FIRST timeline element; deception requires a debrief (ethics §1.4); fair
compensation must be stated (§1.3).
