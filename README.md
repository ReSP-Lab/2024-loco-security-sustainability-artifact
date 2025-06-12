# 2024-loco-security-sustainability-artifact

This repository contains the workspace for an empirical study on the environmental impact of advertisements in webmail solutions. The study compares the energy and traffic profile of executing functional units (such as sending or reading an email) on mainstream providers—Outlook, Gmail, and Proton Mail—with and without a network adblocker enabled. Additionally, we investigate the impact of PGP encryption by implementing a self-hosted solution called **my_email_solution**.

The entire project is designed and tested for Intel x86_64/amd64 architectures. **Docker** is required to run the self-hosted solution. You can find Docker installation instructions [here](https://docs.docker.com/get-docker/).

---

## 1) Self-Hosted Solution: Installation Guide

### 1. Clone the Repository

```sh
git clone https://github.com/ReSP-Lab/2024-loco-security-sustainability-artifact.git
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

> **Note 1:** You need at least two addresses to exchange emails. This setup is experimental and mimics real-life scenarios, but since you do not own the domain, sending emails to external domains will not work.

> **Note 2:** In the container, the Mailvelope extension is pre-configured with an account and PGP public keys for `jason.kayembe@my-solution.com` and `marie.hupin@my-solution.com`. Use these addresses with the password `Azerty123` to ensure the automation tool has a working routine for using PGP encryption.

### 5. Test Access To the Webmail Interface

Open your browser and navigate to [https://localhost](https://localhost). You can now log in with the email addresses and passwords you created.

---

## 2) Automation Tool (`simulator`) Overview

The `simulator` folder contains an automation tool for running and measuring email scenarios on various webmail providers. It is designed to be run in a Docker container and orchestrated for reproducible, automated experiments.

### Folder Structure

#### 1. Folders Included in the Simulator Docker Image

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
      > **Note:** For our study, we used PiHole, an external network adblocker running on the host (not in the container). Therefore, this parameter was set to `'false'`.
      >
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
- **setup.sh**: Configuration script for the container.

  - Starts Xvfb (virtual display).
  - Starts the x11vnc (VNC server) if option `--send-gui-to-vnc` is passed to the script
  - Detects the Docker gateway IP and adds it to `/etc/hosts` as `my-solution.com` (for accessing the self-hosted mail solution).
  - Sets the DNS to the gateway IP (enables PiHole adblocker testing) if the script is passed the option `--use-host-as-dns`. **The option needs needs not to be passed if no DNS service is running on the host**.
- **entrypoint.sh**:

  - Runs the Python automation script. It is used to serve as the entrypoint in the compose.yaml (or in the usage_scenario.yaml when using the GMT)
- **debug.sh**: A script designed to sequentially run the automation tool for every scenario JSON file located in `scenarios_2025/`.

  - **Purpose**: Primarily used for debugging and testing the automation tool. It allows you to visually monitor the automated browser actions via a VNC client.
  - **How It Works**:
    - Launches the TigerVNC Client (`xtigervncviewer`) to enable viewing the browser automation in real-time. The VNC server runs on `localhost:5900`. You can use any VNC client to connect (e.g., `tigervnc`).
    - Dynamically updates the `entrypoint.sh` file to specify the scenario being executed.
    - Starts the Docker containers, runs the automation tool, and then shuts down the containers after execution.
  - **Customization**: If you prefer a different VNC client, modify the `xtigervncviewer localhost::5900 &` line in the script.
  - **Usage**: Make the script executable (`chmod +x debug.sh`) and run it directly to execute all scenarios in the `scenarios_2025/` folder.

This script is particularly useful for debugging scenarios and ensuring the automation tool behaves as expected before running large-scale experiments.

- **compose.yaml**: The Docker Compose file streamlines container management for the simulator. Key features include:

  - **Custom Network**: Isolates the simulator with a dedicated bridge network and static IP.
  - **Port Mapping**: Exposes the VNC server (`5900`) for GUI debugging.
  - **Environment Variables**: Configures runtime parameters like `IS_MEASURED` and `SEED`.
  - **Volume Mounts**: Links host scripts, source code, and data to the container.
  - **Startup Commands**: Runs setup scripts and launches the automation tool.

  This setup ensures a consistent and efficient environment for running simulations.
- **usage_scenario.yml**: Used by the Green Metric Tool (GMT) to orchestrate the container and monitor energy/traffic, similar to a Compose file.

  > **Note:** The `setup.sh` script supports the following options:
  >
  > - `--use-host-as-dns`: Configures the container to use the host as a DNS server. This is useful when running PiHole or other DNS services on the host.
  > - `--send-gui-to-vnc`: Redirects the GUI to `localhost:5900` through a VNC server for debugging purposes.
  >

...

## Running the Automation Tool

To run the automation tool using the scenarios defined in [`scenarios_2025`](simulator/scenarios_2025):

- **Preliminary Step: Make Scripts Executable**

  Before running the automation tool, ensure that the required scripts are executable:

  ```sh
  chmod +x simulator/setup.sh simulator/entrypoint.sh simulator/debug.sh
  ```
- **Option 1:** Use Docker Compose
  Make sure that [`entrypoint.sh`](simulator/entrypoint.sh) specifies the correct scenario file, for example:

  ```bash
  python -u src/scenario.py scenarios_2025/<your_scenario>.json
  ```

  In the [`compose.yaml`](simulator/compose.yaml)  file, choose to launch or not the [`setup.sh`](simulator/setup.sh) script with additional optionsThe `setup.sh` script supports the following options:

  - `--send-gui-to-vnc`: Redirects the GUI to `localhost:5900` through a VNC server for real-time monitoring.
  - `--use-host-as-dns`: Configures the container to use the host as a DNS server, useful when running PiHole or other DNS services on the host.

  Then, from inside the `simulator/` directory, run:

  ```sh
  docker compose up
  ```
- **Option 2:** Choose the right options for the `setup.sh` in the [`compose.yaml`](simulator/compose.yaml) file as in option 1, then run :

  ```sh
  ./debug.sh
  ```

  This will sequentially run the tool on every scenario JSON file in [`scenarios_2025`](simulator/scenarios_2025).

For further details, refer to the comments and documentation within the scripts.

---

## 3) Monitoring Automated Scenarios with the Green Metric Tool (GMT)

To monitor the automated scenarios and measure their environmental impact, we use the [Green Metric Tool (GMT)](https://docs.green-coding.io/docs/installation/installation-linux/). Follow the steps below to set up and use GMT for monitoring:

### 1. Install the Green Metric Tool

Follow the [official installation guide](https://docs.green-coding.io/docs/installation/installation-linux/) to install GMT on your system. Ensure that all dependencies are installed and the tool is properly configured.

### 2. Configure Metric Providers

To enable monitoring, you need to activate the metric providers in the `config.yaml` file located in the GMT folder. Uncomment the relevant sections in the file to enable the desired metrics.

We provide an example configuration file, [`config.yaml.example`](gmt/config.yaml.example), that we used for our experiments. You can use it as a reference to configure your `config.yaml`.

### 3. Start the GMT Container

Once GMT is installed and configured, start the GMT containers using Docker Compose. Refer to the [GMT documentation](https://docs.green-coding.io/docs/installation/installation-linux/) for detailed instructions.

### 4. Select setup.sh Options

The GMT use the `usage_scenario.yaml` as a kind of compose file to orchestrate the container containing the processes to be monitored. In the `usage_scenario.yaml` file, choose to launch or not the [`setup.sh`](simulator/setup.sh) script with additional options
The `setup.sh` script supports the following options:

- `--send-gui-to-vnc`: Redirects the GUI to `localhost:5900` through a VNC server for real-time monitoring.
- `--use-host-as-dns`: Configures the container to use the host as a DNS server, useful when running PiHole or other DNS services on the host.
### 4. Run the Automation Tool with GMT Monitoring

We provide a script, [`measure_scenarios.sh`](gmt/measure_scenarios.sh), to automate the process of running the scenarios and monitoring them with GMT. Follow these steps:

1. Make the script executable:

   ```bash
   chmod +x gmt/measure_scenarios.sh
   ```
2. Run the script with the required arguments:

   ```bash
   ./measure_scenarios.sh <number_of_iterations> <path_to_2024_loco_security_sustainability_artifact> <path_to_green_metric_tool>
   ```
   - `<number_of_iterations>`: Number of times the test will be launched.
   - `<path_to_2024_loco_security_sustainability_artifact>`: The path to this repository.
   - `<path_to_green_metric_tool>`: The path to the installed GMT directory.

This script will:

- Loop through all `.json` scenario files in the `scenarios_2025` directory.
- Update the `usage_scenario.yml` file to run each scenario.
- Launch the GMT monitoring tool and execute the scenarios.

### Example Usage

```bash
./measure_scenarios.sh 10 ~/2024-loco-security-sustainability-artifact ~/green-metric-tool
```
This will monitor the automated scenarios 10 times each and save the results in GMT database.

For further details, refer to the GMT documentation and the provided example files in this repository.

---

## 4) Data Preprocessing and Analysis

We provide the notebooks used to preprocess and analyze the data collected for this study. These notebooks are located in the `notebook` folder of this repository. They include all the steps required to clean, transform, and analyze the raw data collected during the experiments.

### Preprocessed Data

The preprocessed data is also included in the repository for convenience:

- [`2025_data.csv`](notebook/2025_data_analysis.csv): Contains the preprocessed data for the scenarios executed during the study.
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

   - [`analysis_notebook.ipynb`](notebook/2025_data_analysis.ipynb): Main notebook for analysing the collected data during email services usage.
   - [`topnews_analysis.ipynb`](notebook/2025_topnews_data_analysis.ipynb): Notebook for analysing `adblocking effect on mainstream websites` experiment (validating Pesari et al. experiment).

   To open a notebook, run:

   ```sh
   jupyter notebook
   ```

These notebooks provide insights into the environmental impact of advertisements and encryption in webmail solutions, as well as the energy and traffic profiles of functional units across different providers.

For further details, refer to the comments and documentation within the notebooks.
