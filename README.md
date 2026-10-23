# Grouse harvests across Norwegian landscapes

An exploratory BIO940 project asking whether harvest patterns differ between
forest-associated grouse and ptarmigan across contrasting landscapes. Four
species are compared in six illustrative municipalities during 2008-2009 to
2018-2019, with an official land-cover snapshot and a location map.

Open [`report.html`](report.html) for the results and discussion of four
research papers. Edit [`report.qmd`](report.qmd), not the HTML.
**See [`EDITING.md`](EDITING.md) for a short VS Code editing walkthrough.**

The harvest CSV comes from the course file `smallGame.RDS`; all 264 cells were
checked against [SSB table 07514](https://www.ssb.no/en/statbank1/table/07514).
There are 205 observed and 59 missing values. Land cover comes from SSB table
09594, map points from © Kartverket and outlines from Natural Earth.
See [`data/README.md`](data/README.md) for selection, licences and limitations.
The original RDS is not needed. On a fresh clone, the pipeline downloads the
small elevation archive once; later runs reuse the local file.

## Project files

```text
_targets.R                    Pipeline and dependencies
R/functions.R                 Cleaning, summaries and four figures
data/small_game.csv            Source harvest extract
data/land_cover.csv            SSB 2018 land-cover snapshot
data/municipalities.csv        Official map points and name/code mapping
data/scandinavia.geojson       Natural Earth reference map
data/norway_elevation.tif      Elevation input downloaded once; ignored by Git
data/README.md                 Data provenance and licences
data/small_game_clean.csv      Generated tidy data
data/harvest_summary.csv       Generated 24-row summary
data/habitat_comparison.csv    Generated six-row comparison
figures/grouse_harvest.png     Generated annual series, 300 dpi
figures/study_map.png          Generated location map, 300 dpi
figures/harvest_comparison.png Means on a common scale, 300 dpi
figures/forest_relationship.png Conifer cover versus forest-grouse harvest
report.qmd / report.html       Editable report / standalone output
references.bib                 Four research-paper citations
styles.css                    Report appearance
renv.lock / renv/              R package versions and activation files
.Rprofile / .gitignore         Project activation and Git exclusions
assignment.Rproj              Optional RStudio compatibility
README.md / EDITING.md         Reproduction and editing instructions
```

The `_targets/` cache, `.local/` working files, and local `renv` libraries/caches
are ignored. The initial version is preserved in ignored `.local/version1/`.
Generated CSVs, figures and HTML are retained for convenient peer review.

## Reproduce in VS Code on Windows

Tested software: **R 4.6.1**, **Quarto CLI 1.10.19**, Git and VS Code. R and
Quarto are separate installations; renv restores R packages, including sf
and terra for the elevation background.
RStudio is not required. VS Code's R and Quarto extensions are optional.

Open the project folder in VS Code and a **PowerShell terminal at the project
root**. Configure paths once per terminal (edit for another computer):

```powershell
$rBin = Join-Path $env:LOCALAPPDATA 'Programs\R\R-4.6.1\bin'
$quartoBin = Join-Path $env:LOCALAPPDATA 'Programs\Quarto\bin'
$env:PATH = "$rBin;$quartoBin;$env:PATH"
$env:QUARTO_R = Join-Path $rBin 'Rscript.exe'
$env:LC_ALL = 'English_United States.utf8'
New-Item -ItemType Directory -Force '.local/tmp' | Out-Null
$env:TMPDIR = (Resolve-Path '.local/tmp').Path
$env:TEMP = $env:TMPDIR
$env:TMP = $env:TMPDIR
```

Restore packages and run the workflow:

```powershell
Rscript -e 'renv::restore(prompt = FALSE)'
Rscript -e 'renv::status()'
Rscript -e 'targets::tar_make()'
Rscript -e 'targets::tar_make()'
Rscript -e 'targets::tar_outdated()'
Start-Process .\report.html
```

Accept the renv bootstrap prompt on a new computer if shown. Internet access
is needed for packages missing from the cache and the first elevation download.
Harvest, land-cover and coordinate inputs are already included. Do not add
`--vanilla`: it skips `.Rprofile` and the project library. The second unchanged
run should skip all targets and `tar_outdated()` should return `character(0)`.
On Linux, sf may additionally require system GDAL, GEOS and PROJ libraries.

After a successful pipeline run, `quarto render report.qmd` can render only the
report. For normal work use `tar_make()` so changed inputs and analysis code
are rebuilt first. After a text edit, save and rerun; only the report should
rebuild. Ordinary text changes do not require `renv::snapshot()`.

## Workflow and interpretation

File targets register all five source files. Functions reshape and validate
harvest records, retain missingness, calculate summaries and forest percentages,
export CSVs, and draw the terrain map, mean comparison, habitat scatterplots
and annual series. Comparisons use shared linear axes. The terrain raster is
coarsened for display; conifer forest percentage is the municipal environmental
parameter compared with harvest. It is not a causal model. `tar_quarto()` detects explicit
`tar_read()` calls in the report and tracks its source, stylesheet, bibliography
and lockfile. All report numbers are calculated from the pipeline.

The six places form an exploratory geographical comparison, not a random
sample. Habitat context can motivate explanations but cannot establish causes.
Incomplete series, hunting effort, accessibility, regulations, municipal area
and reporting affect interpretation. Harvest is not population abundance.
Read the report's limitations before reusing a result.

Code uses indented blocks: each target is written across multiple lines,
long calls have one argument per line, and conditional summaries use braces.
The report's R chunks use the same style. Short, simple calls remain compact.

## GitHub: wait until content review is finished

Git is initialized locally on `main`. Nothing has been published and no remote
is configured. After the report is approved, review the publishable files:

```powershell
git status --short
git add .
git diff --cached --stat
git diff --cached
git commit -m "Add reproducible grouse landscape analysis"
```

Create an **empty** GitHub repository, without prefilled files, then replace
the placeholder below with its URL:

```powershell
git remote add origin https://github.com/YOUR-USERNAME/bio940-grouse-harvest.git
git push -u origin main
```

Sign in through Git's credential manager if requested; do not save tokens in
project files. If needed, set your own Git author name/email locally before
committing. A project code licence has not yet been selected; data licences
are documented separately. Ask a classmate to clone, restore, run and review.

## A short introduction for classmates

“I compared four grouse species across six Norwegian municipalities to explore
how harvest patterns vary between forest and mountain landscapes. I added
official land-cover data and a location map, and kept missing records visible.
My targets pipeline cleans the data, calculates summaries, produces the figures
and renders a Quarto report. Renv records the package versions, and Git tracks
the project files. Another student can restore the packages and run the whole
workflow with one command. The interpretation draws on ecological literature,
but I keep habitat explanations separate from causal claims because harvest
also depends on hunters, regulations and reporting.”

Course resources: [course materials](https://open-science-course.github.io/course_website/course_content.html),
[Biostats tutorials](https://biostats-r.github.io/),
[tar_quarto documentation](https://docs.ropensci.org/tarchetypes/reference/tar_quarto.html).
