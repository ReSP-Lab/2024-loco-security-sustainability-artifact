#!/bin/bash

# Run the Python script (-u option to unbuffer the output)
echo "Running the automation tool..."
python -u src/scenario.py scenarios_2025/2025_mysolution_session_noadblock_pgp_remote50.json
#python -u src/topnews.py noadblock