# ==============================================================================
# ML Model 4 — R Plumber ML Inference Service
# Exposes the four serialized .rds models via RESTful API
# ==============================================================================

suppressPackageStartupMessages({
  library(plumber)
  library(jsonlite)
  library(stats)
  library(cluster)
})

cat("[*] Initializing ML Model 4 Plumber Inference Microservice...\n")

# Determine project root dynamically
project_root <- if (file.exists(file.path("models", "brain_kmeans.rds"))) {
  "."
} else if (file.exists(file.path("..", "models", "brain_kmeans.rds"))) {
  ".."
} else {
  getwd()
}
cat(sprintf("[*] Resolved project root: %s (current wd: %s)\n", project_root, getwd()))

# 1. Load Serialized Models Once at Startup (Zero Retraining on Requests)
models_dir <- file.path(project_root, "models")
data_dir   <- file.path(project_root, "data", "processed")


cat("[*] Loading Model 1: Brain K-Means (models/brain_kmeans.rds)...\n")
b_model <- readRDS(file.path(models_dir, "brain_kmeans.rds"))

cat("[*] Loading Model 2: Country Hierarchical (models/country_hierarchical.rds)...\n")
c_model <- readRDS(file.path(models_dir, "country_hierarchical.rds"))

cat("[*] Loading Model 3: F1 Linear Regression (models/f1_regression.rds)...\n")
f_model <- readRDS(file.path(models_dir, "f1_regression.rds"))

cat("[*] Loading Model 4: Placement Logistic Regression (models/placement_logistic.rds)...\n")
p_model <- readRDS(file.path(models_dir, "placement_logistic.rds"))

# 2. Load Processed Datasets for Data Endpoints & Lookup
cat("[*] Loading processed datasets for lookup and visualization...\n")
country_data_df   <- read.csv(file.path(data_dir, "country_clustered.csv"), stringsAsFactors = FALSE)
brain_data_df     <- read.csv(file.path(data_dir, "brain_clustered.csv"), stringsAsFactors = FALSE)
f1_pred_df        <- read.csv(file.path(data_dir, "f1_predictions.csv"), stringsAsFactors = FALSE)
placement_pred_df <- read.csv(file.path(data_dir, "placement_predictions.csv"), stringsAsFactors = FALSE)

# Precompute Country Cluster Centroids in Standardized Space
c_indicators <- c_model$indicator_names
c_transformed <- country_data_df[, c_indicators]
c_transformed$gdp_per_capita <- log1p(c_transformed$gdp_per_capita)
c_transformed$total_population <- log1p(c_transformed$total_population)
c_scaled_mat <- scale(c_transformed, center = c_model$scaler$center, scale = c_model$scaler$scale)

c_centroids <- matrix(NA, nrow = 3, ncol = length(c_indicators))
colnames(c_centroids) <- c_indicators
rownames(c_centroids) <- paste0("Tier_", 1:3)
for (cl in 1:3) {
  idx <- which(country_data_df$cluster == cl)
  c_centroids[cl, ] <- colMeans(c_scaled_mat[idx, , drop = FALSE])
}

# Cluster name dictionaries
brain_cluster_names <- c(
  "1" = "Relaxed Wakefulness / Posterior Alpha State",
  "2" = "High-Amplitude Slow-Wave Burst",
  "3" = "Alert Cognitive Engagement / Desynchronized State"
)

brain_cluster_interpretations <- c(
  "1" = "Elevated occipital alpha power (O1, O2) representing sensory idle or relaxed wakefulness.",
  "2" = "High-amplitude slow-wave delta oscillation burst or deep synchronized shift.",
  "3" = "Elevated fast beta power with desynchronized posterior alpha reflecting cognitive attention and alertness."
)

country_tier_names <- c(
  "1" = "Tier 1: Underdeveloped / High Humanitarian Need",
  "2" = "Tier 2: Developing / Emerging Markets",
  "3" = "Tier 3: Developed Industrial Economies"
)

cat("[+] All 4 models and support matrices loaded successfully!\n")

#* @apiTitle ML Model 4 R Inference API
#* @apiDescription Real-world ML prediction and clustering microservice using serialized R models (.rds).

#* Health check endpoint
#* @get /health
#* @serializer json list(auto_unbox = TRUE)
function() {
  list(
    status = "ok",
    service = "R ML API",
    models_loaded = list(
      brain_kmeans = TRUE,
      country_hierarchical = TRUE,
      f1_regression = TRUE,
      placement_logistic = TRUE
    ),
    timestamp = as.character(Sys.time())
  )
}

#* Model 1: Brain Activity Pattern Discovery (K-Means)
#* @post /brain/predict
#* @serializer json list(auto_unbox = TRUE)
function(req, res) {
  body <- tryCatch({
    if (is.list(req$body)) req$body else jsonlite::fromJSON(req$postBody)
  }, error = function(e) {
    NULL
  })

  if (is.null(body) || length(body) == 0) {
    res$status <- 400
    return(list(error = TRUE, message = "Malformed or empty JSON request body."))
  }

  required_features <- b_model$feature_names

  # 1. Lookup by authentic epoch_id if provided
  if (!is.null(body$epoch_id)) {
    ep_id <- suppressWarnings(as.integer(body$epoch_id))
    if (!is.na(ep_id) && ep_id %in% brain_data_df$epoch_id) {
      match_row <- brain_data_df[brain_data_df$epoch_id == ep_id, ]
      cl <- match_row$cluster[1]

      # Compute distances to cluster centers
      raw_vals <- as.numeric(match_row[1, required_features])
      names(raw_vals) <- required_features
      power_cols <- c("delta_power", "theta_power", "alpha_power", "beta_power", "gamma_power", "occipital_alpha", "signal_variance")
      for (p in power_cols) raw_vals[p] <- log1p(raw_vals[p])
      scaled_vec <- (raw_vals - b_model$scaler$center) / b_model$scaler$scale
      diffs <- sweep(b_model$kmeans_model$centers, 2, scaled_vec, "-")
      dists <- sqrt(rowSums(diffs^2))

      return(list(
        epoch_id = ep_id,
        matched_epoch = ep_id,
        cluster = cl,
        cluster_name = unname(brain_cluster_names[as.character(cl)]),
        interpretation = unname(brain_cluster_interpretations[as.character(cl)]),
        pca = list(
          x = round(match_row$PCA1[1], 4),
          y = round(match_row$PCA2[1], 4)
        ),
        distances = list(
          cluster_1 = round(unname(dists[1]), 4),
          cluster_2 = round(unname(dists[2]), 4),
          cluster_3 = round(unname(dists[3]), 4)
        ),
        input_features = as.list(match_row[1, required_features]),
        features = as.list(match_row[1, required_features])
      ))
    } else {
      res$status <- 404
      return(list(error = TRUE, message = sprintf("Epoch ID %s not found in verified 233-epoch dataset.", as.character(body$epoch_id))))
    }
  }

  missing <- setdiff(required_features, names(body))
  if (length(missing) > 0) {
    res$status <- 400
    return(list(error = TRUE, message = paste("Missing required features:", paste(missing, collapse = ", "))))
  }

  # Validate and extract features
  vec <- numeric(length(required_features))
  names(vec) <- required_features
  for (f in required_features) {
    val <- suppressWarnings(as.numeric(body[[f]]))
    if (is.na(val)) {
      res$status <- 400
      return(list(error = TRUE, message = sprintf("Feature '%s' must be a valid numerical value.", f)))
    }
    vec[f] <- val
  }

  # Apply log1p to power features
  power_cols <- c("delta_power", "theta_power", "alpha_power", "beta_power", "gamma_power", "occipital_alpha", "signal_variance")
  for (p in power_cols) {
    if (vec[p] < 0) {
      res$status <- 400
      return(list(error = TRUE, message = sprintf("Power spectral feature '%s' cannot be negative.", p)))
    }
    vec[p] <- log1p(vec[p])
  }

  # Standardize
  scaled_vec <- (vec - b_model$scaler$center) / b_model$scaler$scale

  # Compute distance to each cluster center
  centers <- b_model$kmeans_model$centers
  diffs <- sweep(centers, 2, scaled_vec, "-")
  dists <- sqrt(rowSums(diffs^2))
  assigned_cluster <- as.integer(which.min(dists))

  # Compute 2D PCA projection
  pca_coords <- as.numeric(scaled_vec %*% b_model$pca$rotation[, 1:2])

  list(
    cluster = assigned_cluster,
    cluster_name = unname(brain_cluster_names[as.character(assigned_cluster)]),
    interpretation = unname(brain_cluster_interpretations[as.character(assigned_cluster)]),
    pca = list(
      x = round(pca_coords[1], 4),
      y = round(pca_coords[2], 4)
    ),
    distances = list(
      cluster_1 = round(unname(dists[1]), 4),
      cluster_2 = round(unname(dists[2]), 4),
      cluster_3 = round(unname(dists[3]), 4)
    )
  )
}

#* Model 2: Country Development Analysis (Hierarchical Clustering)
#* @post /country/predict
#* @serializer json list(auto_unbox = TRUE)
function(req, res) {
  body <- tryCatch({
    if (is.list(req$body)) req$body else jsonlite::fromJSON(req$postBody)
  }, error = function(e) {
    NULL
  })

  if (is.null(body) || length(body) == 0) {
    res$status <- 400
    return(list(error = TRUE, message = "Malformed or empty JSON request body."))
  }

  # 1. Check if lookup by country or country_code
  lookup_key <- NULL
  if (!is.null(body$country_code) && nzchar(as.character(body$country_code))) {
    lookup_key <- toupper(trimws(as.character(body$country_code)))
    match_row <- country_data_df[toupper(country_data_df$country_code) == lookup_key, ]
  } else if (!is.null(body$country) && nzchar(as.character(body$country))) {
    lookup_key <- tolower(trimws(as.character(body$country)))
    match_row <- country_data_df[tolower(country_data_df$country) == lookup_key, ]
  } else {
    match_row <- data.frame()
  }

  if (nrow(match_row) > 0) {
    cl <- match_row$cluster[1]
    return(list(
      matched_country = match_row$country[1],
      country_code = match_row$country_code[1],
      cluster = cl,
      tier_name = unname(country_tier_names[as.character(cl)]),
      cluster_profile = list(
        mean_gdp = unname(c_model$cluster_summaries[[cl]]["gdp_per_capita", "Mean"]),
        mean_life_expectancy = unname(c_model$cluster_summaries[[cl]]["life_expectancy", "Mean"]),
        mean_infant_mortality = unname(c_model$cluster_summaries[[cl]]["infant_mortality", "Mean"])
      ),
      indicators = as.list(match_row[1, c_indicators]),
      pca = list(
        x = round(match_row$PCA1[1], 4),
        y = round(match_row$PCA2[1], 4)
      )
    ))
  }

  # 2. Numerical indicators input
  missing <- setdiff(c_indicators, names(body))
  if (length(missing) > 0) {
    res$status <- 400
    return(list(error = TRUE, message = paste("Missing required indicators or valid country/country_code:", paste(missing, collapse = ", "))))
  }

  vec <- numeric(length(c_indicators))
  names(vec) <- c_indicators
  for (ind in c_indicators) {
    val <- suppressWarnings(as.numeric(body[[ind]]))
    if (is.na(val)) {
      res$status <- 400
      return(list(error = TRUE, message = sprintf("Indicator '%s' must be a valid numerical value.", ind)))
    }
    vec[ind] <- val
  }

  if (vec["gdp_per_capita"] <= 0 || vec["total_population"] <= 0) {
    res$status <- 400
    return(list(error = TRUE, message = "GDP per capita and total population must be strictly positive."))
  }

  vec["gdp_per_capita"] <- log1p(vec["gdp_per_capita"])
  vec["total_population"] <- log1p(vec["total_population"])

  scaled_vec <- (vec - c_model$scaler$center) / c_model$scaler$scale

  # Compute distance to Ward.D2 cluster centroids in standardized space
  diffs <- sweep(c_centroids, 2, scaled_vec, "-")
  dists <- sqrt(rowSums(diffs^2))
  assigned_cluster <- as.integer(which.min(dists))

  pca_coords <- as.numeric(scaled_vec %*% c_model$pca$rotation[, 1:2])

  list(
    cluster = assigned_cluster,
    tier_name = unname(country_tier_names[as.character(assigned_cluster)]),
    cluster_profile = list(
      mean_gdp = unname(c_model$cluster_summaries[[assigned_cluster]]["gdp_per_capita", "Mean"]),
      mean_life_expectancy = unname(c_model$cluster_summaries[[assigned_cluster]]["life_expectancy", "Mean"]),
      mean_infant_mortality = unname(c_model$cluster_summaries[[assigned_cluster]]["infant_mortality", "Mean"])
    ),
    pca = list(
      x = round(pca_coords[1], 4),
      y = round(pca_coords[2], 4)
    ),
    distances = list(
      tier_1 = round(unname(dists[1]), 4),
      tier_2 = round(unname(dists[2]), 4),
      tier_3 = round(unname(dists[3]), 4)
    )
  )
}

#* Model 3: Formula 1 Race Outcome Analysis (Multiple Linear Regression)
#* @post /f1/predict
#* @serializer json list(auto_unbox = TRUE)
function(req, res) {
  body <- tryCatch({
    if (is.list(req$body)) req$body else jsonlite::fromJSON(req$postBody)
  }, error = function(e) {
    NULL
  })

  if (is.null(body) || length(body) == 0) {
    res$status <- 400
    return(list(error = TRUE, message = "Malformed or empty JSON request body."))
  }

  required_preds <- f_model$predictors
  missing <- setdiff(required_preds, names(body))
  if (length(missing) > 0) {
    res$status <- 400
    return(list(error = TRUE, message = paste("Missing required predictors:", paste(missing, collapse = ", "))))
  }

  # Validate inputs
  grid_pos <- suppressWarnings(as.numeric(body$grid_position))
  quali_pos <- suppressWarnings(as.numeric(body$qualifying_position))
  q_delta <- suppressWarnings(as.numeric(body$q_delta_to_pole))
  drv_pts <- suppressWarnings(as.numeric(body$driver_previous_points))
  con_pts <- suppressWarnings(as.numeric(body$constructor_previous_points))
  rnd_num <- suppressWarnings(as.numeric(body$round))

  if (any(is.na(c(grid_pos, quali_pos, q_delta, drv_pts, con_pts, rnd_num)))) {
    res$status <- 400
    return(list(error = TRUE, message = "All F1 predictors must be valid numerical values."))
  }

  if (grid_pos < 1 || grid_pos > 25 || quali_pos < 1 || quali_pos > 25) {
    res$status <- 400
    return(list(error = TRUE, message = "Grid and qualifying positions must be between 1 and 25."))
  }
  if (drv_pts < 0 || con_pts < 0 || q_delta < 0 || rnd_num < 1) {
    res$status <- 400
    return(list(error = TRUE, message = "Points, lap delta, and round numbers must be non-negative (round >= 1)."))
  }

  new_df <- data.frame(
    grid_position = grid_pos,
    qualifying_position = quali_pos,
    q_delta_to_pole = q_delta,
    driver_previous_points = drv_pts,
    constructor_previous_points = con_pts,
    round = rnd_num
  )

  pred_res <- predict(f_model$model, newdata = new_df, interval = "prediction", level = 0.95)
  fit_val <- as.numeric(pred_res[1, "fit"])
  lwr_val <- as.numeric(pred_res[1, "lwr"])
  upr_val <- as.numeric(pred_res[1, "upr"])

  list(
    predicted_points = round(max(0, fit_val), 2),
    raw_fit = round(fit_val, 4),
    confidence_interval = list(
      lower = round(max(0, lwr_val), 2),
      upper = round(max(0, upr_val), 2),
      level = 0.95
    ),
    features = list(
      grid_position = grid_pos,
      qualifying_position = quali_pos,
      q_delta_to_pole = q_delta,
      driver_previous_points = drv_pts,
      constructor_previous_points = con_pts,
      round = rnd_num
    )
  )
}

#* Model 4: Student Placement Prediction (Logistic Regression)
#* @post /placement/predict
#* @serializer json list(auto_unbox = TRUE)
function(req, res) {
  body <- tryCatch({
    if (is.list(req$body)) req$body else jsonlite::fromJSON(req$postBody)
  }, error = function(e) {
    NULL
  })

  if (is.null(body) || length(body) == 0) {
    res$status <- 400
    return(list(error = TRUE, message = "Malformed or empty JSON request body."))
  }

  required_features <- c(
    "ssc_percentage", "hsc_percentage", "degree_percentage",
    "work_experience", "aptitude_test_percentage", "mba_percentage",
    "mba_specialisation", "degree_field"
  )
  missing <- setdiff(required_features, names(body))
  if (length(missing) > 0) {
    res$status <- 400
    return(list(error = TRUE, message = paste("Missing required student predictors:", paste(missing, collapse = ", "))))
  }

  # Numerical validations
  ssc  <- suppressWarnings(as.numeric(body$ssc_percentage))
  hsc  <- suppressWarnings(as.numeric(body$hsc_percentage))
  deg  <- suppressWarnings(as.numeric(body$degree_percentage))
  wexp <- suppressWarnings(as.integer(body$work_experience))
  tst  <- suppressWarnings(as.numeric(body$aptitude_test_percentage))
  mba  <- suppressWarnings(as.numeric(body$mba_percentage))

  if (any(is.na(c(ssc, hsc, deg, wexp, tst, mba)))) {
    res$status <- 400
    return(list(error = TRUE, message = "Academic scores and work experience must be valid numbers."))
  }

  if (ssc < 0 || ssc > 100 || hsc < 0 || hsc > 100 || deg < 0 || deg > 100 || tst < 0 || tst > 100 || mba < 0 || mba > 100) {
    res$status <- 400
    return(list(error = TRUE, message = "Academic percentages must be between 0 and 100."))
  }

  if (!wexp %in% c(0, 1)) {
    res$status <- 400
    return(list(error = TRUE, message = "Work experience must be 0 (No) or 1 (Yes)."))
  }

  # Categorical validations
  mba_spec <- as.character(body$mba_specialisation)
  deg_fld  <- as.character(body$degree_field)

  valid_mba_specs <- p_model$model$xlevels$mba_specialisation
  valid_deg_flds  <- p_model$model$xlevels$degree_field

  if (!mba_spec %in% valid_mba_specs) {
    res$status <- 400
    return(list(error = TRUE, message = sprintf("Invalid mba_specialisation '%s'. Allowed: %s", mba_spec, paste(valid_mba_specs, collapse = ", "))))
  }

  if (!deg_fld %in% valid_deg_flds) {
    res$status <- 400
    return(list(error = TRUE, message = sprintf("Invalid degree_field '%s'. Allowed: %s", deg_fld, paste(valid_deg_flds, collapse = ", "))))
  }

  new_df <- data.frame(
    ssc_percentage = ssc,
    hsc_percentage = hsc,
    degree_percentage = deg,
    work_experience = wexp,
    aptitude_test_percentage = tst,
    mba_percentage = mba,
    mba_specialisation = factor(mba_spec, levels = valid_mba_specs),
    degree_field = factor(deg_fld, levels = valid_deg_flds)
  )

  prob <- as.numeric(predict(p_model$model, newdata = new_df, type = "response"))
  threshold <- 0.50
  pred_class <- ifelse(prob >= threshold, 1, 0)
  pred_label <- ifelse(pred_class == 1, "Placed", "Not Placed")

  list(
    probability = round(prob, 4),
    prediction = pred_class,
    label = pred_label,
    threshold = threshold,
    odds_multipliers = list(
      work_experience_odds = 9.9884,
      ssc_percentage_unit_odds = 1.2541,
      hsc_percentage_unit_odds = 1.1136,
      degree_percentage_unit_odds = 1.1398
    )
  )
}

#* Data endpoint: Brain Activity Clustered Records
#* @get /brain/data
#* @serializer json
function() {
  list(
    total_records = nrow(brain_data_df),
    data = brain_data_df[, c("epoch_id", "cluster", "PCA1", "PCA2", b_model$feature_names)]
  )
}

#* Data endpoint: Country Development Clustered Records
#* @get /country/data
#* @serializer json
function() {
  list(
    total_countries = nrow(country_data_df),
    data = country_data_df[, c("country", "country_code", "cluster", "PCA1", "PCA2", "gdp_per_capita", "life_expectancy", "infant_mortality", "internet_usage_pct")]
  )
}

#* Data endpoint: Formula 1 Out-of-Sample Predictions
#* @get /f1/data
#* @serializer json
function() {
  if (!"actual_points" %in% names(f1_pred_df) && "race_points" %in% names(f1_pred_df)) {
    f1_pred_df$actual_points <<- f1_pred_df$race_points
  }
  list(
    total_races = nrow(f1_pred_df),
    data = f1_pred_df[, c("season", "round", "race_name", "driver_name", "grid_position", "actual_points", "predicted_points", "residual")]
  )
}

#* Data endpoint: Student Placement Out-of-Sample Predictions
#* @get /placement/data
#* @serializer json
function() {
  list(
    total_candidates = nrow(placement_pred_df),
    data = placement_pred_df[, c("student_id", "actual_placed", "predicted_probability", "predicted_class", "correct", "ssc_percentage", "degree_percentage", "work_experience")]
  )
}
