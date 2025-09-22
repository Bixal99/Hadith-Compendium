from abc import ABC,abstractmethod
from typing import List,Dict,Any
from TO.HadithTO import HadithTO
class AbsHadithDAO(ABC):

    @abstractmethod
    def insertHadith(self, hadithTO: HadithTO) -> bool:
        pass

    @abstractmethod
    def getHadithEmbeddings(self,matn:str)->str:
        pass
    
    @abstractmethod
    def getProjectHadithsEmbedding(self, projectName:str) -> dict:
        pass

    @abstractmethod
    def getHadithFirstNarrator(self, hadith:str) -> str:
        pass

    @abstractmethod
    def associate_hadiths_with_project(self, book_name: str, project_name: str):
        pass
    @abstractmethod
    def getAllHadithsOfProject(self, project_name: str,page:int) -> dict:
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
    def stringBasedSearch(self, query: str, project_name: str) -> List[str]:
        pass
    @abstractmethod
    def rootBasedSearch(self, query: str, project_name: str, page: int) -> dict:
        pass
    @abstractmethod
    def operatorBasedSearch(self,query:str,project_name:str,)->List[str]:
        pass
    @abstractmethod
    def getAllHadithsEmbeddings(self) -> dict:
        pass