#!/bin/bash
# gather_multi_queries.sh
# Usage: ./gather_multi_queries.sh <multi_query.sig> <database.sig or db.sbt.zip>

set -euo pipefail

# Function: gather_multi_queries
gather_multi_queries() {
    local query_sig="$1"
    local db="$2"

    # Check for required arguments
    if [[ -z "$query_sig" || -z "$db" ]]; then
        echo "Usage: gather_multi_queries <multi_query.sig> <database.sig or db.sbt.zip>"
        return 1
    fi

    # Verify files exist
    if [[ ! -f "$query_sig" ]]; then
        echo "Error: Query signature file '$query_sig' does not exist."
        return 1
    fi

    if [[ ! -f "$db" ]]; then
        echo "Error: Database file '$db' does not exist."
        return 1
    fi

    # Prepare directories
    mkdir -p tmp_sigs gather_${query_sig}

    echo "🔪 Splitting multi-signature file..."
    sourmash sig split "$query_sig" --output-dir tmp_sigs

    echo "⚔️ Running sourmash gather for each individual signature..."
    for sig in tmp_sigs/*.sig; do
        base=$(basename "$sig" .sig)
        echo "  → Gathering for $base..."
        sourmash gather "$sig" "$db" -o "gather_${query_sig}/${base}_${db}.csv"
    done

    echo "🏁 All done. Results stored in 'gather_${query_sig}/'."
}

# Invoke the function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    gather_multi_queries "$@"
fi

rm -r tmp_sigs
