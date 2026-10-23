library(targets)
library(tarchetypes)

tar_option_set(
  packages = c("dplyr", "tidyr", "ggplot2", "sf", "terra")
)

source("R/functions.R")

list(
  # Read the local source files.
  tar_target(
    raw_file,
    "data/small_game.csv",
    format = "file"
  ),
  tar_target(
    raw_data,
    read.csv(
      raw_file,
      check.names = FALSE
    )
  ),
  tar_target(
    municipalities_file,
    "data/municipalities.csv",
    format = "file"
  ),
  tar_target(
    municipalities,
    {
      read.csv(
        municipalities_file,
        colClasses = "character"
      ) |>
        mutate(
          across(c(longitude, latitude), as.numeric)
        )
    }
  ),
  tar_target(
    land_file,
    "data/land_cover.csv",
    format = "file"
  ),
  tar_target(
    land_cover,
    read.csv(
      land_file,
      colClasses = c(class_code = "character")
    )
  ),
  tar_target(
    land_context,
    summarise_land_cover(
      land_cover,
      municipalities
    )
  ),
  tar_target(
    map_file,
    "data/scandinavia.geojson",
    format = "file"
  ),
  tar_target(
    elevation_file,
    fetch_elevation(),
    format = "file"
  ),
  tar_target(
    terrain,
    prepare_terrain(elevation_file)
  ),

  # Clean the harvest records and export the analysis tables.
  tar_target(
    cleaned_data,
    clean_data(
      raw_data,
      municipalities
    )
  ),
  tar_target(
    cleaned_csv,
    save_table(
      cleaned_data,
      "data/small_game_clean.csv"
    ),
    format = "file"
  ),
  tar_target(
    summary_table,
    summarise_harvest(cleaned_data)
  ),
  tar_target(
    summary_csv,
    save_table(
      summary_table,
      "data/harvest_summary.csv"
    ),
    format = "file"
  ),
  tar_target(
    habitat_table,
    compare_habitats(
      summary_table,
      land_context
    )
  ),
  tar_target(
    habitat_csv,
    save_table(
      habitat_table,
      "data/habitat_comparison.csv"
    ),
    format = "file"
  ),

  # Draw the figures, then render the report from these results.
  tar_target(
    comparison_figure,
    plot_harvest_comparison(summary_table),
    format = "file"
  ),
  tar_target(
    figure,
    plot_data(cleaned_data),
    format = "file"
  ),
  tar_target(
    forest_figure,
    plot_forest_relationship(
      summary_table,
      land_context
    ),
    format = "file"
  ),
  tar_target(
    study_map,
    plot_study_map(
      map_file,
      land_context,
      terrain
    ),
    format = "file"
  ),
  tar_quarto(
    report,
    "report.qmd",
    extra_files = "renv.lock"
  )
)
