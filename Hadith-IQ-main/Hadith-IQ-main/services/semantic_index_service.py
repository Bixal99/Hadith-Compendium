import json
import faiss
import numpy as np
import os
import pickle
from typing import List, Tuple, Dict

BASE_INDEX_DIR = "faiss_indexes"
TOP_K = 500  # Can be tuned

def get_index_path(project_name: str) -> str:
    """Generate path for FAISS index file."""
    os.makedirs(BASE_INDEX_DIR, exist_ok=True)
    return os.path.join(BASE_INDEX_DIR, f"faiss_index_{project_name}.bin")

def get_matn_map_path(project_name: str) -> str:
    """Generate path for matn map file."""
    os.makedirs(BASE_INDEX_DIR, exist_ok=True)
    return os.path.join(BASE_INDEX_DIR, f"faiss_matn_map_{project_name}.pkl")

def check_index_exists(project_name: str) -> bool:
    """Check if FAISS index and matn map files exist."""
    index_path = get_index_path(project_name)
    matn_map_path = get_matn_map_path(project_name)
    print(f"Checking for FAISS index at: {index_path}")
    print(f"Checking for matn map at: {matn_map_path}")
    return os.path.exists(index_path) and os.path.exists(matn_map_path)

def build_faiss_index(hadith_matns: List[str], embeddings: List[np.ndarray], project_name: str):
    """Build and save a FAISS index for Hadith embeddings."""
    if not hadith_matns or not embeddings:
        raise ValueError("Empty Hadith matns or embeddings provided for FAISS index.")
    
    if len(hadith_matns) != len(embeddings):
        raise ValueError("Mismatch between number of Hadith matns and embeddings.")

    expected_shape = embeddings[0].shape
    for idx, emb in enumerate(embeddings):
        if not isinstance(emb, np.ndarray):
            raise ValueError(f"Embedding at idx={idx} is not a numpy array: {type(emb)}")
        if emb.shape != expected_shape:
            raise ValueError(f"Embedding at idx={idx} has mismatched shape: {emb.shape} != {expected_shape}")

    print(f"Starting FAISS index creation for project '{project_name}'...")
    print(f"Received {len(hadith_matns)} Hadith embeddings with shape {expected_shape}")

    dim = embeddings[0].shape[0]
    index = faiss.IndexFlatIP(dim)
    matn_map = {}
    vectors = []

    print(f"Processing {len(hadith_matns)} embeddings...")

    skipped_due_to_nan = 0
    skipped_due_to_zero = 0
    skipped_due_to_norm = 0
    skipped_due_to_exception = 0

    for idx, (matn, emb) in enumerate(zip(hadith_matns, embeddings)):
        try:
            vec = np.array(emb, dtype=np.float32)
            if np.isnan(vec).any() or np.isinf(vec).any():
                print(f"Skipping idx={idx}, Hadith: {matn[:60]}... due to NaN/Inf. "
                      f"Min={np.min(vec)}, Max={np.max(vec)}")
                skipped_due_to_nan += 1
                continue

            norm = np.linalg.norm(vec)
            if norm == 0:
                print(f"Skipping idx={idx}, Hadith: {matn[:60]}... due to zero vector")
                skipped_due_to_zero += 1
                continue

            if not np.isclose(norm, 1.0, rtol=1e-5):
                normalized_vec = vec / norm
                if np.isnan(normalized_vec).any() or np.isinf(normalized_vec).any():
                    print(f"Skipping idx={idx}, Hadith: {matn[:60]}... due to NaN/Inf after normalization. "
                          f"Original norm={norm}")
                    skipped_due_to_norm += 1
                    continue
                vec = normalized_vec

            vectors.append(vec)
            matn_map[len(vectors) - 1] = matn
        except Exception as e:
            print(f"Error processing idx={idx}, Hadith: {matn[:60]}...: {e}")
            skipped_due_to_exception += 1
            continue

    print(f"Finished processing embeddings.")
    print(f"Total valid vectors: {len(vectors)}")
    print(f"Skipped due to NaN/Inf: {skipped_due_to_nan}")
    print(f"Skipped due to zero vectors: {skipped_due_to_zero}")
    print(f"Skipped due to NaN/Inf after normalization: {skipped_due_to_norm}")
    print(f"Skipped due to other exceptions: {skipped_due_to_exception}")

    if not vectors:
        print("No valid vectors to index. Aborting FAISS index creation.")
        return

    vectors = np.vstack(vectors)
    print(f"Adding {len(vectors)} vectors to FAISS index...")
    index.add(vectors)
    print("Vectors added to FAISS index.")

    index_path = get_index_path(project_name)
    matn_map_path = get_matn_map_path(project_name)
    print(f"Saving FAISS index to: {index_path}")
    print(f"Saving matn map to: {matn_map_path}")
    
    faiss.write_index(index, index_path)
    with open(matn_map_path, "wb") as f:
        pickle.dump(matn_map, f)

    print(f"FAISS index and matn map saved for project '{project_name}'.")

def load_index(project_name: str) -> Tuple[faiss.IndexFlatIP, Dict[int, str]]:
    """Load FAISS index and matn map."""
    index_path = get_index_path(project_name)
    matn_map_path = get_matn_map_path(project_name)

    if not os.path.exists(index_path):
        raise FileNotFoundError(f"FAISS index not found at {index_path}")
    if not os.path.exists(matn_map_path):
        raise FileNotFoundError(f"Matn map not found at {matn_map_path}")

    try:
        index = faiss.read_index(index_path)
        with open(matn_map_path, "rb") as f:
            matn_map = pickle.load(f)
        print(f"Loaded FAISS index with {index.ntotal} vectors and matn map with {len(matn_map)} entries")
        return index, matn_map
    except Exception as e:
        raise Exception(f"Error loading FAISS index or matn map: {e}")

def hybrid_query(
    index: faiss.IndexFlatIP,
    query_vec: np.ndarray,
    matn_map: Dict[int, str],
    hadith_embeddings: Dict[str, np.ndarray],
    top_k: int = TOP_K
) -> List[Tuple[str, float]]:
    """Perform FAISS search and re-rank results using cosine similarity."""

    vec = np.array(query_vec, dtype=np.float32)
    if vec.shape != (index.d,):
        raise ValueError(f"Query embedding shape {vec.shape} does not match index dimension {index.d}")
    
    norm = np.linalg.norm(vec)
    if norm == 0:
        raise ValueError("Query embedding is a zero vector")
    if not np.isclose(norm, 1.0, rtol=1e-5):
        vec = vec / norm
    
    vec = vec.reshape(1, -1)
    scores, indices = index.search(vec, top_k)

    results = []
    skipped = 0
    for idx, score in zip(indices[0], scores[0]):
        if idx == -1 or idx not in matn_map:
            skipped += 1
            continue
        matn = matn_map[idx]
        if matn not in hadith_embeddings:
            print(f"Warning: Matn '{matn[:60]}...' not found in hadith_embeddings")
            skipped += 1
            continue
        
        try:
            hadith_vec = np.array(hadith_embeddings[matn], dtype=np.float32)
            if np.isnan(hadith_vec).any() or np.isinf(hadith_vec).any():
                print(f"Skipping matn '{matn[:60]}...' due to NaN/Inf in embedding")
                skipped += 1
                continue
            
            norm = np.linalg.norm(hadith_vec)
            if norm == 0:
                print(f"Skipping matn '{matn[:60]}...' due to zero vector")
                skipped += 1
                continue
            hadith_vec = hadith_vec / norm

            similarity = float(np.dot(hadith_vec, vec.flatten()))
            if np.isnan(similarity) or np.isinf(similarity):
                print(f"Skipping matn '{matn[:60]}...' due to invalid similarity score")
                skipped += 1
                continue
            results.append((matn, similarity))
        except Exception as e:
            print(f"Error processing matn '{matn[:60]}...': {e}")
            skipped += 1
            continue

    if skipped > 0:
        print(f"Skipped {skipped} results due to missing matns or invalid embeddings")

    results.sort(key=lambda x: x[1], reverse=True)
    return results[:top_k]


def json_to_np_array(json_string: str) -> np.ndarray:
    try:
        embedding_list = json.loads(json_string)  # Parse the JSON string into a list
        return np.array(embedding_list, dtype=np.float32)  # Convert the list to a NumPy array
    except Exception as e:
        print(f"Error converting JSON to NumPy array: {e}")
        return None

def convert_embeddings_for_faiss(hadith_dict: dict) -> tuple:
    try:
        # Prepare the list of Hadith identifiers
        matn = list(hadith_dict.keys())
            
        # Convert each embedding to a NumPy array and collect in a list
        embeddings = []
        for embedding_json in hadith_dict.values():
            embedding_np = json_to_np_array(embedding_json)
            if embedding_np is not None:
                embeddings.append(embedding_np)
            
        # Convert the list of embeddings into a NumPy array for FAISS
        embeddings_np = np.stack(embeddings, axis=0)  # Stack the embeddings into a single 2D array (N x D)

        return matn, embeddings_np
        
    except Exception as e:
        print(f"Error converting embeddings for FAISS: {e}")
        return [], np.array([])

