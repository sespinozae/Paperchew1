# Chewing modulates theta oscillation and functional connectivity of the frontocentral cortex in attention and working memory

This repository contains data and MATLAB scripts to reproduce the figures from our study.

### Experiment Methods Summary

## Participants

- Thirty healthy right-handed volunteers (aged 21–60, 50% female).
- No recent psychiatric diagnoses, temporomandibular disorders, falls, vestibular issues, or cognitive impairment (MMSE).
- All maintained natural dentition.

## Anesthesia & Chewing Manipulation

- **Local gingival anesthesia** (lidocaine spray + cetrimide) was applied to the **left side**—blocking sodium channels without crossing the blood-brain barrier and avoiding nociceptive stimulation.
- Participants chewed **rhythmically on the contralateral (right) side**, ensuring the anesthetized side only provided sensory blockade, isolating central mechanisms of chewing.
- A **placebo spray** was used in parallel blocks to control for local sensation.

## Experimental Design

- Fully **within-subject 2 × 2 factorial design**:  
  **Factor 1:** Chewing (yes vs. no)  
  **Factor 2:** Anesthesia (yes vs. placebo)
- Both tasks (2‑Back and visuospatial oddball) were completed in all four conditions.
- Order was **counterbalanced**: 16 participants received anesthesia first, 14 received placebo first.
- A **washout period** ensured no residual anesthesia between blocks.

## Task Protocols

# 1. Two‑Back Working Memory Task
- Visuospatial stimuli: a small square appearing for 200 ms within a 3×3 grid.
- Inter-stimulus interval (ISI): 1600 ms.
- Respond when current position matches the one two trials back.
- 75 stimuli per block, 25% targets → ~300 trials total per participant.

# 2. Visuospatial Oddball Task (VO)
- Five tilted crosses (±15° inversion) shown per trial.
- Each stimulus: 200 ms exposure, 900 ms ISI (with 0–50 ms jitter).
- 60 trials per block, 20% targets → ~240 trials per participant.

No two target trials were consecutive. Both tasks used center‑screen stimuli at ~5° visual angle.

## EEG & EMG Acquisition

- Stimuli delivered via PsychoPy; EEG recorded with Biosemi ActiveTwo (64+8 channels) at 1 kHz sampling.
- EEG preprocessing: downsample to 500 Hz, high-pass filter at 1 Hz, remove line-noise, bad channels, ICA-based artifact removal (ICLabel), re-reference to average.
- Epoch windows: VO task −200 to 800 ms; 2‑Back −300 to 1600 ms.
- All latencies corrected for equipment delay (~13.7 ms).

- EMG: bipolar masseter recordings (predominantly right side), band-pass filtered (20–400 Hz), rectified, envelope via 50-sample RMS.
- Chewing peaks detected using adaptive threshold (mean + 1 SD), minimum inter-peak distance 0.5 s.
- Chewing frequency (peaks/sec), coefficient of variation (CV), and median absolute deviation (MAD) were computed; CV ≤ 0.25 considered acceptable.

## Behavioral & Statistical Analysis

- Trials trimmed below 1st and above 99th percentile per participant.
- Normality checked via Anderson‑Darling test.
- Repeated-measures ANOVA (Chewing × Anesthesia) initially showed no anesthesia effects (p > 0.1), so subsequent analyses collapsed across anesthesia and focused on chewing effects.
- Comparisons: paired t‑tests or Wilcoxon signed-rank tests, depending on normality.
- Time–frequency ROI power compared with t‑tests.
- Correlations between chewing frequency and neural metrics used Spearman’s rho.
- Significance threshold: p < 0.05; corrections applied for multiple comparisons.

## Time-Frequency & Connectivity Analysis

- Time–frequency analysis via wavelet transform (Morlet wavelets, 4 cycles at 1 Hz to 13 cycles at 40 Hz), high resolution (0.1 Hz, 1–40 Hz).
- ROI averaging over fronto-central electrodes: Fp1, Fpz, Fp2, AF3, AFz, AF4, F1, Fz, F2.
- Functional connectivity estimated with phase-lag index (PLI); values thresholded at ±1.96 SD to identify significant electrode pairs.

---

## Repository Structure

project-root/
├── make_all_figs.m # Generates all figures (main & supplemental)
├── Exp1_30_dataset.csv # Behavioral data
├── *.mat # EEG/EMG/TF/connectivity data
├── Supplemental/ # Supplemental .mat files (s1a, s1b … s2b)
├── outputs/ # Generated figure files (.png / .svg)
└── README.md # This file
