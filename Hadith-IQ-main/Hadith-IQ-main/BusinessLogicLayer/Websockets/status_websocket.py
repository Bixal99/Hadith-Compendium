from fastapi import APIRouter, WebSocket, WebSocketDisconnect
import asyncio

def status_websocket_router():

    status_websocket_router = APIRouter()

    clients = []
    status = {"status": "online"}  # Can be updated elsewhere

    @status_websocket_router.websocket("/ws/status")
    async def websocket_status(websocket: WebSocket):
        await websocket.accept()
        clients.append(websocket)
        try:
            while True:
                await websocket.send_json(status)
                await asyncio.sleep(5)
        except WebSocketDisconnect:
            clients.remove(websocket)

    def update_status(new_status: str):
        status["status"] = new_status

    return status_websocket_router
