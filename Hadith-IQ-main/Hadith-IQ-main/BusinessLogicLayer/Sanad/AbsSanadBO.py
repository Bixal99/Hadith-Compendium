from abc import ABC,abstractmethod
from typing import List
from TO.SanadTO import SanadTO
from TO.NarratorTO import NarratorTO
class AbsSanadBO(ABC):
    @abstractmethod
    def authenticateSanad(self,sanadTO:SanadTO)->str:
        pass

    @abstractmethod
    def insertOpinion(self,narratorTO:NarratorTO,opinion:str)->bool:
        pass

    @abstractmethod
    def getSanad(self,matn:str)->List[NarratorTO]:
        pass