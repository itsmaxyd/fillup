# Use official Python image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create database directory
RUN mkdir -p /app/data

# Set environment variables
ENV PYTHONPATH=/app
ENV DATABASE_URL=sqlite:///./data/fuel_prices.db

# Expose port
EXPOSE 8443

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8443"]
