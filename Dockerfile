FROM python:3.11-alpine

# Set the working directory in the container
WORKDIR /app

# Copy your Python script to the working directory
COPY . /app/
RUN pip3 install -r requirements.txt

# Run your Python script
CMD ["python", "version-master.py"]