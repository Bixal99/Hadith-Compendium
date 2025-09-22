from typing import List
from fastapi import APIRouter, HTTPException
from BusinessLogicLayer.Fascade.AbsBLLFascade import AbsBLLFascade
from BusinessLogicLayer.api.PydanticModel.HadithRequest import ExpandSearchRequest, FilePathRequest, SemanticSearchRequest,SortResultRequest,GetAllProjectHadithsRequest,ImportBookRequest,GetHadithDetails,GetListOfHadithDetails,RagRequest
from BusinessLogicLayer.api.PydanticModel.HadithResponse import ExpandSearchResponse, ExpandSearchResult, SemanticSearchResponse,SortResultResponse,GetAllProjectHadithsResponse,HadithDetailsResponse,SearchResponse
from BusinessLogicLayer.api.PydanticModel.HadithResponse import SemanticSearchResult ,SortResultResult

def hadith_router(fascade: AbsBLLFascade):
    router = APIRouter()

    @router.post("/importBook")
    async def import_book(request: ImportBookRequest):
        try:
            results=[]
            books=request.bookNames
            for book in books:
            # Call the function from your BLL
                success = fascade.importHadithFile(projectName=request.projectName,filePath=book)
                if success:
                    print(book + " imported successfully ")
                    results.append(success)
                else:
                    print(book + " import failed ")
                    results.append(success)
            if False in results:
                return {"message": "File import failed. Please check the data.", "success": False}
            else:
                return {"message": "File imported successfully!", "success": True}
                
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
    
    @router.post("/importHadithFileCSV")
    async def import_hadith_csv(request: FilePathRequest):
        try:
            # Call the function from your BLL
            success = fascade.importHadithFileCSV(request.filePath)
            if success:
                return {"message": "File imported successfully!","success":True}
            else:
                return {"message": "File import failed. Please check the data.", "success": False}
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    @router.post("/semanticSearch", response_model=SemanticSearchResponse)
    async def semantic_search(request: SemanticSearchRequest):
        try:
            hadith = request.hadith
            projectName = request.projectName
            threshold=request.threshold
            results = fascade.semanticSearch(hadith, projectName,threshold)

            # Assuming `results` is a list of dicts or tuples, convert to SemanticSearchResult
            searchResults = [
            SemanticSearchResult(matn=result["matn"], similarity=result["similarity"])
            for result in results
            ]
            
            # Returning the response as expected
            return {"query": hadith, "results": searchResults}
        
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
        
    @router.post("/expandSearch", response_model=ExpandSearchResponse)
    async def expand_search(request: ExpandSearchRequest):
        try:
            hadith_list = request.hadithTO
            projectName = request.projectName
            threshold=request.threshold
            results = fascade.expandSearch(hadith_list, projectName,threshold)
            expanded_results = [
                ExpandSearchResult(matn=result["matn"], similarity=result["similarity"])
                for result in results
            ]

            return {"query": hadith_list,"results": expanded_results}
        
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
        
    @router.post("/sortHadith", response_model=SortResultResponse)
    async def sort_search(request: SortResultRequest):
        try:
            hadithList = request.hadithList
            sortByNarrotor = request.sortByNarrator
            sortByAuthenticity=request.sortByAuthenticity
            authenticityType=request.authenticityType
            results = fascade.sortHadith(sortByNarrotor,sortByAuthenticity,authenticityType,hadithList)
            sorted_results = [
                SortResultResult(matn=result["matn"], narratorName=result["narratorName"], similarity=result["similarity"])
                for result in results
            ]

            return {"query": hadithList,"results": sorted_results}
        
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))

    
   
    @router.get("/getAllProjectHadiths",response_model=List[GetAllProjectHadithsResponse])
    async def get_all_project_hadiths(projectName:str,page:int):
        try:

            hadith=fascade.getAllHadithsOfProject(projectName,page)
            return[ GetAllProjectHadithsResponse(results=hadith["results"],  
            totalPages=hadith["total_pages"],
            currentpage=hadith["current_page"],)]
            
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    @router.get("/getAllHadiths",response_model=List[GetAllProjectHadithsResponse])
    async def get_all_hadiths(page:int):
        try:

            hadith=fascade.getAllHadiths(page)
            return[ GetAllProjectHadithsResponse(results=hadith["results"],  
            totalPages=hadith["total_pages"],
            currentpage=hadith["current_page"],)]

        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
        
    @router.post("/getHadithDetails",response_model=HadithDetailsResponse)
    async def get_hadith_details(request:GetHadithDetails ):
        try:
            hadith=fascade.getHadithDetails(request.matn,request.projectName)
            return HadithDetailsResponse(
            matn=hadith["matn"],
            sanads=hadith["sanads"],
            books=hadith["books"]
        )

        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
        
    @router.post("/getListOfHadithsDetails", response_model=List[HadithDetailsResponse])
    async def get_list_of_hadith_details(requests: GetListOfHadithDetails):
        try:
            hadiths_list = []
            for requestMatn in requests.matn:
                hadith = fascade.getHadithDetails(requestMatn)
                if hadith:
                    hadiths_list.append(
                        HadithDetailsResponse(
                            matn=hadith["matn"],
                            sanads=hadith["sanads"],
                            books=hadith["books"]
                        )
                    )
            return hadiths_list

        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
        
    @router.get("/searchHadithsByNarrator", response_model=SearchResponse)
    async def searchHadithsByNarrator(project_name:str,narrator_name:str,page:int):
        try:
            hadith=fascade.searchHadithByNarrator(project_name,narrator_name,page)
            return SearchResponse(results=hadith["results"],  
            totalPages=hadith["total_pages"],
            currentpage=hadith["current_page"],)

            
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    @router.get("/searchHadithsByString")
    async def searchHadithsByString(project_name:str,hadith:str):
        try:
            hadith=fascade.stringBasedSearch(hadith,project_name)
            if not hadith:
                return []
            else:
                return hadith

            
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    
    @router.get("/searchHadithsByRoot",response_model=SearchResponse)
    async def searchHadithsByRoot(project_name:str,hadith:str,page:int):
        try:
            hadith=fascade.rootBasedSearch(hadith,project_name,page)
            return SearchResponse(results=hadith["results"],  
            totalPages=hadith["total_pages"],
            currentpage=hadith["current_page"],)

            
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    @router.get("/searchHadithsByOperators",)
    async def searchHadithsByOperator(project_name:str,hadith:str):
        try:
            hadith=fascade.operatorBasedSearch(hadith,project_name)
            if not hadith:
                return []
            else:
                return hadith

            
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    @router.post("/hadithRag")
    async def hadith_rag(request: RagRequest):
        try:
            results = fascade.hadith_rag(request.question,request.projectName)
            
            return results
        
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))





    return router