from abc import ABC,abstractmethod
from TO.ProjectTO import ProjectTO
from typing import List
class AbsProjectBO(ABC):
 
    @abstractmethod
    def createProject(self,name:str)->bool:
        pass
   
        
    @abstractmethod
    def deleteProject(self, name: str) -> bool:
        pass
        
    @abstractmethod
    def renameProject(self,currName:str,newName:str)->bool:
        pass
        
    @abstractmethod
    def getProjects(self)->List[ProjectTO]:
        pass

    @abstractmethod
    def saveProjectState(self,name:str, stateData: List[str],query:str)->bool:
        pass

    @abstractmethod
    def getProjectState(self,name:str)->List[str]:
        pass
    @abstractmethod
    def getSingleProjectState(self,name:str,query:str)->List[str]:
      pass
    @abstractmethod
    def removeHadithFromState(self, matn: List[str], projectName: str, stateQuery: str) -> bool:
        pass
    @abstractmethod
    def mergeProjectState(self, projectname: str, query_names: List[str], queryname: str) -> bool:
        pass
    @abstractmethod
    def renameQueryOfState(self, project_name: str, old_query_name: str, new_query_name: str) -> bool:
        pass
    @abstractmethod
    def deleteState(self, project_name: str, query_name: str) -> bool:
        pass
    @abstractmethod
    def get_project_stats(self, projectName: str) -> dict:
        pass
    

