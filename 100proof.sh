#!/bin/bash

# Exit on error
set -e

# Check for input
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <chromosome_accession1> [chromosome_accession2 ...]"
  exit 1
fi

get_genome_sig() {
  for acc in "$@"; do
    local ACCESSION="$1"
    # Use efetch to get the chromosome in FASTA format
    echo "=== Processing $ACCESSION ==="
    echo "Fetching $ACCESSION..."
    efetch -db nucleotide -id "$ACCESSION" -format fasta > "${ACCESSION}.fasta"
    # Split the chromosome in two equal halves
    LEN=$(seqkit stats -T "${ACCESSION}.fasta" | awk 'NR==1 {next} {print $5}')
    HALF=$((LEN / 3))
    seqkit subseq -r 1:$HALF "${ACCESSION}.fasta" > "${ACCESSION}.part_1.fasta"
    seqkit subseq -r $((HALF * 1)):$LEN "${ACCESSION}.fasta" > "${ACCESSION}.part_2.fasta"
    # Cleanup
    rm *fai
    rm "${ACCESSION}.fasta"
    # Get signatures for each half
    echo "Sketching sourmash signature..."
    sourmash sketch dna -p k=31,scaled=1000 -o "${ACCESSION}.part_1.sig" ${ACCESSION}.part_1* --name ${ACCESSION}.part_1
    sourmash sketch dna -p k=31,scaled=1000 -o "${ACCESSION}.part_2.sig" ${ACCESSION}.part_2* --name ${ACCESSION}.part_2
    sourmash sig cat -o ${ACCESSION}.sig ${ACCESSION}.part_1.sig ${ACCESSION}.part_2.sig
    gzip "${ACCESSION}.sig"
    rm ${ACCESSION}.part*
  done
}

# Loop over all accessions passed to the script
for accession in "$@"; do
  get_genome_sig "$accession"
done
