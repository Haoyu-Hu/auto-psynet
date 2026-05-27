# PsyNet function: Prescreening tasks

**What:** drop-in modules that screen participants for eligibility/quality before the main task.

**Modules (`psynet/prescreen`):** `AttentionTest`; `HeadphoneTest` (+ `HugginsHeadphoneTest`,
`AntiphaseHeadphoneTest`, `BeepHeadphoneTest`); `ColorBlindnessTest`, `ColorVocabularyTest`;
`LexTaleTest`, `LanguageVocabularyTest`; `AudioForcedChoiceTest`; REPP tapping/volume calibration; vocab
tests (`WikiVocab`, `BibleVocab`).

**Use:** place after consent, before the trial maker(s). Failing participants are excluded per the
module; these exclusions feed gate **G5** (data-quality).

**Gotchas:** choose screens matching the modality (headphone tests for audio, color tests for color
vision); each adds a `time_estimate`; align the prescreen with the preregistered exclusion criteria (§4).
