#!/bin/bash

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <chromosome_accession1> [chromosome_accession2 ...]"
  exit 1
fi

get_genome_sig() {
  for acc in "$@"; do
    local ACCESSION="$acc"
    echo "=== Processing $ACCESSION ==="
    echo "Fetching $ACCESSION..."
    efetch -db nucleotide -id "$ACCESSION" -format fasta > "${ACCESSION}.fasta"

    LEN=$(seqkit stats -T "${ACCESSION}.fasta" | awk 'NR==1 {next} {print $5}')
    HALF=$((LEN / 2))

    seqkit subseq -r 1:$HALF "${ACCESSION}.fasta" > "${ACCESSION}.part_1.fasta"
    seqkit subseq -r $((HALF + 1)):$LEN "${ACCESSION}.fasta" > "${ACCESSION}.part_2.fasta"

    rm -f *fai
    rm -f "${ACCESSION}.fasta"

    echo "Sketching sourmash signature..."
    sourmash sketch dna -p k=31,scaled=1000 -o "${ACCESSION}.part_1.sig" "${ACCESSION}.part_1.fasta" --name "${ACCESSION}.part_1"
    sourmash sketch dna -p k=31,scaled=1000 -o "${ACCESSION}.part_2.sig" "${ACCESSION}.part_2.fasta" --name "${ACCESSION}.part_2"
    sourmash sig cat -o "${ACCESSION}.sig" "${ACCESSION}.part_1.sig" "${ACCESSION}.part_2.sig"
    gzip "${ACCESSION}.sig"
    rm -f "${ACCESSION}.part_1.fasta" "${ACCESSION}.part_2.fasta" "${ACCESSION}.part_1.sig" "${ACCESSION}.part_2.sig"
  done
}

get_genome_sig "$@"
