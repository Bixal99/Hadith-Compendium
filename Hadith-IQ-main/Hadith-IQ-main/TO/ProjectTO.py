from datetime import datetime

class ProjectTO:
    def __init__(self,projectID:int,name:str,lastUpdated: str,createdAt: str):
        self.__projectID = projectID
        self.__name = name
        self.__lastUpdated = self.convert_to_string(lastUpdated)
        self.__createdAt = self.convert_to_string(createdAt)

    def convert_to_string(self, datetime_obj):
        # Check if datetime is already a string
        if isinstance(datetime_obj, datetime):
            return datetime_obj.strftime('%Y-%m-%d %H:%M:%S')
        return datetime_obj
    
    @property
    def projectID(self)->int:
        return self.__projectID
    @projectID.setter
    def projectID(self,value:int):
        self.__projectID=value
    
    @property
    def name(self)->str:
        return self.__name
    @name.setter
    def name(self,value:str):
        self.__name = value

    @property
    def lastUpdated(self)->str:
        return self.__lastUpdated
    @lastUpdated.setter
    def lastUpdated(self,value:str):
        self.__lastUpdated = value
    
    @property
    def createdAt(self)->str:
        return self.__createdAt
    @createdAt.setter
    def createdAt(self,value:str):
        self.__createdAt=value