from fastapi import FastAPI
from BusinessLogicLayer.Fascade.BLLFascade import BLLFascade
from BusinessLogicLayer.Hadith.HadithBO import HadithBO
from BusinessLogicLayer.Narrator.NarratorBO import NarratorBO
from BusinessLogicLayer.Project.ProjectBO import ProjectBO
from BusinessLogicLayer.api.HadithApi import hadith_router
from BusinessLogicLayer.api.ProjectApi import project_router
from BusinessLogicLayer.api.BookApi import book_router
from BusinessLogicLayer.api.NarratorApi import narrator_router
from BusinessLogicLayer.api.HealthApi import health_router
from BusinessLogicLayer.Websockets.status_websocket import status_websocket_router
from DataAccessLayer.Book.BookDAO import BookDAO
from DataAccessLayer.Fascade.DALFascade import DALFascade
from DataAccessLayer.DbConnection import DbConnectionModel
from DataAccessLayer.Hadith.HadithDAO import HadithDAO
from DataAccessLayer.Narrator.NarratorDAO import NarratorDAO
from DataAccessLayer.Project.ProjectDAO import ProjectDAO
from DataAccessLayer.Sanad.SanadDAO import SanadDAO
from DataAccessLayer.UtilDAO import UtilDao
from DataAccessLayer.Book.BookDAO import BookDAO
from BusinessLogicLayer.Book.BookBO import BookBO


#Initiallizing DAL
dbConnection = DbConnectionModel()
utilDAO= UtilDao(dbConnection)
hadithDAO= HadithDAO(dbConnection,utilDAO)
narratorDAO= NarratorDAO(dbConnection,utilDAO)
projectDAO= ProjectDAO(dbConnection,utilDAO)
bookDAO=BookDAO(dbConnection,utilDAO)
sanadDAO= SanadDAO(dbConnection,utilDAO)
dalFascade= DALFascade(projectDAO,bookDAO,hadithDAO,sanadDAO,narratorDAO)

# Initializing BLL
hadithBO= HadithBO(dalFascade)
narratorBO= NarratorBO(dalFascade)
projectBO= ProjectBO(dalFascade)
bookBO=BookBO(dalFascade)
bllFascade= BLLFascade(hadithBO,projectBO,narratorBO,bookBO)

# Initialize FastAPI app
app = FastAPI(
    title="Hadith IQ Server",
    description="API for Hadith IQ Project",
    version="1.0.0",
)

# Included routers and pass facade to them
app.include_router(hadith_router(bllFascade), prefix="/api/hadith")
app.include_router(project_router(bllFascade), prefix="/api/project")
app.include_router(narrator_router(bllFascade),prefix="/api/narrator")
app.include_router(book_router(bllFascade),prefix="/api/book")
app.include_router(health_router())
# WebSocket router
app.include_router(status_websocket_router())

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)

# Command to run server: uvicorn BusinessLogicLayer.server:app --host 127.0.0.1 --port 8000 --reload
# call this command in the root directory of the project
# for multi request handeling server: uvicorn BusinessLogicLayer.server:app --host 127.0.0.1 --port 8000 --workers 5
# if error came for no module found bll although its there then make the pyhton to editer mode
# it will work the, run 'pip install -e .'   if its not work and give some error then: pip install --user -e .
# if ngrok installed: ngrok http --url=more-keen-elk.ngrok-free.app 8000
