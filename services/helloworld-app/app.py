# services/helloworld-app/app.py v1.0.0
# A simple Flask app that calls the Carbone service.

import os
import requests
from flask import Flask, jsonify

app = Flask(__name__)

# The Carbone service is resolved using Kubernetes DNS.
# The service is named 'carbone-service' and listens on port 4000.
CARBONE_STATUS_URL = "http://carbone-service:4000/status"

@app.route("/")
def hello_and_check_carbone():
    """
    Main endpoint that provides a greeting and checks Carbone's status.
    """
    try:
        response = requests.get(CARBONE_STATUS_URL, timeout=5)
        response.raise_for_status()  # Raise an exception for bad status codes
        carbone_status = "available"
        carbone_data = response.json()
    except requests.exceptions.RequestException as e:
        carbone_status = "unavailable"
        carbone_data = {"error": str(e)}

    return jsonify(
        greeting="Hello from the new helloworld app!",
        carbone_service_status=carbone_status,
        carbone_service_response=carbone_data
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)