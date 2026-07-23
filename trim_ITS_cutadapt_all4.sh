#!/bin/bash
source "/c/Users/user/miniconda3/etc/profile.d/conda.sh"
conda activate fastq_trim
# =============================================================================
# Cutadapt Trimming Script – Pilz ITS (ITS3_KYO2 / ITS4_KYO2)
# Masterarbeit – Paired-End Illumina Reads
# Läufe: ns2024-18-EC24-245_MT, 3XX_S3XX, Popa-XXXXXX, EC25_600a_02_pFITS_04
# =============================================================================

BASE="C:/Users/user/Documents/Master_EnvironmentalSciences/Master_Thesis/Data"

# Eingabe-Ordner
INPUT_DIRS=(
    "$BASE/Raw/Data/ns2024-18-EC24-245_MT"
    "$BASE/Raw/Data/3XX_S3XX"
    "$BASE/Raw/Data/Popa-XXXXXX"
    "$BASE/Raw/Data/EC25_600a_02_pFITS_04"
)

# Ausgabe-Ordner (je ein Unterordner pro Lauf)
OUTPUT_DIRS=(
    "$BASE/Processed/Trimmed/EC24_245"
    "$BASE/Processed/Trimmed/3XX"
    "$BASE/Processed/Trimmed/Popa"
    "$BASE/Processed/Trimmed/Buse"
)

# --------------------------------------------------------------------
# Primer-Sequenzen
# --------------------------------------------------------------------
FWD="GATGAAGAACGYAGYRAA"
REV="RBTTTCTTTTCCTCCGCT"
FWD_RC="TTYRCTRCGTTCTTCATC"
REV_RC="AGCGGAGGAAAAGAAACVY"

ERROR_RATE=0.2
MIN_LENGTH=50
CORES=4

# --------------------------------------------------------------------
# Alle Ordner durchlaufen
# --------------------------------------------------------------------
for i in 0 1 2 3; do

    INPUT_DIR="${INPUT_DIRS[$i]}"
    OUTPUT_DIR="${OUTPUT_DIRS[$i]}"

    mkdir -p "$OUTPUT_DIR"

    echo "========================================"
    echo "Verarbeite Ordner: $INPUT_DIR"
    echo "Ausgabe:           $OUTPUT_DIR"
    echo "========================================"

    SAMPLE_COUNT=0
    ERROR_COUNT=0

    # Suche sowohl .fastq als auch .fastq.gz
    for R1_FILE in "$INPUT_DIR"/*_R1_001.fastq "$INPUT_DIR"/*_R1_001.fastq.gz; do

        [ -f "$R1_FILE" ] || continue

        # Zugehoeriges R2-File bestimmen
        if [[ "$R1_FILE" == *.fastq.gz ]]; then
            R2_FILE="${R1_FILE/_R1_001.fastq.gz/_R2_001.fastq.gz}"
            SAMPLE=$(basename "$R1_FILE" | sed 's/_R1_001\.fastq\.gz//')
        else
            R2_FILE="${R1_FILE/_R1_001.fastq/_R2_001.fastq}"
            SAMPLE=$(basename "$R1_FILE" | sed 's/_R1_001\.fastq//')
        fi

        if [ ! -f "$R2_FILE" ]; then
            echo "FEHLER: Kein R2-File gefunden fuer: $R1_FILE"
            ((ERROR_COUNT++))
            continue
        fi

        OUT_R1="$OUTPUT_DIR/${SAMPLE}_R1_trimmed.fastq"
        OUT_R2="$OUTPUT_DIR/${SAMPLE}_R2_trimmed.fastq"
        LOG_FILE="$OUTPUT_DIR/${SAMPLE}_cutadapt.log"

        echo "Verarbeite Probe: $SAMPLE"

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

        if [ $? -eq 0 ]; then
            echo "  ✓ Erfolgreich → Log: ${SAMPLE}_cutadapt.log"
            ((SAMPLE_COUNT++))
        else
            echo "  ✗ FEHLER bei Probe $SAMPLE – siehe $LOG_FILE"
            ((ERROR_COUNT++))
        fi

    done

    echo "----------------------------------------"
    echo "Lauf fertig! $SAMPLE_COUNT Proben erfolgreich, $ERROR_COUNT Fehler."
    echo ""

done

echo "Alle Läufe abgeschlossen!"
