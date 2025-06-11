# 2024-loco-security-sustainability-artifact

This repository contains the workspace for an empirical study on the environmental impact of advertisements in webmail solutions. The study compares the energy and traffic profile of executing functional units (such as sending or reading an email) on mainstream providers—Outlook, Gmail, and Proton Mail—with and without a network adblocker enabled. Additionally, we investigate the impact of PGP encryption by implementing a self-hosted solution called **my_email_solution**.

The entire project is designed and tested for Intel x86_64/amd64 architectures. **Docker** is required to run the self-hosted solution. You can find Docker installation instructions [here](https://docs.docker.com/get-docker/).

---

## Self-Hosted Solution: Installation Guide

### 1. Clone the Repository

```sh
git clone https://github.com/your-username/2024-loco-security-sustainability-artifact.git
cd 2024-loco-security-sustainability-artifact
```

### 2. Generate Certificates

Make the certificate generation script executable and run it:

```sh
chmod +x my_email_solution/utils/generate_cert.sh
my_email_solution/utils/generate_cert.sh
```

This script creates certificates for the different components of the solution (mailserver and webmail), both signed by a self-signed CA.

### 3. Start the Services

Navigate to the `my_email_solution` directory and start the services with Docker Compose:

```sh
cd my_email_solution
docker compose up
```

### 4. Create Email Addresses

Once the containers are running, you need to create email accounts:

1. Enter the mailserver container:

    ```sh
    docker exec -it mailserver bash
    ```

2. Inside the container, create email addresses (replace `xxx@my-solution.com` with your desired addresses; use the domain `my-solution.com`):

    ```sh
    setup email add user1@my-solution.com
    setup email add user2@my-solution.com
    ```

   Set a password for each address when prompted.

> **Note:** You need at least two addresses to exchange emails. This setup is experimental and mimics real-life scenarios, but since you do not own the domain, sending emails to external domains will not work.

### 5. Test Access To the Webmail Interface

Open your browser and navigate to [https://localhost](https://localhost). You can now log in with the email addresses and passwords you created.

---

## Automation Tool (`simulator`) Overview

The `simulator` folder contains an automation tool for running and measuring email scenarios on various webmail providers. It is designed to be run in a Docker container and orchestrated for reproducible, automated experiments.

### Folder Structure

#### 1. Folders Included in the Simulator Docker Image (for transparency)

If you want to modify any of these files (e.g., to change the Chrome profiles, add attachments, or update extensions), you can do so and then mount the modified folder into the container using Docker Compose or the `usage_scenario.yaml` (if using the Green Metric Tool). For example, to use a custom Chrome profile, mount it as `./chrome_profiles:/app/chrome_profiles`.

- **attached_files/**: Dummy files used as attachments in emails.
- **chrome_profiles/**: Chromium browser profiles for testing.
  - *untracked profile*: All privacy settings enabled.
  - *tracked profile*: All privacy protections disabled.
  - Both profiles include a configured Mailvelope extension with public keys (password: `Azerty123`) for `jason.kayembe@my-solution.com` and `marie.hupin@my-solution.com`. To test PGP's impact on the self-hosted solution, create and use these addresses on the mailserver.
- **mailvelope/**: The Mailvelope PGP extension for Chromium.
- **ublock/**: The uBlock adblock extension for Chromium.
- **requirements.txt**: Python dependencies (notably `selenium`).

#### 2. Folders Mounted in the Container at Runtime

- **emails_answers/**: Contains CSV files with emails and answers for users. For an address `x.y@domain`, you must have `x_y_emails.csv` and `x_y_answers.csv` (same structure as existing files). To use a new address, copy and rename an existing user's files.
- **src/**: Python scripts implementing the automation logic (using Selenium).
  - To automate a new provider "A", create `ASession.py` (following the pattern of `OutlookSession.py`).
  - To use your new session:
    - Import it in `src/scenario.py`.
    - Add a case in `Scenario.get_session()` to instantiate your session class when the provider matches.
    - Ensure any provider-specific constants/selectors are defined (especially in `src/constants.py`).
- **scenarios_2025/**: JSON files describing scenarios (functional units and account parameters).
  - Example parameters:
    - **USER**: The name of the user (e.g., "Jason Kayembe").
    - **USER_PASSWORD**: The password for the user.
    - **DOMAIN**: The domain of the address to be used (e.g., `@my-solution.com`).
    - **CONTACTS**: List of contacts (email addresses) the user can send mail to and read/respond mail from. **Note:** To respond to a contact, a corresponding `emails_answers/name_surname_answers.csv` must exist.
    - **PROVIDER**: The name of the provider (e.g., `'outlook'`, `'gmail'`, `'proton'`, `'my_solution'`).
    - **BROWSER**: The browser to use (currently only `'chrome'` is supported by default; to use another browser, it must be installed in the simulator container and a corresponding case must be added in `src/sessions.py`).
    - **ADBLOCK**: `'true'` or `'false'` to specify whether to use an adblocker extension within the container.
    - **UNTRACKED**: `'true'` or `'false'` to specify whether to use a privacy-focused browser profile.
    - **PGP**: `'true'` or `'false'` to specify whether to use PGP encryption (only relevant for the self-hosted solution).
    - **TIME_LIMIT**: The time limit (in minutes) for the scenario (limits the total duration of the scenario).
    - **N_SESSION**: Number of repeated sessions to run.
    - **N_MAIL_SENT**: A dictionary specifying how many emails to send with each attachment size (e.g., `{ "0": 1, "5": 1, ... }` means send 1 email with no attachment, 1 with 5MB, etc.).
    - **N_MAIL_READ_AND_ANSWER**: Number of emails to read and answer.
    - **N_MAIL_READ_AND_DELETE**: Number of emails to read and delete.
  - The tool uses these parameters to generate and execute the test actions.

#### 3. Utility Files

- **Dockerfile**: Builds the `jkayembe/simulator` image (Python, Selenium, Chromium 132.0.6834.110).
- **entrypoint.sh**: Entrypoint script for the container.

  - Starts Xvfb (virtual display) and x11vnc (VNC server).
  - Detects the Docker gateway IP and adds it to `/etc/hosts` as `my-solution.com` (for accessing the self-hosted mail solution).
  - Sets the DNS to the gateway IP (enables PiHole adblocker testing). **This needs to be removed if no DNS service is running on the host**.
  - Runs the Python automation script.
- **debug.sh**: Script to run the automation for every scenario in `scenarios_2025/`.
  - For debugging: launches Xvfb and x11vnc so you can view the automated browser via VNC.
  - Tested with `tigervnc`, but any VNC client will work (connect to `localhost:5900`). Adjust the `xtigervncviewer localhost::5900 &` line as needed.
- **compose.yaml**: Docker Compose file for easy container launch.
- **usage_scenario.yml**: Used by the Green Metric Tool (GMT) to orchestrate the container and monitor energy/traffic, similar to a Compose file.

...
## Running the Automation Tool

To run the automation tool using the scenarios defined in [`scenarios_2025`](simulator/scenarios_2025):

- **Option 1:** Use Docker Compose  
  Make sure that [`entrypoint.sh`](simulator/entrypoint.sh) specifies the correct scenario file, for example:
  ```bash
  python -u src/scenario.py scenarios_2025/<your_scenario>.json
  ```
  Then, from inside the `simulator/` directory, run:
  ```sh
  docker compose up
  ```

- **Option 2:** Run all scenarios for debugging  
  Make the debug script executable and run it:
  ```sh
  chmod +x debug.sh
  ./debug.sh
  ```
  This will sequentially run the tool on every scenario JSON file in [`scenarios_2025`](simulator/scenarios_2025).

For further details, refer to the comments and documentation within the scripts.

---

## Monitoring Automated Scenarios with the Green Metric Tool (GMT)

To monitor the automated scenarios and measure their environmental impact, we use the [Green Metric Tool (GMT)](https://docs.green-coding.io/docs/installation/installation-linux/). Follow the steps below to set up and use GMT for monitoring:

### 1. Install the Green Metric Tool
Follow the [official installation guide](https://docs.green-coding.io/docs/installation/installation-linux/) to install GMT on your system. Ensure that all dependencies are installed and the tool is properly configured.

### 2. Configure Metric Providers
To enable monitoring, you need to activate the metric providers in the `config.yaml` file located in the GMT folder. Uncomment the relevant sections in the file to enable the desired metrics.

We provide an example configuration file, [`config.yaml.example`](gmt/config.yaml.example), that we used for our experiments. You can use it as a reference to configure your `config.yaml`.

### 3. Start the GMT Container
Once GMT is installed and configured, start the GMT container using Docker Compose. Refer to the [GMT documentation](https://docs.green-coding.io/docs/installation/installation-linux/) for detailed instructions.

### 4. Run the Automation Tool with GMT Monitoring
We provide a script, [`measure_scenarios.sh`](GMT/measure_scenarios.sh), to automate the process of running the scenarios and monitoring them with GMT. Follow these steps:

1. Make the script executable:
   ```bash
   chmod +x GMT/measure_scenarios.sh
   ```

2. Run the script with the required arguments:
   ```bash
   ./measure_scenarios.sh <path_to_2024_loco_security_sustainability_artifact> <path_to_green_metric_tool>
   ```

   - `<path_to_2024_loco_security_sustainability_artifact>`: The path to this repository.
   - `<path_to_green_metric_tool>`: The path to the installed GMT directory.

This script will:
- Loop through all `.json` scenario files in the `scenarios_2025` directory.
- Update the `usage_scenario.yml` file to run each scenario.
- Launch the GMT monitoring tool and execute the scenarios.

### Example Usage
```bash
./measure_scenarios.sh /home/jason/2024-loco-security-sustainability-artifact /home/jason/green-metric-tool
```

This will monitor the automated scenarios and save the results in GMT database.

For further details, refer to the GMT documentation and the provided example files in this repository.

---

## Data Preprocessing and Analysis

We provide the notebooks used to preprocess and analyze the data collected for this study. These notebooks are located in the `notebook` folder of this repository. They include all the steps required to clean, transform, and analyze the raw data collected during the experiments.

### Preprocessed Data
The preprocessed data is also included in the repository for convenience:
- [`2025_data.csv`](notebook/2025_data.csv): Contains the preprocessed data for the scenarios executed during the study.
- [`2025_topnews_data.csv`](notebook/2025_topnews_data.csv): Contains the preprocessed data for the top news experiments.

### Usage
1. Navigate to the `notebook` folder:
  ```sh
  cd notebook
  ```

2. Create a Python virtual environment and install the required dependencies:
  ```sh
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  ```
3. Open the provided Jupyter notebooks:

    - [`analysis_notebook.ipynb`](notebook/analysis_notebook.ipynb): Main notebook for analysing the collected data.
    - [`topnews_analysis.ipynb`](notebook/topnews_analysis.ipynb): Notebook for analysing `adblocking effect on mainstream websites` experiment.

    To open a notebook, run:
    ```sh
    jupyter notebook
    ```

These notebooks provide insights into the environmental impact of advertisements and encryption in webmail solutions, as well as the energy and traffic profiles of functional units across different providers.

For further details, refer to the comments and documentation within the notebooks.
