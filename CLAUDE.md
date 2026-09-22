# CLAUDE.md

LaTeX resume/CV for Kuo-Han Hung. Produces several tailored PDFs from one shared body of
content.

## Layout

```
pdf/                       built PDFs, one per variant
source/
  preamble.tex             \documentclass, packages, custom macros
  phd_cv.tex               variant: PhD applications
  robot_research_cv.tex    variant: robotics research roles
  robot_engineer_cv.tex    variant: robotics engineering roles
  robot_resume.tex         variant: robotics roles, resume format
  sections/*.tex           the content, single source of truth
  build/                   latexmk scratch (gitignored)
```

A **variant file** is thin: `\def\cvvariant`, `\def\cvdoclabel`, the preamble, and an
ordered `\input` list. It holds no prose. All prose lives in `sections/`, written once.

### The four variants

| File | Audience | Section order |
|---|---|---|
| `phd_cv.tex` | PhD applications | Education, Publications, Research, Work, Teaching, Awards |
| `robot_research_cv.tex` | Robotics research roles | Same, **plus Technical Skills** at the end |
| `robot_engineer_cv.tex` | Robotics engineering roles | Education, **Skills**, **Research**, Work, Publications, Teaching, Awards |
| `robot_resume.tex` | Robotics roles, resume format | Shortest: `research_exp_short`, no Teaching/Awards sections, publications [1]-[5] only, awards as one line in Education |

All four are currently 2 pages with zero Overfull boxes.

**`robot_resume.tex` has diverged from `robot_engineer_cv.tex`** and is now maintained
separately. It targets one page: it uses `sections/research_exp_short.tex` (one line per
project, Embodied AI Lab omitted), drops the Teaching and Awards sections, and shows only
publications [1]-[5].

`\cvdoclabel` sets the footer: `CV` for the three `*_cv` variants, `Resume` for
`robot_resume`. `\cvvariant` drives `\tagged`, which **is** wired up in
`preamble.tex`. It is currently used in exactly one place: the CSIE1000 teaching entry
is `\tagged{phd}`, because only `phd_cv` has room for a second TA entry. Publications [6]
and [7] are `\tagged{phd,research,engineer}` to keep them off the resume, and the one-line
awards entry in `education.tex` is `\tagged{resume}`.

## Build

Run **from `source/`** — every `\input` path is relative to the variant file, and
`source/.latexmkrc` supplies the output paths.

```bash
cd source && latexmk -interaction=nonstopmode robot_engineer_cv.tex
```

`.latexmkrc` pins three things, so don't pass `-pdf`, `-outdir` or `-auxdir` by hand:

- `$pdf_mode = 1` — build with **pdflatex**, not xelatex/lualatex/tectonic. The preamble
  uses the pdfTeX-only primitive `\pdfgentounicode=1` (and `\input{glyphtounicode}`) to
  keep the PDF ATS-parsable. Do not swap the engine to make a build work.
- `$out_dir = '../pdf'` — **finished PDFs collect in `pdf/`**, named after their variant.
- `$aux_dir = 'build'` — `.aux`, `.log`, `.fls`, `.out` go to `source/build/`. Read the log
  at `source/build/<variant>.log`. Never commit or hand-edit anything in `build/`.

Two passes are needed for `\publink` cross-references to resolve; `latexmk` handles this.
Clean with `latexmk -C` (removes the aux dir and the root PDF).

Toolchain: TeX Live is installed via `brew install texlive` (no sudo, real pdflatex,
~4.6GB). If `pdflatex` is missing on another machine, that is the command to run.

## Rules for multiple versions

Use the **cheapest level** that expresses the difference.

**Level 1 — whole sections: the variant file's `\input` list.** This list is expected to
differ between variants in three ways, and all three are normal:

- *Which* sections appear (`projects` in the industry version, out of the research one).
- *What order* they appear in (research experience above work experience for academic
  applications, reversed for industry).
- *Which file* backs a section. When tagging inside one file would make it unreadable, a
  variant may point at its own file — `sections/skills-industry.tex` instead of
  `sections/skills.tex`. Use this sparingly; it is the one place duplicate prose is
  tolerated, and the two files must be updated together.

**Level 2 — entries and bullets: the `\tagged` macro** (wired up in `preamble.tex`).
Content carries its audience and is still stored once:

```latex
\tagged{research,academic}{\resumeItem{Introduced attention entropy regularization...}}
```

Defined in `preamble.tex`:

```latex
\usepackage{etoolbox}
\providecommand{\cvvariant}{full}
\newtoggle{cvmatch}
\newcommand{\cvchecktag}[1]{\ifdefstring{\cvvariant}{#1}{\toggletrue{cvmatch}}{}}
\newcommand{\tagged}[2]{%
  \togglefalse{cvmatch}%
  \ifdefstring{\cvvariant}{full}{\toggletrue{cvmatch}}{\forcsvlist{\cvchecktag}{#1}}%
  \iftoggle{cvmatch}{#2}{}%
}
```

**Level 3 — different prose for the same item:** two `\tagged` blocks with different
wording. Rare. Do not reach for it before Levels 1 and 2.

### Constraints

- **Never fork a whole variant into its own copy of the content.** Content drift is the
  exact failure this structure exists to prevent.
- **Build all four after any `sections/` edit.** There is no master "shows everything"
  variant, so content that falls out of every `\input` list is invisible until someone
  greps for it.
- **Tag by audience, never by company.** `research`, `industry`, `mleng` — not `deepmind`,
  `openai`. Company tags multiply without bound and end as forked copies.
- **A `\tagged` block that empties a list breaks the build.** If every bullet inside a
  `\resumeItemListStart`/`End` pair can be hidden at once, LaTeX fails with "perhaps a
  missing \item". Tag the whole entry — subheading, list start, bullets, list end —
  instead of tagging bullets one by one.
- **Changing a shared bullet changes every variant.** Before editing untagged text in
  `sections/`, check which variants render it; rebuild each affected one.
- **Page length is per variant.** Each `cv-*.tex` has its own page budget. A bullet that
  fits the research version may overflow the industry one.

## Custom macros

Use these instead of raw LaTeX — they carry the spacing tuning.

| Macro | Args | Used for |
|---|---|---|
| `\resumeSubHeadingListStart` / `End` | – | wraps a list of entries in a section |
| `\resumeSubheading` | `{title}{dates}{subtitle}{location}` | a job / degree / lab entry |
| `\resumeItemListStart` / `End` | – | wraps bullets under one entry |
| `\resumeItem` | `{text}` | a top-level bullet |
| `\resumeSubItemListStart` / `End` | – | wraps sub-bullets under a bullet |
| `\resumeSubItem` | `{text}` | a dash-prefixed sub-bullet |
| `\resumePubItemListStart` / `End` | – | wraps the publication list |
| `\resumePubItem` | `{authors}{title}{venue}{url}{label}` | one publication, auto-numbered `[n]` |
| `\resumeProjectHeading` | `{name}{right-aligned text}` | a project entry |
| `\cvlink` | `{text}{url}` | blue `[text]` external link |
| `\publink` | `{label}` | blue `[n]` back-reference to a publication |
| `\tagged` | `{tag,tag}{content}` | include content only in the listed variants |

## Publication cross-references

`\resumePubItem`'s 5th argument is a `\label`; `\publink{thatLabel}` renders that
publication's number. Numbering follows source order in `publication.tex` and only counts
*rendered* items, so it is correct per variant automatically — but reordering publications
silently renumbers every `\publink`.

**A `\publink` whose publication is hidden in that variant renders `[??]`.** Two ways this
happens: the publication is commented out, or it carries tags that exclude the current
variant while the `\publink` does not. Give a `\publink` the same tags as the publication
it points at.

Make `\publink` degrade instead of printing `??`:

```latex
\newcommand{\publink}[1]{\ifcsname r@#1\endcsname\textcolor{blue}{[\ref{#1}]}\fi}
```

Known existing breakage: `sections/work_exp.tex` calls `\publink{route}`, but the `route`
publication in `publication.tex` is commented out.

## Conventions

- **Commented-out blocks are deliberate.** Entries and sections are toggled per
  application. Never delete them while "cleaning up." As variants land, prefer converting
  these to `\tagged` rather than leaving them commented.
- The `\vspace{-Npt}` values throughout are hand-tuned to fit the page. Leave them alone
  unless the task is explicitly about spacing.
- Bullets are one line each in the rendered PDF. Keep new text short enough to fit.
- Bold (`\textbf`) marks the research topic at the start of a bullet and venue
  abbreviations (**CoRL**, **ICML**) in publications.
- Names are written in full (`Kuo-Han Hung`), with the user's own name bolded in author
  lists; `*` denotes equal contribution, explained in the section preamble.
- Dates use `Mon. YYYY -- Mon. YYYY`, with `Present` for ongoing work.

## After editing

Rebuild **every** variant — a change to any `sections/` file affects all four — and read
the logs:

```bash
cd source && for v in phd_cv robot_research_cv robot_engineer_cv robot_resume; do
  latexmk -interaction=nonstopmode "$v.tex" >/dev/null 2>&1
  echo "[$v] $(grep -oE '\([0-9]+ pages' build/$v.log | tr -d '(')" \
       "overfull=$(grep -cE '^(Overfull|Underfull)' build/$v.log)" \
       "undefrefs=$(grep -c 'Reference.*undefined' build/$v.log)"
done
```

All four must stay at **2 pages, overfull=0, undefrefs=0**.

Note that `grep -c undefined` over the log also matches a harmless pre-existing
`Font shape OT1/cmr/bx/sc undefined` warning — match `Reference.*undefined` for real
broken cross-references.

**Reordering sections changes pagination.** Moving Research Experience above Publications
in the engineer variant pushed Technical Skills onto a third page; moving Skills up to sit
directly after Education fixed it. Always rebuild and check page counts after changing an
`\input` order.
