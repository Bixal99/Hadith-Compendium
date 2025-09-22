from abc import ABC, abstractmethod
from typing import Dict, List

from TO.HadithTO import HadithTO
from TO.NarratorTO import NarratorTO


class AbsNarratorDAO(ABC):

    @abstractmethod
    def insertNarrator(self,sanad: str, narratorTO : NarratorTO)->bool:
        pass

    
    @abstractmethod
    def getSimilarNarrator(self,narratorName:str)->dict:
        pass
    
    @abstractmethod
    def getNarratorDetails(self,narratorName:str,projectName:str)->dict:
        pass
    @abstractmethod
    def getAllNarratorsOfProject(self, project_name: str,page :int) ->dict:
        pass
    @abstractmethod
    def getAllNarrators(self, page: int) -> dict:
        pass
    @abstractmethod
    def getNarratedHadiths(self, project_name: str, narrator_name: str) -> dict:
        pass
    @abstractmethod
    def getNarratorChains(self, project_name: str, narrator_name: str) -> dict:
        pass
    @abstractmethod
    def sortNarrators(self,project_name: str,narrator_list: List[str],ascending: bool,authenticity:bool) -> List[str]:
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
      