import re
from DataAccessLayer.DbConnection import DbConnectionModel
from DataAccessLayer.Project.AbsProjectDAO import AbsProjectDAO
from DataAccessLayer.UtilDAO import UtilDao
from TO.ProjectTO import ProjectTO
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from DataAccessLayer.DataModels import Hadith, Project,ProjectState,hadith_book,hadith_project,Sanad,sanad_project,project_narrator,hadith_sanad,Narrator,NarratorDetailed,Book,book_project,narrator_sanad
from typing import List, Dict,Set
import json
from datetime import datetime,timezone
from sqlalchemy import func, desc


class ProjectDAO(AbsProjectDAO):

    def __init__(self, dbConnection: DbConnectionModel, util: UtilDao):
        self.__dbConnection = dbConnection
        self.__util = util

    def createProject(self, name: str, creationDate: str) -> bool:
        try:
            newProject = Project(projectname=name)

            session: Session = self.__dbConnection.getSession()
            session.add(newProject)
            session.commit()

            # If commit successful
            if newProject.projectid:
                print("Project added successfully.")
                return True
            else:
                print("Project not inserted.")
                return False
        except SQLAlchemyError as e:
            session.rollback()
            print(f"Error: {e}")
            return False
        finally:
            session.close()

    def saveProject() -> bool:
        return None

    def renameProject(self, currName: str, newName: str) -> bool:
        try:
            session: Session = self.__dbConnection.getSession()
            project = session.query(Project).filter_by(projectname=currName).first()
            if not project:
                print(f"Project with name '{currName}' not found.")
                return False
            if project.projectname != currName:
                print(f"Project with name '{currName}' is not same as '{project.projectname}'.")
                return False
            
            project.projectname = newName
            session.commit()
            return True
        except SQLAlchemyError as e:
            session.rollback()
            print(f"Error renaming project: {e}")
            return False

        finally:
            session.close()

    def getProjects(self) -> List[ProjectTO]:
        try:
            projects = []
            session: Session = self.__dbConnection.getSession()
            results = session.query(Project).all()
            for project in results:
                projectTO = ProjectTO(
                    project.projectid,
                    project.projectname,
                    project.lastupdated.strftime("%d-%m-%Y") if project.lastupdated else None,
                    project.createdat.strftime("%d-%m-%Y") if project.createdat else None,
                )
                projects.append(projectTO)
            return projects
        except Exception as e:
            print(f"Error in getProjects: {e}")
            return []
        finally:
            session.close()


    def deleteProject(self, projectName: str) -> bool:
        try:
            session: Session = self.__dbConnection.getSession()
            project = session.query(Project).filter_by(projectname=projectName).first()
            
            if not project:
                print(f"Project with name '{projectName}' not found.")
                return False
            
            session.delete(project)
            session.commit()
            return True

        except SQLAlchemyError as e:
            session.rollback()
            print(f"Error deleting project: {e}")
            return False

        finally:
            session.close()

##################################################################ProjectState

    def saveProjectStatewqwqqwwwqwqw(self, projectName: str, stateData: list, query: str) -> bool:
        session = None
        try:
            projectId = self.__util.getProjectId(projectName)
            if projectId == -1:
                print(f"Project with name '{projectName}' not found.")
                return False

            session: Session = self.__dbConnection.getSession()
            hadith_ids = []
            for matn in stateData:
                hadith_id = self.__util.getHadithId(matn)
                if hadith_id != -1:
                    hadith_ids.append(hadith_id)
                else:
                    print(f"Hadith with matn '{matn}' not found.")

            new_state_str = ",".join(map(str, hadith_ids))
            state_entry = session.query(ProjectState).filter(
                ProjectState.projectid == projectId,
                ProjectState.query == query
            ).first()

            if state_entry:
                # Update the existing state entry
                stored_data = state_entry.statedata.strip('"') if isinstance(state_entry.statedata, str) else ""
                existing_hadiths = set(map(int, stored_data.split(","))) if stored_data else set()
                combined_hadiths = sorted(existing_hadiths.union(set(hadith_ids)))
                updated_state_str = ",".join(map(str, combined_hadiths))

                # Use synchronize_session='fetch' to ensure session consistency
                session.query(ProjectState).filter(
                    ProjectState.projectid == projectId,
                    ProjectState.query == query
                ).update(
                    {"statedata": updated_state_str},
                    synchronize_session='fetch'
                )
            else:
                new_state = ProjectState(
                    projectid=projectId,
                    query=query,
                    statedata=new_state_str
                )
                session.add(new_state)

            project_entry = session.query(Project).filter_by(projectid=projectId).first()
            if project_entry:
                project_entry.lastupdated = datetime.now(timezone.utc)

            session.commit()
            print("Project state saved successfully, and LastUpdated time updated.")
            return True

        except SQLAlchemyError as e:
            if session:
                session.rollback()
            print(f"Error saving project state: {e}")
            return False
        finally:
            if session:
                session.close()

    def saveProjectState(self, projectName: str, stateData: list, query: str) -> bool:
        session = None
        try:
            projectId = self.__util.getProjectId(projectName)
            if projectId == -1:
                print(f"Project with name '{projectName}' not found.")
                return False

            session: Session = self.__dbConnection.getSession()
            hadith_ids = []
            for matn in stateData:
                hadith_id = self.__util.getHadithId(matn)
                if hadith_id != -1:
                    hadith_ids.append(hadith_id)
                else:
                    print(f"Hadith with matn '{matn}' not found.")

            new_state_str = ",".join(map(str, hadith_ids))
            state_entry = session.query(ProjectState).filter(
            ProjectState.projectid == projectId,
            ProjectState.query == query
        ).first()

            if state_entry:
                stored_data = state_entry.statedata.strip('"') if isinstance(state_entry.statedata, str) else ""

                # **NEW CHECK: If `statedata` is empty, delete the existing entry**
                if stored_data == "":
                    session.query(ProjectState).filter(
                        ProjectState.projectid == projectId,
                        ProjectState.query == query  # Ensure only this query is deleted
                    ).delete(synchronize_session=False)  
                    session.commit()  # Ensure deletion before creating a new entry
                    state_entry = None  # Reset to None to trigger new state creation

            if state_entry is None:
                # Create a new state entry
                new_state = ProjectState(
                    projectid=projectId,
                    query=query,
                    statedata=new_state_str
                )
                session.add(new_state)
            else:
                # Update the existing state entry
                existing_hadiths = set(map(int, stored_data.split(","))) if stored_data else set()
                combined_hadiths = sorted(existing_hadiths.union(set(hadith_ids)))
                updated_state_str = ",".join(map(str, combined_hadiths))

                session.query(ProjectState).filter(
                    ProjectState.projectid == projectId,
                    ProjectState.query == query
                ).update(
                    {"statedata": updated_state_str},
                    synchronize_session='fetch'
                )

            project_entry = session.query(Project).filter_by(projectid=projectId).first()
            if project_entry:
                project_entry.lastupdated = datetime.now(timezone.utc)

            session.commit()
            print("Project state saved successfully, and LastUpdated time updated.")
            return True

        except SQLAlchemyError as e:
            if session:
                session.rollback()
            print(f"Error saving project state: {e}")
            return False
        finally:
            if session:
                session.close()




    def getProjectState(self, projectName: str) -> List[str]:
        session = None
        try:
            projectId = self.__util.getProjectId(projectName)
            if projectId == -1:
                print(f"Project with name '{projectName}' not found.")
                return []

            session: Session = self.__dbConnection.getSession()
            state_entries = session.query(ProjectState.query).filter(
                ProjectState.projectid == projectId
            ).all()
            
            if not state_entries:
                print(f"No project state found for '{projectName}'.")
                return []
            
            result = [entry.query for entry in state_entries]
            
            return result

        except SQLAlchemyError as e:
            print(f"Error fetching project state: {e}")
            return []
        finally:
            if session:
                session.close()

    def clean_hadith_id(self,hadith_id: str) -> str:
        cleaned_id = re.sub(r"[^\d]", "", hadith_id)
        return cleaned_id


    def getSingleProjectState(self, projectName: str, query_names: str) -> List[str]:
        project_id = self.__util.getProjectId(projectName)
        if project_id == -1:
            print(f"Project with name '{projectName}' not found.")
            return []

        session: Session = self.__dbConnection.getSession()
        try:
            state = session.query(ProjectState).filter(
                ProjectState.projectid == project_id,
                ProjectState.query == query_names
            ).first()

            if state and state.statedata:
                hadith_ids = state.statedata.strip('"').split(",") if state.statedata else []
                print("Hadith IDs:", hadith_ids)
                matn_list = []
                for hadith_id in hadith_ids:
                    cleaned_id = self.clean_hadith_id(hadith_id)
                    if cleaned_id:
                        hadith = session.query(Hadith).filter(Hadith.hadithid == int(cleaned_id)).first()
                        if hadith:
                            matn_list.append(hadith.matn)

                return matn_list
            else:
                print(f"No state data found for query '{query_names}'.")
                return []
        finally:
            session.close()

    def mergeProjectState(self, projectname: str, query_names: List[str], queryname: str) -> bool:
        session = None
        try:
            projectId = self.__util.getProjectId(projectname)
            if projectId == -1:
                print(f"Project with name '{projectname}' not found.")
                return False

            session: Session = self.__dbConnection.getSession()
            existing_state = session.query(ProjectState).filter(
                ProjectState.projectid == projectId,
                ProjectState.query == queryname
            ).first()

            if existing_state:
                print(f"Error: Query name '{queryname}' already exists in the database.")
                return False
            session.close()
            merged_hadith_ids = set() 
            for query in query_names:
                session: Session = self.__dbConnection.getSession()
                state = session.query(ProjectState).filter(
                    ProjectState.projectid == projectId,
                    ProjectState.query == query
                ).first()

                if state and state.statedata:
                    cleaned_data = state.statedata.strip('"')
                    print(f"Cleaned data for query '{query}': {cleaned_data}")
                    hadith_ids = cleaned_data.split(",") if cleaned_data else []
                    print(f"Hadith IDs for query '{query}': {hadith_ids}")
                    for hadith_id in hadith_ids:
                        stripped_id = hadith_id.strip()
                        if stripped_id.isdigit():
                            merged_hadith_ids.add(stripped_id)
                        else:
                            print(f"Invalid hadith_id '{hadith_id}' in query '{query}'")
                else:
                    print(f"No state data found for query '{query}'")
                session.close()
            if not merged_hadith_ids:
                print(f"No valid state data found for queries '{', '.join(query_names)}'.")
                return False

            new_state_data_str = ",".join(sorted(merged_hadith_ids, key=int))  
            print(f"Merged state data: {new_state_data_str}")

            new_state = ProjectState(
                projectid=projectId,
                query=queryname,
                statedata=new_state_data_str
            )
            session.add(new_state)

            project_entry = session.query(Project).filter_by(projectid=projectId).first()
            if project_entry:
                project_entry.lastupdated = datetime.now(timezone.utc)

            session.commit()
            print(f"Merged state saved as '{queryname}'.")
            return True

        except SQLAlchemyError as e:
            if session:
                session.rollback()
            print(f"Error merging project state: {e}")
            return False
        finally:
            if session:
             session.close()


    
    def renameQueryOfState(self, project_name: str, old_query_name: str, new_query_name: str) -> bool:
        session = None
        try:
            project_id = self.__util.getProjectId(project_name)
            if project_id == -1:
                print(f"Project with name '{project_name}' not found.")
                return False

            session: Session = self.__dbConnection.getSession()
            existing_state = session.query(ProjectState).filter(
                ProjectState.projectid == project_id,
                ProjectState.query == new_query_name
            ).first()

            if existing_state:
                print(f"Error: Query name '{new_query_name}' already exists in the database.")
                return False
            old_states = session.query(ProjectState).filter(
                ProjectState.projectid == project_id,
                ProjectState.query == old_query_name
            )
            count = old_states.count() 
            print(f"Found {count} rows matching '{old_query_name}'.")

            if count == 0:
                print(f"No states found for query '{old_query_name}'.")
                return False
            old_states.update({ProjectState.query: new_query_name}, synchronize_session=False)

            project_entry = session.query(Project).filter_by(projectid=project_id).first()
            if project_entry:
                project_entry.lastupdated = datetime.now(timezone.utc)

            session.commit()
            print(f"Query '{old_query_name}' renamed to '{new_query_name}' and states updated.")
            return True

        except SQLAlchemyError as e:
            if session:
                session.rollback()
            print(f"Error renaming query: {e}")
            return False
        finally:
            if session:
                session.close()
    def deleteState(self, project_name: str, query_name: str) -> bool:
        session = None
        try:
            project_id = self.__util.getProjectId(project_name)
            if project_id == -1:
                print(f"Project with name '{project_name}' not found.")
                return False
            session: Session = self.__dbConnection.getSession()
            states_to_delete = session.query(ProjectState).filter(
                ProjectState.projectid == project_id,
                ProjectState.query == query_name
            )
            count = states_to_delete.count()
            if count == 0:
                print(f"No states found for query '{query_name}' in project '{project_name}'.")
                return False
            states_to_delete.delete(synchronize_session=False)
            project_entry = session.query(Project).filter_by(projectid=project_id).first()
            if project_entry:
                project_entry.lastupdated = datetime.now(timezone.utc)
            session.commit()
            print(f"Deleted {count} states for query '{query_name}' in project '{project_name}'.")
            return True

        except SQLAlchemyError as e:
            if session:
                session.rollback()
            print(f"Error deleting state: {e}")
            return False
        finally:
            if session:
                session.close()

    def removeHadithFromState(self, matn_list: List[str], projectName: str, stateQuery: str) -> bool:
        session = None
        try:
            session: Session = self.__dbConnection.getSession()
            project_id = self.__util.getProjectId(projectName)
            if project_id == -1:
                print(f"Project with name '{projectName}' not found.")
                return False

            existing_state = session.query(ProjectState).filter(
                ProjectState.projectid == project_id,
                ProjectState.query == stateQuery
            ).first()

            if not existing_state:
                print(f"No state found for project ID '{project_id}' and query '{stateQuery}'.")
                return False
            existing_state_query = existing_state.statedata
            updated_state_query = existing_state_query

            for matn in matn_list:
                hadith_id = self.__util.getHadithId(matn)
                if not hadith_id:
                    print(f"No hadith_id found for matn: '{matn}'.")
                    continue  
                if str(hadith_id) not in updated_state_query:
                    print(f"Hadith ID '{hadith_id}' not found in stateQuery for matn: '{matn}'.")
                    continue  
                updated_state_query = self.remove_hadith_id_from_state_query(updated_state_query, str(hadith_id))
                print(f"Hadith ID '{hadith_id}' successfully removed from stateQuery for matn: '{matn}'.")
                updated_state_query = updated_state_query.strip(",") 
                updated_state_query = updated_state_query.strip('"')  
            
            session.query(ProjectState).filter(
                ProjectState.projectid == project_id,
                ProjectState.query == stateQuery
            ).update(
                {"statedata": updated_state_query},
                synchronize_session='fetch'
            )
            session.commit()
            print("State updated successfully.")
            project_entry = session.query(Project).filter_by(projectid=project_id).first()
            if project_entry:
                project_entry.lastupdated = datetime.now(timezone.utc)

            session.commit()
            print("Project state saved successfully, and LastUpdated time updated.")
            return True

        except SQLAlchemyError as e:
            if session:
                session.rollback()
            print(f"Error deleting state: {e}")
            return False
        finally:
            if session:
                session.close()

    def remove_hadith_id_from_state_query(self, stateQuery: str, hadith_id: str) -> str:
        updated_state_query = stateQuery.replace(f",{hadith_id},", ",")
        updated_state_query = updated_state_query.replace(f"{hadith_id},", "")
        updated_state_query = updated_state_query.replace(f",{hadith_id}", "")
        updated_state_query = updated_state_query.replace(f"{hadith_id}", "")
        return updated_state_query.strip(",")

    def get_project_stats(self, projectName: str) -> dict:
        session = None
        try:
            session: Session = self.__dbConnection.getSession()
            project = session.query(Project).filter(Project.projectname == projectName).first()
            
            if not project:
                print(f"Project with name '{projectName}' not found.")
                return False

            project_id = project.projectid

            # 1. Count of books
            book_count = session.query(func.count(func.distinct(book_project.c.bookid)))\
                .filter(book_project.c.projectid == project_id).scalar()

            # 2. Count of hadiths
            hadith_count = session.query(func.count(hadith_project.c.hadithid))\
                .filter(hadith_project.c.projectid == project_id).scalar()

            # 3. Count of sanads
            sanad_count = session.query(func.count(sanad_project.c.sanadid))\
                .filter(sanad_project.c.projectid == project_id).scalar()

            # 4. Count of distinct narrators in project through sanads
            sanad_narrator_count = session.query(func.count(func.distinct(narrator_sanad.c.narratorid)))\
                .join(sanad_project, narrator_sanad.c.sanadid == sanad_project.c.sanadid)\
                .filter(sanad_project.c.projectid == project_id).scalar()

            # 5. Count of distinct narrators in project through project_narrator
            project_narrator_count = session.query(func.count(func.distinct(project_narrator.c.narrator_id)))\
                .filter(project_narrator.c.project_id == project_id).scalar()

            # 6. Narrator opinion distribution from narrator_detailed
            narrator_opinion_stats = session.query(
                    NarratorDetailed.final_opinion,
                    func.count(NarratorDetailed.narrator_detailed_id).label('count')
                )\
                .join(project_narrator, NarratorDetailed.narrator_detailed_id == project_narrator.c.narrator_detailed_id)\
                .filter(project_narrator.c.project_id == project_id)\
                .group_by(NarratorDetailed.final_opinion)\
                .all()

            # 7. Hadith count by book
            hadiths_by_book = session.query(
                    Book.bookid, 
                    Book.bookname, 
                    func.count(hadith_book.c.hadithid)
                )\
                .join(book_project, Book.bookid == book_project.c.bookid)\
                .join(hadith_book, Book.bookid == hadith_book.c.bookid)\
                .filter(book_project.c.projectid == project_id)\
                .group_by(Book.bookid, Book.bookname)\
                .all()

            # 8. Top narrators in sanads of this project
            top_narrators = session.query(
                    Narrator.narratorid,
                    Narrator.narratorname,
                    func.count(narrator_sanad.c.narratorid).label('count')
                )\
                .join(narrator_sanad, Narrator.narratorid == narrator_sanad.c.narratorid)\
                .join(sanad_project, narrator_sanad.c.sanadid == sanad_project.c.sanadid)\
                .filter(sanad_project.c.projectid == project_id)\
                .group_by(Narrator.narratorid, Narrator.narratorname)\
                .order_by(desc('count'))\
                .limit(5)\
                .all()

            return {
                "counts": {
                    "books": book_count,
                    "hadiths": hadith_count,
                    "sanads": sanad_count,
                    "narrators_from_sanads": sanad_narrator_count,
                    "narrators_from_project": project_narrator_count,
                    "total_unique_narrators": max(sanad_narrator_count, project_narrator_count)  # or implement actual distinct count
                },
                "narrator_opinions": [
                    {"opinion": opinion, "count": count}
                    for opinion, count in narrator_opinion_stats
                ],
                "hadiths_by_book": [
                    {"book_id": b_id, "title": title, "hadith_count": count}
                    for b_id, title, count in hadiths_by_book
                ],
                "top_narrators": [
                    {"narrator_id": n_id, "name": name, "count": count}
                    for n_id, name, count in top_narrators
                ]
            }
        except SQLAlchemyError as e:
            if session:
                session.rollback()
            print(f"Error getting project stats: {e}")
            return False
        finally:
            if session:
                session.close()