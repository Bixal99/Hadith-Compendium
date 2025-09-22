from typing import List
from pydantic import BaseModel

class GetAllNarratorsResponse(BaseModel):
        results: List[str]
        totalPages:int
        currentpage:int
class FileResponse(BaseModel):
        message:str
        success:bool
class FetchNarratorResponse(BaseModel):
        response:dict

class GetNarratedHadiths(BaseModel):
    results: List[dict]

class SearchNarrator(BaseModel):
       narrator:List[str]
class SortNarratorResponse(BaseModel):
       narrator:List[str]
class NarratorDetails(BaseModel):
    narrator_name: str
    detailed_name:str
    final_opinion:str
