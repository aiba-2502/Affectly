# Rails 8.0 with Ruby 3.3
FROM ruby:3.3.5-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    git \
    curl \
    vim \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN npm install -g yarn

# Set working directory
WORKDIR /app

# Install Rails 8
RUN gem install rails -v "~> 8.0.0"

# Add a script to handle Rails setup
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Remove a potentially pre-existing server.pid for Rails.\n\
rm -f /app/backend/tmp/pids/server.pid 2>/dev/null || true\n\
\n\
# Then exec the container main process (what is set as CMD in the Dockerfile).\n\
exec "$@"' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Expose port 3000
EXPOSE 3000

# Default command
CMD ["bash"]