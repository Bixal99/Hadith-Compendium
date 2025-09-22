from typing import Dict, List
import pandas as pd
from DataAccessLayer.Book.AbsBookDAO import AbsBookDAO
from DataAccessLayer.DataModels import Book, Project
from DataAccessLayer.DbConnection import DbConnectionModel
from DataAccessLayer.UtilDAO import UtilDao
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError


class BookDAO(AbsBookDAO):
    def __init__(self, dbConnection: DbConnectionModel, util: UtilDao):
        self.__dbConnection = dbConnection
        self.__util = util

    def insertBook(self, bookName: str) -> bool:
        try:
            session: Session = self.__dbConnection.getSession()
            book = session.query(Book).filter_by(bookname=bookName).first()
            if not book:
                book = Book(bookname=bookName)
                session.add(book)
                session.commit()

            session.commit()
            print(f"Book '{bookName}' added successfully.")
            return True

        except SQLAlchemyError as e:
            session.rollback()
            print(f"Error: {e}")
            return False
        

    # def update_progress(self, task_id, progress):
    #     progress_record = self.session.query(Progress).filter_by(task_id=task_id).first()
    #     if progress_record:
    #         progress_record.progress = progress
    #     else:
    #         new_progress = Progress(task_id=task_id, progress=progress)
    #         self.session.add(new_progress)
    #     self.session.commit()

    def deleteBook(self, bookName: str) -> bool:
        return False
    
    def importBook(self,filePath: str) -> List[Dict[str, str]]:
        try:
            dataFrame = pd.read_csv(filePath)
            
            result_data = []

            if not dataFrame.isnull().values.any():
                for index, row in dataFrame.iterrows():
                        _book = row["Book"]

                        # Only process rows where "Book" is not empty
                        if _book is not None and _book != "":
                            _sanad = row["Sanad"]
                            _matn = row["Matn"]

                            sanad_dict = {
                                "matn": _matn,
                                "bookname": _book,
                                "sanad": _sanad
                            }

                            result_data.append(sanad_dict)

                return result_data

            return []

        except Exception as e:
            print("Exception", e)
            return []

    


    def importBookdsdksm(self, projectName: str, filePath: str) -> List[Dict[str, str]]:
        try:
            dataFrame = pd.read_csv(filePath)
            
            _projectID = self.__util.getProjectId(projectName)

            # If project ID is valid, proceed with processing
            if _projectID != -1:
                result_data = []

                if not dataFrame.isnull().values.any():
                    for index, row in dataFrame.iterrows():
                        _book = row["Book"]

                        # Only process rows where "Book" is not empty
                        if _book is not None and _book != "":
                            _sanad = row["Sanad"]
                            _matn = row["Matn"]

                            sanad_dict = {
                                "matn": _matn,
                                "bookname": _book,
                                "sanad": _sanad
                            }

                            result_data.append(sanad_dict)

                return result_data

            return []

        except Exception as e:
            print("Exception", e)
            return []

    def associate_book_with_project(self, book_name: str, project_name: str):
        try:
                session: Session = self.__dbConnection.getSession()
                book = session.query(Book).filter(Book.bookname == book_name).first()
                if not book:
                    print(f"No book found with name '{book_name}'")
                    return False
                project = session.query(Project).filter(Project.projectname == project_name).first()
                if not project:
                    print(f"No project found with name '{project_name}'")
                    return False
                if book not in project.books:
                    project.books.append(book)
                    session.commit()
                    print(f"Book '{book_name}' successfully linked to Project '{project_name}'")
                    return True
                else:
                    print(f"Book '{book_name}' is already linked to Project '{project_name}'")
        except SQLAlchemyError as e:
                session.rollback()
                print(f"Error: {e}")
                return False
    
    def getAllBooks(self)->List[str]:
        try:
            books = []
            session: Session = self.__dbConnection.getSession()
            results = session.query(Book).all()
            for book in results:
                books.append(book.bookname)
            return books
        except Exception as e:
            print(f"Error in get books: {e}")
            return []
        finally:
            session.close()

    def getBooksOfProject(self, project_name: str) -> List[str]:
        try:
            books = []
            session: Session = self.__dbConnection.getSession()

            project = session.query(Project).filter(Project.projectname == project_name).first()
            if project and hasattr(project, "books"):
                for book in project.books:
                    books.append(book.bookname)

            return books
        except SQLAlchemyError as e:
            print(f"Error fetching books for project '{project_name}': {e}")
            return []
        finally:
            session.close()

