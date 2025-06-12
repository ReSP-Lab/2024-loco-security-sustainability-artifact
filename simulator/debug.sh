#! /bin/bash

# Function to clean up on exit
cleanup() {
	docker compose down
	exit 0
}

# Trap SIGINT (Ctrl+C) and call the cleanup function
trap cleanup SIGINT

# Run 5 measurements
for i in {1..1}
do
	# Loop through each .json file in the scenarios directory
	for filepath in $(dirname "$0")/scenarios_2025/*.json
	do
		# Extract the filename from the path
		filename=$(basename "$filepath")

		# Replace the line in the entrypoint.sh file: we want the scenario.py to be run with the scenario.json in this loop
		sed -i "s/^\([[:space:]]*\)python -u src\/scenario.py.*/\1python -u src\/scenario.py scenarios_2025\/$filename/" "$(dirname "$0")/entrypoint.sh"
		
		# Script to launch the containers and open the window immediately
		xtigervncviewer localhost::5900 &
		docker compose up
		docker compose down
	done
done
