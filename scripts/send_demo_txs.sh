#!/bin/bash

set -euo pipefail

if [[ -f .env ]]; then
  source .env
fi

################################################################################
#                                  CONSTANTS                                     #
################################################################################

readonly FIRST_TX=1
readonly LAST_TX=72
readonly DEFAULT_BITCOIN_CLI="eval bitcoin-cli"
readonly DRY_RUN=0
readonly LIVE_RUN=1

# Transaction flow strategies
readonly STRATEGY_SEQUENTIAL="sequential"        # Send all transactions sequentially without waiting
readonly STRATEGY_TIMED="timed"                 # Send transactions with configurable pause between each
readonly STRATEGY_PER_BLOCK="per-block"         # Send configurable number of transactions per block

# Default strategy parameters
readonly DEFAULT_STRATEGY=$STRATEGY_SEQUENTIAL
readonly DEFAULT_PAUSE_SECONDS=1
readonly DEFAULT_TXS_PER_BLOCK=1
readonly DEFAULT_CONFIRMATION_CHECK_INTERVAL=10  # Seconds between confirmation checks
readonly DEFAULT_MAX_CONFIRMATION_WAIT=3600     # Maximum seconds to wait for confirmation

################################################################################
#                                  FUNCTIONS                                     #
################################################################################

print_usage() {
  echo "Usage: $0 [-d|--dry-run] [-s|--strategy <strategy>] [-p|--pause <seconds>] [-n|--num-per-block <number>] <tx_directory>"
  echo
  echo "Send transactions sequentially from a directory containing raw transaction files"
  echo
  echo "Arguments:"
  echo "  tx_directory    Directory containing transaction files (tx-1.txt to tx-72.txt)"
  echo
  echo "Options:"
  echo "  -d, --dry-run         Simulate sending transactions without actually sending them"
  echo "  -s, --strategy        Transaction flow strategy (default: $DEFAULT_STRATEGY)"
  echo "                          - $STRATEGY_SEQUENTIAL: Send all transactions sequentially without waiting"
  echo "                          - $STRATEGY_TIMED: Send transactions with configurable pause between each"
  echo "                          - $STRATEGY_PER_BLOCK: Send configurable number of transactions per block"
  echo "  -p, --pause           Pause duration in seconds for timed strategy (default: $DEFAULT_PAUSE_SECONDS)"
  echo "  -n, --num-per-block   Number of transactions per block for per-block strategy (default: $DEFAULT_TXS_PER_BLOCK)"
  echo
  echo "Environment variables:"
  echo "  BITCOIN_CLI_CMD_DEMO    Override default bitcoin-cli command ($DEFAULT_BITCOIN_CLI)"
  echo "  TX_FLOW_STRATEGY        Override default transaction flow strategy"
  echo "  TX_PAUSE_SECONDS        Override default pause duration for timed strategy"
  echo "  TX_PER_BLOCK            Override default number of transactions per block"
  exit 1
}

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
  exit 1
}

is_transaction_confirmed() {
  local tx_id=$1
  local bitcoin_cli=$2
  
  # Get transaction info
  local confirmations
  confirmations=$(eval "$bitcoin_cli getrawtransaction $tx_id 1 2>/dev/null | jq -r '.confirmations // 0'")
  
  # Check if we got a valid number
  if [[ "$confirmations" =~ ^[0-9]+$ ]]; then
    [[ $confirmations -gt 0 ]] && return 0
  fi
  return 1
}

wait_for_transaction_confirmation() {
  local tx_id=$1
  local bitcoin_cli=$2
  local start_time
  start_time=$(date +%s)
  
  while true; do
    # Check if we've exceeded maximum wait time
    local current_time
    current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    
    if [[ $elapsed -gt $DEFAULT_MAX_CONFIRMATION_WAIT ]]; then
      error "Timeout waiting for transaction $tx_id to be confirmed"
    fi
    
    # Check if transaction is confirmed
    if is_transaction_confirmed "$tx_id" "$bitcoin_cli"; then
      log "Transaction $tx_id confirmed after ${elapsed}s"
      return 0
    fi
    
    # Wait before next check
    sleep "$DEFAULT_CONFIRMATION_CHECK_INTERVAL"
  done
}

validate_strategy() {
  local strategy=$1
  case $strategy in
    $STRATEGY_SEQUENTIAL|$STRATEGY_TIMED|$STRATEGY_PER_BLOCK)
      return 0
      ;;
    *)
      error "Invalid strategy: $strategy. Valid options are: $STRATEGY_SEQUENTIAL, $STRATEGY_TIMED, $STRATEGY_PER_BLOCK"
      ;;
  esac
}

handle_transaction_flow() {
  local strategy=$1
  local tx_num=$2
  local pause_seconds=$3
  local txs_per_block=$4
  local last_tx_id=$5
  local bitcoin_cli=$6
  local run_mode=$7

  case $strategy in
    $STRATEGY_SEQUENTIAL)
      # No waiting needed
      return 0
      ;;
    $STRATEGY_TIMED)
      log "Pausing for $pause_seconds seconds before next transaction..."
      sleep "$pause_seconds"
      ;;
    $STRATEGY_PER_BLOCK)
      # If we've sent txs_per_block transactions, wait for confirmation
      if ((tx_num % txs_per_block == 0)); then
        if [[ $run_mode -eq $DRY_RUN ]]; then
          log "[DRY RUN] Would wait for transaction confirmation: $last_tx_id"
          return 0
        fi
        
        log "Reached $txs_per_block transactions, waiting for confirmation of tx: $last_tx_id"
        wait_for_transaction_confirmation "$last_tx_id" "$bitcoin_cli"
        log "Batch confirmed, proceeding with next transactions"
      fi
      ;;
  esac
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
    echo "tx_$(printf "%03d" "$tx_num")_simulated_hash"
    return 0
  fi
  
  local tx_id
  tx_id=$(eval "$bitcoin_cli sendrawtransaction \"$raw_tx\"")
  
  if [[ -n "$tx_id" ]]; then
    log "Transaction sent successfully: $tx_id"
    echo "$tx_id"
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
strategy=${TX_FLOW_STRATEGY:-$DEFAULT_STRATEGY}
pause_seconds=${TX_PAUSE_SECONDS:-$DEFAULT_PAUSE_SECONDS}
txs_per_block=${TX_PER_BLOCK:-$DEFAULT_TXS_PER_BLOCK}

while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--dry-run)
      run_mode=$DRY_RUN
      shift
      ;;
    -s|--strategy)
      strategy=$2
      shift 2
      ;;
    -p|--pause)
      pause_seconds=$2
      shift 2
      ;;
    -n|--num-per-block)
      txs_per_block=$2
      shift 2
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

# Validate strategy and parameters
validate_strategy "$strategy"
[[ ! $pause_seconds =~ ^[0-9]+$ ]] && error "Pause duration must be a positive integer"
[[ ! $txs_per_block =~ ^[0-9]+$ ]] && error "Transactions per block must be a positive integer"
[[ $txs_per_block -lt 1 ]] && error "Transactions per block must be at least 1"

# Set bitcoin-cli command
bitcoin_cli=${BITCOIN_CLI_CMD_DEMO:-$DEFAULT_BITCOIN_CLI}

################################################################################
#                              INITIALIZATION                                    #
################################################################################

log "Starting transaction sending process"
[[ $run_mode -eq $DRY_RUN ]] && log "Running in DRY RUN mode - No transactions will be sent"
log "Using directory: $tx_directory"
log "Using bitcoin-cli command: $bitcoin_cli"
log "Transaction flow strategy: $strategy"
case $strategy in
  $STRATEGY_TIMED)
    log "Pause between transactions: $pause_seconds seconds"
    ;;
  $STRATEGY_PER_BLOCK)
    log "Transactions per block: $txs_per_block"
    ;;
esac

total_txs=$((LAST_TX - FIRST_TX + 1))
processed_txs=0
last_tx_id=""

################################################################################
#                              MAIN PROCESSING                                   #
################################################################################

for ((i=FIRST_TX; i<=LAST_TX; i++)); do
  tx_file="$tx_directory/tx-$i.txt"

  # Validate transaction file exists
  if [[ ! -f "$tx_file" ]]; then
    error "Transaction file not found: $tx_file"
  fi

  last_tx_id=$(send_transaction "$tx_file" "$i" "$total_txs" "$bitcoin_cli" "$run_mode")
  processed_txs=$((processed_txs + 1))

  progress=$((processed_txs * 100 / total_txs))
  log "Progress: $progress% ($processed_txs/$total_txs transactions processed)"

  # Handle transaction flow based on strategy
  if [[ $i -lt $LAST_TX ]]; then  # Don't wait after the last transaction
    handle_transaction_flow "$strategy" "$processed_txs" "$pause_seconds" "$txs_per_block" "$last_tx_id" "$bitcoin_cli" "$run_mode"
  fi
done

################################################################################
#                                 OUTPUT                                         #
################################################################################

log "Completed!"
echo "----------------------------------------"
echo "SUMMARY"
echo "----------------------------------------"
echo "Total transactions processed: $processed_txs"
echo "Strategy used: $strategy"
case $strategy in
  $STRATEGY_TIMED)
    echo "Pause between transactions: $pause_seconds seconds"
    ;;
  $STRATEGY_PER_BLOCK)
    echo "Transactions per block: $txs_per_block"
    ;;
esac
[[ $run_mode -eq $DRY_RUN ]] && echo "Mode: DRY RUN (no transactions were actually sent)"
echo "----------------------------------------"