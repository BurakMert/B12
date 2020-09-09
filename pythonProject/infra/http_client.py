import requests
import json

def make_http_call(url, params, method="GET"):
    try:
        if method == "GET":
            resp = requests.get(url, params)
        elif method == "POST":
            resp = requests.post(url, params)
        return resp
    except Exception as e:
        print(e)
        return False