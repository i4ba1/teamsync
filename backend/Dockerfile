# syntax=docker/dockerfile:1
FROM ruby:3.2.2-slim-bookworm

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  libsodium-dev \
  libvips \
  pkg-config \
  git \
  curl \
  && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install gems (all groups: the compose stack runs RAILS_ENV=development)
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'false' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Create non-root user
RUN groupadd -r rails && useradd -r -g rails rails
RUN chown -R rails:rails /app
USER rails

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
