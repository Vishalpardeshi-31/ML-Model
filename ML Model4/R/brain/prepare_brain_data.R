# ==============================================================================
# ML Model 4 - Brain Activity Pattern Discovery
# Data Preparation & Feature Extraction Script
# Algorithm: K-Means Clustering (Unsupervised)
# Source: UCI Machine Learning Repository (EEG Eye State Dataset, Oliver Roesler)
# ==============================================================================

# 1. Paths configuration
raw_file <- file.path("data", "raw", "brain", "EEG Eye State.arff")
output_csv <- file.path("data", "processed", "brain_activity.csv")
metadata_json <- file.path("data", "processed", "brain_activity_metadata.json")

cat("[*] Initializing EEG Brain Activity Feature Extraction Pipeline...\n")

# 2. Check if raw file exists
if (!file.exists(raw_file)) {
  stop(sprintf("[-] Raw file not found: %s. Run data acquisition first.", raw_file))
}

# 3. Read ARFF file (parse header and locate @DATA)
lines <- readLines(raw_file)
data_idx <- which(grepl("^@DATA", lines, ignore.case = TRUE))

if (length(data_idx) == 0) {
  stop("[-] Could not locate @DATA section in ARFF file.")
}

# 4. Extract data table
raw_data <- read.csv(
  text = lines[(data_idx + 1):length(lines)],
  header = FALSE,
  stringsAsFactors = FALSE
)

colnames(raw_data) <- c(
  "AF3", "F7", "F3", "FC5", "T7", "P7", "O1",
  "O2", "P8", "T8", "FC6", "F4", "F8", "AF4",
  "eyeDetection"
)

cat(sprintf("[+] Successfully loaded %d raw time-series observations.\n", nrow(raw_data)))

# 5. Outlier rejection: Emotiv headset baseline is ~4000-4800 uV.
# Extreme spikes (< 3000 uV or > 6000 uV) indicate gross motion or electrode loss.
channel_cols <- colnames(raw_data)[1:14]
valid_mask <- rep(TRUE, nrow(raw_data))

for (col in channel_cols) {
  valid_mask <- valid_mask & (raw_data[[col]] >= 3000 & raw_data[[col]] <= 6000)
}

clean_data <- raw_data[valid_mask, ]
cat(sprintf("[+] Retained %d clean continuous observations after physiological artifact filtering.\n", nrow(clean_data)))

# 6. Feature Extraction via Spectral Decomposition
# Sampling frequency = 128 Hz. Window size = 128 samples (1.0 second per epoch), step = 64 (50% overlap).
fs <- 128
window_size <- 128
step_size <- 64
n_samples <- nrow(clean_data)

epoch_starts <- seq(1, n_samples - window_size + 1, by = step_size)
cat(sprintf("[*] Extracting windowed frequency & time-domain features across %d epochs...\n", length(epoch_starts)))

# Helper: Compute spectral band power from single channel window
calc_band_powers <- function(signal, fs) {
  # Demean signal
  x <- signal - mean(signal)
  n <- length(x)
  # FFT
  fft_vals <- stats::fft(x)
  psd <- (Mod(fft_vals[1:(n/2 + 1)])^2) / (n * fs)
  freqs <- seq(0, fs/2, length.out = length(psd))
  
  # Power bands
  delta <- sum(psd[freqs >= 0.5 & freqs < 4.0])
  theta <- sum(psd[freqs >= 4.0 & freqs < 8.0])
  alpha <- sum(psd[freqs >= 8.0 & freqs < 13.0])
  beta  <- sum(psd[freqs >= 13.0 & freqs < 30.0])
  gamma <- sum(psd[freqs >= 30.0 & freqs <= 45.0])
  total <- delta + theta + alpha + beta + gamma + 1e-12
  
  # Spectral entropy
  p_norm <- psd / (sum(psd) + 1e-12)
  p_norm <- p_norm[p_norm > 0]
  spec_entropy <- -sum(p_norm * log2(p_norm))
  
  list(
    delta = delta, theta = theta, alpha = alpha, beta = beta, gamma = gamma,
    delta_rel = delta / total, theta_rel = theta / total,
    alpha_rel = alpha / total, beta_rel = beta / total, gamma_rel = gamma / total,
    spectral_entropy = spec_entropy
  )
}

features_list <- list()

for (i in seq_along(epoch_starts)) {
  idx <- epoch_starts[i]:(epoch_starts[i] + window_size - 1)
  epoch_sub <- clean_data[idx, ]
  
  # Aggregate across channels (Global field power / mean spectrum)
  global_signal <- rowMeans(epoch_sub[, channel_cols])
  spec <- calc_band_powers(global_signal, fs)
  
  # Regional focus: Occipital (O1, O2) alpha power (classic eye open/close marker)
  occipital_signal <- (epoch_sub$O1 + epoch_sub$O2) / 2
  occ_spec <- calc_band_powers(occipital_signal, fs)
  
  # Regional focus: Frontal (F3, F4) asymmetry
  f3_spec <- calc_band_powers(epoch_sub$F3, fs)
  f4_spec <- calc_band_powers(epoch_sub$F4, fs)
  frontal_asymmetry <- (f4_spec$alpha - f3_spec$alpha) / (f4_spec$alpha + f3_spec$alpha + 1e-12)
  
  # Time-domain metrics
  mean_amp <- mean(global_signal)
  signal_var <- stats::var(global_signal)
  tbr <- spec$theta / (spec$beta + 1e-12) # Theta-Beta Ratio
  
  # Modal eye state (ground truth for validation)
  eye_state <- as.integer(mean(epoch_sub$eyeDetection) >= 0.5)
  
  features_list[[i]] <- data.frame(
    epoch_id = i,
    delta_power = spec$delta,
    theta_power = spec$theta,
    alpha_power = spec$alpha,
    beta_power = spec$beta,
    gamma_power = spec$gamma,
    alpha_relative = spec$alpha_rel,
    beta_relative = spec$beta_rel,
    theta_beta_ratio = tbr,
    occipital_alpha = occ_spec$alpha,
    frontal_asymmetry = frontal_asymmetry,
    mean_amplitude = mean_amp,
    signal_variance = signal_var,
    spectral_entropy = spec$spectral_entropy,
    eye_state_ground_truth = eye_state
  )
}

processed_df <- do.call(rbind, features_list)

# 7. Write final processed CSV
dir.create(dirname(output_csv), showWarnings = FALSE, recursive = TRUE)
write.csv(processed_df, output_csv, row.names = FALSE)
cat(sprintf("[SUCCESS] Saved processed EEG dataset to %s (%d rows, %d columns).\n",
            output_csv, nrow(processed_df), ncol(processed_df)))
