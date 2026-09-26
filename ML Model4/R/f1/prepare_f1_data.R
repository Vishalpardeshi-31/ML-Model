# ==============================================================================
# ML Model 4 - Formula 1 Race Outcome Analysis
# Data Preparation & Historical Feature Engineering Script
# Algorithm: Multiple Linear Regression (Supervised)
# Target: race_points (STRICTLY NO TARGET LEAKAGE)
# Source: Ergast Developer API / Historical F1 Relational Archive
# ==============================================================================

raw_dir <- file.path("data", "raw", "f1")
output_csv <- file.path("data", "processed", "f1_race_data.csv")

cat("[*] Initializing Formula 1 Historical Feature Engineering Pipeline...\n")

# Check required files
req_files <- c("races.csv", "results.csv", "qualifying.csv", "drivers.csv")
for (f in req_files) {
  p <- file.path(raw_dir, f)
  if (!file.exists(p)) {
    stop(sprintf("[-] Missing required F1 raw table: %s", p))
  }
}

# 1. Load raw tables
races <- read.csv(file.path(raw_dir, "races.csv"), stringsAsFactors = FALSE)
results <- read.csv(file.path(raw_dir, "results.csv"), stringsAsFactors = FALSE)
qualifying <- read.csv(file.path(raw_dir, "qualifying.csv"), stringsAsFactors = FALSE)
drivers <- read.csv(file.path(raw_dir, "drivers.csv"), stringsAsFactors = FALSE)

cat(sprintf("[+] Loaded raw tables: %d races, %d results, %d qualifying sessions.\n",
            nrow(races), nrow(results), nrow(qualifying)))

# 2. Scope to modern Turbo Hybrid Era (2014-2023)
# Modern regulations establish consistent qualifying format (Q1/Q2/Q3) and scoring system (25-18-15-12-10-8-6-4-2-1).
hybrid_races <- races[races$year >= 2014 & races$year <= 2023, ]
hybrid_race_ids <- hybrid_races$raceId

hybrid_results <- results[results$raceId %in% hybrid_race_ids, ]
cat(sprintf("[+] Filtered to Turbo Hybrid Era (2014-2023): %d driver race entries across %d Grands Prix.\n",
            nrow(hybrid_results), nrow(hybrid_races)))

# Helper: Parse lap time string "1:24.312" or "84.312" into seconds
parse_lap_time <- function(t_str) {
  if (is.na(t_str) || t_str == "" || t_str == "\\N") return(NA)
  parts <- strsplit(t_str, ":")[[1]]
  if (length(parts) == 2) {
    return(as.numeric(parts[1]) * 60 + as.numeric(parts[2]))
  } else if (length(parts) == 1) {
    return(as.numeric(parts[1]))
  }
  return(NA)
}

# 3. Clean and process qualifying lap times
qualifying$q1_sec <- sapply(qualifying$q1, parse_lap_time)
qualifying$q2_sec <- sapply(qualifying$q2, parse_lap_time)
qualifying$q3_sec <- sapply(qualifying$q3, parse_lap_time)

# Best qualifying time achieved across sessions
qualifying$q_best_sec <- apply(qualifying[, c("q1_sec", "q2_sec", "q3_sec")], 1, function(row) {
  vals <- row[!is.na(row)]
  if (length(vals) == 0) NA else min(vals)
})

# Compute pole lap time per race
pole_times <- stats::aggregate(q_best_sec ~ raceId, data = qualifying, FUN = min, na.rm = TRUE)
colnames(pole_times)[2] <- "pole_time_sec"

qualifying <- merge(qualifying, pole_times, by = "raceId", all.x = TRUE)
qualifying$q_delta_to_pole <- qualifying$q_best_sec - qualifying$pole_time_sec
qualifying$q_delta_to_pole[is.na(qualifying$q_delta_to_pole) | qualifying$q_delta_to_pole < 0] <- 0

# 4. Join race metadata with results
merged_df <- merge(hybrid_results, hybrid_races[, c("raceId", "year", "round", "circuitId", "name")], by = "raceId")

# Join driver info
merged_df <- merge(merged_df, drivers[, c("driverId", "driverRef", "forename", "surname")], by = "driverId")

# Join qualifying telemetry
merged_df <- merge(
  merged_df,
  qualifying[, c("raceId", "driverId", "position", "q_best_sec", "q_delta_to_pole")],
  by = c("raceId", "driverId"),
  all.x = TRUE
)
colnames(merged_df)[which(colnames(merged_df) == "position.y")] <- "qualifying_position"

# 5. STRICT PRE-RACE FEATURE ENGINEERING (NO TARGET LEAKAGE)
# Calculate driver_previous_points & constructor_previous_points BEFORE each round within each season
cat("[*] Calculating pre-race cumulative points strictly prior to each Grand Prix round...\n")

# Order chronologically
merged_df <- merged_df[order(merged_df$year, merged_df$round, merged_df$driverId), ]

merged_df$driver_previous_points <- 0.0
merged_df$constructor_previous_points <- 0.0

# Compute cumulative points up to round - 1
seasons <- unique(merged_df$year)
for (s in seasons) {
  s_mask <- merged_df$year == s
  rounds <- sort(unique(merged_df$round[s_mask]))
  
  for (rnd in rounds) {
    if (rnd == 1) {
      # Round 1: All previous season points entering race are 0
      next
    }
    # Prior points scored in rounds < rnd within this season
    prior_entries <- merged_df[s_mask & merged_df$round < rnd, ]
    
    # Driver cumulative prior points
    driver_pts_map <- stats::aggregate(points ~ driverId, data = prior_entries, FUN = sum)
    curr_rnd_mask <- s_mask & merged_df$round == rnd
    
    for (d_id in unique(merged_df$driverId[curr_rnd_mask])) {
      pts <- driver_pts_map$points[driver_pts_map$driverId == d_id]
      if (length(pts) > 0) {
        merged_df$driver_previous_points[curr_rnd_mask & merged_df$driverId == d_id] <- pts
      }
    }
    
    # Constructor cumulative prior points
    cons_pts_map <- stats::aggregate(points ~ constructorId, data = prior_entries, FUN = sum)
    for (c_id in unique(merged_df$constructorId[curr_rnd_mask])) {
      c_pts <- cons_pts_map$points[cons_pts_map$constructorId == c_id]
      if (length(c_pts) > 0) {
        merged_df$constructor_previous_points[curr_rnd_mask & merged_df$constructorId == c_id] <- c_pts
      }
    }
  }
}

# 6. Target Variable & Selected Feature Subset
# Target: race_points (points scored in this specific race)
# Features must only reflect pre-race information!
merged_df$race_points <- as.numeric(merged_df$points)
merged_df$grid_position <- as.integer(merged_df$grid)

# Fallbacks for missing qualifying: if unranked in qualifying, use starting grid
merged_df$qualifying_position[is.na(merged_df$qualifying_position)] <- merged_df$grid_position[is.na(merged_df$qualifying_position)]
merged_df$q_delta_to_pole[is.na(merged_df$q_delta_to_pole)] <- stats::median(merged_df$q_delta_to_pole, na.rm = TRUE)

final_f1 <- data.frame(
  season = merged_df$year,
  round = merged_df$round,
  race_name = merged_df$name,
  circuit_id = merged_df$circuitId,
  driver_name = paste(merged_df$forename, merged_df$surname),
  constructor_id = merged_df$constructorId,
  grid_position = merged_df$grid_position,
  qualifying_position = merged_df$qualifying_position,
  q_delta_to_pole = round(merged_df$q_delta_to_pole, 3),
  driver_previous_points = merged_df$driver_previous_points,
  constructor_previous_points = merged_df$constructor_previous_points,
  race_points = merged_df$race_points,
  stringsAsFactors = FALSE
)

# Filter invalid grid slots (grid > 0)
final_f1 <- final_f1[final_f1$grid_position > 0 & final_f1$grid_position <= 24, ]

# 7. Write processed CSV
dir.create(dirname(output_csv), showWarnings = FALSE, recursive = TRUE)
write.csv(final_f1, output_csv, row.names = FALSE)

cat(sprintf("[SUCCESS] Saved Formula 1 race outcome dataset to %s (%d race entries, %d features + target).\n",
            output_csv, nrow(final_f1), ncol(final_f1) - 1))
