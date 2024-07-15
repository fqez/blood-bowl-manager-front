import requests


def fetch_data(endpoint):
    try:
        response = requests.get(endpoint)
        response.raise_for_status()  # Raises an HTTPError if the response status code is 4XX/5XX
        return response.json()  # Assuming the API returns JSON
    except requests.RequestException as e:
        print(f"Error fetching data from {endpoint}: {e}")
        return None
