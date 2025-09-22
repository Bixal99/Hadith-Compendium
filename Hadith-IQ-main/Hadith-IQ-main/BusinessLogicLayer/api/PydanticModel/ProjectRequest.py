from pydantic import BaseModel
from typing import Dict, Any,List

class ProjectRequest(BaseModel):
    projectName: str

class RenameProjectRequest(BaseModel):
    currentName: str
    newName: str

class SaveProjectStateRequest(BaseModel):
    projectName: str
    stateQuery:str
    stateData: List[str]  

class RemoveHadithRequest(BaseModel):
    matn: List[str]
    projectName: str 
    stateQuery: str  
    
class GetProjectStateRequest(BaseModel):
    projectName: str
    
class GetSingleProjectStateRequest(BaseModel):
    stateQuery:str
    projectName: str

class MergeProjectStateRequest(BaseModel):
    projectName:str
    queryNames:List[str]
    queryName:str
class RenameProjectStateRequest(BaseModel):
    projectName:str
    oldQueryName:str
    newQueryName:str
class DeleteProjectStateRequest(BaseModel):
    projectName:str
    queryName:str