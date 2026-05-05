# ==============================================================================
# simply todo - Database Infrastructure (Dockerfile)
# ==============================================================================
# Repository: todo-db
# Target: PostgreSQL 15 (Alpine)
# License: Apache 2.0
# Description: Minimalist, secure database container for the simply todo system.
# ==============================================================================

# 1. Base Image Specification
# We explicitly use the Alpine variant. It reduces the image size from ~400MB 
# to ~160MB, resulting in faster deployments and a vastly reduced security 
# attack surface compared to standard Debian/Ubuntu images.
FROM postgres:15-alpine

# 2. Metadata Annotations
# These labels embed the project identity and maintainer info directly into 
# the Docker image metadata. You can view these later using `docker inspect`.
LABEL maintainer="Founder & Lead Developer" \
      project="simply todo" \
      component="todo-db" \
      tier="infrastructure" \
      license="Apache 2.0" \
      version="1.0"

# 3. Build-Time Logging (Start)
# This outputs directly to your terminal during the `docker-compose build` step,
# acting as a sanity check that the correct Dockerfile is being executed.
RUN echo "==> [simply todo] Starting build for todo-db infrastructure..."

# 4. Schema Injection
# The official PostgreSQL Docker image is hardcoded to look inside the 
# /docker-entrypoint-initdb.d/ folder on its VERY FIRST boot. Any .sql files 
# found here are automatically executed to set up the database.
# 
# IMPORTANT: This COPY command assumes your docker build context is the root 
# of the repository (which we will configure in docker-compose.yml).
COPY db/init.sql /docker-entrypoint-initdb.d/01-init.sql

# 5. Build-Time Logging (Completion)
# Final verification log before the image build finishes.
RUN echo "==> [simply todo] init.sql successfully injected into entrypoint directory. Build complete."
