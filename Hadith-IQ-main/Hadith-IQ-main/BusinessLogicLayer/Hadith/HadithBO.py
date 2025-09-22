import ast
from BusinessLogicLayer.Hadith.AbsHadithBO import AbsHadithBO
from DataAccessLayer.Fascade.AbsDALFascade import AbsDALFascade
from typing import List, Dict
import re
import json
import requests
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
from TO.HadithTO import HadithTO
from TO.NarratorTO import NarratorTO
from TO.SanadTO import SanadTO
from camel_tools.morphology.database import MorphologyDB
from camel_tools.morphology.analyzer import Analyzer
from camel_tools.utils.dediac import dediac_ar
from camel_tools.tokenizers.word import simple_word_tokenize
from multiprocessing import Pool, cpu_count
import os
from functools import partial
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor
from multiprocessing import Manager
import math
import configparser
from transformers import AutoTokenizer, AutoModel
import torch
import nltk
from nltk.stem.isri import ISRIStemmer


class HadithBO(AbsHadithBO):
    def __init__(self, dalFascade: AbsDALFascade):
        self.__dalFascade = dalFascade
        config = configparser.ConfigParser()
        import os
        config_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "config.properties")
        config.read(config_path)
        self.name = "sentence-transformers/LaBSE"  # Using public LaBSE model instead
        self.API_URL = config.get("API", "API_URL")
        self.API_KEY = config.get("API", "API_KEY")
        self.LLM_MODEL = config.get("API", "LLM_MODEL") 
        # SentenceTransformer("sentence-transformers/LaBSE")
        # self.labse_model.eval()  # For PyTorch-based SentenceTransformer models
        self.morphology_db = MorphologyDB.builtin_db()
        # Load the Arabic-LABSE model and tokenizer - with error handling
        try:
            self.tokenizer = AutoTokenizer.from_pretrained(self.name)
            self.labse_model = AutoModel.from_pretrained(self.name)
            self.labse_model.eval()
            print("✓ LaBSE model loaded successfully")
        except Exception as e:
            print(f"⚠️  Warning: Could not load LaBSE model: {e}")
            print("⚠️  Using fallback mode - semantic search may be limited")
            self.tokenizer = None
            self.labse_model = None
        
        try:
            nltk.download('punkt_tab')
        except Exception as e:
            print(f"⚠️  Warning: Could not download NLTK data: {e}")

    @property
    def dalFascade(self) -> AbsDALFascade:
        return self.__dalFascade

    @dalFascade.setter
    def dalFascade(self, value):
        self.__dalFascade = value

    def importHadithFile(self, projectName, filePath) -> bool:
        try:
            bookcheck = self.dalFascade.associate_book_with_project(
                filePath, projectName
            )
            if bookcheck:
                print(
                    f"Book from file {filePath} successfully associated with project '{projectName}'."
                )
                hadithcheck = self.dalFascade.associate_hadiths_with_project(
                    filePath, projectName
                )
                if hadithcheck:
                    print(
                        f"Hadiths from {filePath} successfully associated with project '{projectName}'."
                    )
                    self.initialize_or_rebuild_index(projectName, True)
                    sanadcheck = self.dalFascade.associate_sanads_with_project_by_book(
                        filePath, projectName
                    )
                    if sanadcheck:
                        print(
                            f"Sanads from {filePath} successfully associated with project '{projectName}'."
                        )
                        
                        return True
                    else:
                        print(
                            f"Failed to associate sanads from file {filePath} with project '{projectName}'."
                        )
                else:
                    print(
                        f"Failed to associate hadiths from file {filePath} with project '{projectName}'."
                    )
            else:
                print(
                    f"Failed to associate book from file {filePath} with project '{projectName}'."
                )

            return False
        except Exception as e:
            print(f"Error during the import process: {e}")
            return False

    def importHadithFileCSV(self, filePath: str) -> bool:
        print("in import")

        bookData = self.dalFascade.importBook(filePath)
        if not bookData:
            print("No book data found.")

            return False
        # Number of CPU cores available
        ##self.logger.info("Started Multiprocessing and multiThreading ")
        num_cores = cpu_count()
        chunk_size = math.ceil(len(bookData) / num_cores)

        # Helper function for threading within each process

        # Process all data in parallel
        ##self.logger.info("Created MultiProcesses")
        process_entry_decoupled = partial(
            HadithBO.process_entry,
            HadithBO._getActualMatn,
            HadithBO._clean_text,
            HadithBO._cleanHadithMatn,
            HadithBO.remove_diacritics,
            HadithBO.get_roots_from_sentence,
            partial(
                HadithBO._lemmatize_arabic_sentence, morphology_db=self.morphology_db
            ),
            partial(
                HadithBO._generateEmbeddings,
                token=self.tokenizer,
                labse_model=self.labse_model,
            ),
            
        )  # change here

        # Decouple process_chunk
        process_chunk_decoupled = partial(
            HadithBO.process_chunk, process_entry=process_entry_decoupled
        )

        # Process data in parallel
        processed_data = self.process_data_in_parallel(
            bookData, num_cores, chunk_size, process_chunk_decoupled
        )
        ##self.logger.info("Multiprocessing and Multithreadig in done starting Inserting")
        print(processed_data)

        # Insertion Logic
        finalResult = False
        for hadith in processed_data:
            _matn = hadith["matn"]
            _matnEmbedding = hadith["matnEmbedding"]
            _cleanedMatn = hadith["cleanedMatn"]
            _matnwithoutarab=hadith["matnwithoutarab"]
            _root=hadith["root"]
            _bookName = hadith.get("bookname")
            _sanad = hadith.get("sanad")
            if _matn and _bookName and _sanad:
                # Insert Book record
                if self.__dalFascade.insertBook(_bookName):
                    _hadithTO = HadithTO(
                        0, _matn, _matnEmbedding, "Authentic", _bookName, _cleanedMatn,_root,_matnwithoutarab
                    )
                    
                    _hadithResult = self.__dalFascade.insertHadith(_hadithTO)
                    if _hadithResult:
                        if _sanad != "No SANAD":
                            sanadTO = SanadTO(_sanad, "Authentic", _hadithTO)
                            _resultSanad = self.__dalFascade.insertSanad(sanadTO)

                        if _resultSanad:
                            _listNarrators = self._transformSanad(_sanad)
                            if _listNarrators:
                                finalResult = self._insertHadithNarrators(
                                    _sanad, _listNarrators
                                )

        return finalResult

    def getHadithDetails(self, matn: str, projectName: str) -> dict:
        return self.__dalFascade.getHadithDetails(matn,projectName)

    def process_entry(
        getActualMatn,
        clean_text,
        cleanHadithMatn,
        remove_diacritics,
        get_roots_from_sentence,
        lemmatize,
        generateEmbeddings,
        hadith,

    ):
        _matn = hadith.get("matn")
        _matnClean = getActualMatn(_matn)
        _matn = clean_text(_matn)
        _cleanedMatn = cleanHadithMatn(lemmatize(cleanHadithMatn(_matnClean)))
        _matnEmbedding = generateEmbeddings(_cleanedMatn)
        _matnwithoutarab= remove_diacritics(_matn)
        _root=get_roots_from_sentence(_matnClean)
        hadith["matn"] = _matn  # errorrrrrr
        hadith["matnEmbedding"] = _matnEmbedding
        hadith["cleanedMatn"] = _cleanedMatn
        hadith["matnwithoutarab"]=_matnwithoutarab
        hadith["root"]=_root
        return hadith
    @staticmethod
    def get_roots_from_sentence(sentence: str) -> str:
        try:
            words = nltk.word_tokenize(sentence)
            st = ISRIStemmer()
            roots = []

            for word in words:
                try:
                    stemmed_word = st.stem(word)
                    roots.append(stemmed_word)
                except Exception as e:
                    print(f"Error stemming word '{word}': {e}")
                    continue  # Skip the word and continue
            return ', '.join(roots)

        except Exception as e:
            print(f"Error processing sentence: {e}")
            return ""

    @staticmethod
    def process_chunk(chunk, process_entry):
        num_threads = cpu_count()
        chunk_size = max(1, len(chunk) // num_threads)
        sub_chunks = [
            chunk[i * chunk_size : (i + 1) * chunk_size] for i in range(num_threads)
        ]

        with ThreadPoolExecutor(max_workers=num_threads) as executor:
            results = list(
                executor.map(
                    lambda sub_chunk: [process_entry(entry) for entry in sub_chunk],
                    sub_chunks,
                )
            )

        processed_chunk = [entry for sublist in results for entry in sublist]
        return processed_chunk

    # Flatten the processed results from all threads
    # self.logger.info("Merging Results from Each Thread")

    """
    # Private Funtions ---------------------------------------------------
    def process_chunk(self,chunk):
        # Use ThreadPoolExecutor for multithreading
        with ThreadPoolExecutor(max_workers=cpu_count()) as executor:
            processed_chunk = list(executor.map(self.process_entry, chunk))
        return processed_chunk
    """
    @staticmethod
    def remove_diacritics( text):
        """Remove diacritics (Tashkeel) from Arabic text."""
        DIACRITICS_PATTERN = re.compile(r"[\u064B-\u065F\u0617-\u061A]")
        return DIACRITICS_PATTERN.sub("", text)
    
    # Function to divide data among processes
    @staticmethod
    def process_data_in_parallel(data, num_processes, chunk_size, process_chunk):
        chunks = [
            data[i * chunk_size : (i + 1) * chunk_size] for i in range(num_processes)
        ]

        with Pool(processes=num_processes) as pool:
            results = pool.map(process_chunk, chunks)

        processed_data = [entry for chunk in results for entry in chunk]
        return processed_data

    # ---------------------------------Multi processing wala-----------------------------------------

    # def importHadithFile(self, projectName: str, filePath: str) -> bool:
    #     start_time = time.time()  # Track start time

    #     bookData = self.dalFascade.importBook(projectName, filePath)

    #     finalResult = False

    #     if not bookData:
    #         # if no data is returned
    #         print("No book data found.")
    #         return False

    #     # Prepare data for parallel processing
    #     hadith_data = [(hadith, projectName) for hadith in bookData]

    #     # Use multiprocessing to process Hadiths in parallel
    #     with multiprocessing.Pool(processes=multiprocessing.cpu_count()) as pool:
    #         results = pool.map(self._process_hadith, hadith_data)

    #     # Track time after multiprocessing
    #     processing_time = time.time() - start_time
    #     print(f"Time taken for multiprocessing: {processing_time:.2f} seconds")

    #     # Process results (db insertion done sequentially)
    #     for result in results:
    #         if result:
    #             finalResult = True

    #     total_time = time.time() - start_time  # Total time including data fetching
    #     print(f"Total time for importing Hadith file: {total_time:.2f} seconds")

    #     return finalResult

    # # Helper function for parallel processing of each Hadith
    # def _process_hadith(self, hadith_data):
    #     hadith, projectName = hadith_data

    #     _matn = hadith.get("matn")
    #     _matnClean = self._getActualMatn(_matn)
    #     _matn = self._clean_text(_matn)
    #     _bookName = hadith.get("bookname")
    #     _sanad = hadith.get("sanad")

    #     # Parallelize the complex text processing (cleaning, lemmatization, etc.)
    #     _cleanedMatn = self._process_text_preprocessing(_matnClean)

    #     # Generate embeddings
    #     _matnEmbedding = self._generateEmbeddings(_cleanedMatn)

    #     return {
    #         "matn": _matn,
    #         "bookName": _bookName,
    #         "sanad": _sanad,
    #         "cleanedMatn": _cleanedMatn,
    #         "matnEmbedding": _matnEmbedding
    #     }

    # # Helper function to handle text preprocessing in parallel
    # def _process_text_preprocessing(self, matnClean):
    #     _cleanedMatn = self._cleanHadithMatn(self._lemmatize_arabic_sentence(self._cleanHadithMatn(matnClean)))
    #     return _cleanedMatn

    # def sequential_db_insertion(self, results, projectName):
    #     finalResult = False

    #     for result in results:
    #         _matn = result.get("matn")
    #         _bookName = result.get("bookName")
    #         _sanad = result.get("sanad")
    #         _cleanedMatn = result.get("cleanedMatn")
    #         _matnEmbedding = result.get("matnEmbedding")

    #         if _matn and _bookName and _sanad:
    #             # Insert Book record (if applicable)
    #             if self.__dalFascade.insertBook(projectName, _bookName):
    #                 _hadithTO = HadithTO(
    #                     0, _matn, _matnEmbedding, "Authentic", _bookName, _cleanedMatn
    #                 )
    #                 _hadithResult = self.__dalFascade.insertHadith(
    #                     projectName, _hadithTO
    #                 )
    #                 if _hadithResult:
    #                     if _sanad != "No SANAD":
    #                         sanadTO = SanadTO(_sanad, "Authentic", _hadithTO)
    #                         _resultSanad = self.__dalFascade.insertSanad(
    #                             projectName, sanadTO
    #                         )

    #                     if _resultSanad:
    #                         _listNarrators = self._transformSanad(_sanad)
    #                         if _listNarrators:
    #                             finalResult = self._insertHadithNarrators(
    #                                 _sanad, _listNarrators
    #                             )
    #     return finalResult

    # --------------------------------------------------------------------------

    def getAllHadiths(self, page: int) -> dict:
        return self.__dalFascade.getAllHadiths(page)

    def searchHadithByNarrator(
        self, project_name: str, narrator_name: str, page: int
    ) -> dict:
        return self.__dalFascade.searchHadithByNarrator(
            project_name, narrator_name, page
        )

    # ---------------------------------Multi processing wala-----------------------------------------

    # def semanticSearch(self, hadith: str, projectName: str, threshold: float) -> dict:
    #     try:
    #         # Step 1: Preprocess and generate embedding for query in parallel
    #         _queryEmbedding = self._process_preprocessing_and_embedding(hadith)

    #         # Get Hadith dictionary
    #         _hadithDict = self.dalFascade.getProjectHadithsEmbedding(projectName)

    #         if not _hadithDict:
    #             return []

    #         # Step 2: Process Hadith dictionary in batches and calculate cosine similarity
    #         _batch_size = 100
    #         _batched_results = []
    #         _hadith_batches = self._createBatches(_hadithDict, _batch_size)

    #         # Apply multiprocessing to cosine similarity computation
    #         with multiprocessing.Pool(processes=multiprocessing.cpu_count()) as pool:
    #             # Map the _process_batch function to each batch
    #             _batched_results = pool.map(self._process_batch, [(batch, _queryEmbedding) for batch in _hadith_batches])

    #         # Flatten the list of results
    #         _batched_results = [item for sublist in _batched_results for item in sublist]

    #         # Step 3: Filter and sort results based on threshold
    #         _filtered_results = [
    #             {"matn": result["matn"], "similarity": result["similarity"]}
    #             for result in _batched_results
    #             if result["similarity"] >= threshold
    #         ]

    #         _filtered_results.sort(key=lambda x: x["similarity"], reverse=True)
    #         return _filtered_results

    #     except Exception as e:
    #         print(f"Error in semanticSearch: {e}")
    #         return []

    # # Helper function for preprocessing and embedding generation in parallel
    # def _process_preprocessing_and_embedding(self, hadith):
    #     _query = self._getActualMatn(hadith)
    #     _query = self._cleanHadithMatn(self._lemmatize_arabic_sentence(self._cleanHadithMatn(_query)))
    #     _queryEmbedding = self._generateEmbeddings(_query)
    #     return _queryEmbedding

    # # Helper function for cosine similarity calculation in parallel
    # def _process_batch(self, batch_and_embedding):
    #     batch, queryEmbedding = batch_and_embedding
    #     # Process the batch and calculate cosine similarity
    #     return self._cosineSimilarity(queryEmbedding, batch)

    # --------------------------------------------------------------------------

    # def semanticSearch(self, hadith: str, projectName: str, threshold: float) -> dict:
    #     print("in semantic Search")
    #     print(hadith)
    #     _query = self._getActualMatn(hadith)
    #     _query=self._cleanHadithMatn(self._lemmatize_arabic_sentence(self._cleanHadithMatn(_query),self.morphology_db))
    #     print("0")
    #     # _query = self._cleanHadithMatn(_query)
    #     _queryEmbedding = self._generateEmbeddings(_query,self.tokenizer,self.labse_model)
    #     print(_queryEmbedding)
    #     print("1")
    #     _hadithDict = self.dalFascade.getProjectHadithsEmbedding(projectName)
    #     # Processing the Hadith dictionary in batches
    #     print("2")
    #     _batch_size = 100
    #     _batched_results = []
    #     _hadith_batches = self._createBatches(_hadithDict, _batch_size)
    #     for batch in _hadith_batches:
    #         _batch_result = self._cosineSimilarity(_queryEmbedding, batch)
    #         _batched_results.extend(_batch_result)
    #     _batched_results.sort(key=lambda x: x["similarity"], reverse=True)
    #     _threshold = threshold
    #     _filtered_results = [
    #         {"matn": result["matn"], "similarity": result["similarity"]}
    #         for result in _batched_results
    #         if result["similarity"] >= _threshold
    #     ]
    #     return _filtered_results

    def semanticSearch(
        self, hadith: str, projectName: str, threshold: float
    ) -> List[Dict[str, float]]:
        from services.semantic_index_service import (
            load_index,
            hybrid_query,
            json_to_np_array,
            convert_embeddings_for_faiss,
        )

        print("🔍 Starting semantic search")

        try:
            # Process the input Hadith
            _query = self._getActualMatn(hadith)
            _query = self._cleanHadithMatn(
                self._lemmatize_arabic_sentence(
                    self._cleanHadithMatn(_query), self.morphology_db
                )
            )
            if not _query.strip():
                raise ValueError(
                    "Processed query is empty after cleaning/lemmatization"
                )

            # Generate query embedding
            _queryEmbedding = self._generateEmbeddings(
                _query, self.tokenizer, self.labse_model
            )
            if _queryEmbedding is None or len(_queryEmbedding) == 0:
                raise ValueError("Failed to generate query embedding")

            # Convert query embedding to NumPy array
            _queryEmbedding = json_to_np_array(_queryEmbedding)
            if _queryEmbedding is None:
                raise ValueError("Failed to convert query embedding to NumPy array")

            # Fetch Hadith embeddings from DAL
            print("📥 Fetching embeddings from DAL")
            _hadithDict = self.dalFascade.getProjectHadithsEmbedding(projectName)
            if not _hadithDict:
                raise ValueError(f"No embeddings found for project '{projectName}'")

            # Convert Hadith embeddings using convert_embeddings_for_faiss
            print("🧠 Converting Hadith embeddings for FAISS")
            matns, embeddings = convert_embeddings_for_faiss(_hadithDict)
            if embeddings.shape[0] == 0:  # Check if embeddings are empty
                raise ValueError("No valid embeddings after conversion")

            # Ensure matns and embeddings have the same length
            if len(matns) != embeddings.shape[0]:
                raise ValueError("The number of matns and embeddings do not match")

            # Create the dictionary with matns (strings) as keys and embeddings as values
            hadith_embeddings = {
                matn: embedding for matn, embedding in zip(matns, embeddings)
            }

            # Load FAISS index and matn map
            print("📦 Loading FAISS index")
            index, matn_map = load_index(projectName)

            # Perform hybrid search
            print("⚡ Performing FAISS + Re-rank search")
            results = hybrid_query(index, _queryEmbedding, matn_map, hadith_embeddings)

            # Filter results by threshold
            filtered_results = [
                {"matn": matn, "similarity": score}
                for matn, score in results
                if score >= threshold
            ]

            print(f"Found {len(filtered_results)} results above threshold {threshold}")
            return filtered_results

        except FileNotFoundError as e:
            print(f"Error: {e}")
            raise
        except Exception as e:
            print(f"Error during semantic search: {e}")
            raise
    def semanticSearchGlobal(
        self, hadith: str, projectName: str, threshold: float
    ) -> List[Dict[str, float]]:
        from services.semantic_index_service import (
            load_index,
            hybrid_query,
            json_to_np_array,
            convert_embeddings_for_faiss,
        )

        print("🔍 Starting semantic search")

        try:
            # Process the input Hadith
            _query = self._getActualMatn(hadith)
            _query = self._cleanHadithMatn(
                self._lemmatize_arabic_sentence(
                    self._cleanHadithMatn(_query), self.morphology_db
                )
            )
            if not _query.strip():
                raise ValueError(
                    "Processed query is empty after cleaning/lemmatization"
                )

            # Generate query embedding
            _queryEmbedding = self._generateEmbeddings(
                _query, self.tokenizer, self.labse_model
            )
            if _queryEmbedding is None or len(_queryEmbedding) == 0:
                raise ValueError("Failed to generate query embedding")

            # Convert query embedding to NumPy array
            _queryEmbedding = json_to_np_array(_queryEmbedding)
            if _queryEmbedding is None:
                raise ValueError("Failed to convert query embedding to NumPy array")

            # Fetch Hadith embeddings from DAL
            print("📥 Fetching embeddings from DAL")
            _hadithDict = self.dalFascade.getAllHadithsEmbeddings()
            if not _hadithDict:
                raise ValueError(f"No embeddings found for project '{projectName}'")

            # Convert Hadith embeddings using convert_embeddings_for_faiss
            print("🧠 Converting Hadith embeddings for FAISS")
            matns, embeddings = convert_embeddings_for_faiss(_hadithDict)
            if embeddings.shape[0] == 0:  # Check if embeddings are empty
                raise ValueError("No valid embeddings after conversion")

            # Ensure matns and embeddings have the same length
            if len(matns) != embeddings.shape[0]:
                raise ValueError("The number of matns and embeddings do not match")

            # Create the dictionary with matns (strings) as keys and embeddings as values
            hadith_embeddings = {
                matn: embedding for matn, embedding in zip(matns, embeddings)
            }

            # Load FAISS index and matn map
            print("📦 Loading FAISS index")
            index, matn_map = load_index(projectName)

            # Perform hybrid search
            print("⚡ Performing FAISS + Re-rank search")
            results = hybrid_query(index, _queryEmbedding, matn_map, hadith_embeddings)

            # Filter results by threshold
            filtered_results = [
                {"matn": matn, "similarity": score}
                for matn, score in results
                if score >= threshold
            ]

            print(f"Found {len(filtered_results)} results above threshold {threshold}")
            return filtered_results

        except FileNotFoundError as e:
            print(f"Error: {e}")
            raise
        except Exception as e:
            print(f"Error during semantic search: {e}")
            raise


    

    def sortHadith(
        self, byNarrator: bool, byGrade: bool, gradeType: str, hadithList: List[str]
    ) -> List[dict]:
        resultant_hadith_list = []
        narrator_count = {}
        hadiths = []
        matn_pattern = r"matn:\s*(.*?),"
        similarity_pattern = r"similarity:\s*(\d+\.\d+)"
        # Loop through each string in the list
        for h in hadithList:
            hadith = {}
            # Extracting matn and similarity
            matn_match = re.search(matn_pattern, h)
            similarity_match = re.search(similarity_pattern, h)
            # Assign values to the hadith dictionary if found
            if matn_match:
                hadith["matn"] = matn_match.group(1).strip()
            if similarity_match:
                hadith["similarity"] = float(similarity_match.group(1))
            # Append the dictionary to the list
            hadiths.append(hadith)
        if byNarrator:
            for h in hadiths:
                _matn = h.get("matn", "")
                if not isinstance(_matn, str):
                    raise ValueError(
                        f"Invalid 'matn' value: expected string, got {type(_matn).__name__}"
                    )
                _similarity = h.get("similarity", None)
                if _similarity is None:
                    raise ValueError("Similarity not found in the dictionary.")
                # If similarity exists and is not a float, raise an error
                if not isinstance(_similarity, float):
                    raise ValueError(
                        f"Invalid 'similarity' value: expected float, got {type(_similarity).__name__}"
                    )
                narrator_name = self.__dalFascade.getHadithFirstNarrator(_matn)
                if not narrator_name:
                    continue

                hadith_entry = {
                    "matn": _matn,
                    "narratorName": narrator_name,
                    "similarity": _similarity,
                }
                resultant_hadith_list.append(hadith_entry)
                if narrator_name in narrator_count:
                    narrator_count[narrator_name] += 1
                else:
                    narrator_count[narrator_name] = 1
                print(resultant_hadith_list)

            resultant_hadith_list.sort(
                key=lambda x: (-narrator_count[x["narratorName"]], x["narratorName"])
            )

        return resultant_hadith_list

    def generateHadithFile(self, path: str, HadithTO: List[HadithTO]) -> bool:
        return None

    # ---------------------------------Multi processing wala-----------------------------------------

    # def expandSearch(self, hadith_list: List[str], projectName: str, threshold: float) -> List[dict]:
    #     try:
    #         hadiths = []

    #         # Regular expressions to extract matn and similarity
    #         matn_pattern = r"matn:\s*(.*?),"
    #         similarity_pattern = r"similarity:\s*(\d+\.\d+)"
    #         # Loop through each string in the list
    #         for h in hadith_list:
    #             hadith = {}
    #             # Extracting matn and similarity
    #             matn_match = re.search(matn_pattern, h)
    #             similarity_match = re.search(similarity_pattern, h)

    #             # Assign values to the hadith dictionary if found
    #             if matn_match:
    #                 hadith["matn"] = matn_match.group(1).strip()

    #             if similarity_match:
    #                 hadith["similarity"] = float(similarity_match.group(1))

    #             # Append the dictionary to the list
    #             hadiths.append(hadith)

    #         # Step 1: Preprocessing with multiprocessing
    #         with multiprocessing.Pool(processes=multiprocessing.cpu_count()) as pool:
    #             # Map the _process_preprocessing function to each Hadith
    #             preprocessed_hadiths = pool.map(self._process_preprocessing, hadiths)

    #         # Step 2: Embedding generation with multiprocessing
    #         with multiprocessing.Pool(processes=multiprocessing.cpu_count()) as pool:
    #             # Map the _generate_embedding function to each preprocessed Hadith
    #             embeddings = pool.map(
    #                 self._generate_embedding_for_hadith, preprocessed_hadiths
    #             )

    #         # Step 3: Cosine similarity calculation with multiprocessing
    #         _hadithDict = self.dalFascade.getProjectHadithsEmbedding(projectName)

    #         if not _hadithDict:
    #             return []

    #         _batch_size = 100
    #         _batched_results = []
    #         _hadith_batches = self._createBatches(_hadithDict, _batch_size)

    #         with multiprocessing.Pool(processes=multiprocessing.cpu_count()) as pool:
    #             # Map the _process_cosine_similarity function to each batch
    #             _batched_results = pool.map(
    #                 self._process_cosine_similarity,
    #                 [(batch, embeddings) for batch in _hadith_batches],
    #             )

    #         # Flatten the list of results
    #         _batched_results = [item for sublist in _batched_results for item in sublist]

    #         # Step 4: Filtering and Sorting
    #         _filtered_results = [
    #             {"matn": result["matn"], "similarity": result["similarity"]}
    #             for result in _batched_results
    #             if result.get("similarity", 0) >= threshold
    #         ]
    #         _filtered_results.sort(key=lambda x: x["similarity"], reverse=True)
    #         _top_results = _filtered_results

    #         # Step 5: Removing duplicates by similarity for each unique matn
    #         seen_mats = {}
    #         for result in _top_results:
    #             matn = result["matn"]
    #             similarity = result["similarity"]

    #             if matn not in seen_mats or seen_mats[matn]["similarity"] < similarity:
    #                 seen_mats[matn] = result

    #         # Collect unique results
    #         _expanded_results = list(seen_mats.values())

    #         _expanded_results.sort(key=lambda x: x.get("similarity", 0), reverse=True)
    #         return _expanded_results

    #     except Exception as e:
    #         print(f"Error in expandSearch: {e}")
    #         return []

    # # Helper function for preprocessing in parallel
    # def _process_preprocessing(self, hadith):
    #     _matn = hadith.get("matn", "")
    #     if not isinstance(_matn, str):
    #         raise ValueError(
    #             f"Invalid 'matn' value: expected string, got {type(_matn).__name__}"
    #         )

    #     _cleaned_hadith = self._cleanHadithMatn(
    #         self._lemmatize_arabic_sentence(
    #             self._cleanHadithMatn(self._getActualMatn(_matn))
    #         )
    #     )
    #     return {"matn": _cleaned_hadith, "original": hadith}

    # # Helper function for generating embeddings in parallel
    # def _generate_embedding_for_hadith(self, preprocessed_hadith):
    #     cleaned_hadith = preprocessed_hadith["matn"]
    #     _queryEmbedding = self._generateEmbeddings(cleaned_hadith)
    #     return {"embedding": _queryEmbedding, "original": preprocessed_hadith}

    # # Helper function for cosine similarity calculation in parallel
    # def _process_cosine_similarity(self, batch_and_embeddings):
    #     batch, embeddings = batch_and_embeddings
    #     return self._cosineSimilarity(embeddings, batch)

    # --------------------------------------------------------------------------

    # def expandSearch(
    #     self, hadith_list: List[str], projectName: str, threshold: float
    # ) -> List[dict]:
    #     try:
    #         hadiths = []

    #         # Regular expressions to extract matn and similarity
    #         matn_pattern = r"matn:\s*(.*?),"
    #         similarity_pattern = r"similarity:\s*(\d+\.\d+)"
    #         # Loop through each string in the list
    #         for h in hadith_list:
    #             hadith = {}
    #             # Extracting matn and similarity
    #             matn_match = re.search(matn_pattern, h)
    #             similarity_match = re.search(similarity_pattern, h)

    #             # Assign values to the hadith dictionary if found
    #             if matn_match:
    #                 hadith["matn"] = matn_match.group(1).strip()

    #             if similarity_match:
    #                 hadith["similarity"] = float(similarity_match.group(1))

    #             # Append the dictionary to the list
    #             hadiths.append(hadith)
    #             print(hadiths)
    #         _expanded_results = []
    #         for hadith in hadiths:
    #             _matn = hadith.get("matn", "")
    #             if not isinstance(_matn, str):
    #                 raise ValueError(
    #                     f"Invalid 'matn' value: expected string, got {type(_matn).__name__}"
    #                 )

    #             _cleaned_hadith = self._cleanHadithMatn(
    #                 self._lemmatize_arabic_sentence(
    #                     self._cleanHadithMatn(self._getActualMatn(_matn)),
    #                     self.morphology_db,
    #                 )
    #             )
    #             print(_cleaned_hadith)
    #             _queryEmbedding = self._generateEmbeddings(
    #                 _cleaned_hadith, self.tokenizer, self.labse_model
    #             )
    #             _hadithDict = self.dalFascade.getProjectHadithsEmbedding(projectName)

    #             if not _hadithDict:
    #                 return []
    #             _batch_size = 100
    #             _batched_results = []
    #             _hadith_batches = self._createBatches(_hadithDict, _batch_size)

    #             for batch in _hadith_batches:
    #                 _batch_result = self._cosineSimilarity(_queryEmbedding, batch)
    #                 _batched_results.extend(_batch_result)

    #             _filtered_results = [
    #                 {"matn": result["matn"], "similarity": result["similarity"]}
    #                 for result in _batched_results
    #                 if result.get("similarity", 0) >= threshold
    #             ]
    #             _filtered_results.sort(key=lambda x: x["similarity"], reverse=True)
    #             _top_results = _filtered_results
    #             print(_top_results)
    #             _expanded_results.extend(_top_results)

    #         # Remove duplicates by keeping only the one with the highest similarity for each matn
    #         seen_mats = {}
    #         for result in _expanded_results:
    #             matn = result["matn"]
    #             similarity = result["similarity"]

    #             # If matn not seen or higher similarity, update
    #             if matn not in seen_mats or seen_mats[matn]["similarity"] < similarity:
    #                 seen_mats[matn] = result

    #         # Collect unique results
    #         _expanded_results = list(seen_mats.values())

    #         _expanded_results.sort(key=lambda x: x.get("similarity", 0), reverse=True)
    #         return _expanded_results

    #     except Exception as e:
    #         print(f"Error in expandSearch: {e}")
    #         return []

    def expandSearch(self, hadith_list: List[str], projectName: str, threshold: float) -> List[dict]:
        from concurrent.futures import ThreadPoolExecutor
        import re
        from services.semantic_index_service import (
            load_index,
            hybrid_query,
            json_to_np_array,
            convert_embeddings_for_faiss,
        )

        try:
            print("🔍 Starting optimized expandSearch")

            # Extract matn and similarity from input list
            hadiths = []
            matn_pattern = r"matn:\s*(.*?),"
            similarity_pattern = r"similarity:\s*(\d+\.\d+)"

            for h in hadith_list:
                matn_match = re.search(matn_pattern, h)
                similarity_match = re.search(similarity_pattern, h)

                if matn_match and similarity_match:
                    hadiths.append({
                        "matn": matn_match.group(1).strip(),
                        "similarity": float(similarity_match.group(1)),
                    })

            # Load FAISS index and Hadith embeddings once
            index, matn_map = load_index(projectName)
            hadith_dict = self.dalFascade.getProjectHadithsEmbedding(projectName)
            matns, embeddings = convert_embeddings_for_faiss(hadith_dict)
            hadith_embeddings = {matn: emb for matn, emb in zip(matns, embeddings)}

            # Function to preprocess and search one hadith
            def process_and_search(hadith):
                _matn = hadith["matn"]
                try:
                    cleaned = self._cleanHadithMatn(
                        self._lemmatize_arabic_sentence(
                            self._cleanHadithMatn(_matn),
                            self.morphology_db
                        )
                    )

                    if not cleaned.strip():
                        return []

                    query_emb = self._generateEmbeddings(cleaned, self.tokenizer, self.labse_model)
                    if not query_emb:
                        return []

                    query_emb = json_to_np_array(query_emb)
                    if query_emb is None:
                        return []

                    results = hybrid_query(index, query_emb, matn_map, hadith_embeddings)
                    return [
                        {"matn": matn, "similarity": score}
                        for matn, score in results
                        if score >= threshold
                    ]
                except Exception as e:
                    print(f"⚠️ Error processing matn: {e}")
                    return []

            # Run all queries in parallel
            _expanded_results = []
            with ThreadPoolExecutor() as executor:
                for result_list in executor.map(process_and_search, hadiths):
                    _expanded_results.extend(result_list)

            # Remove duplicates: keep highest similarity per matn
            seen = {}
            for r in _expanded_results:
                matn = r["matn"]
                if matn not in seen or seen[matn]["similarity"] < r["similarity"]:
                    seen[matn] = r

            final_results = list(seen.values())
            final_results.sort(key=lambda x: x["similarity"], reverse=True)

            print(f"✅ expandSearch completed with {len(final_results)} results")
            return final_results

        except Exception as e:
            print(f"❌ Error in expandSearch: {e}")
            return []




    # Private Funtions ---------------------------------------------------

    def _createBatches(self, data_dict: dict, batch_size: int) -> List[dict]:
        items = list(data_dict.items())
        return [
            dict(items[i : i + batch_size]) for i in range(0, len(items), batch_size)
        ]
    
    
    @staticmethod
    def _cleanHadithMatn(matn: str) -> str:
        # List of phrases to remove
        phrases_to_remove = [
            #  r"عن نبي صلي الله عليه وسلم",  # Fixed typo in the phrase
            r"قَالَ رَسُولُ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ",
            r"عَنِ النَّبِيِّ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ",
            r"عَنِ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ",
            r"صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ",
        ]
        cleaned_text = matn

        for phrase in phrases_to_remove:
            cleaned_text = re.sub(phrase, "", cleaned_text).strip()

        cleaned_text = re.sub(r"[إأٱآ]", "ا", cleaned_text)  # Normalize Alif variations
        cleaned_text = re.sub(r"ة", "ه", cleaned_text)  # Replace Taa Marbuta with Ha
        cleaned_text = re.sub(r"ى", "ي", cleaned_text)  # Replace Alif Maqsura with Ya
        cleaned_text = re.sub(r"[،؟:.]", "", cleaned_text)  # Remove punctuation
        cleaned_text = re.sub(
            r"[\u0617-\u061A\u064B-\u0652\u0670]", "", cleaned_text
        )  # Remove diacritics
        cleaned_text = re.sub(r"-", "", cleaned_text)  # Remove dashes
        cleaned_text = re.sub(r"\d+", "", cleaned_text)  # Remove numbers
        cleaned_text = re.sub(r"[^\w\s]", "", cleaned_text)  # Remove unwanted chars
        cleaned_text = re.sub(r"\s+", " ", cleaned_text).strip()  # Normalize spaces
        cleaned_text = re.sub(
            r"(\s+)(و)\1", r" \2", cleaned_text
        )  # Remove extra spaces between "و"

        return cleaned_text

    def _cosineSimilarity(self, queryEmbedding: str, hadith_embeddings: dict) -> dict:
        try:
            queryEmbedding = np.array(ast.literal_eval(queryEmbedding)).reshape(
                1, -1
            )  # Convert to 2D array for sklearn
            similarities = []
            for matn, embedding in hadith_embeddings.items():
                matnEmbedding = np.array(ast.literal_eval(embedding)).reshape(1, -1)
                similarity = cosine_similarity(queryEmbedding, matnEmbedding)[0][0]
                similarities.append(
                    {"matn": matn, "embedding": embedding, "similarity": similarity}
                )

            similarities.sort(key=lambda x: x["similarity"], reverse=True)
            return similarities[:10]

        except Exception as e:
            print(f"Error calculating cosine similarity: {e}")
            return []

    @staticmethod
    def _lemmatize_arabic_sentence(sentence: str, morphology_db: MorphologyDB) -> str:
        try:
            analyzer = Analyzer(morphology_db)
            cleaned_sentence = dediac_ar(sentence)
            words = simple_word_tokenize(cleaned_sentence)
            lemmatized_words = []

            for word in words:
                try:
                    analyses = analyzer.analyze(word)
                    if analyses:
                        lemmatized_words.append(analyses[0].get("lex", word))
                    else:
                        lemmatized_words.append(word)
                except Exception:
                    lemmatized_words.append(word)

            lemmatized_sentence = " ".join(lemmatized_words)
            return lemmatized_sentence
        except Exception as e:
            print(f"Error in lemmatizing sentence: {e}")
            return sentence

    @staticmethod
    def _generateEmbeddings(matn: str, token, labse_model) -> str:
        inputs = token(matn, return_tensors="pt", padding=True, truncation=True)
        with torch.no_grad():
            outputs = labse_model(**inputs)
        embedding = outputs.last_hidden_state[:, 0, :].squeeze().numpy()
        # print(embedding)
        # Convert the NumPy array (embedding) into a Python list (JSON serializable)
        embedding_list = embedding.tolist()

        # Convert the list into a JSON string with pretty print (indentation)
        embedding_json = json.dumps(embedding_list, indent=4, separators=(",", ": "))
        return embedding_json

    """   @staticmethod
   def _generateEmbeddingscfchgv(matn: str,labse_model) -> str:
        embedding = labse_model.encode([matn])[
            0
        ]  # Use the instance variable `labse_model`
        # Convert the NumPy array (embedding) into a Python list (JSON serializable)
        embedding_list = embedding.tolist()
        # Convert the list into a JSON string with pretty print (indentation)
        embedding_json = json.dumps(embedding_list, indent=4, separators=(",", ": "))
        return embedding_json

    def _generateEmbeddingsBatchaszs(self, matn_list: List[str]) -> List[str]:
        try:
            # Generate embeddings for the entire batch
            embeddings = self.labse_model.encode(
                matn_list, batch_size=32
            )  # Adjust batch_size based on hardware
            # Convert each NumPy embedding array to JSON-serializable string
            embedding_json_list = [
                json.dumps(embedding.tolist(), indent=4, separators=(",", ": "))
                for embedding in embeddings
            ]
            return embedding_json_list
        except Exception as e:
            print(f"Error generating embeddings for batch: {e}")
            return []
        """

    def _generateEmbeddingsBatch(self, matn_list: List[str]) -> List[str]:
        try:
            # Tokenize the batch of sentences
            inputs = self.tokenizer(
                matn_list, return_tensors="pt", padding=True, truncation=True
            )
            print("in batch")
            with torch.no_grad():
                outputs = self.model(**inputs)

            # Extract the sentence embeddings (CLS token representations)
            embeddings = outputs.last_hidden_state[:, 0, :].numpy()

            # Convert each NumPy embedding array to a JSON-serializable string
            embedding_json_list = [
                json.dumps(embedding.tolist(), indent=4, separators=(",", ": "))
                for embedding in embeddings
            ]

            return embedding_json_list

        except Exception as e:
            print(f"Error generating embeddings for batch: {e}")
            return []

    def _transformSanad(self, sanad: str) -> List[NarratorTO]:
        try:
            if sanad == "No SANAD":
                return []
            cleanedSanad = re.sub(r"</?IDF>", "", sanad)
            tokens = cleanedSanad.strip("[]").replace("'", "").split(",")

            narrators = []
            level = 0
            for token in tokens:
                level += 1
                narrator_name = token.strip()

                if narrator_name:
                    narrator = NarratorTO(0, narrator_name, level)
                    narrators.append(narrator)
            return narrators
        except Exception as e:
            print("Error transforming sanad:", e)
            return []

    def _insertHadithNarrators(self, sanad: str, narrators: List[NarratorTO]) -> bool:
        for narrator in narrators:
            success = self.dalFascade.insertNarrator(sanad, narrator)

            if not success:
                print(f"Failed to insert narrator: {narrator.narratorName}")
                return False

        print("All narrators inserted successfully.")
        return True

    @staticmethod
    def _clean_text(input_str: str) -> str:
        chars_to_remove = [",", "،", ".", '"', "“", "”"]
        for char in chars_to_remove:
            input_str = input_str.replace(char, "")
        input_str = " ".join(input_str.split())
        return input_str

    @staticmethod
    def _getActualMatn(input_str: str) -> str:
        # Regular expression to match text within quotation marks
        match = re.search(r'["“](.*?)["”]', input_str)
        if match:
            result = match.group(1).strip()  # Extract text inside quotation marks
        elif ":" in input_str:
            # Get text after the first colon
            result = input_str.split(":", 1)[-1].strip()
        else:
            # Return the original string if no colon or quotation marks are found
            result = input_str

        return result

    def getAllHadithsOfProject(self, projectName: str, page: int) -> dict:
        self.initialize_or_rebuild_index(projectName, False)
        return self.__dalFascade.getAllHadithsOfProject(projectName, page)

    def initialize_or_rebuild_index(self, project_name: str, must_build: bool):
        from services.semantic_index_service import (
            convert_embeddings_for_faiss,
            check_index_exists,
            build_faiss_index,
        )

        if check_index_exists(project_name) and not must_build:
            print(f"FAISS index already exists for '{project_name}'. Skipping rebuild.")
            return

        print(f"FAISS index not found for '{project_name}', rebuilding...")

        # Retrieve Hadith embeddings from DAL
        hadith_dict = self.dalFascade.getProjectHadithsEmbedding(project_name)

        # Convert embeddings to FAISS-compatible format
        hadith_ids, embeddings_np = convert_embeddings_for_faiss(hadith_dict)

        # Optionally: Filter out invalid embeddings
        expected_dim = 768
        filtered_hadiths = []
        filtered_embeddings = []
        for matn, emb in zip(hadith_ids, embeddings_np):
            if emb.shape[0] == expected_dim:
                filtered_hadiths.append(matn)
                filtered_embeddings.append(emb)
            else:
                print(f"Skipping Hadith due to shape mismatch: {matn[:60]}...")

        # Build FAISS index using filtered data
        build_faiss_index(filtered_hadiths, filtered_embeddings, project_name)

        print(f"FAISS index for project '{project_name}' rebuilt and saved.")

    def stringBasedSearch(self, query: str, project_name: str) -> List[str]:
        cleanQuery=self.remove_diacritics(query)
        return self.__dalFascade.stringBasedSearch(cleanQuery,project_name)
    def rootBasedSearch(self, query: str, project_name: str, page: int) -> dict:
        cleanQuery=self.remove_diacritics(query)
        return self.__dalFascade.rootBasedSearch(cleanQuery,project_name,page)
    def operatorBasedSearch(self,query:str,project_name:str)->List[str]:
        cleanQuery=self.remove_diacritics(query)
        return self.__dalFascade.operatorBasedSearch(cleanQuery,project_name)
    def generate_arabic_search_query(self,question: str) -> str:
        headers = {
                "Authorization": f"Bearer {self.API_KEY}",
                "Content-Type": "application/json"
            }
        
        prompt = f"""You are an assistant that specializes in converting user questions into clear and accurate Arabic search queries suitable for querying Hadith databases.Your task is to:

                    Translate the question into formal Arabic using correct Islamic terminology.

                    Remove all interrogative words such as: how, what, when, why, how many, etc.

                    Preserve only the essential nouns and verbs. dont include Prophet Muhammad (peace be upon him)

                    Ensure the result is a grammatically correct and semantically faithful Arabic phrase that reflects the user’s intent.

                    Output the final Arabic search phrase only — no explanations, no quotes, no extra formatting.

                    Examples:

                    Q: "How to perform wudu?"
                    A: طريقة الوضوء

                    Q: "How many rak'ahs in Isha?"
                    A: عدد ركعات صلاة العشاء

                    Q: "What is the ruling on fasting while traveling?"
                    A: حكم الصيام أثناء السفر

                    Q: "Is it allowed to delay salah?"
                    A: حكم تأخير الصلاة

                    Now convert the following question:

                    Q: "{question}"
                    A:
                    """
            
            
        data = {
                "model": self.LLM_MODEL,
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a helpful assistant that converts English questions into search-friendly Arabic phrases for Islamic content."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                "temperature": 0.0
            }

        response = requests.post(self.API_URL, headers=headers, json=data)
        response.raise_for_status()
        arabic_query = response.json()["choices"][0]["message"]["content"].strip()

        if not any(char in arabic_query for char in "ءآأؤإئابةتثجحخدذرزسشصضطظعغفقكلمنهوىي"):
            raise ValueError("Non-Arabic output generated")
        return arabic_query
    
    
    def hadith_rag(
        self,
        question: str,
        projectName: str
    ) -> dict:
       
        arabic_query = self.generate_arabic_search_query(question)
        print(arabic_query)
        self.initialize_or_rebuild_index(projectName, False)
    
        
        if projectName == "":
            hadiths = self.semanticSearchGlobal(
                hadith=arabic_query,
                projectName=projectName,
                threshold=0.85
            )
        else:
            hadiths = self.semanticSearch(
                hadith=arabic_query,
                projectName=projectName,
                threshold=0.85
            )
            
        if not hadiths:
            return {
                "answer": "I cannot find a reliable reference. [[Confidence: 0%]]",
                "references": [],
                "retrieval_confidence": 0.0
            }

        # Step 4: Format the Hadiths for the LLM context
        hadiths_str = "\n".join(
            f"[Hadith {i+1}] {h['matn']} (Similarity: {h['similarity'] * 100:.0f}%)"
            for i, h in enumerate(hadiths[:10])
        )
        print(hadiths_str)

        # Step 5: Prepare the LLM prompt
        prompt = f"""
    As a Hadith scholar, answer using ONLY these Hadiths:
    {hadiths_str}

    Question: {question}

    Requirements:
    1. Start with "According to [Hadith X]"
    2. Keep Arabic text verbatim and give translaion in english in brackets
    3. End with "[[Confidence: X%]]" (0–100%)
    4. Confidence must reflect:
    - Match quality (higher for exact answers)
    - Clarity of evidence

    Example Response:
    "According to [Hadith text3], the Prophet said: «الصلاة في وقتها» (Pray on time) [[Confidence: 90%]]"
        """.strip()

        # Step 6: Generate answer using the language model
        try:
            headers = {
                "Authorization": f"Bearer {self.API_KEY}",  # Make sure this is valid!
                "Content-Type": "application/json"
            }

            response = requests.post(
                self.API_URL,
                headers=headers,
                json={
                    "model": self.LLM_MODEL,
                    "messages": [{"role": "user", "content": prompt}],
                    "temperature": 0.1
                },
                timeout=30
            )

            response.raise_for_status()  # Raise error if status code is 4xx or 5xx
            data = response.json()

            # Access message content safely
            answer = data.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
            if not answer:
                answer = "No answer returned. [[Confidence: 0%]]"
            elif "[[Confidence:" not in answer:
                answer += " [[Confidence: 20%]]"

        except requests.exceptions.HTTPError as e:
            print(f"HTTP error: {e}")
            print(f"Response content: {response.text}")
            answer = "Authentication failed or invalid API request. [[Confidence: 0%]]"

        except Exception as e:
            print(f"LLM error: {e}")
            answer = "Unexpected error while generating answer. [[Confidence: 0%]]"


        
        result = answer

        return result






