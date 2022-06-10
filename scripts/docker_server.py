from typing import Optional
from fastapi import FastAPI

app = FastAPI()

@app.get("/hello/{hello_id}")
def hello(hello_id: int):
    return {"hello_id": hello_id}
