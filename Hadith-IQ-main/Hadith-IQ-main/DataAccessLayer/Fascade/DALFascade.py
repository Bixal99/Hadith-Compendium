import datetime
from typing import Dict, List
from DataAccessLayer.Book.AbsBookDAO import AbsBookDAO
from DataAccessLayer.Fascade.AbsDALFascade import AbsDALFascade
from DataAccessLayer.Narrator.AbsNarratorDAO import AbsNarratorDAO
from DataAccessLayer.Project.AbsProjectDAO import AbsProjectDAO
from DataAccessLayer.Sanad.AbsSanadDAO import AbsSanadDAO
from TO.HadithTO import HadithTO
from DataAccessLayer.Hadith.AbsHadithDAO import AbsHadithDAO
from TO.NarratorTO import NarratorTO
from TO.ProjectTO import ProjectTO
from TO.SanadTO import SanadTO
class DALFascade(AbsDALFascade):
    
    #ABSHadithDAO initializer
    def __init__(self,projectDAO:AbsProjectDAO, bookDAO: AbsBookDAO, hadithDAO:AbsHadithDAO, sanadDAO:AbsSanadDAO,  narratorDAO:AbsNarratorDAO):     
        self.__projectDAO=projectDAO
        self.__bookDAO = bookDAO
        self.__hadithDAO=hadithDAO
        self.__sanadDAO=sanadDAO
        self.__narratorDAO=narratorDAO
  
    #AbsProject Functions

    def createProject(self,name:str, creationDate: str)->bool:
        return self.__projectDAO.createProject(name, creationDate)
    
    def renameProject(self,currName:str,newName:str)->bool:
        return self.__projectDAO.renameProject(currName, newName)
    
    def getProjects(self) -> List[ProjectTO]:
        return self.__projectDAO.getProjects()
    
    def deleteProject(self, projectName: str) -> bool:
        return self.__projectDAO.deleteProject(projectName)
    
    def saveProjectState(self,name:str, stateData: List[str],query:str)->bool:
        return self.__projectDAO.saveProjectState(name,stateData,query)
    
    def getProjectState(self,name:str)->List[str]:
        return self.__projectDAO.getProjectState(name)
    def getSingleProjectState(self,name:str,query:str)->List[str]:
      return self.__projectDAO.getSingleProjectState(name,query)
    def mergeProjectState(self, projectname: str, query_names: List[str], queryname: str) -> bool:
        return self.__projectDAO.mergeProjectState(projectname,query_names,queryname)
    def renameQueryOfState(self, project_name: str, old_query_name: str, new_query_name: str) -> bool:
        return self.__projectDAO.renameQueryOfState(project_name,old_query_name,new_query_name)
    def deleteState(self, project_name: str, query_name: str) -> bool:
        return self.__projectDAO.deleteState(project_name,query_name)
    def removeHadithFromState(self, matn: List[str], projectName: str, stateQuery: str) -> bool:
        return self.__projectDAO.removeHadithFromState(matn,projectName,stateQuery)
    def get_project_stats(self, projectName: str) -> dict:
        return self.__projectDAO.get_project_stats(projectName)
      
    
    #AbsBook Functions

    def insertBook(self,bookName:str)->bool:
        return self.__bookDAO.insertBook(bookName)

    def deleteBook(self,bookName:str)->bool:
        return self.__bookDAO.deleteBook(bookName)
    
    def importBook(self, filePath: str) -> List[Dict[str, str]]:
        return self.__bookDAO.importBook(filePath)
    
    def associate_book_with_project(self, book_name: str, project_name: str):
        return self.__bookDAO.associate_book_with_project(book_name,project_name)
    def getAllBooks(self)->List[str]:
        return self.__bookDAO.getAllBooks()
    
    #AbsHadith Functions
    
    def insertHadith(self, hadithTO: HadithTO) -> bool:
        return self.__hadithDAO.insertHadith(hadithTO)

    
    def getProjectHadithsEmbedding(self, projectName:str) -> dict:
        return self.__hadithDAO.getProjectHadithsEmbedding(projectName)
    def getAllHadithsEmbeddings(self) -> dict:
        return self.__hadithDAO.getAllHadithsEmbeddings()
    
    def getHadithFirstNarrator(self, hadith:str) -> str:
        return self.__hadithDAO.getHadithFirstNarrator(hadith)
    
    def associate_hadiths_with_project(self, book_name: str, projectName: str):
        return self.__hadithDAO.associate_hadiths_with_project(book_name,projectName)
    def getAllHadithsOfProject(self, projectName: str,page:int) -> dict:
        return self.__hadithDAO.getAllHadithsOfProject(projectName,page)
    def getHadithDetails(self, matn: str, projectName: str) -> dict:
        return self.__hadithDAO.getHadithDetails(matn,projectName)
    def getAllHadiths(self, page: int) -> dict:
        return self.__hadithDAO.getAllHadiths(page)
    def searchHadithByNarrator(self, project_name: str, narrator_name: str, page: int) -> dict:
        return self.__hadithDAO.searchHadithByNarrator(project_name,narrator_name,page)
    def stringBasedSearch(self, query: str, project_name: str) -> List[str]:
        return self.__hadithDAO.stringBasedSearch(query,project_name)
    def rootBasedSearch(self, query: str, project_name: str, page: int) -> dict:
        return self.__hadithDAO.rootBasedSearch(query,project_name,page)
    def operatorBasedSearch(self,query:str,project_name:str)->List[str]:
        return self.__hadithDAO.operatorBasedSearch(query,project_name)
    
    #AbsSanad Function
    
    def insertSanad(self, sanadTO: SanadTO) -> bool:
        return self.__sanadDAO.insertSanad( sanadTO)

    def getSanad(self,matn:str)->List[SanadTO]:
        return self.__sanadDAO.getSanad(matn)
    
    def associate_sanads_with_project_by_book(self,book_name: str, projectName: str):
        return self.__sanadDAO.associate_sanads_with_project_by_book(book_name,projectName)
   


    #AbsNarrator Function
    def insertNarrator(self,sanad: str, narratorTO : NarratorTO)->bool:
        return self.__narratorDAO.insertNarrator(sanad, narratorTO)
    
    def getSimilarNarrator(self,narratorName:str)->dict:
        return self.__narratorDAO.getSimilarNarrator(narratorName)
    def sortNarrators(self,project_name: str,narrator_list: List[str],ascending: bool,authenticity:bool) -> List[str]:
        return self.__narratorDAO.sortNarrators(project_name,narrator_list,ascending,authenticity)
    
    def getNarratorDetails(self,narratorName:str,projectName:str)->dict:
        return self.__narratorDAO.getNarratorDetails(narratorName,projectName)
    def getAllNarratorsOfProject(self, project_name: str,page:int) -> dict:
        return self.__narratorDAO.getAllNarratorsOfProject(project_name,page)
    def getAllNarrators(self, page: int) -> dict:
        return self.__narratorDAO.getAllNarrators(page)
    def getNarratedHadiths(self, project_name: str, narrator_name: str) -> dict:
        return self.__narratorDAO.getNarratedHadiths(project_name,narrator_name)
    def getBooksOfProject(self, project_name: str) -> List[str]:
        return self.__bookDAO.getBooksOfProject(project_name)
    def importNarratorDetails(self,narratorName:str,narratorTeacher:List[str],narratorStudent:List[str],opinion:List[str],scholar:List[str],final_opinion:str,authenticity:float)->bool:
        return self.__narratorDAO.importNarratorDetails(narratorName,narratorTeacher,narratorStudent,opinion,scholar,final_opinion,authenticity)
    def getSimilarNarratorName(self,narratorName:str)->dict:
        return self.__narratorDAO.getSimilarNarratorName(narratorName)
    def associateHadithNarratorWithNarratorDetails(self, projectName: str, narrator_name: str, detailed_narrator_name: str) -> bool:
        return self.__narratorDAO.associateHadithNarratorWithNarratorDetails(projectName,narrator_name,detailed_narrator_name)

    def getNarratorStudent(self, narratorName: str, projectName: str) -> str:
        return self.__narratorDAO.getNarratorStudent(narratorName,projectName)
    def getNarratorTeacher(self, narratorName: str, projectName: str) -> str:
        return self.__narratorDAO.getNarratorTeacher(narratorName,projectName)
    def updateHadithNarratorAssociation(self, projectName: str, narrator_name: str, new_detailed_narrator_name: str) -> bool:
        return self.__narratorDAO.updateHadithNarratorAssociation(projectName,narrator_name,new_detailed_narrator_name)
    def deleteHadithNarratorAssociation(self, projectName: str, narrator_name: str) -> bool:
        return self.__narratorDAO.deleteHadithNarratorAssociation(projectName,narrator_name)
    def getNarratorChains(self, project_name: str, narrator_name: str) -> dict:
        return self.__narratorDAO.getNarratorChains(project_name, narrator_name)
    
      