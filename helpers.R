# Gemeinsame Hilfsfunktionen für 08_lifestyle_network_v3.qmd und
# 09_discussion_analyses.qmd (via source("helpers.R") eingebunden).

#' ASV(Sequenz) x Sample-Matrix in Long-Format bringen.
#'
#' Entfernt das "X"-Präfix, das R beim Einlesen numerisch beginnender
#' Sample-Namen als Spaltennamen ergänzt, filtert Nullreads raus und
#' joint optional Metadaten (über "sample") und/oder Taxonomie (über
#' "sequence"). Bündelt ein Muster, das in beiden Skripten wiederholt
#' vorkam.
reads_long <- function(otu_wide, meta = NULL, tax = NULL) {
  df <- otu_wide %>%
    tibble::rownames_to_column("sequence") %>%
    tidyr::pivot_longer(-sequence, names_to = "sample", values_to = "reads") %>%
    dplyr::mutate(sample = gsub("^X", "", sample)) %>%
    dplyr::filter(reads > 0)

  if (!is.null(meta)) df <- dplyr::left_join(df, meta, by = "sample")
  if (!is.null(tax))  df <- dplyr::left_join(df, tax, by = "sequence")

  df
}
