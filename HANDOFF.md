# GLU IFC Preparation — Work Handoff

**Project:** Gelephu Airport (GLU) · Package 1 — Airfield Works
**Deliverable:** Team-alignment deck on how to prepare the Issued-For-Construction (IFC) set, plus a review of the designer's Tender lists
**Prepared for:** APMT / PMO
**Handoff date:** 16 July 2026
**Status:** Ready to continue locally

---

## 1. What was produced

| File | What it is | Where it lives |
|---|---|---|
| `GLU_IFC_Airfield_Preparation.pptx` | 19-slide alignment deck (English, GLU house style) | Root of this repo, branch `claude/jolly-dirac-LAdEI`, PR #1 |
| `HANDOFF.md` (this file) | Work report for local continuation | Root of this repo |

The deck was built in the existing GLU internal-review house style (warm-brown palette, Segoe UI, "STRICTLY CONFIDENTIAL" footer, bilingual chrome adapted to English-only). It supersedes an earlier project-wide draft; the current version is scoped to the **Airfield package (P01) only**, per the boundary slide provided.

---

## 2. Deck structure — 19 slides

**Part 1 · Scope & Principle**
1. Title — *IFC Preparation — Airfield Package*
2. Contents
3. Scope of this IFC (Airfield) — in-scope works + NSC equipment + PTB/Landside boundary
4. Why align now — bid evaluation, ~16 BoQ gaps, BCAA compatibility, certification clock, controlled register, build on PMO
5. Organising principle — `Airfield(P01) → Asset/Zone → Discipline → Type → Number → Rev/Status`

**Part 2 · Structure & Controls**
6. Airfield work-area matrix — 10 zones × (key works · disciplines · interfaces · owner)
7. Document volume structure — Volume 0 to Volume 8
8. Master register — 17 control fields with airfield example values

**Part 3 · Coding & Interfaces**
9. Key interfaces & hold points — 6 cards (Airfield↔PTB, NAVAIDS↔DoAT, BCAA compatibility, flight calibration & certification, drainage↔ESIA, NSC equipment)
10. Drawing coding — `GLU-P01-[Asset]-[Discipline]-[Type]-[Sequence]` + discipline codes + asset codes
11. Specification coding — CSI MasterFormat + airport-specific `40-AF…48-OR` divisions

**Part 4 · Gate, Roles & Next Steps**
12. Minimum IFC issue checklist — 14 mandatory gate items
13. Roles & lead ownership — APMT, CAPE, AGL/NAVAIDS/MET specialists, QS
14. Next steps — 5 actions with owners and Week 1–4 schedule

**Part 5 · Review of designer's Tender lists (appended)**
15. Review overview & verdict — 765 drawings across 6 transmittals; 119 spec chapters across 6 disciplines
16. Drawing list — strengths & gaps vs IFC rules
17. Specification list — strengths & gaps vs IFC rules
18. Coverage RAG vs the airfield work-area matrix (Covered / Verify / Confirm)
19. Actions to make it IFC-ready — 5 prioritised moves (P1–P5)

---

## 3. Design system (keep consistent when editing)

**Slide size:** 10.0 × 7.5 in (4:3)  ·  **Font:** Segoe UI throughout

**Palette (hex):**

| Role | Hex | Usage |
|---|---|---|
| Dark brown | `#6D594C` | Titles, headings, page number, primary chrome |
| Mid brown | `#8C7464` | Subtitles, footer, "STRICTLY CONFIDENTIAL" |
| Body dark | `#5A493F` | Body text |
| Terracotta | `#A33D2E` | Alerts, big numbers, package codes, red accents |
| Steel blue | `#3E5C76` | Secondary accents, headers, owners |
| Green | `#2E7D32` | OK / checkbox / RAG-covered |
| Orange | `#E68A00` | Warning / RAG-verify |
| Cream | `#F4EFE9` | Row stripe, panel backgrounds |
| Red tint | `#F7E1DA` | Airport-specific block backgrounds |
| Line grey | `#E5E5E5` | Divider rules |

**Standard chrome (every content slide):**

- Title 22 pt bold `#6D594C` at (0.5", 0.4"), width 9.2"
- Subtitle 13 pt `#8C7464` at (0.5", 0.9")
- Divider rule 0.75 pt `#E5E5E5` at (0.5", 1.42")
- Bottom rule at (0.4", 7.15") · "STRICTLY CONFIDENTIAL" 8 pt `#8C7464` centered at (4.0", 7.18")
- Vertical page-tick 2 pt `#6D594C` at (9.3", 7.18") + page number 10 pt bold at (9.4", 7.16")

---

## 4. Key review findings (what to raise with the designer)

**Source assessed:** `GLU_CAP_AV_Consolidated_Drawing_List__Tender_20260220.xlsx` (TR 1005, 20 Feb 2026) and `GLU_CAP_AV_List_of_Spec_consolidated_Tender_20260220.xlsx`.

**Verdict:** Technically comprehensive design coverage — but issued as a Tender transmittal, not yet a controlled IFC baseline.

**Quantitative evidence:**

- Drawings: **765** total across 6 transmittals (ANB Arch 115, ANB C&S 148, ANB M&E 188, Sitewide Utilities 147, AFL 50, Airfield 117).
- **Every one of the 765 rows** has Rev blank or `"-"` — no status, no frozen revision.
- Numbering inconsistent: top-level `AV` (715) vs `UTL` (50 — the AFL sheet); underscores everywhere, plus **191 hyphens + 36 spaces** as mixed separators; 3- vs 4-digit sequences; **8 numbers still contain `---`/`XX` placeholders**.
- Specs: **119 chapters** across 6 disciplines (Arch 13, Civil/Struct 23, M&E 14, Specialised 3, Airfield Electrical 38, Airfield Mechanical 28). "Chapter 01: General" repeats in multiple disciplines — not unique. Not mapped to CSI or `40-AF…48-OR`.

**Coverage RAG:** most work areas Covered; **NAVAIDS/ANS** and **MET** are **Verify** (siting + performance spec only); **NSC equipment** is **Confirm** (mark NSC · FAT/SAT/T&C · BCAA compatibility · BoQ).

**Prioritised actions:**

| # | Action | Owner | Reference slide |
|---|---|---|---|
| P1 | Consolidate into one master register (V0) — 765 dwgs + 119 spec chapters, one row per doc | APMT / PMO | 7 · 8 |
| P2 | Freeze revision & add status — IFC / For Tender / Superseded + IFC baseline date | APMT + designers | 8 · 12 |
| P3 | Harmonise numbering — one scheme `GLU-P01-[Asset]-[Disc]-[Type]-[Seq]`; fix AV/UTL, separators, digits; clear `---/XX` | CAPE + APMT | 10 |
| P4 | Add control & cross-reference fields — asset/zone, discipline, type, related spec/BoQ/model, dependencies, contractual status | APMT | 8 |
| P5 | Map specs to CSI + `40-AF…48-OR` & link BoQ — single Div 00/01; add ORAT/48-OR; close the ~16 BoQ gaps | CAPE / QS | 11 |

---

## 5. Continuing on your Mac

**Files to pull:**

```bash
# on your Mac, in a working folder
git clone <MrLidonghai/MrLidonghai repo url>
cd MrLidonghai
git checkout claude/jolly-dirac-LAdEI
open GLU_IFC_Airfield_Preparation.pptx   # opens in Keynote or PowerPoint
```

Or download the PPTX directly from PR #1's "Files changed" tab.

**Editing options:**

- **Keynote (macOS):** opens the PPTX. On save-back, use *File → Export To → PowerPoint* to preserve `.pptx`. Some manual textboxes may re-flow slightly — check the chrome (footer/page tick) after save.
- **PowerPoint for Mac:** cleanest fidelity, especially for the `▸ › ✓` glyphs and Segoe UI. Recommended.
- **Google Slides:** avoid — will lose Segoe UI and re-flow the manual textboxes.

**If you want to script edits (optional):** the deck was built programmatically with `python-pptx`. I can regenerate the build script and drop it in `scripts/` on the branch — just ask. That lets you re-run to add slides or bulk-update content without touching the visual layout.

---

## 6. Open items / decisions to confirm

1. **Owner assignments (Slide 13)** — I inferred APMT lead, CAPE for airfield main works, plus AGL / NAVAIDS / MET specialists and QS. Please sanity-check against the actual GLU org chart.
2. **Week 1–4 schedule (Slide 14 and P1–P5)** — starting proposal only. Adjust to real cadence and any bid-evaluation deadlines.
3. **Coverage assessment (Slide 18)** — derived from titles, section headers and spec chapters. Worth a quick confirm with CAP/AV on:
   - NAVAIDS/ANS drawing scope — is `LLZ Antenna` the only siting drawing, or are there more not exposed by title?
   - MET equipment scope — how much is in `Specialised System · CNS and Meteorological Equipment`, and what's the NSC split?
   - NSC pricing split in the BoQ — reconcile to the ~16 flagged BoQ gaps.
4. **PTB & Landside interface freeze** — needs a joint session with the PTB package team before the Airfield IFC can freeze (Slide 9, hold point #1).

---

## 7. Git & PR references

- **Repo / branch:** `MrLidonghai/MrLidonghai` @ `claude/jolly-dirac-LAdEI`
- **PR:** #1 (open)
- **Commits on the branch:**
  1. Initial airfield-scoped English deck (14 slides)
  2. Appended review of designer's Tender lists (slides 15–19)
  3. This handoff report

Any further push to this branch will keep updating the same PR.

---

## 8. Contact / next handoff

Once you've picked this up locally, natural next steps are:

- Circulate the deck to APMT, CAPE and the specialist leads for review.
- Run the alignment session and capture the decisions on the open items above.
- Kick off **P1** (stand up the Volume-0 master register) — this is the single most valuable move; everything else hangs off it.

Good luck — happy to pick this back up if you want any additions or a follow-up round.
