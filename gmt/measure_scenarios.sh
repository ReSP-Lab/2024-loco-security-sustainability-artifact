#!/bin/bash

# Check if the user provided the required arguments
if [ "$#" -ne 3 ]; then
	echo "Usage: $0 <number_of_iterations> <absolute_path_to_2024_loco_security_sustainability_artifact> <absolute_path_to_green_metric_tool>"
	exit 1
fi

REPO_PATH="${2%/}"
GMT_PATH="${3%/}"

# Change to the green_metric_tool directory
cd "$GMT_PATH" || { echo "Failed to change directory to $GMT_PATH"; exit 1; }

# Activate the GMT virtual environment
source venv/bin/activate

# Run measurements
for i in $(seq 1 $1)
do
	# Loop through each .json file in the scenarios directory
	for filepath in "$REPO_PATH/simulator/scenarios_2025"/*.json
	do
		# Extract the filename from the path
		filename=$(basename "$filepath")
		echo $filename
		# Replace the line in the entrypoint.sh file: we want the scenario.py to be run with the scenario.json in this loop
		sed -i "s|^\([[:space:]]*\)python -u src/scenario.py.*|\1python -u src/scenario.py scenarios_2025/$filename|" "$REPO_PATH/simulator/entrypoint.sh"
		# Launch the green metric tool
		python3 runner.py --uri "$REPO_PATH/simulator" --name "$filename" --allow-unsafe --print-logs
	done
done
