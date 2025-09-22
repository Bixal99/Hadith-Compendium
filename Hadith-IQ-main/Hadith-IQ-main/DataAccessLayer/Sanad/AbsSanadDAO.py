from abc import ABC, abstractmethod
from typing import List

from TO.SanadTO import SanadTO


class AbsSanadDAO(ABC):
    @abstractmethod
    def insertSanad(self, sanadTO: SanadTO) -> bool:
        pass

    @abstractmethod
    def getSanad(self, matn: str) -> List[SanadTO]:
        pass

    @abstractmethod
    def associate_sanads_with_project_by_book(self,book_name: str, project_name: str):
        pass