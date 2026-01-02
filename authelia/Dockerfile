FROM authelia/authelia:latest

# Copy entrypoint script
COPY authelia/entrypoint.sh /entrypoint.sh
COPY config/configuration.yml /config/configuration.yml

# Make sure entrypoint is executable
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
