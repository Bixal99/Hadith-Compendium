from abc import ABC,abstractmethod
from typing import List
class AbsBookBO(ABC):

    @abstractmethod
    def getAllBooks(self)->List[str]:
        pass
    @abstractmethod
    def getBooksOfProject(self, project_name: str) -> List[str]:
       pass