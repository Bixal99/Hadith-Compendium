from typing import List
from fastapi import APIRouter, HTTPException,UploadFile
from BusinessLogicLayer.Fascade.AbsBLLFascade import AbsBLLFascade
from BusinessLogicLayer.api.PydanticModel.NarratorRequest import GetAllNarratorsRequest,ConvertToTxt,CleanFile,SaveNarrator,SortNarrator,Associate,Deassociate,GetListOfNarratorDetails
from BusinessLogicLayer.api.PydanticModel.NarratorResponse import GetAllNarratorsResponse,FileResponse,FetchNarratorResponse,GetNarratedHadiths,SearchNarrator,SortNarratorResponse,NarratorDetails

def narrator_router(fascade: AbsBLLFascade):
    router = APIRouter()

    @router.get("/getAllProjectNarrators", response_model=GetAllNarratorsResponse)
    async def get_all_project_narrators(projectName:str,page:int):
        try:
            narrator_names = fascade.getAllNarratorsOfProject(projectName,page)
            return GetAllNarratorsResponse(
            results=narrator_names["results"],
            totalPages=narrator_names["total_pages"],
            currentpage=narrator_names["current_page"],
        )
        except Exception as e:
            print(f"Error: {e}")
            raise HTTPException(status_code=400, detail=str(e))

    @router.post("/convertHtmlToText",response_model=FileResponse)
    async def convert_html(request:ConvertToTxt):
        try:
            success = fascade.convertHtmlToText(request.filePath)
            if success["success"] is False:
                return FileResponse(success= success["success"],message="File not converted to text file")
            return FileResponse(success=success["success"],message=f"File saved in path: {success['filePath']}")
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Error processing file: {str(e)}")
    
    @router.post("/cleanFile",response_model=FileResponse)
    async def clean_File(request:CleanFile):
        try:
            success = fascade.cleanNarratorTxtFile(request.filePath,request.arabic_count)
            if success["success"] is False:
                return FileResponse(success= success["success"],message="File not Cleaned")
            return FileResponse(success=success["success"],message="File cleaned")
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Error processing file: {str(e)}")
    
    @router.post("/fetchNarratorData",response_model=FetchNarratorResponse)
    async def fetch_narrator_data(request:CleanFile):
        try:
            response = fascade.fetch_narrator_data(request.filePath,request.arabic_count)
            if not response:
                return FetchNarratorResponse(response="No response Found")
            return FetchNarratorResponse(response=response)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Error processing file: {str(e)}")
        
    
    @router.get("/getAllNarrators", response_model=GetAllNarratorsResponse)
    async def getAllNarrators(page:int):
        try:
            narrator_names = fascade.getAllNarrators(page)
            return GetAllNarratorsResponse(
                results=narrator_names["results"],
                totalPages=narrator_names["total_pages"],
                currentpage=narrator_names["current_page"],)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Error processing file: {str(e)}")
        
    @router.get("/getNarratedHadiths", response_model=GetNarratedHadiths)
    async def getNarratedHadiths(project_name:str,narrator_name:str):
        try:
            hadith=fascade.getNarratedHadiths(project_name,narrator_name)
            print(narrator_name)
            print(hadith)
            return GetNarratedHadiths(results=hadith["results"])

        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    
    @router.get("/getNarratorChains")
    async def getNarratorChains(project_name:str,narrator_name:str):
        try:
            chains = fascade.getNarratorChains(project_name,narrator_name)
            print(f"Narrator chains for {narrator_name}:")
            print(chains)
            return chains

        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
        
    @router.get("/searchNarrator", response_model=SearchNarrator)
    async def searchNarrator(narrator_name:str):
        try:
            narrators=fascade.searchNarrator(narrator_name)
            if not narrators:
                return SearchNarrator(narrator=[])
            return SearchNarrator(narrator=narrators["narratornames"])
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    
    @router.post("/importNarratorDetails")
    async def importNarrator(request:SaveNarrator):
        try:
            narrators=fascade.importNarratorDetails(request.narratorName,request.narratorTeacher,request.narratorStudent,request.opinion,request.scholar)
            if not narrators:
                return FileResponse(message="not saved ",success=False)
            return FileResponse(message="done",success=True)
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    
    @router.get("/getSimilarNarrators", response_model=SearchNarrator)
    async def similarNarrator(narrator_name:str):
        try:
            narrators=fascade.getSimilarNarratorName(narrator_name)
            if not narrators:
                return SearchNarrator(narrator=[])
            return SearchNarrator(narrator=narrators["narratornames"])
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    
    @router.post("/associateNarrator")
    async def associateNarrator(request:Associate):
        try:
            narrators=fascade.associateHadithNarratorWithNarratorDetails(request.projectName,request.narrator_name,request.detailed_narrator)
            if narrators:
                return FileResponse(message="Narrator Associated",success=True)
            return FileResponse(message="Failed Association ",success=False)
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    @router.get("/getNarratorTeacher")
    async def getNarratorTeacher(narratorName:str,projectName:str):
        teachers=""
        try:
            teachers=fascade.getNarratorTeacher(narratorName,projectName)
            if not teachers:
                return teachers
            return teachers
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    @router.get("/getNarratorStudent")
    async def getNarratorStudent(narratorName:str,projectName:str):
        student=[]
        try:
            student=fascade.getNarratorStudent(narratorName,projectName)
            if not student:
                return student
            return student
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    
    @router.get("/getNarratorDetails",response_model=NarratorDetails)
    async def getNarratorDetails(narratorName:str,projectName:str):
       
        try:
            narrator=fascade.getNarratorDetails(narratorName,projectName)
            if not narrator:
                return NarratorDetails(narrator_name=narratorName,detailed_name="",final_opinion="")
            return NarratorDetails(narrator_name=narratorName,detailed_name=narrator["detailed_name"],final_opinion=narrator["authenticity"])
        
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    
    @router.post("/updateAssociateNarrator")
    async def updateAssociateNarrator(request:Associate):
        try:
            narrators=fascade.updateHadithNarratorAssociation(request.projectName,request.narrator_name,request.detailed_narrator)
            if narrators:
                return FileResponse(message="Narrator Association Updated",success=True)
            return FileResponse(message="Failed Association Updation",success=False)
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    @router.post("/deleteAssociateNarrator")
    async def deleteAssociateNarrator(request:Deassociate):
        try:
            narrators=fascade.deleteHadithNarratorAssociation(request.projectName,request.narrator_name)
            if narrators:
                return FileResponse(message="Narrator Successflly Deassociated",success=True)
            return FileResponse(message="Failed Narrator Deassociation ",success=False)
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    @router.post("/sortNarrators", response_model=SortNarratorResponse)
    async def sortNarrators(req: SortNarrator):
            try:
                narrators = fascade.sortNarrators(
                    req.projectName, req.narrator, req.byorder, req.byauthenticity
                )
                return SortNarratorResponse(narrator=narrators or [])
            except Exception as e:
                raise HTTPException(status_code=400, detail=str(e))
    @router.post("/getAllNarratorDetails", response_model=List[NarratorDetails])
    async def get_all_narrator_details(requests: GetListOfNarratorDetails):
        try:
            result = []
            for narratorName in requests.narrator_names:
                narrator = fascade.getNarratorDetails(
                    narratorName, requests.project_name
                )
                if not narrator:
                    result.append(
                        NarratorDetails(
                            narrator_name=narratorName,
                            detailed_name="",
                            final_opinion="",
                        )
                    )
                else:
                    result.append(
                        NarratorDetails(
                            narrator_name=narratorName,
                            detailed_name=narrator["detailed_name"],
                            final_opinion=narrator["authenticity"],
                        )
                    )
            return result

        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))

    @router.get("/getNarratorTree")
    async def getNarratorTree(narratorName: str, projectName: str):
        """
        Get narrator tree data including teachers, students, and biographical info
        for tree visualization
        """
        try:
            # Get the narrator details
            narrator_details = fascade.getNarratorDetails(narratorName, projectName)
            
            # Get teachers and students
            teachers = fascade.getNarratorTeacher(narratorName, projectName)
            students = fascade.getNarratorStudent(narratorName, projectName)
            
            # Structure the tree data
            tree_data = {
                "narrator": {
                    "name": narratorName,
                    "details": narrator_details if narrator_details else {},
                    "is_center": True
                },
                "teachers": teachers if teachers else [],
                "students": students if students else [],
                "tree_structure": {
                    "levels": {
                        "teachers": len(teachers) if teachers else 0,
                        "current": 1,
                        "students": len(students) if students else 0
                    }
                }
            }
            
            return tree_data
            
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))

    
        
        
    return router
    
