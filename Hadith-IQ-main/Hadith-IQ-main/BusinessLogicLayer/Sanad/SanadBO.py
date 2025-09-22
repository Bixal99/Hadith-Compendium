from DataAccessLayer.Fascade.AbsDALFascade import AbsDALFascade
from BusinessLogicLayer.Sanad.AbsSanadBO import AbsSanadBO
from typing import List
from TO.SanadTO import SanadTO
from TO.NarratorTO import NarratorTO
class SanadBO(AbsSanadBO):

    def __init__(self, dalFascade: AbsDALFascade):
        self.__dalFascade = dalFascade

    @property
    def dalFascade(self) -> AbsDALFascade:
        return self.__dalFascade

    @dalFascade.setter
    def dalFascade(self, value):
        self.__dalFascade = value

    def convertSanadNarratorList(self,sanadTO:SanadTO)->List[NarratorTO]:
        return None
    

    def authenticateSanad(self,sanadTO:SanadTO)->str:
        return None

    
    def insertOpinion(self,narratorTO:NarratorTO,opinion:str)->bool:
        return None

    
    def getSanad(self,matn:str)->List[NarratorTO]:
        return None