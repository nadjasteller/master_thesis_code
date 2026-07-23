#!/usr/bin/env Rscript
# =============================================================================
# assign_taxonomy_v3_EC25_600_a01_CORRECTED.R
# ASV Taxonomie-Klassifizierung mit UNITE -- NUR der neue Lauf EC25_600_a_01
# KORRIGIERTE Pfade: alles direkt unter ~/, passend zum tatsaechlichen
# v3-Cluster-Layout (nicht ~/Master_Thesis/Data/Final/...)
# =============================================================================

library(dada2)

# ----------------------------------------------------------------------------
# Pfade -- korrigiert auf tatsaechliches Cluster-Layout
# ----------------------------------------------------------------------------
unite_db   <- "~/Master_Thesis/Data/Databases/sh_general_release_dynamic_19.02.2025.fasta"
output_dir <- "~/DADA2_Output_v3"  # ASV-Tabellen liegen hier
tax_dir    <- "~"                   # Taxonomie-CSVs liegen direkt im Home

new_seqtab_path   <- "~/DADA2_Output_v3/EC25_600_a_01/seqtab_nochim.rds"
taxonomy_all_path <- "~/taxonomy_v3_updated.csv"   # deine hochgeladene, aktuelle Version

# ── Checks, bevor es losgeht ─────────────────────────────────────────────────
if (!file.exists(path.expand(unite_db))) {
  stop("UNITE-Datenbank nicht gefunden unter: ", unite_db)
}
if (!file.exists(path.expand(new_seqtab_path))) {
  stop("seqtab_nochim.rds fuer EC25_600_a_01 nicht gefunden unter: ", new_seqtab_path)
}
if (!file.exists(path.expand(taxonomy_all_path))) {
  stop("taxonomy_v3_updated.csv nicht gefunden unter: ", taxonomy_all_path)
}
cat("Alle Eingabedateien gefunden. Starte...\n\n")

# ----------------------------------------------------------------------------
# Klassifizieren
# ----------------------------------------------------------------------------
cat("========================================\n")
cat("Klassifiziere Lauf: EC25_600_a_01\n")
cat("Start:", format(Sys.time()), "\n")
cat("========================================\n")

seqtab <- readRDS(path.expand(new_seqtab_path))
seqs   <- colnames(seqtab)
cat("Anzahl ASVs:", length(seqs), "\n")

taxonomy <- assignTaxonomy(
  seqs,
  path.expand(unite_db),
  multithread = TRUE,   # auf dem Cluster: volle 8 CPUs nutzen (SLURM-Skript)
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

out_path <- "~/taxonomy_EC25_600_a_01.csv"
write.csv(taxonomy_df, path.expand(out_path), row.names = FALSE)
cat("\nGespeichert:", out_path, "\n")
cat("Ende:", format(Sys.time()), "\n")

# ----------------------------------------------------------------------------
# Mit taxonomy_v3_updated.csv zusammenfuehren
# ----------------------------------------------------------------------------
cat("\n========================================\n")
cat("Fuehre neue Taxonomie mit bestehender Tabelle zusammen\n")
cat("========================================\n")

taxonomy_all_old <- read.csv(path.expand(taxonomy_all_path), stringsAsFactors = FALSE)
cat("taxonomy_v3_updated.csv (vorher):", nrow(taxonomy_all_old), "ASVs\n")

taxonomy_new_only <- taxonomy_df[!(taxonomy_df$sequence %in% taxonomy_all_old$sequence), ]
cat("Davon tatsaechlich neu:", nrow(taxonomy_new_only), "von", nrow(taxonomy_df), "\n")

taxonomy_all_final <- rbind(taxonomy_all_old, taxonomy_new_only)
cat("Finale Taxonomie-Tabelle:", nrow(taxonomy_all_final), "ASVs\n")

final_path <- "~/taxonomy_v3_final.csv"
write.csv(taxonomy_all_final, path.expand(final_path), row.names = FALSE)
cat("Gespeichert:", final_path, "\n")
cat("\n>>> BITTE taxonomy_v3_final.csv herunterladen und lokal als\n")
cat(">>> Data/Final/Taxonomy_v3/taxonomy_all.csv ablegen. <<<\n")

cat("\nFERTIG.\n")
sessionInfo()
