
from abc import ABC,abstractmethod
import datetime
from typing import Dict, List
from DataAccessLayer.Hadith import AbsHadithDAO
from TO.HadithTO import HadithTO
from TO.NarratorTO import NarratorTO
from TO.ProjectTO import ProjectTO
from TO.SanadTO import SanadTO
class AbsDALFascade(ABC):

    @abstractmethod
    def createProject(self,name:str, creationDate: str)->bool:
        pass

    @abstractmethod
    def getProjects(self) -> List[ProjectTO]:
        pass

    @abstractmethod
    def renameProject(self,currName:str,newName:str)->bool:
        pass

    @abstractmethod
    def deleteProject(self, projectName: str) -> bool:
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
    def insertBook(self,bookName:str)->bool:
        pass

    @abstractmethod
    def deleteBook(self,bookName:str)->bool:
        pass
    @abstractmethod
    def getAllBooks(self)->List[str]:
        pass
    @abstractmethod
    def getBooksOfProject(self, project_name: str) -> List[str]:
        pass

    @abstractmethod
    def associate_book_with_project(self, book_name: str, project_name: str):
        pass
    
    @abstractmethod
    def getHadithFirstNarrator(self, hadith:str) -> str:
        pass
    @abstractmethod
    def importBook(self, filePath: str) -> List[Dict[str, str]]:
        pass

    @abstractmethod
    def insertHadith(self, hadithTO: HadithTO) -> bool:
        pass

    @abstractmethod
    def associate_hadiths_with_project(self, book_name: str, project_name: str):
        pass
    @abstractmethod
    def getAllHadithsOfProject(self, projectName: str,page:int) -> dict:
        pass
    @abstractmethod
    def getHadithDetails(self, matn: str, projectName: str) -> dict:
        pass
    @abstractmethod
    def getAllHadiths(self, page: int) -> dict:
        pass
    @abstractmethod
    def searchHadithByNarrator(self, project_name: str, narrator_name: str, page: int) -> dict:
        pass
    @abstractmethod
    def sortNarrators(self,project_name: str,narrator_list: List[str],ascending: bool,authenticity:bool) -> List[str]:
        pass
    @abstractmethod
    def getProjectHadithsEmbedding(self, projectName:str) -> dict:
        pass
    @abstractmethod
    def getAllHadithsEmbeddings(self) -> dict:
        pass
    @abstractmethod
    def get_project_stats(self, projectName: str) -> dict:
        pass


    @abstractmethod
    def insertSanad(self, sanadTO: SanadTO) -> bool:
        pass
    
    @abstractmethod
    def getSanad(self,matn:str)->List[SanadTO]:
        pass

    @abstractmethod
    def associate_sanads_with_project_by_book(self,book_name: str, project_name: str):
        pass


    @abstractmethod
    def insertNarrator(self,sanad: str, narratorTO : NarratorTO)->bool:
        pass
    
    @abstractmethod
    def getSimilarNarrator(self,narratorName:str)->dict:
        pass
    
    @abstractmethod
    def getNarratedHadiths(self, project_name: str, narrator_name: str) -> dict:
        pass

    @abstractmethod
    def getNarratorDetails(self,narratorName:str,projectName:str)->dict:
        pass
    @abstractmethod
    def getAllNarratorsOfProject(self, project_name: str,page:int) -> dict:
        pass
    @abstractmethod
    def getAllNarrators(self, page: int) -> dict:
        pass
    @abstractmethod
    def importNarratorDetails(self,narratorName:str,narratorTeacher:List[str],narratorStudent:List[str],opinion:List[str],scholar:List[str],final_opinion:str,authenticity:float)->bool:
        pass
    @abstractmethod
    def getSimilarNarratorName(self,narratorName:str)->dict:
        pass
    @abstractmethod
    def associateHadithNarratorWithNarratorDetails(self, projectName: str, narrator_name: str, detailed_narrator_name: str) -> bool:
        pass
    @abstractmethod
    def getNarratorStudent(self, narratorName: str, projectName: str) -> str:
        pass
    @abstractmethod
    def getNarratorTeacher(self, narratorName: str, projectName: str) -> str:
        pass
    @abstractmethod
    def updateHadithNarratorAssociation(self, projectName: str, narrator_name: str, new_detailed_narrator_name: str) -> bool:
        pass
    @abstractmethod
    def deleteHadithNarratorAssociation(self, projectName: str, narrator_name: str) -> bool:
        pass
    @abstractmethod
    def getNarratorChains(self, project_name: str, narrator_name: str) -> dict:
        pass
    @abstractmethod
    def stringBasedSearch(self, query: str, project_name: str) -> List:
        pass
    @abstractmethod
    def rootBasedSearch(self, query: str, project_name: str, page: int) -> dict:
        pass
    @abstractmethod
    def operatorBasedSearch(self,query:str,project_name:str)->List[str]:
        pass