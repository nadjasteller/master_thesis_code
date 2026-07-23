#!/bin/bash
# =============================================================================
# Cutadapt Trimming Script – Pilz ITS (ITS3_KYO2 / ITS4_KYO2)
# Masterarbeit – Paired-End Illumina Reads
#
# WICHTIG zu den Dateinamen:
#   R1_001.fastq.gz  --> enthaelt REVERSE-Reads
#   R2_001.fastq.gz  --> enthaelt FORWARD-Reads
#
# Primer:
#   FWD (ITS3_KYO2): GATGAAGAACGYAGYRAA   --> sitzt in R2
#   REV (ITS4_KYO2): RBTTTCTTTTCCTCCGCT   --> sitzt in R1
# =============================================================================

source "/c/Users/user/miniconda3/etc/profile.d/conda.sh"
conda activate fastq_trim

# --------------------------------------------------------------------
# 1) PFADE ANPASSEN
# --------------------------------------------------------------------
INPUT_DIR="C:/Users/user/Documents/Master_EnvironmentalSciences/Master Thesis/Data/Rohdaten/Data/ns2024-18-EC24-245_MT"
OUTPUT_DIR="C:/Users/user/Documents/Master_EnvironmentalSciences/Master Thesis/Data/Trimmed"

# Ausgabeordner erstellen falls nicht vorhanden
mkdir -p "$OUTPUT_DIR"

# --------------------------------------------------------------------
# 2) PRIMER-SEQUENZEN
#    Zusaetzlich: reverse complements beider Primer,
#    da Illumina paired-end auch den RC am anderen Ende lesen kann.
# --------------------------------------------------------------------
FWD="GATGAAGAACGYAGYRAA"          # ITS3_KYO2 – sitzt am Anfang von R2
REV="RBTTTCTTTTCCTCCGCT"          # ITS4_KYO2 – sitzt am Anfang von R1

FWD_RC="TTYRCTRCGTTCTTCATC"       # Reverse complement von FWD
REV_RC="AGCGGAGGAAAAGAAACVY"      # Reverse complement von REV

# --------------------------------------------------------------------
# 3) CUTADAPT PARAMETER (Erklaerung unten)
# --------------------------------------------------------------------
ERROR_RATE=0.2          # 20% Fehlertoleranz (noetig fuer IUPAC-Codes)
MIN_LENGTH=50           # Reads kuerzer als 50bp nach Trimming verwerfen
CORES=4                 # Anzahl CPU-Kerne (anpassen nach PC)

# --------------------------------------------------------------------
# 4) ALLE PROBEN AUTOMATISCH DURCHLAUFEN
#    Sucht alle R1-Dateien und findet das zugehoerige R2-File
# --------------------------------------------------------------------
echo "Starte Cutadapt Trimming..."
echo "Eingabe: $INPUT_DIR"
echo "Ausgabe: $OUTPUT_DIR"
echo "----------------------------------------"

SAMPLE_COUNT=0
ERROR_COUNT=0

for R1_FILE in "$INPUT_DIR"/*_R1_001.fastq; do

    # Pruefe ob Dateien gefunden wurden
    if [ ! -f "$R1_FILE" ]; then
        echo "WARNUNG: Keine R1-Dateien gefunden in $INPUT_DIR"
        break
    fi

    # Zugehoeriges R2-File bestimmen
    R2_FILE="${R1_FILE/_R1_001.fastq/_R2_001.fastq}"

    if [ ! -f "$R2_FILE" ]; then
        echo "FEHLER: Kein R2-File gefunden fuer: $R1_FILE"
        ((ERROR_COUNT++))
        continue
    fi

    # Probenname aus Dateiname extrahieren (alles vor _R1_001)
    SAMPLE=$(basename "$R1_FILE" | sed 's/_R1_001.fastq//')

    # Ausgabedateien benennen
    OUT_R1="$OUTPUT_DIR/${SAMPLE}_R1_trimmed.fastq"
    OUT_R2="$OUTPUT_DIR/${SAMPLE}_R2_trimmed.fastq"
    LOG_FILE="$OUTPUT_DIR/${SAMPLE}_cutadapt.log"

    echo "Verarbeite Probe: $SAMPLE"

    # ------------------------------------------------------------------
    # CUTADAPT BEFEHL
    #
    # R1 (Reverse-Reads) erwartet:
    #   -g REV        = REV-Primer am 5'-Ende von R1
    #   -a FWD_RC     = RC des FWD-Primers am 3'-Ende von R1
    #
    # R2 (Forward-Reads) erwartet:
    #   -G FWD        = FWD-Primer am 5'-Ende von R2
    #   -A REV_RC     = RC des REV-Primers am 3'-Ende von R2
    # ------------------------------------------------------------------
    cutadapt \
        -g "$REV" \
        -a "$FWD_RC" \
        -G "$FWD" \
        -A "$REV_RC" \
        --error-rate $ERROR_RATE \
        --minimum-length $MIN_LENGTH \
        --discard-untrimmed \
        --cores $CORES \
        -o "$OUT_R1" \
        -p "$OUT_R2" \
        "$R1_FILE" "$R2_FILE" \
        > "$LOG_FILE" 2>&1

    # Pruefe ob cutadapt erfolgreich war
    if [ $? -eq 0 ]; then
        echo "  ✓ Erfolgreich → Log: ${SAMPLE}_cutadapt.log"
        ((SAMPLE_COUNT++))
    else
        echo "  ✗ FEHLER bei Probe $SAMPLE – siehe $LOG_FILE"
        ((ERROR_COUNT++))
    fi

done

echo "----------------------------------------"
echo "Fertig! $SAMPLE_COUNT Proben erfolgreich, $ERROR_COUNT Fehler."
echo "Trimmed files liegen in: $OUTPUT_DIR"
