from pydantic import BaseModel
from typing import List

class GetAllBooksResponse(BaseModel):
    books:List[str]