library(sf)
library(dplyr)
library(purrr)

if (list.files("soil-type/base") |> length() == 0) {
    stop("Base soil type file is empty. Please grab it from OneDrive.")
}

base_path <- Sys.glob("soil-type/base/*.gpkg")
cat("Reading soil type data from:", base_path, "\n")
soil_type <- read_sf(base_path) |> st_make_valid() |> st_transform(4326)
cat(
    "Successfully read soil type data with",
    nrow(soil_type),
    "features.\n"
)

if (list.files("soil-type/input") |> length() == 0) {
    stop("Input property boundary is empty. Please provide a valid input file.")
}

input_path <- Sys.glob("soil-type/input/*.shp")
cat("Reading input data from:", input_path, "\n")
sf_input <- read_sf(input_path) |> st_make_valid() |> st_transform(4326)
cat(
    "Successfully read input data with",
    nrow(sf_input),
    "features.\n"
)

cat("Filtering soil type data...\n")
subset_soil <- st_filter(soil_type, sf_input)
cat(
    "Successfully filtered soil type data with",
    nrow(subset_soil),
    "features.\n"
)

cat("Creating intersection...")
snipped_sf <- st_intersection(subset_soil, sf_input)
cat(
    "Successfully created intersection with",
    nrow(snipped_sf),
    "features.\n"
)

if (dir.exists("soil-type/output") == FALSE) {
    cat("Output directory does not exist. Creating 'soil-type/output'...\n")
    dir.create("soil-type/output")
}
cat("Writing output to 'soil-type/output/subset_soil.geojson'...\n")
write_sf(snipped_sf, "soil-type/output/subset_soil.geojson", delete_dsn = TRUE)
cat("Successfully wrote output to 'soil-type/output/subset_soil.geojson'.\n")
