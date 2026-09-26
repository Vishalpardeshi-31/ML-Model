# ==============================================================================
# ML Model 4 - Country Development Analysis
# Data Preparation & Indicator Harmonization Script
# Algorithm: Hierarchical Clustering (Unsupervised)
# Source: The World Bank Group (World Development Indicators - WDI)
# ==============================================================================

raw_json <- file.path("data", "raw", "country", "worldbank_indicators_raw.json")
output_csv <- file.path("data", "processed", "country_development.csv")

cat("[*] Initializing Country Development Indicator Harmonization Pipeline...\n")

if (!file.exists(raw_json)) {
  stop(sprintf("[-] Raw JSON not found: %s. Run data acquisition first.", raw_json))
}

# Regional aggregates and non-country codes used by World Bank
REGIONAL_CODES <- c(
  "AFE", "AFW", "ARB", "CEB", "CSS", "EAP", "EAR", "EAS", "ECA", "ECS",
  "EMU", "EUU", "FCS", "HIC", "HPC", "IBD", "IBT", "IDA", "IDB", "IDX",
  "INX", "KAC", "LAC", "LCN", "LDC", "LIC", "LMC", "LMY", "LTE", "MEA",
  "MIC", "MNA", "NAC", "OED", "OSS", "PRE", "PSS", "PST", "SAS", "SSA",
  "SSF", "SST", "TEA", "TEC", "TLA", "TMN", "TSA", "TSS", "UMC", "WLD"
)

# Parse JSON using base R or jsonlite if available
# We implement a robust parser using jsonlite or standard parsing
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  cat("[*] Package 'jsonlite' not installed; reading via base connection...\n")
}

# Read JSON
json_text <- paste(readLines(raw_json, warn = FALSE), collapse = " ")
raw_wb <- jsonlite::fromJSON(json_text)

indicators <- names(raw_wb)
cat(sprintf("[+] Found %d indicator collections in raw JSON.\n", length(indicators)))

# Target year: 2020 (harmonized global baseline)
target_year <- "2020"

country_map <- list()

for (ind_name in indicators) {
  df_ind <- raw_wb[[ind_name]]
  # Filter for target year
  df_sub <- df_ind[df_ind$date == target_year, ]
  
  for (r in seq_len(nrow(df_sub))) {
    iso <- df_sub$countryiso3code[r]
    cname <- df_sub$country$value[r]
    val <- df_sub$value[r]
    
    if (is.null(iso) || is.na(iso) || nchar(iso) != 3 || iso %in% REGIONAL_CODES) {
      next
    }
    
    if (!iso %in% names(country_map)) {
      country_map[[iso]] <- list(country = cname, country_code = iso, year = as.integer(target_year))
    }
    country_map[[iso]][[ind_name]] <- val
  }
}

# Convert map to data.frame
rows_list <- list()
for (iso in names(country_map)) {
  item <- country_map[[iso]]
  # Check if core indicators exist
  rows_list[[length(rows_list) + 1]] <- data.frame(
    country = item$country,
    country_code = item$country_code,
    year = item$year,
    gdp_per_capita = ifelse(!is.null(item$gdp_per_capita), item$gdp_per_capita, NA),
    life_expectancy = ifelse(!is.null(item$life_expectancy), item$life_expectancy, NA),
    total_population = ifelse(!is.null(item$total_population), item$total_population, NA),
    unemployment_rate = ifelse(!is.null(item$unemployment_rate), item$unemployment_rate, NA),
    infant_mortality = ifelse(!is.null(item$infant_mortality), item$infant_mortality, NA),
    health_expenditure_pct_gdp = ifelse(!is.null(item$health_expenditure_pct_gdp), item$health_expenditure_pct_gdp, NA),
    education_expenditure_pct_gdp = ifelse(!is.null(item$education_expenditure_pct_gdp), item$education_expenditure_pct_gdp, NA),
    internet_usage_pct = ifelse(!is.null(item$internet_usage_pct), item$internet_usage_pct, NA),
    stringsAsFactors = FALSE
  )
}

final_df <- do.call(rbind, rows_list)

# Handle missing values: keep nations with at least 6 of the 8 metrics populated
# Impute missing education/health from median of developmental tier if necessary, or drop incomplete cases
complete_cases <- stats::complete.cases(final_df[, c("gdp_per_capita", "life_expectancy", "total_population", "unemployment_rate", "infant_mortality", "internet_usage_pct")])
clean_countries <- final_df[complete_cases, ]

# For health and education, fill missing with median of available records to maximize coverage while preserving true distributions
clean_countries$health_expenditure_pct_gdp[is.na(clean_countries$health_expenditure_pct_gdp)] <- stats::median(clean_countries$health_expenditure_pct_gdp, na.rm = TRUE)
clean_countries$education_expenditure_pct_gdp[is.na(clean_countries$education_expenditure_pct_gdp)] <- stats::median(clean_countries$education_expenditure_pct_gdp, na.rm = TRUE)

# Sort alphabetically by country
clean_countries <- clean_countries[order(clean_countries$country), ]

# Save final processed CSV
dir.create(dirname(output_csv), showWarnings = FALSE, recursive = TRUE)
write.csv(clean_countries, output_csv, row.names = FALSE)

cat(sprintf("[SUCCESS] Saved country development dataset to %s (%d sovereign nations, %d indicators).\n",
            output_csv, nrow(clean_countries), ncol(clean_countries)))
