# Paper build

Single-file journal-style manuscript: `paper.tex`.

## Build

```bash
cd paper
pdflatex -interaction=nonstopmode paper.tex
bibtex paper
pdflatex -interaction=nonstopmode paper.tex
pdflatex -interaction=nonstopmode paper.tex
```

## Layout

- `paper.tex` — main manuscript.
- `refs.bib` — bibliography.
- `tbl_*.tex` — table fragments included from the main file.
- Figures are read from `../wpi/outputs/figures/` and `../improved-v2/outputs/figures/` via `\graphicspath`.

## DOCX export (optional)

```bash
pandoc paper.tex --bibliography=refs.bib --citeproc -o paper.docx
```
