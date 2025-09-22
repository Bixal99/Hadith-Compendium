from pydantic import BaseModel
from typing import List 

class GetAllNarratorsRequest(BaseModel):
    projectName: str
    page:int
class ConvertToTxt(BaseModel):
    filePath:str
class CleanFile(BaseModel):
    filePath:str
    arabic_count:int
class GetListOfNarratorDetails(BaseModel):
    narrator_names: List[str]
    project_name: str

class SortNarrator(BaseModel):
    byauthenticity:bool
    byorder:bool
    narrator:List[str]
    projectName:str

class SaveNarrator(BaseModel):
    narratorName:str
    narratorTeacher:List[str]
    narratorStudent:List[str]
    opinion:List[str]
    scholar:List[str]
class Associate(BaseModel):
    projectName:str
    narrator_name:str
    detailed_narrator:str

class Deassociate(BaseModel):
    projectName:str
    narrator_name:str