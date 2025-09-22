from abc import ABC,abstractmethod
from typing import Dict, List
class AbsBookDAO(ABC):
    
    @abstractmethod
    def insertBook(self,bookName:str)->bool:
        pass

    @abstractmethod
    def deleteBook(self,bookName:str)->bool:
        pass

    @abstractmethod
    def importBook(self, filePath: str) -> List[Dict[str, str]]:
        pass
    @abstractmethod
    def associate_book_with_project(self, book_name: str, project_name: str):
        pass
    @abstractmethod
    def getAllBooks(self)->List[str]:
        pass
    @abstractmethod
    def getBooksOfProject(self, project_name: str) -> List[str]:
        pass
