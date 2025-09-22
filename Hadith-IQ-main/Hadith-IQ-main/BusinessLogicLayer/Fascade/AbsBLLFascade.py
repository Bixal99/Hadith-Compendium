from BusinessLogicLayer.Project.AbsProjectBO import AbsProjectBO
from BusinessLogicLayer.Hadith.AbsHadithBO import AbsHadithBO
from BusinessLogicLayer.Narrator.AbsNarratorBO import AbsNarratorBO
from TO.SanadTO import SanadTO
from TO.HadithTO import HadithTO
from TO.ProjectTO import ProjectTO
from TO.NarratorTO import NarratorTO
from typing import List,Dict
from abc import ABC,abstractmethod

class AbsBLLFascade(ABC):
   #AbsProjectBO functions
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
   def getAllBooks(self)->List[str]:
      pass
   @abstractmethod
   def getBooksOfProject(self, project_name: str) -> List[str]:
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
   #AbsHadithBO Functions
   @abstractmethod
   def importHadithFile(self, projectName: str, filePath: str) -> bool:
      pass
   @abstractmethod
   def importHadithFileCSV(self, filePath: str) -> bool:
      pass
    
   @abstractmethod
   def getAllHadiths(self, page: int) -> dict:
      pass
    
   @abstractmethod
   def semanticSearch(self, hadith: str,projectName:str,threshold:float) -> dict:
      pass

   @abstractmethod
   def getHadithData(self,HadithTO:HadithTO)->Dict:
      pass
   @abstractmethod
   def getAllHadithsOfProject(self, projectName: str,page:int) -> dict:
       pass
   @abstractmethod
   def sortHadith(
        self, byNarrator: bool, byGrade: bool, gradeType: str, hadithList: List[str]
    ) -> List[dict]:
      pass

   @abstractmethod
   def generateHadithFile(self,path:str,HadithTO:List[HadithTO])->bool:
      pass
    
   @abstractmethod
   def expandSearch(self,HadithTO:List[str],projectName: str,threshold:float)->dict:
      pass
   @abstractmethod
   def getHadithDetails(self, matn: str, projectName: str) -> dict:
      pass
   @abstractmethod
   def stringBasedSearch(self, query: str, project_name: str) -> List[str]:
        pass
   @abstractmethod
   def rootBasedSearch(self, query: str, project_name: str) -> List[str]:
        pass
   @abstractmethod
   def operatorBasedSearch(self,query:str,project_name:str)->List[str]:
        pass
   @abstractmethod
   def hadith_rag(self, question: str, projectName: str) -> str:
      pass
   @abstractmethod
   def get_project_stats(self, projectName: str) -> dict:
      pass

     
   #AbsNarratorBO funtions
   @abstractmethod
   def getNarratedHadiths(self, project_name: str, narrator_name: str) -> dict:
      pass

   @abstractmethod
   def getNarratorChains(self, project_name: str, narrator_name: str) -> dict:
      pass

   @abstractmethod
   def getNarratorTeachers(self,narratorTO:NarratorTO)->List[NarratorTO]:
      pass

   @abstractmethod
   def getNarratorStudents(self,narratorTO:NarratorTO)->List[NarratorTO]:
      pass

   @abstractmethod
   def applySentimentAnalysis(self,narratorTO:NarratorTO)->str:
      pass

   @abstractmethod
   def searchNarrator(self,narrator:str)->dict:
      pass

   @abstractmethod
   def getNarratorAuthenticity(self,narratorTO:NarratorTO)->str:
      pass

   @abstractmethod
   def getNarratorDetails(self,narratorName:str,projectName:str)->dict:
      pass

  
   @abstractmethod
   def getAllNarratorsOfProject(self, project_name: str,page:int) -> dict:
      pass
   @abstractmethod
   def convertHtmlToText(html_file: str) -> dict:
      pass
   @abstractmethod
   def cleanNarratorTxtFile(self, input_file, arabic_count)->dict:
      pass
   @abstractmethod
   def fetch_narrator_data(self,file_path:str,arabic_count:int)->dict:
      pass
   @abstractmethod
   def getAllNarrators(self, page: int) -> dict:
      pass
   @abstractmethod
   def searchHadithByNarrator(self, project_name: str, narrator_name: str, page: int) -> dict:
      pass
   @abstractmethod
   def sortNarrators(self,project_name: str,narrator_list: List[str],ascending: bool,authenticity:bool) -> List[str]:
      pass
   @abstractmethod
   def importNarratorDetails(self,narratorName:str,narratorTeacher:List[str],narratorStudent:List[str],opinion:List[str],scholar:List[str])->bool:
        pass
   @abstractmethod
   def getSimilarNarratorName(self,narratorName:str)->dict:
      pass
   
   #AbsSanadBO function
   @abstractmethod
   def authenticateSanad(self,sanadTO:SanadTO)->str:
      pass


   @abstractmethod
   def getSanad(self,matn:str)->List[NarratorTO]:
      pass
   @abstractmethod
   def associateHadithNarratorWithNarratorDetails(self, projectName: str, narrator_name: str, detailed_narrator_name: str) -> bool:
      pass
   @abstractmethod
   def getNarratorStudent(self, narratorName: str, projectName: str) -> List[str]:
      pass
   @abstractmethod
   def getNarratorTeacher(self, narratorName: str, projectName: str) -> List[str]:
      pass
   @abstractmethod
   def updateHadithNarratorAssociation(self, projectName: str, narrator_name: str, new_detailed_narrator_name: str) -> bool:
      pass
   @abstractmethod
   def deleteHadithNarratorAssociation(self, projectName: str, narrator_name: str) -> bool:
      pass