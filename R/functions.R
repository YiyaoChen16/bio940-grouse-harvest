# Shared ordering and colours keep the figures consistent.
species_order <- c(
  "Capercaillie",
  "Black grouse",
  "Willow ptarmigan",
  "Rock ptarmigan"
)

species_colours <- c(
  "#14665B",
  "#D07B19",
  "#3975B9",
  "#A04492"
)

municipality_order <- c(
  "Kongsberg",
  "Trysil",
  "Oppdal",
  "Rana",
  "Alta",
  "Kautokeino"
)

clean_data <- function(raw_data, municipalities) {
  stopifnot(all(raw_data$contents == "Felled small game"))

  municipality_names <- municipalities |>
    select(source_name, municipality)

  data <- raw_data |>
    rename(
      species = `small game`,
      hunting_year = `interval (year)`
    ) |>
    select(-contents) |>
    pivot_longer(
      cols = -c(species, hunting_year),
      names_to = "source_name",
      values_to = "harvest"
    ) |>
    left_join(
      municipality_names,
      by = "source_name"
    ) |>
    mutate(
      species = recode(
        species,
        "Black Grouse" = "Black grouse",
        "Willow Ptarmigan" = "Willow ptarmigan",
        "Ptarmigan" = "Rock ptarmigan"
      ),
      species = factor(species, levels = species_order),
      municipality = factor(municipality, levels = municipality_order),
      start_year = as.integer(substr(hunting_year, 1, 4))
    ) |>
    select(
      municipality,
      species,
      hunting_year,
      start_year,
      harvest
    ) |>
    arrange(municipality, species, start_year)

  # Unavailable or suppressed harvests remain missing, never zero.
  stopifnot(
    !anyNA(data[c("species", "municipality", "start_year")]),
    all(is.na(data$harvest) | (is.finite(data$harvest) & data$harvest >= 0)),
    !anyDuplicated(data[c("species", "municipality", "hunting_year")])
  )

  data
}

summarise_harvest <- function(data) {
  data |>
    group_by(municipality, species) |>
    summarise(
      years_observed = sum(!is.na(harvest)),
      years_missing = sum(is.na(harvest)),
      mean_harvest = if (all(is.na(harvest))) {
        NA_real_
      } else {
        mean(harvest, na.rm = TRUE)
      },
      min_harvest = if (all(is.na(harvest))) {
        NA_real_
      } else {
        min(harvest, na.rm = TRUE)
      },
      max_harvest = if (all(is.na(harvest))) {
        NA_real_
      } else {
        max(harvest, na.rm = TRUE)
      },
      .groups = "drop"
    )
}

summarise_land_cover <- function(land_cover, municipalities) {
  stopifnot(
    !anyNA(land_cover$area_km2),
    all(land_cover$area_km2 >= 0)
  )

  land_cover |>
    mutate(
      # Exclude water and nested forest subclasses from the denominator.
      is_terrestrial_class = class_code != "22" &
        !grepl(".", class_code, fixed = TRUE)
    ) |>
    group_by(municipality) |>
    summarise(
      land_area_km2 = sum(area_km2[is_terrestrial_class]),
      forest_pct = 100 * area_km2[class_code == "17"] / land_area_km2,
      conifer_pct = 100 * area_km2[class_code == "17.01"] / land_area_km2,
      .groups = "drop"
    ) |>
    left_join(
      municipalities,
      by = "municipality"
    ) |>
    mutate(
      municipality = factor(municipality, levels = municipality_order)
    ) |>
    arrange(municipality)
}

compare_habitats <- function(summary_table, land_context) {
  forest_context <- land_context |>
    select(municipality, forest_pct, conifer_pct)

  summary_table |>
    mutate(
      estimate = if_else(
        years_observed == 0,
        "NA (0/11)",
        sprintf("%.0f (%d/11)", mean_harvest, years_observed)
      )
    ) |>
    select(municipality, species, estimate) |>
    pivot_wider(
      names_from = species,
      values_from = estimate
    ) |>
    left_join(
      forest_context,
      by = "municipality"
    ) |>
    select(
      municipality,
      forest_pct,
      conifer_pct,
      all_of(species_order)
    )
}

save_table <- function(data, path) {
  write.csv(
    data,
    file = path,
    row.names = FALSE,
    na = ""
  )

  path
}

plot_harvest_comparison <- function(summary_table) {
  observed <- summary_table |>
    filter(years_observed > 0) |>
    mutate(
      label = sprintf("%.0f (%d/11)", mean_harvest, years_observed)
    )

  missing <- summary_table |>
    filter(years_observed == 0)

  # All four panels share one linear scale.
  plot <- ggplot(
    observed,
    aes(x = mean_harvest, y = municipality, colour = species)
  ) +
    geom_point(size = 2.8) +
    geom_text(
      aes(label = label),
      nudge_x = 130,
      hjust = 0,
      size = 3.1,
      colour = "#263D45"
    ) +
    geom_text(
      data = missing,
      aes(y = municipality),
      x = 130,
      label = "NA (0/11)",
      hjust = 0,
      size = 3.1,
      colour = "#737373",
      inherit.aes = FALSE
    ) +
    facet_wrap(
      ~species,
      ncol = 2,
      scales = "fixed"
    ) +
    scale_y_discrete(limits = rev(municipality_order)) +
    scale_x_continuous(
      limits = c(0, 6500),
      breaks = c(0, 2000, 4000, 6000),
      expand = expansion(mult = c(0.02, 0.02))
    ) +
    scale_colour_manual(
      values = setNames(species_colours, species_order),
      guide = "none"
    ) +
    labs(
      x = "Mean annual harvest (birds; shared linear scale)",
      y = NULL,
      caption = paste(
        "Labels: mean (observed years / 11).",
        "NA is unavailable, not zero."
      )
    ) +
    theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_blank(),
      strip.text = element_text(face = "bold", colour = "#173E49"),
      panel.spacing = grid::unit(1.4, "lines"),
      plot.caption = element_text(size = 9, colour = "#52656B")
    )

  dir.create("figures", showWarnings = FALSE)
  path <- "figures/harvest_comparison.png"

  ggsave(
    filename = path,
    plot = plot,
    width = 10.5,
    height = 6.5,
    dpi = 300,
    bg = "white"
  )

  path
}

plot_data <- function(data) {
  plot <- ggplot(
    data,
    aes(
      x = start_year,
      y = harvest,
      colour = species,
      shape = species
    )
  ) +
    geom_line(
      linewidth = 0.6,
      alpha = 0.85,
      na.rm = TRUE
    ) +
    geom_point(
      size = 1.8,
      na.rm = TRUE
    ) +
    facet_wrap(
      ~municipality,
      ncol = 2,
      scales = "fixed"
    ) +
    scale_colour_manual(
      values = setNames(species_colours, species_order),
      drop = FALSE
    ) +
    scale_shape_manual(
      values = c(16, 17, 15, 18),
      drop = FALSE
    ) +
    scale_x_continuous(breaks = c(2008, 2013, 2018)) +
    scale_y_continuous(
      limits = c(0, NA),
      expand = expansion(mult = c(0.03, 0.1))
    ) +
    labs(
      x = "Hunting year (starting year)",
      y = "Harvest (birds per hunting year; shared scale)",
      colour = NULL,
      shape = NULL
    ) +
    theme_minimal(
      base_size = 11,
      base_family = "sans"
    ) +
    theme(
      legend.position = "top",
      legend.justification = "left",
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      strip.text = element_text(face = "bold", colour = "#173E49"),
      panel.spacing = grid::unit(1.2, "lines")
    )

  dir.create("figures", showWarnings = FALSE)
  path <- "figures/grouse_harvest.png"

  ggsave(
    filename = path,
    plot = plot,
    width = 9,
    height = 7.8,
    dpi = 300,
    bg = "white"
  )

  path
}

fetch_elevation <- function(path = "data/norway_elevation.tif") {
  # Cache the provider's raster locally; do not redistribute it in Git.
  if (!file.exists(path)) {
    archive <- tempfile(fileext = ".zip")
    extraction_dir <- tempfile(pattern = "norway-elevation-")

    download.file(
      url = paste0(
        "https://geodata.ucdavis.edu/diva/msk_alt/",
        "NOR_msk_alt_tif.zip"
      ),
      destfile = archive,
      mode = "wb"
    )

    unzip(
      archive,
      files = "NOR_msk_alt.tif",
      exdir = extraction_dir
    )

    dir.create(
      dirname(path),
      recursive = TRUE,
      showWarnings = FALSE
    )

    copied <- file.copy(
      from = file.path(extraction_dir, "NOR_msk_alt.tif"),
      to = path,
      overwrite = FALSE
    )

    stopifnot(copied)
  }

  # Fail visibly if the provider replaces this source snapshot.
  stopifnot(
    unname(tools::md5sum(path)) == "6833a8e1a66c3787651e63d300564e14"
  )

  path
}

prepare_terrain <- function(elevation_file) {
  elevation <- terra::rast(elevation_file)

  # Coarsen only for this national overview; these are not site measurements.
  elevation <- terra::aggregate(
    elevation,
    fact = 5,
    fun = "mean",
    na.rm = TRUE
  )

  elevation <- terra::project(
    elevation,
    "EPSG:3035",
    res = 5000,
    method = "bilinear"
  )

  names(elevation) <- "elevation_m"

  terra::as.data.frame(
    elevation,
    xy = TRUE,
    na.rm = TRUE
  )
}

plot_study_map <- function(map_file, land_context, terrain) {
  countries <- sf::st_read(map_file, quiet = TRUE)

  points <- sf::st_as_sf(
    land_context,
    coords = c("longitude", "latitude"),
    crs = 4258
  ) |>
    sf::st_transform(3035)

  labels <- cbind(
    sf::st_drop_geometry(points),
    sf::st_coordinates(points)
  )

  map_bounds <- sf::st_bbox(
    c(xmin = 3, ymin = 57, xmax = 33, ymax = 72),
    crs = 4326
  )

  extent <- sf::st_as_sfc(map_bounds) |>
    sf::st_transform(3035) |>
    sf::st_bbox()

  plot <- ggplot() +
    geom_sf(
      data = countries,
      fill = "#F1F1ED",
      colour = NA
    ) +
    geom_raster(
      data = terrain,
      aes(x = x, y = y, fill = elevation_m)
    ) +
    scale_fill_gradientn(
      colours = c("#EDF0D8", "#C5C6A3", "#A29575", "#70685F", "#F2F1EE"),
      values = c(0, 0.2, 0.4, 0.7, 1),
      limits = c(0, 2500),
      oob = scales::squish,
      name = "Elevation (m)\nNorway only"
    ) +
    geom_sf(
      data = countries,
      fill = NA,
      colour = "#A8B4B7",
      linewidth = 0.25
    ) +
    geom_sf(
      data = points,
      aes(colour = conifer_pct),
      size = 3.8
    ) +
    geom_label(
      data = labels,
      aes(x = X + 30000, y = Y, label = municipality),
      hjust = 0,
      size = 3.3,
      linewidth = 0.15,
      label.padding = grid::unit(0.15, "lines")
    ) +
    scale_colour_gradient(
      low = "#E3962D",
      high = "#07594B",
      limits = c(0, 100),
      name = "Conifer forest\n(% of land)"
    ) +
    coord_sf(
      crs = 3035,
      xlim = extent[c("xmin", "xmax")],
      ylim = extent[c("ymin", "ymax")],
      expand = FALSE
    ) +
    labs(
      x = NULL,
      y = NULL,
      caption = paste(
        "Locations: © Kartverket · Forest: SSB, 2018 · Outlines: Natural Earth",
        "Elevation: DIVA-GIS / CIAT SRTM and USGS GTOPO30; 5 km display grid",
        sep = "\n"
      )
    ) +
    theme_minimal(base_size = 11) +
    theme(
      panel.background = element_rect(fill = "#EFF6F8", colour = NA),
      panel.grid.major = element_line(colour = "#D8E4E9", linewidth = 0.25),
      legend.position = "right",
      plot.caption = element_text(size = 8, colour = "#52656B")
    )

  dir.create("figures", showWarnings = FALSE)
  path <- "figures/study_map.png"

  ggsave(
    filename = path,
    plot = plot,
    width = 9,
    height = 7.5,
    dpi = 300,
    bg = "white"
  )

  path
}

plot_forest_relationship <- function(summary_table, land_context) {
  forest_context <- land_context |>
    select(municipality, conifer_pct)

  comparison <- summary_table |>
    filter(species %in% c("Capercaillie", "Black grouse")) |>
    left_join(
      forest_context,
      by = "municipality"
    ) |>
    mutate(
      # Numbers identify the same municipalities in both panels.
      site_id = match(as.character(municipality), municipality_order),
      coverage = if_else(
        years_observed == 11,
        "All 11 years",
        "Fewer than 11 years"
      ),
      # Separate crowded low values using labels and short leader lines.
      label_y = case_when(
        municipality == "Kautokeino" ~ 85,
        municipality == "Alta" ~ 205,
        municipality == "Oppdal" ~ 320,
        municipality == "Rana" ~ 440,
        TRUE ~ mean_harvest + 65
      ),
      label_x = if_else(conifer_pct < 10, conifer_pct + 5, conifer_pct)
    )

  plot <- ggplot(
    comparison,
    aes(x = conifer_pct, y = mean_harvest, colour = species)
  ) +
    geom_segment(
      aes(xend = label_x, yend = label_y),
      colour = "#B0B6B8",
      linewidth = 0.35
    ) +
    geom_point(
      aes(shape = coverage),
      size = 3
    ) +
    geom_text(
      aes(x = label_x, y = label_y, label = site_id),
      size = 3.5,
      colour = "#263D45"
    ) +
    facet_wrap(
      ~species,
      ncol = 2,
      scales = "fixed"
    ) +
    scale_x_continuous(
      limits = c(0, 100),
      breaks = seq(0, 100, 25),
      expand = expansion(mult = c(0.03, 0.03))
    ) +
    scale_y_continuous(
      limits = c(0, 1150),
      breaks = seq(0, 1000, 250),
      expand = expansion(mult = c(0.03, 0.03))
    ) +
    scale_colour_manual(
      values = setNames(species_colours, species_order),
      guide = "none"
    ) +
    scale_shape_manual(
      values = c("All 11 years" = 16, "Fewer than 11 years" = 1)
    ) +
    labs(
      x = "Conifer forest (% of terrestrial area, 2018)",
      y = "Mean annual harvest (birds)",
      shape = NULL,
      caption = paste(
        paste(
          "1 Kongsberg · 2 Trysil · 3 Oppdal",
          "4 Rana · 5 Alta · 6 Kautokeino",
          sep = " · "
        ),
        paste(
          "Means use available years.",
          "No trend line or causal effect is estimated."
        ),
        sep = "\n"
      )
    ) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "top",
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold", colour = "#173E49"),
      plot.caption = element_text(size = 9, colour = "#52656B")
    )

  dir.create("figures", showWarnings = FALSE)
  path <- "figures/forest_relationship.png"

  ggsave(
    filename = path,
    plot = plot,
    width = 9.5,
    height = 5.4,
    dpi = 300,
    bg = "white"
  )

  path
}
