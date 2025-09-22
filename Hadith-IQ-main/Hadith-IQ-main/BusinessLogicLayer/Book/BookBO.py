from typing import List
from BusinessLogicLayer.Book.AbsBookBO import AbsBookBO
from DataAccessLayer.Fascade.AbsDALFascade import AbsDALFascade
from DataAccessLayer.DataModels import Book


class BookBO(AbsBookBO):
    def __init__(self, dalFascade: AbsDALFascade):
        self.__dalFascade = dalFascade

    @property
    def dalFascade(self) -> AbsDALFascade:
        return self.__dalFascade

    @dalFascade.setter
    def dalFascade(self, value):
        self.__dalFascade = value
    
    def getAllBooks(self)->List[str]:
        return self.__dalFascade.getAllBooks()
    def getBooksOfProject(self, project_name: str) -> List[str]:
        return self.__dalFascade.getBooksOfProject(project_name)

        
