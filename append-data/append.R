library(sf)
library(here)
library(aws.s3)
suppressPackageStartupMessages(library(tidyverse))

# --- AWS Configuration ---
# Credentials are read from a CSV file (Access key ID + Secret access key)
bucket_name <- "survey-polygons"
aws_region <- "ap-southeast-2"

key <- read.csv(here(
  getwd(),
  "append-data",
  "s3-base-read_write_accessKeys.csv"
))

Sys.setenv(
  "AWS_ACCESS_KEY_ID" = key$Access.key.ID,
  "AWS_SECRET_ACCESS_KEY" = key$Secret.access.key,
  "AWS_DEFAULT_REGION" = aws_region
)

# --- Parse Command-Line Arguments ---
# Expected: Rscript append-data/append.R <business_name> <code>
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript append-data/append.R <business_name> <code>") # nolint
}

# --- Load Base Dataset from S3 ---
sf_base <- s3read_using(
  FUN = read_sf,
  object = "data/cea_1.geojson",
  bucket = bucket_name
)

# --- Validate Inputs Against Existing Data ---
# Prevent duplicate business names or codes, which would corrupt the dataset
if (args[1] %in% sf_base$Business) {
  stop("Error: Business name already exists in the base dataset.")
}
if (nrow(filter(sf_base, code == as.numeric(args[2]))) > 0) {
  stop("Error: Code already exists in the base dataset.")
}

# --- Load and Reproject Input Shapefile ---
# Sys.glob resolves the wildcard path to the single .shp file in the input folder
input_path <- Sys.glob("append-data/input/*.shp")
sf_input <- read_sf(input_path)
# Reproject to EPSG 4326 (WGS84) to match the base dataset's CRS
sf_input <- st_transform(sf_input, 4326)

# --- Append New Row to Base Dataset ---
# FID_1 is set to 0 as a placeholder; the original field is not used downstream
sf_base <- sf_base |>
  add_row(
    FID_1 = 0,
    code = as.numeric(args[2]),
    Client = args[1],
    Business = args[1],
    geometry = sf_input$geometry
  )

# --- Write Updated Dataset Back to S3 ---
s3write_using(
  sf_base,
  FUN = write_sf,
  object = "data/cea_1.geojson",
  bucket = bucket_name
)
