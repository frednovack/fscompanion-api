# syntax=docker/dockerfile:1
# This Dockerfile is designed for production use

# Stage 1: Build stage
FROM ruby:3.2.2 AS builder

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
  nodejs \
  postgresql-client \
  build-essential \
  libpq-dev \
  git \
  && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /rails

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems (production only)
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy the rest of the application
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Stage 2: Production stage
FROM ruby:3.2.2

# Install runtime dependencies only
RUN apt-get update -qq && apt-get install -y \
  postgresql-client \
  && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /rails

# Copy installed gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application code from builder
COPY --from=builder /rails /rails

# Create a non-root user to run the app
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /rails

# Switch to non-root user
USER rails:rails

# Expose port 3000
EXPOSE 3000

# Set production environment
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/api/v1/airports || exit 1

# Start the Rails server
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
