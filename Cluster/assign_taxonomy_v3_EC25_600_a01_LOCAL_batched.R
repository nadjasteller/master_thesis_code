#!/usr/bin/env Rscript
# =============================================================================
# assign_taxonomy_v3_EC25_600_a01_LOCAL_batched.R
# ASV Taxonomie-Klassifizierung mit UNITE -- NUR der neue Lauf EC25_600_a_01
# LOKALE, RAM-schonende Version: begrenzte Thread-Zahl + Batch-Verarbeitung
# + Zwischenspeicherung nach jedem Batch (uebersteht Abstuerze/Haenger)
# =============================================================================

library(dada2)

# ----------------------------------------------------------------------------
# Pfade
# ----------------------------------------------------------------------------
base_path  <- "C:/Users/user/Documents/Master_EnvironmentalSciences/Master_Thesis"
unite_db   <- file.path(base_path,
                        "Data/Databases/sh_general_release_dynamic_19.02.2025.fasta")
output_dir <- file.path(base_path, "Data/Final/Taxonomy_v3")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

checkpoint_path <- file.path(output_dir, "taxonomy_EC25_600_a01_checkpoint.rds")

# ----------------------------------------------------------------------------
# WICHTIG: Thread-Zahl explizit begrenzen statt multithread=TRUE (alle 12 Kerne)
# Bei nur ~6.8 GB RAM verursachen 12 parallele Threads vermutlich Swapping
# (Festplatten-Auslagerung), was die Berechnung extrem verlangsamt.
# Erst mit 2 Threads probieren -- bei Bedarf spaeter vorsichtig erhoehen.
# ----------------------------------------------------------------------------
N_THREADS  <- 2
BATCH_SIZE <- 20   # ASVs pro Batch -- kleiner = weniger RAM-Spitze, mehr Zwischenspeicherung

# ----------------------------------------------------------------------------
# ASVs laden
# ----------------------------------------------------------------------------
new_seqtab_path <- file.path(base_path,
                             "Data/Final/DADA2_Output_v3/EC25_600_a_01/seqtab_nochim.rds")
seqtab <- readRDS(new_seqtab_path)
seqs   <- colnames(seqtab)
cat("Anzahl ASVs gesamt:", length(seqs), "\n")
cat("Threads:", N_THREADS, "| Batch-Groesse:", BATCH_SIZE, "\n\n")

# ----------------------------------------------------------------------------
# Checkpoint laden, falls vorhanden (Fortsetzung nach Abbruch/Absturz)
# ----------------------------------------------------------------------------
if (file.exists(checkpoint_path)) {
  results_list <- readRDS(checkpoint_path)
  done_seqs    <- unlist(lapply(results_list, rownames))
  cat("Checkpoint gefunden:", length(done_seqs), "von", length(seqs),
      "ASVs bereits klassifiziert. Setze fort...\n\n")
} else {
  results_list <- list()
  done_seqs    <- character(0)
}

remaining_seqs <- setdiff(seqs, done_seqs)
cat("Verbleibend zu klassifizieren:", length(remaining_seqs), "\n\n")

if (length(remaining_seqs) == 0) {
  cat("Bereits alle ASVs klassifiziert! Springe direkt zum Zusammenfuehren.\n")
} else {

  batches <- split(remaining_seqs, ceiling(seq_along(remaining_seqs) / BATCH_SIZE))
  cat("Anzahl Batches:", length(batches), "\n\n")

  for (i in seq_along(batches)) {
    batch_start <- Sys.time()
    cat("=== Batch", i, "/", length(batches), "===\n")
    cat("Start:", format(batch_start), "| ASVs in diesem Batch:", length(batches[[i]]), "\n")

    tax_batch <- assignTaxonomy(
      batches[[i]],
      unite_db,
      multithread = N_THREADS,
      tryRC       = TRUE,
      minBoot     = 80,
      verbose     = TRUE
    )

    results_list[[length(results_list) + 1]] <- tax_batch

    # ── Nach JEDEM Batch zwischenspeichern ────────────────────────────────
    saveRDS(results_list, checkpoint_path)

    batch_end <- Sys.time()
    elapsed   <- round(as.numeric(difftime(batch_end, batch_start, units = "mins")), 1)
    cat("Batch", i, "fertig nach", elapsed, "Minuten.\n")
    cat("Gesamt bisher klassifiziert:",
        sum(sapply(results_list, nrow)), "/", length(seqs), "\n\n")
  }
}

# ----------------------------------------------------------------------------
# Alle Batches zusammenfuegen
# ----------------------------------------------------------------------------
taxonomy_new <- do.call(rbind, results_list)
taxonomy_new_df          <- as.data.frame(taxonomy_new)
taxonomy_new_df$sequence <- rownames(taxonomy_new_df)

cat("\n========================================\n")
cat("Klassifizierungsrate pro Ebene (gesamt):\n")
for (rank in c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")) {
  n <- sum(!is.na(taxonomy_new_df[[rank]]))
  cat(sprintf("  %-10s %4d / %d  (%.1f%%)\n",
              rank, n, nrow(taxonomy_new_df), 100 * n / nrow(taxonomy_new_df)))
}

write.csv(taxonomy_new_df,
          file.path(output_dir, "taxonomy_EC25_600_a_01.csv"),
          row.names = FALSE)
cat("\nGespeichert:", file.path(output_dir, "taxonomy_EC25_600_a_01.csv"), "\n")

# ----------------------------------------------------------------------------
# Mit bestehender taxonomy_all.csv zusammenfuehren
# ----------------------------------------------------------------------------
taxonomy_all_path <- file.path(output_dir, "taxonomy_all.csv")
backup_path <- file.path(output_dir, "taxonomy_all_backup_pre_EC25_600_a01.csv")
if (!file.exists(backup_path)) {
  file.copy(taxonomy_all_path, backup_path, overwrite = FALSE)
  cat("Backup gespeichert:", backup_path, "\n")
}

taxonomy_all_old <- read.csv(taxonomy_all_path, stringsAsFactors = FALSE)
taxonomy_new_only <- taxonomy_new_df[!(taxonomy_new_df$sequence %in% taxonomy_all_old$sequence), ]
taxonomy_all_updated <- rbind(taxonomy_all_old, taxonomy_new_only)

write.csv(taxonomy_all_updated, taxonomy_all_path, row.names = FALSE)
cat("taxonomy_all.csv aktualisiert:", nrow(taxonomy_all_updated), "ASVs gesamt\n")

# ── Checkpoint aufraeumen, da fertig ─────────────────────────────────────────
if (file.exists(checkpoint_path)) file.remove(checkpoint_path)

cat("\nFERTIG.\n")
sessionInfo()
