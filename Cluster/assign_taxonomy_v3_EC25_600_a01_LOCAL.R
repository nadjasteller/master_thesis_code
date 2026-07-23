#!/usr/bin/env Rscript
# =============================================================================
# assign_taxonomy_v3_EC25_600_a01_LOCAL.R
# ASV Taxonomie-Klassifizierung mit UNITE -- NUR der neue Lauf EC25_600_a_01
# LOKALE Version (Cluster derzeit wegen Sicherheitsvorfall gesperrt)
# =============================================================================

library(dada2)

# ----------------------------------------------------------------------------
# Pfade (lokal, Windows -- statt ~/Master_Thesis auf dem Cluster)
# ----------------------------------------------------------------------------
base_path  <- "C:/Users/user/Documents/Master_EnvironmentalSciences/Master_Thesis"
unite_db   <- file.path(base_path,
                        "Data/Databases/sh_general_release_dynamic_19.02.2025.fasta")
output_dir <- file.path(base_path, "Data/Final/Taxonomy_v3")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ── Kurzer Check, ob die UNITE-Datenbank lokal vorhanden ist ────────────────
if (!file.exists(unite_db)) {
  stop("UNITE-Datenbank nicht gefunden unter: ", unite_db,
       "\nBitte von https://unite.ut.ee/repository.php herunterladen ",
       "(exakt dieselbe Version wie fuer die anderen vier Laeufe verwendet: 19.02.2025).")
}
cat("UNITE-Datenbank gefunden:", unite_db, "\n")

# ----------------------------------------------------------------------------
# Hilfsfunktion: Taxonomie fuer einen Lauf zuweisen (identisch zu v3)
# ----------------------------------------------------------------------------
classify_run <- function(run_name, seqtab_path, output_dir, unite_db) {

  cat("\n========================================\n")
  cat("Klassifiziere Lauf:", run_name, "\n")
  cat("Start:", format(Sys.time()), "\n")
  cat("========================================\n")

  seqtab <- readRDS(seqtab_path)
  seqs   <- colnames(seqtab)
  cat("Anzahl ASVs:", length(seqs), "\n")

  taxonomy <- assignTaxonomy(
    seqs,
    unite_db,
    multithread = TRUE,   # nutzt automatisch verfuegbare Kerne, auch unter Windows
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
  cat("Ende:", format(Sys.time()), "\n")

  return(taxonomy_df)
}

# ----------------------------------------------------------------------------
# NUR den neuen Lauf klassifizieren
# ----------------------------------------------------------------------------
new_run_name    <- "EC25_600_a_01"
new_seqtab_path <- file.path(base_path,
                             "Data/Final/DADA2_Output_v3/EC25_600_a_01/seqtab_nochim.rds")

if (!file.exists(new_seqtab_path)) {
  stop("seqtab_nochim.rds fuer EC25_600_a_01 nicht gefunden unter: ", new_seqtab_path,
       "\nBitte zuerst den lokalen DADA2-Schritt fuer diesen Lauf abschliessen.")
}

taxonomy_new <- classify_run(
  run_name    = new_run_name,
  seqtab_path = new_seqtab_path,
  output_dir  = output_dir,
  unite_db    = unite_db
)

# ----------------------------------------------------------------------------
# Mit bestehender taxonomy_all.csv zusammenfuehren
# ----------------------------------------------------------------------------
cat("\n========================================\n")
cat("Fuehre neue Taxonomie mit taxonomy_all.csv zusammen\n")
cat("========================================\n")

taxonomy_all_path <- file.path(output_dir, "taxonomy_all.csv")

# Backup der bisherigen Version, bevor ueberschrieben wird
backup_path <- file.path(output_dir, "taxonomy_all_backup_pre_EC25_600_a01.csv")
if (!file.exists(backup_path)) {
  file.copy(taxonomy_all_path, backup_path, overwrite = FALSE)
  cat("Backup gespeichert:", backup_path, "\n")
} else {
  cat("Backup existiert bereits, wird nicht ueberschrieben:", backup_path, "\n")
}

taxonomy_all_old <- read.csv(taxonomy_all_path, stringsAsFactors = FALSE)
cat("taxonomy_all.csv (vorher):", nrow(taxonomy_all_old), "ASVs\n")

# Nur wirklich neue Sequenzen anhaengen (keine Duplikate, falls das Skript
# versehentlich zweimal laeuft)
taxonomy_new_only <- taxonomy_new[!(taxonomy_new$sequence %in% taxonomy_all_old$sequence), ]
cat("Davon tatsaechlich neu (noch nicht in taxonomy_all.csv):",
    nrow(taxonomy_new_only), "von", nrow(taxonomy_new), "\n")

taxonomy_all_updated <- rbind(taxonomy_all_old, taxonomy_new_only)
cat("taxonomy_all.csv (nachher):", nrow(taxonomy_all_updated), "ASVs\n")

write.csv(taxonomy_all_updated, taxonomy_all_path, row.names = FALSE)
cat("Aktualisiert und gespeichert:", taxonomy_all_path, "\n")

# ----------------------------------------------------------------------------
# Session Info
# ----------------------------------------------------------------------------
cat("\n")
sessionInfo()
