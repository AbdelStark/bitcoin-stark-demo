#!/bin/bash

set -euo pipefail

# Source an eventual .env file
if [[ -f .env ]]; then
  source .env
fi

################################################################################
#                                  CONSTANTS                                     #
################################################################################

readonly FIRST_TX=1
readonly LAST_TX=72
readonly DEFAULT_BITCOIN_CLI="bitcoin-cli"
readonly DRY_RUN=0
readonly LIVE_RUN=1

################################################################################
#                                  FUNCTIONS                                     #
################################################################################

print_usage() {
  echo "Usage: $0 [-d|--dry-run] <tx_directory>"
  echo
  echo "Send transactions sequentially from a directory containing raw transaction files"
  echo
  echo "Arguments:"
  echo "  tx_directory    Directory containing transaction files (tx-1.txt to tx-72.txt)"
  echo
  echo "Options:"
  echo "  -d, --dry-run   Simulate sending transactions without actually sending them"
  echo
  echo "Environment variables:"
  echo "  BITCOIN_CLI_CMD_DEMO    Override default bitcoin-cli command ($DEFAULT_BITCOIN_CLI)"
  exit 1
}

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
  exit 1
}

send_transaction() {
  local tx_file=$1
  local tx_num=$2
  local total=$3
  local bitcoin_cli=$4
  local run_mode=$5

  # Read raw transaction from file
  local raw_tx
  raw_tx=$(cat "$tx_file")
  if [[ -z "$raw_tx" ]]; then
    error "Empty transaction data in $tx_file"
  fi

  # Send transaction
  log "Sending transaction $tx_num/$total ($(basename "$tx_file"))"
  
  if [[ $run_mode -eq $DRY_RUN ]]; then
    log "[DRY RUN] Would execute: $bitcoin_cli sendrawtransaction \"$raw_tx\""
    log "[DRY RUN] Simulating successful transaction: tx_$(printf "%03d" "$tx_num")_simulated_hash"
    return 0
  fi
  
  local tx_id
  tx_id=$($bitcoin_cli sendrawtransaction "$raw_tx")
  
  if [[ -n "$tx_id" ]]; then
    log "Transaction sent successfully: $tx_id"
    return 0
  else
    error "Failed to send transaction from $tx_file"
  fi
}

################################################################################
#                              INPUT VALIDATION                                  #
################################################################################

# Parse command line arguments
run_mode=$LIVE_RUN
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--dry-run)
      run_mode=$DRY_RUN
      shift
      ;;
    *)
      tx_directory=$1
      shift
      ;;
  esac
done

# Validate tx_directory was provided
[[ -z "${tx_directory-}" ]] && print_usage

# Validate directory exists
[[ ! -d "$tx_directory" ]] && error "Directory does not exist: $tx_directory"

# Set bitcoin-cli command
bitcoin_cli=${BITCOIN_CLI_CMD_DEMO:-$DEFAULT_BITCOIN_CLI}

# Validate bitcoin-cli command exists
if [[ $run_mode -eq $LIVE_RUN ]]; then
  command -v "$bitcoin_cli" >/dev/null 2>&1 || error "Bitcoin CLI command not found: $bitcoin_cli"
fi

################################################################################
#                              INITIALIZATION                                    #
################################################################################

log "Starting transaction sending process"
[[ $run_mode -eq $DRY_RUN ]] && log "Running in DRY RUN mode - No transactions will be sent"
log "Using directory: $tx_directory"
log "Using bitcoin-cli command: $bitcoin_cli"

total_txs=$((LAST_TX - FIRST_TX + 1))
processed_txs=0

################################################################################
#                              MAIN PROCESSING                                   #
################################################################################

for ((i=FIRST_TX; i<=LAST_TX; i++)); do
  tx_file="$tx_directory/tx-$i.txt"

  # Validate transaction file exists
  if [[ ! -f "$tx_file" ]]; then
    error "Transaction file not found: $tx_file"
  fi

  send_transaction "$tx_file" "$i" "$total_txs" "$bitcoin_cli" "$run_mode"
  processed_txs=$((processed_txs + 1))

  progress=$((processed_txs * 100 / total_txs))
  log "Progress: $progress% ($processed_txs/$total_txs transactions processed)"

  # Sleep for 1 second
  sleep 1
done

################################################################################
#                                 OUTPUT                                         #
################################################################################

log "Completed!"
echo "----------------------------------------"
echo "SUMMARY"
echo "----------------------------------------"
echo "Total transactions processed: $processed_txs"
[[ $run_mode -eq $DRY_RUN ]] && echo "Mode: DRY RUN (no transactions were actually sent)"
echo "----------------------------------------"
