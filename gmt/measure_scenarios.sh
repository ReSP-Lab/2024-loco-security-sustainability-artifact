#!/bin/bash

# Check if the user provided the required arguments
if [ "$#" -ne 3 ]; then
	echo "Usage: $0 <number of test iteration > <path_to_2024_loco_security_sustainability_artifact> <path_to_green_metric_tool>"
	exit 1
fi

SIMULATOR_PATH="$2"
GMT_PATH="$3"

# Change to the green_metric_tool directory
cd "$GMT_PATH" || { echo "Failed to change directory to $GMT_PATH"; exit 1; }

# Activate the GMT virtual environment
source venv/bin/activate

# Run measurements
for i in $(seq 1 $1)
do
	# Loop through each .json file in the scenarios directory
	for filepath in "$SIMULATOR_PATH/scenarios_2025"/*.json
	do
		# Extract the filename from the path
		filename=$(basename "$filepath")

		# Replace the line in the entrypoint.sh file: we want the scenario.py to be run with the scenario.json in this loop
		sed -i "s|^\([[:space:]]*\)command: python src/scenario.py.*|\1command: python src/scenario.py scenarios_2025/$filename|" "$SIMULATOR_PATH/entrypoint.sh"

		# Launch the green metric tool
		python3 runner.py --uri "$SIMULATOR_PATH" --name "$filename" --allow-unsafe --print-logs
	done
done
