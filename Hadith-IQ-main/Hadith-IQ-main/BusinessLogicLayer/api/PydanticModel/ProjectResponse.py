from pydantic import BaseModel
from typing import Dict, Any,List

class ProjectResponse(BaseModel):
    projectName: str
    lastUpdated: str
    createdAt: str

class GetProjectStateResponse(BaseModel):
    stateQuery:List[str]

class GetSingleProjectStateResponse(BaseModel):
    query:str
    stateData: List[str]

class MergeProjectStateResponse(BaseModel):
    message:str
    success:bool
class RenameProjectStateResponse(BaseModel):
    message:str
    success:bool
class DeleteProjectStateResponse(BaseModel):
    message:str
    success:bool


class RemoveHadithResponse(BaseModel):
    success: bool  
    message: str 