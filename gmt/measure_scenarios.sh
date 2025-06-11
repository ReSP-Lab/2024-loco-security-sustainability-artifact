#!/bin/bash

# Check if the user provided the required arguments
if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <path_to_2024_loco_security_sustainability_artifact> <path_to_green_metric_tool>"
	exit 1
fi

SIMULATOR_PATH="$1"
GMT_PATH="$2"

# Change to the green_metric_tool directory
cd "$GMT_PATH" || { echo "Failed to change directory to $GMT_PATH"; exit 1; }

# Activate the GMT virtual environment
source venv/bin/activate

# Run 1 measurement
for i in {1..1}
do
	# Loop through each .json file in the scenarios directory
	for filepath in "$SIMULATOR_PATH/scenarios_2025"/*.json
	do
		# Extract the filename from the path
		filename=$(basename "$filepath")

		# Replace the line in the usage_scenario.yml file: we want the scenario.py to be run with the scenario.json in this loop
		sed -i "s|^\([[:space:]]*\)command: python src/scenario.py.*|\1command: python src/scenario.py scenarios_2025/$filename|" "$SIMULATOR_PATH/usage_scenario.yml"

		python3 runner.py --uri "$SIMULATOR_PATH" --name "$filename" --allow-unsafe --print-logs
	done
done
