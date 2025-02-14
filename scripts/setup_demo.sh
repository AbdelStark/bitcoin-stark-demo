#!/bin/bash

set -euo pipefail

if [[ -f .env ]]; then
  source .env
fi

################################################################################
#                                  CONSTANTS                                     #
################################################################################

readonly DEFAULT_BITCOIN_CLI="eval bitcoin-cli"
readonly DEFAULT_FUNDING_AMOUNT="13.4356"
readonly DEFAULT_OUTPUT_FILE="demo_params.env"

# Amount calculations (in BTC)
readonly PROGRAM_AMOUNT="13.42959670"
readonly STATE_CABOOSE_AMOUNT="0.0000033"

################################################################################
#                                  FUNCTIONS                                     #
################################################################################

print_usage() {
  echo "Usage: $0 [-a|--amount <btc_amount>] [-o|--output <output_file>]"
  echo
  echo "Setup initial transactions for the demo"
  echo
  echo "Options:"
  echo "  -a, --amount        Amount of BTC to fund (default: $DEFAULT_FUNDING_AMOUNT)"
  echo "  -o, --output        Output file for parameters (default: $DEFAULT_OUTPUT_FILE)"
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

print_section() {
  echo
  echo "=================================================================================="
  echo "                               $1"
  echo "=================================================================================="
  echo
}

save_param() {
  local param_name=$1
  local param_value=$2
  local output_file=$3
  
  # Save to file
  echo "export ${param_name}=\"${param_value}\"" >> "$output_file"
  
  # Also display in terminal
  log "Saved $param_name=$param_value"
}

################################################################################
#                              INPUT VALIDATION                                  #
################################################################################

# Parse command line arguments
funding_amount=$DEFAULT_FUNDING_AMOUNT
output_file=$DEFAULT_OUTPUT_FILE

while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--amount)
      funding_amount=$2
      shift 2
      ;;
    -o|--output)
      output_file=$2
      shift 2
      ;;
    *)
      print_usage
      ;;
  esac
done

# Validate amount is a valid number
if ! [[ $funding_amount =~ ^[0-9]+\.?[0-9]*$ ]]; then
  error "Invalid amount: $funding_amount"
fi

# Set bitcoin-cli command
bitcoin_cli=${BITCOIN_CLI_CMD_DEMO:-$DEFAULT_BITCOIN_CLI}

################################################################################
#                              INITIALIZATION                                    #
################################################################################

print_section "INITIALIZATION"

log "Starting demo setup process"
log "Using bitcoin-cli command: $bitcoin_cli"
log "Funding amount: $funding_amount BTC"
log "Output file: $output_file"

# Load existing parameters
if [[ ! -f "$output_file" ]]; then
  error "Parameters file not found: $output_file"
fi

source "$output_file"

if [[ -z "${PROGRAM_ADDRESS:-}" ]] || [[ -z "${STATE_CABOOSE_ADDRESS:-}" ]]; then
  error "Required addresses not found in $output_file"
fi

# Save amounts to params file
save_param "PROGRAM_AMOUNT" "$PROGRAM_AMOUNT" "$output_file"
save_param "STATE_CABOOSE_AMOUNT" "$STATE_CABOOSE_AMOUNT" "$output_file"

################################################################################
#                           CREATE FUNDING TRANSACTION                           #
################################################################################

print_section "CREATING FUNDING TRANSACTION"

log "Generating new address for funding..."
funding_address=$(eval "$bitcoin_cli getnewaddress")
log "Generated address: $funding_address"
save_param "FUNDING_ADDRESS" "$funding_address" "$output_file"

log "Creating funding transaction..."
funding_txid=$(eval "$bitcoin_cli sendtoaddress \"$funding_address\" $funding_amount")
if [[ -z "$funding_txid" ]]; then
  error "Failed to create funding transaction"
fi
log "Funding transaction created: $funding_txid"
save_param "FUNDING_TXID" "$funding_txid" "$output_file"

# Add confirmation check
log "Waiting for funding transaction confirmation..."
sleep 3
log "Funding transaction confirmed"

# Get transaction details to find the vout
log "Getting transaction details..."
tx_details=$(eval "$bitcoin_cli gettransaction \"$funding_txid\"")
funding_vout=$(echo "$tx_details" | jq -r '.details[] | select(.category == "receive") | .vout')
if [[ -z "$funding_vout" ]]; then
  error "Failed to get funding vout"
fi
log "Funding vout: $funding_vout"
save_param "FUNDING_VOUT" "$funding_vout" "$output_file"

################################################################################
#                         CREATE PROGRAM TRANSACTION                             #
################################################################################

print_section "CREATING PROGRAM TRANSACTION"

log "Creating raw transaction..."
raw_tx=$(eval "$bitcoin_cli createrawtransaction \"[{\\\"txid\\\":\\\"$funding_txid\\\", \\\"vout\\\": $funding_vout}]\" \"[{\\\"$PROGRAM_ADDRESS\\\":$PROGRAM_AMOUNT}, {\\\"$STATE_CABOOSE_ADDRESS\\\":$STATE_CABOOSE_AMOUNT}]\"")
if [[ -z "$raw_tx" ]]; then
  error "Failed to create raw transaction"
fi
log "Raw transaction created"

log "Signing transaction..."
signed_tx=$(eval "$bitcoin_cli signrawtransactionwithwallet \"$raw_tx\"")
if [[ -z "$signed_tx" ]]; then
  error "Failed to sign transaction"
fi

signed_hex=$(echo "$signed_tx" | jq -r '.hex')
if [[ -z "$signed_hex" ]]; then
  error "Failed to get signed transaction hex"
fi
log "Transaction signed successfully"

log "Sending transaction to network..."
program_txid=$(eval "$bitcoin_cli sendrawtransaction \"$signed_hex\"")
if [[ -z "$program_txid" ]]; then
  error "Failed to send transaction"
fi
log "Program transaction sent: $program_txid"
# Add confirmation check
log "Waiting for program transaction confirmation..."
sleep 3
log "Program transaction confirmed"
save_param "INITIAL_PROGRAM_TXID" "$program_txid" "$output_file"

################################################################################
#                                  SUMMARY                                       #
################################################################################

print_section "SETUP COMPLETE"

echo "Parameters saved to: $output_file"
echo
echo "Key Parameters:"
echo "----------------------------------------"
echo "Funding Transaction: $funding_txid"
echo "Program Transaction: $program_txid"
echo "Program Address: $PROGRAM_ADDRESS"
echo "State Caboose Address: $STATE_CABOOSE_ADDRESS"
echo "----------------------------------------"
echo
log "Setup completed successfully"
echo
echo "You can now proceed with generating the demo transactions using:"
echo "cargo run --bin demo -- -f $funding_txid -i $program_txid --randomizer $RANDOMIZER" 
echo "or"
echo "demo -f $funding_txid -i $program_txid --randomizer $RANDOMIZER"
echo "if you have the demo binary in your PATH"