# Use an official Python image as a parent image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy requirements and install dependencies
COPY ./requirements.txt ./
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose the backend port
EXPOSE 8000

# Command to run the backend
CMD ["bash", "-c", "source venv/bin/activate && python main.py"]
