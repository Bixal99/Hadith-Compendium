from typing import List
from fastapi import APIRouter, HTTPException
from BusinessLogicLayer.Fascade.AbsBLLFascade import AbsBLLFascade
from BusinessLogicLayer.api.PydanticModel.BookResponse import GetAllBooksResponse

def book_router(fascade: AbsBLLFascade):
    router = APIRouter()

    
   
    @router.get("/getAllBooks",response_model=GetAllBooksResponse)
    async def getAllBooks():
        try:
            results=fascade.getAllBooks()
            if not results:
                return GetAllBooksResponse(books=[])
            return GetAllBooksResponse(books=results)

            
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))
    @router.get("/getAllBooksOfProjects",response_model=GetAllBooksResponse)
    async def getAllBooks(projectName:str):
        try:
            results=fascade.getBooksOfProject(projectName)
            if not results:
                return GetAllBooksResponse(books=[])
            return GetAllBooksResponse(books=results)
        except Exception as e:
            raise HTTPException(status_code=400, detail=str(e))



    return router