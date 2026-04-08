#!/bin/bash
# Usage: ./gatherall.sh <multi_query.sig> <database.sig or db.sbt.zip>

set -euo pipefail

gather_multi_queries() {
  local query_sig="$1"
  local db="$2"

  if [[ -z "$query_sig" || -z "$db" ]]; then
    echo "Usage: gather_multi_queries <multi_query.sig> <database.sig or db.sbt.zip>"
    return 1
  fi

  if [[ ! -f "$query_sig" ]]; then
    echo "Error: Query signature file '$query_sig' does not exist."
    return 1
  fi

  if [[ ! -f "$db" ]]; then
    echo "Error: Database file '$db' does not exist."
    return 1
  fi

  mkdir -p tmp_sigs "gather_${query_sig}"

  sourmash sig split "$query_sig" --output-dir tmp_sigs

  for sig in tmp_sigs/*.sig; do
    base=$(basename "$sig" .sig)
    sourmash gather "$sig" "$db" -o "gather_${query_sig}/${base}_${db}.csv"
  done

  rm -rf tmp_sigs
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  gather_multi_queries "$@"
fi
