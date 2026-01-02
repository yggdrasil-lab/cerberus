FROM authelia/authelia:latest

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Make sure entrypoint is executable
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
