FROM python:3.12-slim

RUN apt-get update && apt-get install -y \
    # chromium-driver \
    chromium \
    x11vnc \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt /app
COPY chrome_profiles_backup /app/chrome_profiles
RUN chmod -R +rwx chrome_profiles/
COPY mailvelope /app/mailvelope
COPY ublock /app/ublock


RUN pip install -r requirements.txt

# Expose the VNC port
EXPOSE 5900

# Set environment variables for chromium binary path and chromedriver binary path
ENV CHROMIUM_PATH='/usr/bin/chromium'
ENV CHROMIUM_DRIVER_PATH='/usr/bin/chromedriver'
ENV IS_CONTAINER=true
ENV DISPLAY=:0
# A seed for deterministic behavior
ENV SEED=123