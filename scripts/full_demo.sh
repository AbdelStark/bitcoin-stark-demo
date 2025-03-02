#!/bin/bash

set -euo pipefail

################################################################################
#                                  CONSTANTS                                     #
################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly DEFAULT_TRANSCRIPT_FILE="demo_transcript.log"
readonly DEFAULT_PARAMS_FILE="demo_params.env"
readonly DEFAULT_RANDOMIZER=42

################################################################################
#                                  FUNCTIONS                                     #
################################################################################

print_usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Run the complete Bitcoin Circle Stark demo end-to-end"
  echo
  echo "Options:"
  echo "  -b, --break           Add breakpoints between steps"
  echo "  -t, --transcript      Transcript output file (default: $DEFAULT_TRANSCRIPT_FILE)"
  echo "  -p, --params          Parameters output file (default: $DEFAULT_PARAMS_FILE)"
  echo "  -r, --randomizer      Randomizer value (default: $DEFAULT_RANDOMIZER)"
  echo "  -h, --help           Show this help message"
}

log() {
  local msg=$1
  local timestamp
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $msg" | tee -a "$transcript_file"
}

error() {
  log "ERROR: $1" >&2
  exit 1
}

print_section() {
  local title=$1
  local line="=================================================================="
  echo | tee -a "$transcript_file"
  echo "$line" | tee -a "$transcript_file"
  echo "                         $title" | tee -a "$transcript_file"
  echo "$line" | tee -a "$transcript_file"
  echo | tee -a "$transcript_file"
}

wait_for_user() {
  if [[ $use_breakpoints == true ]]; then
    read -r -p "Press Enter to continue..."
  fi
}

run_command() {
  local cmd=$1
  local description=$2
  
  log "Running: $description"
  log "Command: $cmd"
  
  if ! eval "$cmd" >> "$transcript_file" 2>&1; then
    error "Failed to execute: $description"
  fi
  
  log "Successfully completed: $description"
}

save_param() {
  local param_name=$1
  local param_value=$2
  local output_file=$3
  
  echo "export ${param_name}=\"${param_value}\"" >> "$output_file"
  log "Saved $param_name=$param_value"
}

################################################################################
#                              PARSE ARGUMENTS                                   #
################################################################################

use_breakpoints=false
transcript_file="$DEFAULT_TRANSCRIPT_FILE"
params_file="$DEFAULT_PARAMS_FILE"
randomizer=$DEFAULT_RANDOMIZER

while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--break)
      use_breakpoints=true
      shift
      ;;
    -t|--transcript)
      transcript_file=$2
      shift 2
      ;;
    -p|--params)
      params_file=$2
      shift 2
      ;;
    -r|--randomizer)
      randomizer=$2
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      print_usage
      error "Unknown option: $1"
      ;;
  esac
done

################################################################################
#                              INITIALIZATION                                    #
################################################################################

cd "$WORKSPACE_DIR"

# Initialize transcript file
> "$transcript_file"
log "Starting Bitcoin Circle Stark Demo"
log "Transcript will be saved to: $transcript_file"
log "Parameters will be saved to: $params_file"
log "Using randomizer value: $randomizer"

################################################################################
#                         STEP 1: GENERATE DEMO PARAMS                          #
################################################################################

print_section "GENERATING DEMO PARAMETERS"

# Initialize params file
> "$params_file"
save_param "RANDOMIZER" "$randomizer" "$params_file"

# Get program and caboose addresses
log "Getting program and caboose addresses..."
demo_params_json=$(gen_demo_params --randomizer "$randomizer")
if [[ -z "$demo_params_json" ]]; then
  error "Failed to get demo parameters"
fi

# Extract addresses from JSON
program_address=$(echo "$demo_params_json" | jq -r '.program_address')
caboose_address=$(echo "$demo_params_json" | jq -r '.caboose_address')

if [[ -z "$program_address" ]] || [[ -z "$caboose_address" ]]; then
  error "Failed to extract addresses from demo parameters"
fi

# Save addresses to params file
save_param "PROGRAM_ADDRESS" "$program_address" "$params_file"
save_param "STATE_CABOOSE_ADDRESS" "$caboose_address" "$params_file"

wait_for_user

################################################################################
#                         STEP 2: SETUP INITIAL STATE                           #
################################################################################

print_section "SETTING UP INITIAL STATE"

run_command "./scripts/setup_demo.sh -o $params_file" "Setting up initial transactions"
wait_for_user

# Source the parameters as setup_demo.sh adds more variables
source "$params_file"

if [[ -z "${FUNDING_TXID:-}" ]] || [[ -z "${INITIAL_PROGRAM_TXID:-}" ]]; then
  error "Required transaction IDs not found in $params_file"
fi

################################################################################
#                         STEP 3: RUN MAIN DEMO                                 #
################################################################################

print_section "RUNNING MAIN DEMO"

run_command "demo -f $FUNDING_TXID -i $INITIAL_PROGRAM_TXID --randomizer $randomizer --funding-tx-vout $FUNDING_VOUT" "Running main demo binary"
wait_for_user

################################################################################
#                         STEP 4: SEND DEMO TRANSACTIONS                        #
################################################################################

print_section "SENDING DEMO TRANSACTIONS"

if [[ ! -d "./demo" ]]; then
  error "Demo transaction directory not found"
fi

run_command "./scripts/send_demo_txs.sh ./demo" "Sending demo transactions"

################################################################################
#                                 SUMMARY                                        #
################################################################################

print_section "DEMO COMPLETED"

log "Demo completed successfully"
log "Full transcript saved to: $transcript_file"
log "Parameters saved to: $params_file"
