# Drivers of Insect–Fungi Associations: Phylogeny and Functional Traits

Analysis code for the Master's thesis by Nadja Steller (University of
Freiburg, Faculty of Environment and Natural Resources), examining
whether beetle phylogeny or functional traits better predict the
composition of their associated fungal communities (ITS metabarcoding,
14 beetle species, five families).

The LaTeX source of the thesis text itself is version-controlled
separately and not part of this repository.

## Pipeline order

The numbered `.qmd` files in the repository root are the final, current
analysis scripts and should be read/run in this order:

| Script | Purpose |
|---|---|
| `01_QC_DADA2_Corymbia.qmd` | Initial quality control (pilot run) |
| `01_dada2_qualitycontrol4all.qmd` | Quality control across all sequencing runs |
| `02_dada2_pipeline_v3.qmd` | DADA2 ASV inference pipeline |
| `03_build_phyloseq_v3_FINAL3.qmd` | Assemble the phyloseq object |
| `04_filter_taxonomy_v3_NEWSPECIES.qmd` | Taxonomic filtering, trait annotation |
| `05_diversity_community_v3.qmd` | Alpha diversity, NMDS, PERMANOVA, betadisper, pairwise PERMANOVA, variance partitioning |
| `06_indicator_species_v3_FINAL.qmd` | Indicator species analysis |
| `07_core_mycobiome_v3.qmd` | Core mycobiome analysis |
| `08_lifestyle_network_v3.qmd` | Fungal lifestyle / bipartite network analysis |
| `09_discussion_analyses.qmd` | Supplementary analyses referenced in the Discussion |

Also in the root: `beetle_traits.qmd` (compiles the beetle functional
trait table used throughout), `helpers.R` (shared helper functions),
and `trim_ITS_cutadapt*.sh` (primer trimming via cutadapt, run before
`02_dada2_pipeline_v3.qmd`).

- **`Archive/`** — superseded/earlier versions of scripts, kept for
  traceability, not used to produce the final reported results. (E.g.
  `Archive/06_AlphaBetaDiversity.qmd` contains the earlier,
  abundance-based/Bray-Curtis variance partitioning explicitly noted as
  superseded in the thesis Discussion; the Jaccard/presence-absence
  version actually reported in Results is the variance partitioning
  section of `05_diversity_community_v3.qmd` itself.)
- **`Cluster/`** — taxonomy assignment scripts (DECIPHER/UNITE, IdTaxa)
  as run on the bwUniCluster 3.0 (bwHPC, State of Baden-Württemberg),
  plus the SLURM submission scripts used to run them there.
- **`Figures/`** — rendered output figures (PDF) from the analysis
  scripts, as referenced in the thesis.

## Data

Raw sequencing data and large intermediate files (phyloseq objects,
DADA2 outputs, etc.) are not tracked in this repository due to size.
Raw ITS amplicon sequencing reads are archived separately (see the
thesis Methods for repository/accession details, if deposited).

**Note on paths:** each script sets an absolute local path near the
top, e.g.:

```r
base_path <- "C:/Users/user/Documents/Master_EnvironmentalSciences/Master_Thesis"
```

and then reads/writes data via `file.path(base_path, "Data/...")` etc.
These paths are hardcoded to the author's own machine and are not
portable as-is; to rerun a script, edit its `base_path` (and any other
hardcoded absolute paths) to point at wherever the corresponding
`Data/`/`Results/`/`Figures/` folders are placed locally, and recreate
the expected subfolder structure referenced within each script (e.g.
`Data/Final/Taxonomy_v3/`, `Data/Metadata/`, `Results/Figures/`).

## Software requirements

R version 4.3.1 was used for all analyses in this repository. (As of
writing, some newer R installations, e.g. 4.4.x, have been observed
missing packages such as `knitr` required to knit these `.qmd` files —
R 4.3.1 is recommended.)

R packages used across the scripts (install via `install.packages()` /
`BiocManager::install()` as appropriate):

```
Biostrings, RColorBrewer, ShortRead, UpSetR, bipartite, cluster,
colorspace, corrplot, cowplot, dada2, data.table, data.tree, dplyr,
edgebundleR, forcats, ggalluvial, ggforce, ggnewscale, ggpattern,
ggplot2, ggraph, ggrepel, ggsci, ggtree, ggvenn, htmlwidgets, httr,
igraph, indicspecies, janitor, knitr, microeco, openxlsx, otuSummary,
pairwiseAdonis, patchwork, pheatmap, phyloseq, reshape2, scales, scico,
stringr, tibble, tidyr, tidyverse, vegan, xtable
```

Bioconductor packages (`BiocManager::install()`, not
`install.packages()`): `Biostrings`, `ShortRead`, `dada2`, `ggtree`,
`phyloseq`.

`pairwiseAdonis` is not on CRAN; install from GitHub:

```r
remotes::install_github("pmartinezarbizu/pairwiseAdonis")
```

Files are written as [Quarto](https://quarto.org) documents (`.qmd`);
Quarto plus R and the packages above are required to render/knit them.
[Cutadapt](https://cutadapt.readthedocs.io) is required for the
primer-trimming shell scripts.

## Citation

If you use this code, please cite the associated Master's thesis. A
citable, versioned snapshot of this repository is available via
Zenodo: *https://doi.org/10.5281/zenodo.22662416*.

## Contact

Nadja Steller — stellernadja@gmail.com
