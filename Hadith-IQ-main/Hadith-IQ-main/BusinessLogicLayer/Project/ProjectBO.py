from datetime import datetime, timezone
from BusinessLogicLayer.Project.AbsProjectBO import AbsProjectBO
from DataAccessLayer.Fascade.AbsDALFascade import AbsDALFascade
from typing import List
from TO.ProjectTO import ProjectTO


class ProjectBO(AbsProjectBO):

    def __init__(self, dalFascade: AbsDALFascade):
        self.__dalFascade = dalFascade

    @property
    def dalFascade(self) -> AbsDALFascade:
        return self.__dalFascade

    @dalFascade.setter
    def dalFascade(self, value):
        self.__dalFascade = value

    def _getCurrentDate(self) -> str:
        return datetime.now(timezone.utc).strftime("%d-%m-%Y")

    def createProject(self, name: str) -> bool:
        currentDate = self._getCurrentDate()
        print(currentDate)
        if not self.dalFascade.createProject(name, currentDate):
            print(f"Failed to create Project: {name}")
            return False
        return True

    def getProjects(self) -> List[ProjectTO]:
        try:
            projects = self.dalFascade.getProjects()
            return projects
        except Exception as e:
            print(f"Error fetching projects: {e}")
            return []
    
    def deleteProject(self, name: str) -> bool:
        if not self.dalFascade.deleteProject(name):
            print(f"Failed to delete Project: {name}")
            return False
        return True
    
    def renameProject(self, currName: str, newName: str) -> bool:
        if newName is currName:
            print("New name cannot be same")
            return False

        if not self.dalFascade.renameProject(currName, newName):
            print(f"Failed to rename Project: {currName}")
            return False
        return True
    def saveProjectState(self,name:str, stateData: List[str],query:str)->bool:
        return self.__dalFascade.saveProjectState(name,stateData,query)
    
    def getProjectState(self,name:str)->List[str]:
        return self.__dalFascade.getProjectState(name)
    
    def getSingleProjectState(self,name:str,query:str)->List[str]:
      return self.__dalFascade.getSingleProjectState(name,query)
    def removeHadithFromState(self, matn: List[str], projectName: str, stateQuery: str) -> bool:
        return self.__dalFascade.removeHadithFromState(matn,projectName,stateQuery)
    
    def mergeProjectState(self, projectname: str, query_names: List[str], queryname: str) -> bool:
        return self.__dalFascade.mergeProjectState(projectname,query_names,queryname)
    def renameQueryOfState(self, project_name: str, old_query_name: str, new_query_name: str) -> bool:
        return self.__dalFascade.renameQueryOfState(project_name,old_query_name,new_query_name)
    def deleteState(self, project_name: str, query_name: str) -> bool:
        return self.__dalFascade.deleteState(project_name,query_name)
    
    def get_project_stats(self, projectName: str) -> dict:
        return self.__dalFascade.get_project_stats(projectName)
    
    
      
