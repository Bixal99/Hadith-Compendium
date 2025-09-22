class HadithTO:
    def __init__(self,hadithID:int,matn:str,matnEmbedding: str,hadithAuthenticity: str,bookName :str,cleanedMatn :str,root:str,matnwithoutarab:str):
        self.__hadithId = hadithID
        self.__matn = matn
        self.__matnEmbedding = matnEmbedding
        self.__hadithAuthenticity = hadithAuthenticity
        self.__bookName=bookName
        self.__cleanedMatn=cleanedMatn
        self.__root=root
        self.__matnwithoutarab=matnwithoutarab
    
    @property
    def hadithId(self)->int:
        return self.__hadithId
    @hadithId.setter
    def hadithId(self,value:int):
        self.__hadithId=value

    @property
    def root(self)->str:
        return self.__root
    @root.setter
    def root(self,value:str):
        self.__root=value
    
    @property
    def matnwithoutarab(self)->str:
        return self.__matnwithoutarab
    @matnwithoutarab.setter
    def matnwithoutarab(self,value:str):
        self.__matnwithoutarab=value
    
    @property
    def matn(self)->str:
        return self.__matn
    @matn.setter
    def matn(self,value:str):
        self.__matn = value

    @property
    def matnEmbedding(self)->str:
        return self.__matnEmbedding
    @matnEmbedding.setter
    def matnEmbedding(self,value:str):
        self.__matnEmbedding = value
    
    @property
    def hadithAuthenticity(self)->str:
        return self.__hadithAuthenticity
    @hadithAuthenticity.setter
    def hadithAuthenticity(self,value:str):
        self.__hadithAuthenticity=value

    @property
    def bookName(self)->str:
        return self.__bookName
    @bookName.setter
    def bookName(self,value:str):
        self.__bookName=value
    
    @property
    def cleanedMatn(self)->str:
        return self.__cleanedMatn
    @cleanedMatn.setter
    def cleanedMatn(self,value:str):
        self.__cleanedMatn=value