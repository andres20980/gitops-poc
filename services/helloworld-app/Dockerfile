# services/helloworld-app/Dockerfile v1.0.0
# Use a multi-stage build to keep the final image small and secure.

# ---- Builder Stage ----
# This stage installs dependencies.
FROM python:3.9-slim as builder

WORKDIR /app

# Install build dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---- Final Stage ----
# This stage copies the installed dependencies and the application code.
FROM python:3.9-slim

WORKDIR /app

# Copy dependencies from the builder stage
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

# Copy the application code
COPY app.py .

# Expose the port the app runs on
EXPOSE 8080

# Command to run the application
CMD ["python", "app.py"]