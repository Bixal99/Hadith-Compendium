from abc import ABC,abstractmethod
from typing import List,Dict
from TO.HadithTO import HadithTO
class AbsHadithBO(ABC):

    @abstractmethod
    def importHadithFile(self, projectName: str, filePath: str) -> bool:
        pass
    
    @abstractmethod
    def getAllHadiths(self, page: int) -> dict:
        pass
    
    @abstractmethod
    def semanticSearch(self, hadith: str,projectName:str,threshold:float) -> dict:
        pass


    @abstractmethod
    def sortHadith(self, byNarrator: bool, byGrade: bool, gradeType: str, hadithList: List[str]) -> List[dict]:
        pass

    
    @abstractmethod
    def expandSearch(self,HadithTO:List[str],projectName: str,threshold:float)->dict:
        pass

    @abstractmethod
    def getAllHadithsOfProject(self, projectName: str,page:int) -> dict:
       pass
    @abstractmethod
    
    def importHadithFileCSV(self, filePath: str) -> bool:
        pass
    @abstractmethod
    def getHadithDetails(self, matn: str, projectName: str) -> dict:
        pass
    @abstractmethod
    def searchHadithByNarrator(self, project_name: str, narrator_name: str, page: int) -> dict:
        pass
    @abstractmethod
    def stringBasedSearch(self, query: str, project_name: str, page: int) -> dict:
        pass
    @abstractmethod
    def stringBasedSearch(self, query: str, project_name: str) -> List[str]:
        pass
    @abstractmethod
    def operatorBasedSearch(self,query:str,project_name:str)->List[str]:
        pass
    @abstractmethod
    def hadith_rag(self, question: str, projectName: str) -> str:
        pass