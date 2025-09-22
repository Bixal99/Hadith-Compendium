from typing import List
from pydantic import BaseModel

class SemanticSearchResult(BaseModel):
    matn: str
    similarity: float


class SemanticSearchResponse(BaseModel):
    query: str
    results: List[SemanticSearchResult]

class SortResultResult(BaseModel):
    matn:str
    narratorName:str
    similarity: float

class SortResultResponse(BaseModel):
    query: List[str]
    results: List[SortResultResult]

class ExpandSearchResult(BaseModel):
    matn: str  
    similarity: float

class ExpandSearchResponse(BaseModel):
    query: List[str] 
    results: List[ExpandSearchResult] 

class GetAllProjectHadithsResponse(BaseModel):
    results: List[dict]
    totalPages:int
    currentpage:int
class SearchResponse(BaseModel):
    results: List[str]
    totalPages:int
    currentpage:int

class NarratorDetails(BaseModel):
    narrator_name: str
    level: int
    detailed_narrator_name:str
    final_opinion:str

class SanadDetails(BaseModel):
    authenticity: str
    narrators: List[NarratorDetails]

class HadithDetailsResponse(BaseModel):
    matn: str
    sanads: List[SanadDetails]
    books: List[str]
    

