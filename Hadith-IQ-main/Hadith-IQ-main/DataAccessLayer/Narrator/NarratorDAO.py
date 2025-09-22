from DataAccessLayer.DataModels import Narrator, Sanad, narrator_sanad,Project,Hadith,hadith_sanad,Scholars,Opinions,ScholarOpinion,NarratorDetailed,NarratorStudent,NarratorTeacher,narrator_opinion,project_narrator,hadith_project
from DataAccessLayer.Narrator.AbsNarratorDAO import AbsNarratorDAO
from typing import List,Dict
from TO.NarratorTO import NarratorTO
from TO.HadithTO import HadithTO
from DataAccessLayer.DbConnection import DbConnectionModel
from DataAccessLayer.UtilDAO import UtilDao
from sqlalchemy.orm import Session,joinedload
from sqlalchemy import func,case
import re
import traceback


class NarratorDAO(AbsNarratorDAO):
  
    def __init__(self, dbConnection: DbConnectionModel,util :UtilDao):
        self.__dbConnection = dbConnection
        self.__util=util
        self.DIACRITICS_PATTERN = re.compile(r'[\u064B-\u065F\u0670\u0610-\u061A]')
        self.__AUTHENTICITY_ORDER = {
    "positive": 1,  # Authentic
    "nuetral": 2,  # Neutral
    "negative": 3,  # Weak
    "not known": 4  # Not Known
}
    def remove_diacritics(self, text):
        """Remove diacritics (Tashkeel) from Arabic text."""
        return self.DIACRITICS_PATTERN.sub("", text)
                
    def insertNarrator(self, sanad: str, narratorTO: NarratorTO) -> bool:
        print("in narrator dao")
        session: Session = self.__dbConnection.getSession()
        try:
            sanadObj = session.query(Sanad).filter(Sanad.sanad == sanad).first()
            if not sanadObj:
                print(f"Sanad '{sanad}' not found.")
                return False
            
            _sanadID = sanadObj.sanadid
            narratorObj = session.query(Narrator).filter(Narrator.narratorname == narratorTO.narratorName).first()
            
            if not narratorObj:
                cleanname=self.remove_diacritics(narratorTO.narratorName)
                narratorObj = Narrator(
                    narratorname=narratorTO.narratorName,
                    cleanedname=cleanname
                )
                session.add(narratorObj)
                session.flush()  
            existing_association = session.query(narrator_sanad).filter(
                narrator_sanad.c.narratorid == narratorObj.narratorid,
                narrator_sanad.c.sanadid == _sanadID
            ).first()

            if existing_association:
                print(f"Narrator '{narratorTO.narratorName}' is already associated with the sanad.")
                return False

            session.execute(
                narrator_sanad.insert().values(
                    narratorid=narratorObj.narratorid,
                    sanadid=_sanadID,
                    level=narratorTO.level
                )
            )

            session.commit()
            print(f"Narrator: '{narratorTO.narratorName}' added successfully.")
            return True

        except Exception as err:
            session.rollback()
            print(f"Error: {err}")
            return False

        finally:
            session.close()

    
    def getSimilarNarrator(self,narratorName:str)->dict:
        session=None
        print("in narrator dao")
        try:
            session: Session = self.__dbConnection.getSession()
            narrators = session.query(Narrator).filter(Narrator.cleanedname.ilike(f"%{narratorName}%")).all()
            
            if narrators:
              return {"narratornames": [narrator.narratorname for narrator in narrators]}
            else:
             return {"narratornames": []}
        
        except Exception as e:
            return {"error": str(e)}
    
    def getAllNarratorsOfProject(self, project_name: str, page: int) -> dict:
        try:
            session: Session = self.__dbConnection.getSession()
            
            project = (
                session.query(Project)
                .options(joinedload(Project.sanads).joinedload(Sanad.narrators))
                .filter_by(projectname=project_name)
                .first()
            )
            
            if not project:
                return {
                    "results": [],
                    "total_pages": 0,
                    "current_page": page,
                }
            sanads = project.sanads

            if not sanads:
                return {
                    "results": [],
                    "total_pages": 0,
                    "current_page": page,
                }

            narrator_names = []
            for sanad in sanads:
                for narrator in sanad.narrators:
                    narrator_names.append(narrator.narratorname)

            per_page = 100
            total_narrators = len(narrator_names)
            total_pages = (total_narrators + per_page - 1) // per_page  
            if page > total_pages:
                return {
                    "results": [],
                    "total_pages": total_pages,
                    "current_page": page,
                }

            start = (page - 1) * per_page
            end = start + per_page
            paginated_names = narrator_names[start:end]

            return {
                "results": paginated_names,
                "total_pages": total_pages,
                "current_page": page,
            }

        except Exception as e:
            session.rollback()
            print(f"Error retrieving narrators for project '{project_name}': {e}")
            return {
                "results": [],
                "total_pages": 0,
                "current_page": page,
            }
        finally:
            session.close()
    def getAllNarrators(self, page: int) -> dict:
        try:
            session: Session = self.__dbConnection.getSession()

            per_page = 100
            total_narrators = session.query(Narrator).count()
            total_pages = (total_narrators + per_page - 1) // per_page  

            if page > total_pages:
                return {
                    "results": [],
                    "total_pages": total_pages,
                    "current_page": page,
                }

            narrators = session.query(Narrator).offset((page - 1) * per_page).limit(per_page).all()
            narrator_names = [ narrator.narratorname for narrator in narrators]

            return {
                "results": narrator_names,
                "total_pages": total_pages,
                "current_page": page,
            }

        except Exception as e:
            session.rollback()
            print(f"Error retrieving narrators: {e}")
            return {
                "results": [],
                "total_pages": 0,
                "current_page": page,
            }
        finally:
            session.close()

    
   
    def sortNarrators(self, projectName: str, narrator_list: List[str], ascending: bool, authenticity: bool) -> List[str]:
        session = None
        try:
            session = self.__dbConnection.getSession()

            project = session.query(Project).filter_by(projectname=projectName).first()
            if not project:
                print(f"Project '{projectName}' not found")
                return []

            results = []

            for narrator_name in narrator_list:
                narrator = session.query(Narrator).filter_by(narratorname=narrator_name).first()
                if not narrator:
                    print(f"Hadith narrator '{narrator_name}' not found")
                    continue

                link = session.execute(
                    project_narrator.select().where(
                        (project_narrator.c.project_id == project.projectid) &
                        (project_narrator.c.narrator_id == narrator.narratorid)
                    )
                ).first()
                if not link:
                    print(f"Narrator detail of '{narrator_name}' not found in project")
                    results.append({
                    "narratorName": narrator_name,
                    "authenticity": "not known"
                })
                    continue

                detail = session.query(NarratorDetailed).filter_by(
                    narrator_detailed_id=link.narrator_detailed_id
                ).first()
                if not detail:
                    print(f"Narrator detail for '{narrator_name}' missing in NarratorDetailed table")
                    results.append({
                    "narratorName": narrator_name,
                    "authenticity": "not known"
                })
                    continue

                results.append({
                    "narratorName": narrator_name,
                    "authenticity": detail.final_opinion
                })


            if authenticity:
                authenticity_rank = self.__AUTHENTICITY_ORDER
                results.sort(key=lambda x: authenticity_rank.get(x["authenticity"], float('inf')))
            if ascending:
                results.sort(key=lambda x: x["narratorName"])
            else:
                results.sort(key=lambda x: x["narratorName"], reverse=True)
            return [r["narratorName"] for r in results]

        except Exception as e:
            print(f"Error sorting Hadiths by authenticity: {e}")
            return []
    
    
    def importNarratorDetails(self,narratorName: str,narratorTeacher: List[str],narratorStudent: List[str],opinion: List[str],scholar: List[str],final_opinion: str,authenticity: float) -> bool:
        
        session: Session = None
        try:
            session = self.__dbConnection.getSession()
            print("in dao")
            if not narratorName or not final_opinion or authenticity is None:
                print("Missing required fields")
                return False

            if not isinstance(narratorTeacher, list): narratorTeacher = []
            if not isinstance(narratorStudent, list): narratorStudent = []
            if not isinstance(scholar, list): scholar = []
            if not isinstance(opinion, list): opinion = []

            # 1. Create NarratorDetailed entry
            narrator = NarratorDetailed(
                narrator_name=narratorName,
                narrator_authenticity=authenticity,
                final_opinion=final_opinion
            )
            session.add(narrator)
            session.flush()  
            print("1")

            # 2. Save teachers as comma-separated string
            teacher_entry = NarratorTeacher(
                narratorid=narrator.narrator_detailed_id,
                narratorteacher=",".join(narratorTeacher)
            )
            session.add(teacher_entry)
            print("2")

            # 3. Save students as comma-separated string
            student_entry = NarratorStudent(
                narratorid=narrator.narrator_detailed_id,
                narratorstudent=",".join(narratorStudent)
            )
            session.add(student_entry)
            print("3")

            # 4. Save scholar-opinion pairs
            for i in range(len(scholar)):
                scholar_name = scholar[i]
                opinion_text = opinion[i] if i < len(opinion) else "No opinion"

                # Get or create scholar
                existing_scholar = session.query(Scholars).filter_by(scholar_name=scholar_name).first()
                if not existing_scholar:
                    existing_scholar = Scholars(scholar_name=scholar_name)
                    session.add(existing_scholar)
                    session.flush()

                # Save opinion and link to narrator
                new_opinion=Opinions(opinion=opinion_text)
                session.add(new_opinion)
                session.flush()
                rel_opinion = ScholarOpinion(
                    opinion_id=new_opinion.opinionid,
                    scholar_id=existing_scholar.scholar_id
                )
                session.add(rel_opinion)
                session.flush()
                nar_op=narrator_opinion.insert().values(narrator_detailed_id=narrator.narrator_detailed_id,
                                        scholar_opinion_id=rel_opinion.scholar_opinion_id)
                
                
                session.execute(nar_op)
        

            session.commit()
            return True

        except Exception as e:
            session.rollback()
            print("Error in importNarratorDetails:", e)
            return False

    def getSimilarNarratorName(self,narratorName:str)->dict:
        session=None
        
        print("in narrator dao")
        try:
            session: Session = self.__dbConnection.getSession()
            narrators = session.query(NarratorDetailed).filter(NarratorDetailed.narrator_name.ilike(f"%{narratorName}%")).all()
            
            if narrators:
              return {"narratornames": [narrator.narrator_name for narrator in narrators]}
            else:
             return {"narratornames": []}
        
        except Exception as e:
            return {"error": str(e)}
    def associateHadithNarratorWithNarratorDetails(self, projectName: str, narrator_name: str, detailed_narrator_name: str) -> bool:
        session: Session = None
        try:
            session = self.__dbConnection.getSession()
            
            project = session.query(Project).filter_by(projectname=projectName).first()
            if not project:
                print(f"Project '{projectName}' not found")
                return False
            hadith_narrator = session.query(Narrator).filter_by(narratorname=narrator_name).first()
            if not hadith_narrator:
                print(f"Hadith narrator '{narrator_name}' not found")
                return False
            detailed_narrator = session.query(NarratorDetailed).filter_by(narrator_name=detailed_narrator_name).first()
            if not detailed_narrator:
                print(f"Detailed narrator '{detailed_narrator_name}' not found")
                return False
            existing = session.execute(
                project_narrator.select().where(
                    (project_narrator.c.project_id == project.projectid) &
                    (project_narrator.c.narrator_id == hadith_narrator.narratorid) &
                    (project_narrator.c.narrator_detailed_id == detailed_narrator.narrator_detailed_id)
                )
            ).first()
            
            if existing:
                print("Association already exists")
                return True

            stmt = project_narrator.insert().values(
                project_id=project.projectid,
                narrator_id=hadith_narrator.narratorid,
                narrator_detailed_id=detailed_narrator.narrator_detailed_id
            )
            session.execute(stmt)
            session.commit()
            return True

        except Exception as e:
            if session:
                session.rollback()
            print(f"Error in associateHadithNarratorWithNarratorDetails: {e}")
            traceback.print_exc()
            return False
        finally:
            if session:
                session.close()

    def getNarratorTeacher(self, narratorName: str, projectName: str) -> str:
        session = None
        try:
            session = self.__dbConnection.getSession()
            
            project = session.query(Project).filter_by(projectname=projectName).first()
            if not project:
                print(f"Project '{projectName}' not found")
                return f"Error, Project '{projectName}' not found"

            hadith_narrator = session.query(Narrator).filter_by(narratorname=narratorName).first()
            if not hadith_narrator:
                print(f"Hadith narrator '{narratorName}' not found")
                return f"Error, Hadith narrator '{narratorName}' not found"
            existing = session.execute(
                project_narrator.select().where(
                    (project_narrator.c.project_id == project.projectid) &
                    (project_narrator.c.narrator_id == hadith_narrator.narratorid)
                )
            ).first()

            if not existing:
                print("No detailed narrator association found.")
                return "Error, No detailed narrator association found."

            teachers = session.query(NarratorTeacher).filter_by(narratorid=existing.narrator_detailed_id).first()
            
            return teachers.narratorteacher

        except Exception as e:
            print(f"Error in getNarratorTeacher: {e}")
            traceback.print_exc()
            return f"Error, {e}"

        finally:
            if session:
                session.close()

    def getNarratorStudent(self, narratorName: str, projectName: str) -> str:
        session = None
        try:
            session = self.__dbConnection.getSession()
            
            project = session.query(Project).filter_by(projectname=projectName).first()
            if not project:
                print(f"Project '{projectName}' not found")
                return f"Error, Project '{projectName}' not found"

            hadith_narrator = session.query(Narrator).filter_by(narratorname=narratorName).first()
            if not hadith_narrator:
                print(f"Hadith narrator '{narratorName}' not found")
                return f"Error, Hadith narrator '{narratorName}' not found"
            existing = session.execute(
                project_narrator.select().where(
                    (project_narrator.c.project_id == project.projectid) &
                    (project_narrator.c.narrator_id == hadith_narrator.narratorid)
                )
            ).first()

            if not existing:
                print("No detailed narrator association found.")
                return "Error, No detailed narrator association found."

            student = session.query(NarratorStudent).filter_by(narratorid=existing.narrator_detailed_id).first()
            
            return student.narratorstudent

        except Exception as e:
            print(f"Error in getNarratorStudent: {e}")
            traceback.print_exc()
            return f"Error, {e}"

        finally:
            if session:
                session.close()
    def getNarratorDetails(self,narratorName:str,projectName:str)->dict:
        session = None
        try:
            session = self.__dbConnection.getSession()
            
            project = session.query(Project).filter_by(projectname=projectName).first()
            if not project:
                print(f"Project '{projectName}' not found")
                return {"error": f"Project '{projectName}' not found"}

            hadith_narrator = session.query(Narrator).filter_by(narratorname=narratorName).first()
            if not hadith_narrator:
                print(f"Hadith narrator '{narratorName}' not found")
                return {"error": f"Hadith narrator '{narratorName}' not found"}
            existing = session.execute(
                project_narrator.select().where(
                    (project_narrator.c.project_id == project.projectid) &
                    (project_narrator.c.narrator_id == hadith_narrator.narratorid)
                )
            ).first()

            if not existing:
                narrator = {"narratorName": narratorName, "authenticity": "", "detailed_name": "not known"}
                return narrator
            detail = session.query(NarratorDetailed).filter_by(narrator_detailed_id=existing.narrator_detailed_id).first()
            if not detail:
                narrator = {"narratorName": narratorName, "authenticity": "", "detailed_name": "not known"}
                return narrator
            
            narrator = {"narratorName": narratorName, "authenticity": detail.final_opinion, "detailed_name": detail.narrator_name}
            return narrator

        except Exception as e:
            print(f"Error in getNarratorDetails: {e}")
            
            traceback.print_exc()
            return {"error": str(e)}

        finally:
            if session:
                session.close()

    def updateHadithNarratorAssociation(self, projectName: str, narrator_name: str, new_detailed_narrator_name: str) -> bool:
        session: Session = None
        try:
            session = self.__dbConnection.getSession()

            project = session.query(Project).filter_by(projectname=projectName).first()
            if not project:
                print(f"Project '{projectName}' not found")
                return False

            hadith_narrator = session.query(Narrator).filter_by(narratorname=narrator_name).first()
            if not hadith_narrator:
                print(f"Hadith narrator '{narrator_name}' not found")
                return False

            new_detailed_narrator = session.query(NarratorDetailed).filter_by(narrator_name=new_detailed_narrator_name).first()
            if not new_detailed_narrator:
                print(f"New detailed narrator '{new_detailed_narrator_name}' not found")
                return False

            stmt = project_narrator.update().where(
                (project_narrator.c.project_id == project.projectid) &
                (project_narrator.c.narrator_id == hadith_narrator.narratorid)
            ).values(
                narrator_detailed_id=new_detailed_narrator.narrator_detailed_id
            )

            result = session.execute(stmt)
            if result.rowcount == 0:
                print("No existing association found to update")
                return False

            session.commit()
            print("Association updated successfully")
            return True

        except Exception as e:
            if session:
                session.rollback()
            print(f"Error in updateHadithNarratorAssociation: {e}")
            traceback.print_exc()
            return False
        finally:
            if session:
                session.close()
    
    def deleteHadithNarratorAssociation(self, projectName: str, narrator_name: str) -> bool:
        session: Session = None
        try:
            session = self.__dbConnection.getSession()

            project = session.query(Project).filter_by(projectname=projectName).first()
            if not project:
                print(f"Project '{projectName}' not found")
                return False

            hadith_narrator = session.query(Narrator).filter_by(narratorname=narrator_name).first()
            if not hadith_narrator:
                print(f"Hadith narrator '{narrator_name}' not found")
                return False

            stmt = project_narrator.delete().where(
                (project_narrator.c.project_id == project.projectid) &
                (project_narrator.c.narrator_id == hadith_narrator.narratorid)
            )

            result = session.execute(stmt)
            if result.rowcount == 0:
                print("No association found to delete")
                return False

            session.commit()
            print("Association deleted successfully")
            return True

        except Exception as e:
            if session:
                session.rollback()
            print(f"Error in deleteHadithNarratorAssociation: {e}")

            traceback.print_exc()
            return False
        finally:
            if session:
                session.close()
    def getNarratedHadiths(self, project_name: str, narrator_name: str) -> dict:
        session: Session = None
        try:
            session = self.__dbConnection.getSession()
            
            project = session.query(Project).filter_by(projectname=project_name).first()
            if not project:
                print(f"Project '{project_name}' not found")
                return {"results": []}

            results = (
                session.query(Hadith.matn, Sanad.sanad)
                .join(hadith_sanad, hadith_sanad.c.hadithid == Hadith.hadithid)
                .join(Sanad, Sanad.sanadid == hadith_sanad.c.sanadid)
                .join(narrator_sanad, narrator_sanad.c.sanadid == Sanad.sanadid)
                .join(Narrator, Narrator.narratorid == narrator_sanad.c.narratorid)
                .join(hadith_project, hadith_project.c.projectid == Hadith.hadithid)
                .filter(Narrator.cleanedname == narrator_name)
                .filter(hadith_project.c.projectid == project.projectid)
                .all()
            )
            
            formatted_results = [{"matn": matn, "sanad": sanad} for matn, sanad in results]
            
            return {"results": formatted_results}

        except Exception as e:
            print(f"Error searching Hadith by narrator '{narrator_name}' in project '{project_name}': {e}")
            return {"results": []}
        finally:
            if session:
                session.close()

    def getNarratorChains(self, project_name: str, narrator_name: str) -> dict:
        """
        Get all chains (sanads) where a narrator appears at any level,
        including detailed chain information as shown in the whiteboard diagram
        """
        session: Session = None
        try:
            session = self.__dbConnection.getSession()
            
            project = session.query(Project).filter_by(projectname=project_name).first()
            if not project:
                print(f"Project '{project_name}' not found")
                return {"results": [], "chains": []}

            # Get all hadiths narrated by this narrator
            narrated_hadiths = (
                session.query(Hadith.matn, Sanad.sanad, Hadith.hadithid)
                .join(hadith_sanad, hadith_sanad.c.hadithid == Hadith.hadithid)
                .join(Sanad, Sanad.sanadid == hadith_sanad.c.sanadid)
                .join(narrator_sanad, narrator_sanad.c.sanadid == Sanad.sanadid)
                .join(Narrator, Narrator.narratorid == narrator_sanad.c.narratorid)
                .join(hadith_project, hadith_project.c.hadithid == Hadith.hadithid)
                .filter(Narrator.cleanedname == narrator_name)
                .filter(hadith_project.c.projectid == project.projectid)
                .all()
            )

            # Get all chains where this narrator appears (at any level)
            narrator_chains = (
                session.query(
                    Sanad.sanadid,
                    Sanad.sanad,
                    narrator_sanad.c.level.label('narrator_level'),
                    Hadith.matn,
                    Hadith.hadithid
                )
                .join(narrator_sanad, narrator_sanad.c.sanadid == Sanad.sanadid)
                .join(Narrator, Narrator.narratorid == narrator_sanad.c.narratorid)
                .join(hadith_sanad, hadith_sanad.c.sanadid == Sanad.sanadid)
                .join(Hadith, Hadith.hadithid == hadith_sanad.c.hadithid)
                .join(hadith_project, hadith_project.c.hadithid == Hadith.hadithid)
                .filter(Narrator.cleanedname == narrator_name)
                .filter(hadith_project.c.projectid == project.projectid)
                .all()
            )

            # Format narrated hadiths
            formatted_hadiths = [{"matn": matn, "sanad": sanad} for matn, sanad, _ in narrated_hadiths]

            # Get detailed chain information for each sanad
            chain_details = []
            processed_sanads = set()

            for sanad_id, sanad_text, narrator_level, hadith_matn, hadith_id in narrator_chains:
                if sanad_id in processed_sanads:
                    continue
                
                processed_sanads.add(sanad_id)

                # Get all narrators in this chain with their levels
                chain_narrators = (
                    session.query(
                        Narrator.narratorname,
                        narrator_sanad.c.level,
                        Narrator.narratorid
                    )
                    .join(narrator_sanad, narrator_sanad.c.narratorid == Narrator.narratorid)
                    .filter(narrator_sanad.c.sanadid == sanad_id)
                    .order_by(narrator_sanad.c.level)
                    .all()
                )

                # Create chain structure as shown in whiteboard
                chain_structure = []
                for name, level, narrator_id in chain_narrators:
                    is_target_narrator = name == narrator_name
                    chain_structure.append({
                        "narrator_name": name,
                        "level": level,
                        "narrator_id": narrator_id,
                        "is_target": is_target_narrator
                    })

                chain_details.append({
                    "sanad_id": sanad_id,
                    "sanad_text": sanad_text,
                    "hadith_matn": hadith_matn,
                    "hadith_id": hadith_id,
                    "target_narrator_level": narrator_level,
                    "chain_structure": chain_structure,
                    "chain_length": len(chain_structure)
                })

            return {
                "results": formatted_hadiths,
                "chains": chain_details,
                "total_chains": len(chain_details),
                "narrator_name": narrator_name
            }

        except Exception as e:
            print(f"Error getting narrator chains for '{narrator_name}' in project '{project_name}': {e}")
            return {"results": [], "chains": [], "total_chains": 0, "narrator_name": narrator_name}
        finally:
            if session:
                session.close()

