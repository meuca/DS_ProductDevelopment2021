from enum import Enum
from typing import Dict, Optional
from pydantic import BaseModel
import pandas as pd
import io

from fastapi import FastAPI
from fastapi.responses import ORJSONResponse, HTMLResponse, StreamingResponse



class RoleName(str, Enum):
    admin = "Admin"
    writer = "Writer"
    reader = "Reader"

class Item(BaseModel):
    name :str
    description: Optional[str] = None
    price: float
    tax: Optional[float] = None

app = FastAPI()

__currentUser = "base"

@app.get("/")
def root():
    return {"message": "Hello World, from Galileo section V"}

#@app.get("/items/{item_id}")
#def read_item(item_id : int) -> Dict[str, int]:
#    return{"item_id": int(item_id)}

@app.get("/users/me")
def read_current_user():
    return{"user_id": __currentUser}


@app.get("/users/{user_id}")
def read_user(user_id : str):
    __currentUser = user_id
    return{"user_id": user_id}

@app.get("/roles/{role_name}")
def get_role_permissions(role_name :RoleName):
    if role_name == RoleName.admin:
        return{ "role_name":role_name, "permissions" : "Full Acces"}
    if role_name == RoleName.writer:
        return{ "role_name":role_name, "permissions" : "Write Acces"}
    if role_name == RoleName.reader:
        return{ "role_name":role_name, "permissions" : "Read Acces"}


fake_items_db = [
    {"item_name" : "uno"},
    {"item_name" : "dos"},
    {"item_name" : "tres"}
]

@app.get("/items/")
def read_ites(skip:int = 0, limit:int = 10):
    return fake_items_db[skip: skip + limit]

@app.get("/items/{item_id}")
def read_item_query(item_id:int, query:Optional[str] = None):
    message = {"item_id" : item_id}
    if query:
        message['query'] = query
    
    return message

@app.get("/users/{user_id}/items/{item_id}")
def read_user_item(user_id : int, item_id: int, query:Optional[str] = None, describe: bool = False):
    item = {"item_id" : item_id, "owner_id" : user_id}

    if query:
        item['query'] = query

    if not describe:
        item['description'] = "This is a long description for the item"
    
    return item

@app.post("/items/")
def create_item(item:Item):
    return{
        "message" : "The item was successfully created",
        "item" : item.dict()
    }
@app.put("/items/")
def update_item(item_id : int, item : Item):
    if item.tax == 0 or item.tax is None:
        item.tax = item.price * 0.12
    return{
        "message" : "The item was updated",
        "item_id" : item_id,
        "item" : item.dict()
    }

@app.get("/itemsall", response_class= ORJSONResponse) #UJSONResponse
def read_long_json():
    return [ {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, 
    {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, 
    {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, 
    {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"}, {"item_id" : "item"},  ]

@app.get("/html", response_class = HTMLResponse)
def read_html():
    return """
        <html>
            <head></head>
            <body>
                <h1>Hello World</h1>
            </body>
        </html>
    """

@app.get("/csv")
def get_csv():
    df = pd.DataFrame({'Column A': [1,2], "Column B" : [3, 4]})
    stream = io.StringIO()

    df.to_csv(stream, index=False)


    response = StreamingResponse(iter([stream.getvalue()]), media_type='text/csv')

    response.headers['Content-Disposition'] = "attachment; filename=my_awesome_report.csv"

    return response


#-------------------------------------------------TAREA----------------------------------------
#------------------------------------------------OPERACIONES CON GETS--------------------------
#--------------------SUMA----------------------------------------------------------------------
@app.get("/suma/{operando1}/{operando2}")
def suma_get(operando1 : float, operando2 : float):
    return operando1 + operando2

#-------------------RESTA----------------------------------------------------------------------
@app.get("/resta/{operando1}/{operando2}")
def suma_get(operando1 : float, operando2 : float):
    return operando1 - operando2

#-------------------MULTIPLICACION--------------------------------------------------------------
@app.get("/multiplicacion/{operando1}/{operando2}")
def suma_get(operando1 : float, operando2 : float):
    return operando1 * operando2

#-------------------DIVISION--------------------------------------------------------------------
@app.get("/division/{operando1}/{operando2}")
def suma_get(operando1 : float, operando2 : float):
    return operando1 / operando2


#------------------------------------------------OPERACIONES CON POST--------------------------
#--------------------SUMA----------------------------------------------------------------------
@app.post("/suma")
def suma_get(operando1 : float, operando2 : float):
    return operando1 + operando2

#--------------------RESTA---------------------------------------------------------------------
@app.post("/resta")
def suma_get(operando1 : float, operando2 : float):
    return operando1 - operando2

#--------------------MULTIPLICACION------------------------------------------------------------
@app.post("/multiplicacion")
def suma_get(operando1 : float, operando2 : float):
    return operando1 * operando2

#--------------------DIVISION------------------------------------------------------------
@app.post("/division")
def suma_get(operando1 : float, operando2 : float):
    return operando1 / operando2