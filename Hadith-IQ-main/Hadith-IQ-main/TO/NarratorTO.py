class NarratorTO():
    def __init__(self,narratorID:int,narratorName:str,level:int):
     self.__narratorName = narratorName
     self.__narratorID = narratorID
     self.__level = level

    @property
    def narratorName(self)->str:
       return self.__narratorName
    @narratorName.setter
    def narratorName(self,value:str):
       self.__narratorName = value
    
    @property
    def narratorID(self)->int:
       return self.__narratorID
    @narratorID.setter
    def narratorID(self,value:int):
       self.__narratorID = value

    @property
    def level(self)->int:
       return self.__level
    @level.setter
    def level(self,value:int):
       self.__level = value
    