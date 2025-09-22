from BusinessLogicLayer.Fascade.AbsBLLFascade import AbsBLLFascade
from BusinessLogicLayer.Hadith.AbsHadithBO import AbsHadithBO
from BusinessLogicLayer.Narrator.AbsNarratorBO import AbsNarratorBO
from BusinessLogicLayer.Project.AbsProjectBO import AbsProjectBO
from BusinessLogicLayer.Book.AbsBookBO import AbsBookBO
from TO.SanadTO import SanadTO
from TO.HadithTO import HadithTO
from TO.ProjectTO import ProjectTO
from TO.NarratorTO import NarratorTO
from typing import List, Dict


class BLLFascade(AbsBLLFascade):

    def __init__(
        self,
        hadithBO: AbsHadithBO,
        projectBO: AbsProjectBO,
        narratorBO: AbsNarratorBO,
        bookBO:AbsBookBO,
    ):
        self.__hadithBO = hadithBO
        self.__narratorBO = narratorBO
        self.__projectBO = projectBO
        self.__bookBO=bookBO

    # projectBo functions

    def createProject(self, name: str) -> bool:
        return self.__projectBO.createProject(name)

    def deleteProject(self, name: str) -> bool:
        return self.__projectBO.deleteProject(name)

    def renameProject(self, currName: str, newName: str) -> bool:
        return self.__projectBO.renameProject(currName, newName)

    def getProjects(self) -> List[ProjectTO]:
        return self.__projectBO.getProjects()
    
    def saveProjectState(self,name:str, stateData: List[str],query:str)->bool:
        return self.__projectBO.saveProjectState(name,stateData,query)
    
    def getProjectState(self,name:str)->List[str]:
        return  self.__projectBO.getProjectState(name)

    def getSingleProjectState(self,name:str,query:str)->List[str]:
      return self.__projectBO.getSingleProjectState(name,query)
    def removeHadithFromState(self, matn: List[str], projectName: str, stateQuery: str) -> bool:
        return self.__projectBO.removeHadithFromState(matn,projectName,stateQuery)
    
    def mergeProjectState(self, projectname: str, query_names: List[str], queryname: str) -> bool:
        return self.__projectBO.mergeProjectState(projectname,query_names,queryname)
    def renameQueryOfState(self, project_name: str, old_query_name: str, new_query_name: str) -> bool:
        return self.__projectBO.renameQueryOfState(project_name,old_query_name,new_query_name)
    def deleteState(self, project_name: str, query_name: str) -> bool:
        return self.__projectBO.deleteState(project_name,query_name)
    def get_project_stats(self, projectName: str) -> dict:
        return self.__projectBO.get_project_stats(projectName)
    # AbsHadithBo Functions

    def importHadithFile(self, projectName: str, filePath: str) -> bool:
        return self.__hadithBO.importHadithFile(projectName, filePath)
    
    def importHadithFileCSV(self, filePath: str) -> bool:
        return self.__hadithBO.importHadithFileCSV(filePath)
    def getAllBooks(self):
        return self.__bookBO.getAllBooks()
    def getBooksOfProject(self, project_name: str) -> List[str]:
        return self.__bookBO.getBooksOfProject(project_name)
    def getAllHadiths(self, page: int) -> dict:
        return self.__hadithBO.getAllHadiths(page)

    def semanticSearch(self, hadith: str, projectName: str, threshold: float) -> dict:
        return self.__hadithBO.semanticSearch(hadith, projectName, threshold)

    def getHadithData(self, HadithTO: HadithTO) -> Dict:
        return self.__hadithBO.getHadithData(HadithTO)
    
    def getAllHadithsOfProject(self, projectName: str,page:int) -> dict:
        return self.__hadithBO.getAllHadithsOfProject(projectName,page)

    def sortHadith(
        self, byNarrator: bool, byGrade: bool, gradeType: str, hadithList: List[str]
    ) -> List[dict]:
        return self.__hadithBO.sortHadith(byNarrator, byGrade, gradeType, hadithList)
    
    def generateHadithFile(self, path: str, HadithTO: List[HadithTO]) -> bool:
        return self.__hadithBO.generateHadithFile(path, HadithTO)

    def expandSearch(
        self, HadithTO: List[str], projectName: str, threshold: float
    ) -> dict:
        return self.__hadithBO.expandSearch(HadithTO, projectName, threshold)
    def getHadithDetails(self, matn: str, projectName: str) -> dict:
        return self.__hadithBO.getHadithDetails(matn,projectName)
    def searchHadithByNarrator(self, project_name: str, narrator_name: str, page: int) -> dict:
        return self.__hadithBO.searchHadithByNarrator(project_name,narrator_name,page)
    def stringBasedSearch(self, query: str, project_name: str) -> List[str]:
        return self.__hadithBO.stringBasedSearch(query,project_name)
    def rootBasedSearch(self, query: str, project_name: str, page: int) -> dict:
        return self.__hadithBO.rootBasedSearch(query,project_name,page)
    def operatorBasedSearch(self,query:str,project_name:str)->List[str]:
        return self.__hadithBO.operatorBasedSearch(query,project_name)
    def hadith_rag(self, question: str, projectName: str) -> str:
        return self.__hadithBO.hadith_rag(question,projectName)

    # NarratorBO Functions
    ##
    def getNarratedHadiths(self, project_name: str, narrator_name: str) -> dict:
        return self.__narratorBO.getNarratedHadiths(project_name,narrator_name)

    def getNarratorChains(self, project_name: str, narrator_name: str) -> dict:
        return self.__narratorBO.getNarratorChains(project_name,narrator_name)

    ##
    def getNarratorTeachers(self, narratorTO: NarratorTO) -> List[NarratorTO]:
        return self.__narratorBO.getNarratorTeachers(narratorTO)

    ##
    def getNarratorStudents(self, narratorTO: NarratorTO) -> List[NarratorTO]:
        return self.__narratorBO.getNarratorStudents(narratorTO)

    ##
    def applySentimentAnalysis(self, narratorTO: NarratorTO) -> str:
        return self.__narratorBO.applySentimentAnalysis(narratorTO)

    ##
    def searchNarrator(self,narrator:str)->dict:
        return self.__narratorBO.searchNarrator(narrator)

    ##
    def getNarratorAuthenticity(self, narratorTO: NarratorTO) -> str:
        return self.__narratorBO.getNarratorAuthenticity(narratorTO)
    def importNarratorDetails(self,narratorName:str,narratorTeacher:List[str],narratorStudent:List[str],opinion:List[str],scholar:List[str])->bool:
        return self.__narratorBO.importNarratorDetails(narratorName,narratorTeacher,narratorStudent,opinion,scholar)

    
      

    ##
    def getNarratorDetails(self,narratorName:str,projectName:str)->dict:
        return self.__narratorBO.getNarratorDetails(narratorName,projectName)
    def convertHtmlToText(self,html_file: str) -> dict:
        return self.__narratorBO.convertHtmlToText(html_file)
    def cleanNarratorTxtFile(self, input_file, arabic_count)->dict:
        return self.__narratorBO.cleanNarratorTxtFile(input_file,arabic_count)

    ##
    def getAllNarratorsOfProject(self, project_name: str,page :int) -> dict:
        return self.__narratorBO.getAllNarratorsOfProject(project_name,page)
    def fetch_narrator_data(self,file_path:str,arabic_count:int)->dict:
        return self.__narratorBO.fetch_narrator_data(file_path,arabic_count)
    def getAllNarrators(self, page: int) -> dict:
        return self.__narratorBO.getAllNarrators(page)
    def sortNarrators(self,project_name: str,narrator_list: List[str],ascending: bool,authenticity:bool) -> List[str]:
        return self.__narratorBO.sortNarrators(project_name,narrator_list,ascending,authenticity)
    
    def getSimilarNarratorName(self,narratorName:str)->dict:
        return self.__narratorBO.getSimilarNarratorName(narratorName)
    def associateHadithNarratorWithNarratorDetails(self, projectName: str, narrator_name: str, detailed_narrator_name: str) -> bool:
        return self.__narratorBO.associateHadithNarratorWithNarratorDetails(projectName,narrator_name,detailed_narrator_name)
    def getNarratorStudent(self, narratorName: str, projectName: str) -> List[str]:
        return self.__narratorBO.getNarratorStudent(narratorName,projectName)
    def getNarratorTeacher(self, narratorName: str, projectName: str) -> List[str]:
        return self.__narratorBO.getNarratorTeacher(narratorName,projectName)
    def updateHadithNarratorAssociation(self, projectName: str, narrator_name: str, new_detailed_narrator_name: str) -> bool:
        return self.__narratorBO.updateHadithNarratorAssociation(projectName,narrator_name,new_detailed_narrator_name)
    def deleteHadithNarratorAssociation(self, projectName: str, narrator_name: str) -> bool:
        return self.__narratorBO.deleteHadithNarratorAssociation(projectName,narrator_name)
      

    # SanadBO Functions
    def authenticateSanad(self, sanadTO: SanadTO) -> str:
        return self.__sanadBO.authenticateSanad(sanadTO)

    def getSanad(self, matn: str) -> List[NarratorTO]:
        return self.__sanadBO.getSanad(matn)

# OpinionBo Functions
# def getOpinions(self,narratorTO:NarratorTO)->List[OpinionTO]:
#     return self.__opinionBO.getOpinions(narratorTO)
