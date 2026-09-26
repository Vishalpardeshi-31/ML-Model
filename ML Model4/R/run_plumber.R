# ==============================================================================
# ML Model 4 — Start Plumber Inference Server
# ==============================================================================

suppressPackageStartupMessages({
  library(plumber)
})

cat("[*] Launching R Plumber ML API on http://127.0.0.1:8000...\n")
pr <- plumb("R/api.R")
pr$run(host = "127.0.0.1", port = 8000, docs = FALSE)
