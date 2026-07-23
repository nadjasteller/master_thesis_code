#!/bin/bash
source "/c/Users/user/miniconda3/etc/profile.d/conda.sh"
conda activate fastq_trim

# =============================================================================
# Cutadapt Trimming Script – Pilz ITS (ITS3_KYO2 / ITS4_KYO2)
# Masterarbeit – Paired-End Illumina Reads
# NUR NextSeq-Läufe: EC24_245 und Buse (quality-binned → --nextseq-trim=20)
# =============================================================================

BASE="C:/Users/user/Documents/Master_EnvironmentalSciences/Master_Thesis/Data"

# Eingabe-Ordner (nur NextSeq-Läufe!)
INPUT_DIRS=(
    "$BASE/Raw/Data/ns2024-18-EC24-245_MT"
    "$BASE/Raw/Data/EC25_600a_02_pFITS_04"
)

# Ausgabe-Ordner (neue Unterordner um alte Daten nicht zu überschreiben)
OUTPUT_DIRS=(
    "$BASE/Processed/Trimmed_nextseq/EC24_245"
    "$BASE/Processed/Trimmed_nextseq/Buse"
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
CORES=1

# --------------------------------------------------------------------
# Alle Ordner durchlaufen
# --------------------------------------------------------------------
for i in 0 1; do
    INPUT_DIR="${INPUT_DIRS[$i]}"
    OUTPUT_DIR="${OUTPUT_DIRS[$i]}"
    mkdir -p "$OUTPUT_DIR"

    echo "========================================"
    echo "Verarbeite NextSeq-Lauf: $INPUT_DIR"
    echo "Ausgabe:                 $OUTPUT_DIR"
    echo "Modus: --nextseq-trim=20 aktiv"
    echo "========================================"

    SAMPLE_COUNT=0
    ERROR_COUNT=0

    for R1_FILE in "$INPUT_DIR"/*_R1_001.fastq "$INPUT_DIR"/*_R1_001.fastq.gz; do
        [ -f "$R1_FILE" ] || continue

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
            --nextseq-trim=20 \
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

echo "NextSeq-Läufe abgeschlossen!"
echo "Output in: $BASE/Processed/Trimmed_nextseq/"
