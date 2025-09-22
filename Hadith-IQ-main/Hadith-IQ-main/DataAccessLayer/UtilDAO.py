from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from DataAccessLayer.DataModels import Project, Book, Hadith, Narrator, Sanad
from DataAccessLayer.DbConnection import DbConnectionModel

class UtilDao:
    def __init__(self, db_connection: DbConnectionModel):
        self.__db_connection = db_connection

    def getHadithId(self, matn: str) -> int:
        try:
            session: Session = self.__db_connection.getSession()
            result = session.query(Hadith.hadithid).filter(Hadith.matn == matn).first()
            if result:
                return result.hadithid
            return -1
        except SQLAlchemyError as e:
            print(f"Error fetching Hadith ID: {e}")
            return -1
        
    def getSanadId(self, sanad: str) -> int:
        try:
            session: Session = self.__db_connection.getSession()
            result = session.query(Sanad.sanadid).filter(Sanad.sanad == sanad).first()
            if result:
                return result.sanadid
            return -1
        except SQLAlchemyError as e:
            print(f"Error fetching Sanad ID: {e}")
            return -1

    def getNarratorId(self, narrator_name: str) -> int:
        try:
            session: Session = self.__db_connection.getSession()
            result = session.query(Narrator.narratorid).filter(Narrator.narratorname == narrator_name).first()
            if result:
                return result.narratorid
            return -1
        except SQLAlchemyError as e:
            print(f"Error fetching Narrator ID: {e}")
            return -1

    def getProjectId(self, project_name: str) -> int:
        try:
            session: Session = self.__db_connection.getSession()
            result = session.query(Project.projectid).filter(Project.projectname == project_name).first()
            if result:
                return result.projectid
            return -1
        except SQLAlchemyError as e:
            print(f"Error fetching Project ID: {e}")
            return -1
        
    # def getBookId(self, book_name: str) -> int:
    #     try:
    #         session: Session = self.__db_connection.getSession()
    #         result = session.query(Book.BookID).filter(Book.BookName == book_name).first()
    #         if result:
    #             return result.BookID
    #         return -1
    #     except SQLAlchemyError as e:
    #         print(f"Error fetching Hadith ID: {e}")
    #         return -1

    def getBookId(self, book_name: str) -> int:
        try:
            cursor = self.__db_connection.getConnection().cursor()
            query = "SELECT bookid FROM books WHERE bookname = %s LIMIT 1"
            cursor.execute(query, (book_name,))
            result = cursor.fetchone()
            return result[0] if result else -1
        except Exception as e:
            print(f"Error fetching book Id: {e}")
            return -1
