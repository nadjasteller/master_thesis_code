#!/usr/bin/env Rscript
# =============================================================================
# assign_taxonomy_v3.R
# ASV Taxonomie-Klassifizierung mit UNITE – alle vier Sequenzierläufe
# Pipeline v3: NextSeq mit loessErrfun + maxEE=c(5,2) + truncQ=3
# Auf KIT-Cluster (bwUniCluster 2.0) berechnet
# Input:  seqtab_nochim.rds pro Lauf + seqtab_all.rds (gemeinsam)
# Output: taxonomy_*.csv pro Lauf + taxonomy_all.csv (gemeinsam)
# =============================================================================

library(dada2)

# ----------------------------------------------------------------------------
# Pfade
# ----------------------------------------------------------------------------
base_path  <- "~/Master_Thesis"
unite_db   <- file.path(base_path,
                        "Data/Databases/sh_general_release_dynamic_19.02.2025.fasta")
output_dir <- file.path(base_path, "Data/Final/Taxonomy_v3")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------------------------
# Hilfsfunktion: Taxonomie für einen Lauf zuweisen
# ----------------------------------------------------------------------------
classify_run <- function(run_name, seqtab_path, output_dir, unite_db) {

  cat("\n========================================\n")
  cat("Klassifiziere Lauf:", run_name, "\n")
  cat("========================================\n")

  seqtab <- readRDS(seqtab_path)
  seqs   <- colnames(seqtab)
  cat("Anzahl ASVs:", length(seqs), "\n")

  taxonomy <- assignTaxonomy(
    seqs,
    unite_db,
    multithread = TRUE,
    tryRC       = TRUE,
    minBoot     = 80,
    verbose     = TRUE
  )

  taxonomy_df          <- as.data.frame(taxonomy)
  taxonomy_df$sequence <- rownames(taxonomy_df)

  cat("\nKlassifizierungsrate pro Ebene:\n")
  for (rank in c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")) {
    n <- sum(!is.na(taxonomy_df[[rank]]))
    cat(sprintf("  %-10s %4d / %d  (%.1f%%)\n",
                rank, n, nrow(taxonomy_df), 100 * n / nrow(taxonomy_df)))
  }

  out_path <- file.path(output_dir, paste0("taxonomy_", run_name, ".csv"))
  write.csv(taxonomy_df, out_path, row.names = FALSE)
  cat("Gespeichert:", out_path, "\n")

  return(taxonomy_df)
}

# ----------------------------------------------------------------------------
# Alle vier Läufe klassifizieren (v3 Pfade!)
# ----------------------------------------------------------------------------
runs <- list(
  EC24_245 = file.path(base_path, "Data/Final/DADA2_Output_v3/EC24_245/seqtab_nochim.rds"),
  `3XX`    = file.path(base_path, "Data/Final/DADA2_Output_v3/3XX/seqtab_nochim.rds"),
  Popa     = file.path(base_path, "Data/Final/DADA2_Output_v3/Popa/seqtab_nochim.rds"),
  Buse     = file.path(base_path, "Data/Final/DADA2_Output_v3/Buse/seqtab_nochim.rds")
)

taxonomy_list <- list()
for (run_name in names(runs)) {
  taxonomy_list[[run_name]] <- classify_run(
    run_name    = run_name,
    seqtab_path = runs[[run_name]],
    output_dir  = output_dir,
    unite_db    = unite_db
  )
}

# ----------------------------------------------------------------------------
# Gemeinsame Taxonomie für seqtab_all (v3)
# ----------------------------------------------------------------------------
cat("\n========================================\n")
cat("Klassifiziere gemeinsame ASV-Tabelle (v3)\n")
cat("========================================\n")

seqtab_all <- readRDS(file.path(base_path, "Data/Final/DADA2_Output_v3/seqtab_all.rds"))
seqs_all   <- colnames(seqtab_all)
cat("Gesamtanzahl ASVs:", length(seqs_all), "\n")

taxonomy_all <- assignTaxonomy(
  seqs_all,
  unite_db,
  multithread = TRUE,
  tryRC       = TRUE,
  minBoot     = 80,
  verbose     = TRUE
)

taxonomy_all_df          <- as.data.frame(taxonomy_all)
taxonomy_all_df$sequence <- rownames(taxonomy_all_df)

cat("\nKlassifizierungsrate (gesamt):\n")
for (rank in c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")) {
  n <- sum(!is.na(taxonomy_all_df[[rank]]))
  cat(sprintf("  %-10s %4d / %d  (%.1f%%)\n",
              rank, n, nrow(taxonomy_all_df), 100 * n / nrow(taxonomy_all_df)))
}

write.csv(taxonomy_all_df,
          file.path(output_dir, "taxonomy_all.csv"),
          row.names = FALSE)
cat("Gespeichert:", file.path(output_dir, "taxonomy_all.csv"), "\n")

# ----------------------------------------------------------------------------
# Session Info
# ----------------------------------------------------------------------------
cat("\n")
sessionInfo()
