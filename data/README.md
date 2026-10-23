# Data sources and selection

All source snapshots were prepared on 23 October 2026. The analysis reads
local files. The elevation file is downloaded once on a fresh clone and
cached locally; the remaining source files are included in the repository.

## Harvest: small_game.csv

This UTF-8 CSV is an extract of the course file `smallGame.RDS`. The original
file stays outside the repository and is not required for reproduction. Its
original download date and export script are unknown. The full RDS has 555 rows,
37 game categories, 15 hunting years and 359 municipality columns, with 61,709
missing cells among 199,245 municipality cells. It has no embedded provenance.

Before sharing the extract, all **264 retained cells**, including missing
status, were verified against the public API for
[SSB table 07514](https://www.ssb.no/en/statbank1/table/07514). Every cell matched.
This extract has 44 rows and nine columns: three descriptors plus six
municipalities. Reshaping produces 264 observations: **205 observed and 59
missing**. SSB's `..` flags were interpreted as missing, not zero.

Selection: species codes `01` Capercaillie, `02` Black Grouse, `03` Willow
Ptarmigan and `04` Ptarmigan; contents `Smaavilt`; hunting years 2008-2009 to
2018-2019 inclusive. The report calls `Ptarmigan` "Rock ptarmigan". Each hunting
year runs from 1 April to 31 March.

| Municipality | Harvest verification code | 2018 land-cover code | Current map code |
|---|---|---|---|
| Kongsberg | 0604 | 0604 | 3303 |
| Trysil | 0428 | 0428 | 3421 |
| Oppdal | 1634 through 2017-2018; 5021 for 2018-2019 | 5021 | 5021 |
| Rana | 1833 | 1833 | 1833 |
| Alta | 2012 | 2012 | 5601 |
| Kautokeino | 2011 | 2011 | 5612 |

The original Kautokeino column is `Guovdageaidnu - Kautokeino`.
`municipalities.csv` records this name mapping. Oppdal's two codes were checked
against the same course-file series; unfilled values under an inapplicable
code were not treated as observations. The period avoids extending the analysis
through the extensive 2020 municipality changes.

The four species contrast forest-associated birds with ptarmigan. The six
municipalities are illustrative geographical cases, spanning southern forest,
central mountain and northern coastal/inland settings. Selection followed
initial data inspection and is neither random nor pre-registered. It must not
be treated as a representative sample or an independent test of a hypothesis
discovered in these data. Missing series are retained rather than filtering
the analysis down to the most complete or most striking combinations.

Source fields: `small game` is the species label; `contents` is the constant
"Felled small game"; `interval (year)` is the hunting year; municipal columns
contain published harvest estimates in birds. Values are subject to reporting,
estimation, suppression and rounding. See
[SSB methods](https://www.ssb.no/en/jord-skog-jakt-og-fiskeri/jakt/statistikk/smavilt-og-radyrjakt).
No individual hunter records or reconstructed suppressed values are included.

## Land cover: land_cover.csv

Source: [SSB table 09594](https://www.ssb.no/en/statbank1/table/09594), year 2018,
contents `Areal`, the six region codes above. The CSV contains 138 values:
six municipalities x 23 classes. `area_km2` is area in square kilometres.
`class_code` and `land_cover` retain SSB's classification.

The top-level classes are `01`, `02`, `03`, `04`, `05`, `06`, `07`, `08-09`,
`10-11`, `12-13`, `14`, `15-16`, `17`, `18`, `19`, `20`, `21`, `22`, `24`.
Forest subclasses `17.01` (coniferous), `17.02` (mixed), `17.03` (deciduous),
`17.04` (unclassified) are also included. Terrestrial area is the sum of the
top-level classes excluding inland waters (`22`). Marine waters (`23`) were
not downloaded. Subclasses are excluded from that sum to prevent double counting.
Forest and conifer percentages are `100 * area / terrestrial area`.

This is a single context snapshot. SSB warns that improvements to underlying
maps make this table unsuitable for straightforward year-to-year change
analysis. Forest area is not equivalent to species-specific habitat, and
municipal percentages do not identify the land actually hunted.

## Locations and reference map

`municipalities.csv` stores display/source names, region codes, the selection
reason, and longitude/latitude from `punktIOmrade` in
[Kartverket's municipality API](https://ws.geonorge.no/kommuneinfo/v1/).
Endpoint: `/kommuner/{map_code}`. Coordinates use ETRS89 (EPSG:4258).
These are current official points within municipalities, not bird locations,
hunting locations, population centroids or historical boundaries.

`scandinavia.geojson` contains Norway, Sweden and Finland from Natural Earth
**v5.1.2**, 1:50 million admin-0 countries. Only the country name and geometry
are retained. [Versioned source](https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_50m_admin_0_countries.geojson).
The plotting window omits Arctic islands; the report uses ETRS89 / LAEA Europe
(EPSG:3035). These are reference outlines, not municipal habitat polygons.

## Elevation background: norway_elevation.tif

Source: the DIVA-GIS country elevation archive hosted by UC Davis,
[NOR_msk_alt_tif.zip](https://geodata.ucdavis.edu/diva/msk_alt/NOR_msk_alt_tif.zip).
Downloaded 23 October 2026. The extracted `NOR_msk_alt.tif` was renamed to
`norway_elevation.tif`; pixel values were not modified in the source file.
SHA-256: `E1C4D31D850DAB8263898199721FAD7D3AF03D6066040DFE55BDB6A9A77D4470`.

The 30-arc-second elevation product uses SRTM and GTOPO30 at high latitudes;
see the [provider's elevation documentation](https://rspatial.github.io/geodata/reference/elevation.html).
Units are metres. `prepare_terrain()` averages 5 x 5 source cells, then projects
the raster to EPSG:3035 on a 5 km grid using bilinear interpolation. This is a
coarse display layer for Norway, not a new high-resolution elevation product.
Sweden and Finland have neutral backgrounds with no elevation data displayed.

The elevation layer is not used to calculate municipal habitat statistics.
No point elevation is substituted for municipal mean elevation. The numerical
environmental comparison uses SSB conifer forest percentage and the available
annual harvest means. Incomplete records and differing municipal areas and
hunting effort prevent interpreting this comparison as a causal effect.

## Attribution and licences

- **Statistics Norway (SSB):** tables 07514 and 09594, selected and reshaped for
  BIO940 coursework. Numbers are unchanged. Reused under
  [CC BY 4.0](https://www.ssb.no/en/diverse/lisens). SSB does not endorse the analysis.
- **© Kartverket:** municipality point coordinates and name/code information,
  selected and relabelled for display, under
  [CC BY 4.0](https://www.kartverket.no/api-og-data/vilkar-for-bruk).
- **Natural Earth:** country outlines, selected from v5.1.2. Made with Natural
  Earth; [public domain](https://www.naturalearthdata.com/about/terms-of-use/).
- **Elevation:** distributed by DIVA-GIS / UC Davis; SRTM processing credited
  to Jarvis, Reuter, Nelson and Guevara (2008), CIAT. See the
  [CGIAR-CSI conditions and attribution](https://srtm.csi.cgiar.org/disclaimer/)
  and [USGS GTOPO30 metadata](https://www.usgs.gov/centers/eros/science/usgs-eros-archive-digital-elevation-global-30-arc-second-elevation-gtopo30).
  The original raster is excluded from Git rather than redistributed under
  the other datasets' licences. `fetch_elevation()` retrieves it directly
  from the provider when absent and verifies its checksum. The report map
  credits the sources; this coursework does not relicense their data.

## Generated outputs

`small_game_clean.csv` contains municipality, species, hunting year, starting
year and harvest. `harvest_summary.csv` has 24 species–municipality rows with
available/missing year counts, mean and range. `habitat_comparison.csv` contains
the six-row report comparison. Means exclude missing years and are NA when
all years are missing; always interpret them alongside coverage.
