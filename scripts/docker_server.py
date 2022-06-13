from flask import Flask, jsonify, request
from model import text_classify
import pandas as pd
import json

app = Flask(__name__)
 
@app.route('/')
def hello_world():
    return jsonify(text_classify(["안녕하세요"]).to_dict(orient = "list"))
 

@app.route("/classify", methods = ["POST"])
def classify():
    params = json.loads(request.get_data(), encoding = "utf-8")
    return jsonify(text_classify(params).to_dict(orient = "list"))

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)