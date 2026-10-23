# Edit and rebuild the report in VS Code

`report.qmd` is the editable source. `report.html` is its generated output.
Editing the HTML directly is temporary: the next render overwrites it.

1. Open this project folder in VS Code, then open `report.qmd` from Explorer.
2. Edit an ordinary paragraph or a heading such as `## Question and motivation`.
   Keep the YAML settings between the opening `---` lines and the R code chunks
   unchanged while you are learning. Press **Ctrl+S** to save.
3. Open **Terminal > New Terminal** and select PowerShell. It should be at the
   project root, where `_targets.R` and `report.qmd` are located.
4. If this is a new terminal, configure the installed software once:

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

5. Rebuild and open the output:

   ```powershell
   Rscript -e 'targets::tar_make()'
   Start-Process .\report.html
   ```

If the report is already open in a browser, refresh it. After a text-only edit,
the report target reruns while the data and figure targets are skipped.
`targets::tar_make()` is **R code**; the full `Rscript -e ...` line runs that R
code from **PowerShell**. Do not type bare R expressions into PowerShell.

Once the pipeline has run successfully, `quarto render report.qmd` can render
only the report. Prefer `tar_make()` because it also updates any changed inputs
or analysis code. Do not use `--vanilla`; it skips the project renv activation.

## Which file should I edit?

| Change | File |
|---|---|
| Title, paragraphs, captions, discussion | `report.qmd` |
| Citation details or a new reference | `references.bib` |
| Cleaning, summaries, colours, axes, map | `R/functions.R` |
| Add a processing step or dependency | `_targets.R` |
| Fonts, spacing, report colours | `styles.css` |
| Source data | `data/` files, with documented provenance |

Text like `` `r observed` `` is an inline R expression that inserts a calculated
number. Change the analysis or inputs if the number should change; do not
replace it with a manually typed result. Cite a paper with `[@kvasnes2018]`;
the key must match an entry in `references.bib`.

Changing text does not require installing packages or running
`renv::snapshot()`. GitHub publication is a separate step after content review.
