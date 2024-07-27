# Stage 1: Build stage
FROM alpine:latest AS builder

# Install Python and necessary build tools
RUN apk add --no-cache python3 python3-dev py3-pip \
    openssl-dev gcc musl-dev libffi-dev make cargo git

# Create a virtual environment
RUN python3 -m venv /work/venv

# Upgrade pip and install setuptools
RUN /work/venv/bin/pip install --upgrade pip setuptools

# Copy requirements and install dependencies
COPY exporter/requirements.txt /work/exporter/requirements.txt
RUN /work/venv/bin/pip install --no-cache-dir --find-links /wheels --requirement /work/exporter/requirements.txt

# Stage 2: Final image
FROM alpine:latest

# Install Python runtime
RUN apk add --no-cache python3 py3-pip

# Copy the virtual environment from the builder stage
COPY --from=builder /work/venv /venv

# Set environment variables
ENV PATH="/venv/bin:$PATH"

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    libffi

# Create and set user
RUN addgroup crypto-exporter && adduser -G crypto-exporter -D -H crypto-exporter

# Copy the application and exporter directory
COPY crypto-exporter /usr/local/bin/crypto-exporter
COPY exporter /exporter

USER crypto-exporter:crypto-exporter

EXPOSE 9188

ENTRYPOINT ["/usr/local/bin/crypto-exporter"]
