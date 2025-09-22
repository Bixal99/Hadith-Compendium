from fastapi import APIRouter
from fastapi.responses import JSONResponse

def health_router():
    router = APIRouter()

    @router.get('/')
    async def server_check():
        return JSONResponse(content={"response": "Server is running!"}, status_code=200)
    
    @router.get("/health")
    async def health_check():
        return JSONResponse(content={"status": "ok"}, status_code=200)
    
    return router
