import time
from typing import List
from DataAccessLayer.Fascade.AbsDALFascade import AbsDALFascade
from BusinessLogicLayer.Narrator.AbsNarratorBO import AbsNarratorBO
from TO.HadithTO import HadithTO
from TO.NarratorTO import NarratorTO
import os
import html2text
import requests
import configparser
import json
import re
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
from collections import Counter
from typing import List, Tuple
from transformers import pipeline
import ast


class NarratorBO(AbsNarratorBO):
    

    def __init__(self, dalFascade: AbsDALFascade):
        self.__dalFascade = dalFascade
        config = configparser.ConfigParser()
        import os
        config_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "config.properties")
        config.read(config_path)
        self.API_URL = config.get("API", "API_URL")
        self.API_KEY = config.get("API", "API_KEY")
        self.LLM_MODEL = config.get("API", "LLM_MODEL")
        self.DIACRITICS_PATTERN = re.compile(r"[\u064B-\u065F\u0617-\u061A]")
        self.model_name="CAMeL-Lab/bert-base-arabic-camelbert-ca-sentiment"
        try:
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)
            self.model = AutoModelForSequenceClassification.from_pretrained(self.model_name)
            print("✓ Arabic sentiment model loaded successfully")
        except Exception as e:
            print(f"⚠️  Warning: Could not load Arabic sentiment model: {e}")
            print("⚠️  Using fallback mode - sentiment analysis may be limited")
            self.tokenizer = None
            self.model = None

    @property
    def dalFascade(self) -> AbsDALFascade:
        return self.__dalFascade

    @dalFascade.setter
    def dalFascade(self, value):
        self.__dalFascade = value
    
    def getNarratedHadiths(self, project_name: str, narrator_name: str) -> dict:
        _name=self.remove_diacritics(narrator_name)
        return self.__dalFascade.getNarratedHadiths(project_name,_name)

    def getNarratorChains(self, project_name: str, narrator_name: str) -> dict:
        _name=self.remove_diacritics(narrator_name)
        return self.__dalFascade.getNarratorChains(project_name,_name)


    
    def searchNarrator(self,narrator:str)->dict:
        name=self.remove_diacritics(narrator)
        return self.__dalFascade.getSimilarNarrator(name)

    
    def getNarratorDetails(self,narratorName:str,projectName:str)->dict:
        return self.__dalFascade.getNarratorDetails(narratorName,projectName)


    def getAllNarratorsOfProject(self, project_name: str,page :int) -> dict:
        return self.__dalFascade.getAllNarratorsOfProject(project_name,page)
    def convertHtmlToText(self, html_file: str) -> dict:
        try:
            with open(html_file, 'r', encoding='utf-8') as file:
                html_content = file.read()
            text_maker = html2text.HTML2Text()
            text_maker.ignore_links = True
            text = text_maker.handle(html_content)
            current_dir = os.getcwd()
            narrator_dir = os.path.join(current_dir, "NarratorFiles")
            os.makedirs(narrator_dir, exist_ok=True)
            base_filename = os.path.splitext(os.path.basename(html_file))[0]  
            save_path = os.path.join(narrator_dir, f"{base_filename}.txt")
            with open(save_path, 'w', encoding='utf-8') as output_file:
                output_file.write(text)

            print(f"File saved at: {save_path}")
            return {"success": True, "filePath": save_path}
        except Exception as e:
            print(f"Error converting HTML to text: {e}")
            return {"success": False, "filePath": "no file path"}

    def remove_diacritics(self, text):
        """Remove diacritics (Tashkeel) from Arabic text."""
        return self.DIACRITICS_PATTERN.sub("", text)
    
    def arabic_to_int(self, arabic_num):
        """Convert Arabic numerals to an integer."""
        arabic_digits = "٠١٢٣٤٥٦٧٨٩"
        return int("".join(str(arabic_digits.index(digit)) for digit in arabic_num))

    def int_to_arabic(self, number):
        """Convert an integer to Arabic numerals."""
        arabic_digits = "٠١٢٣٤٥٦٧٨٩"
        return "".join(arabic_digits[int(digit)] for digit in str(number))

    def increment_arabic_number(self, arabic_num):
        num = self.arabic_to_int(arabic_num)
        num += 1
        return self.int_to_arabic(num)

    def cleanNarratorTxtFile(self, file, count) -> dict:
        _arabic_count=self.int_to_arabic(count)
        _jildNum = 0
        _jildOneStart = False
        _c = 0
        _skipping = False
        _bookStart = False
        _nameCategory = []
        input_file=""

        try:
            _current_dir = os.getcwd()
            _narrator_dir = os.path.join(_current_dir, "NarratorFiles")
            os.makedirs(_narrator_dir, exist_ok=True)
            file_input_name= os.path.splitext(os.path.basename(file))[0]
            input_file = os.path.join(_narrator_dir, f"{file_input_name}.txt")
            _base_filename = os.path.splitext(os.path.basename(input_file))[0]
            _output_filename = f"{_base_filename}_structured.txt"
            _output_path = os.path.join(_narrator_dir, _output_filename)

            with open(input_file, 'r', encoding='utf-8') as infile, \
                open(_output_path, 'a', encoding='utf-8') as outfile:
                for line in infile:
                    try:
                        _cleanLine = self.remove_diacritics(line)

                        if 'تهذيب الكمال في أسماء الرجال' in line and not _bookStart:
                            for _ in range(2):
                                for _ in range(2):
                                    line = next(infile, None)
                                    if line is None:
                                        print("Warning: Unexpected end of file.")
                                        break
                            if line and 'القسم:' in line:
                                _skipping = True
                                _bookStart = True
                                print("Start of Jild")
                                continue

                        if 'تهذيب الكمال في أسماء الرجال - جـ 1' in line and _bookStart and not _jildOneStart:
                            _match = re.search(r"جـ (\d+)", line)
                            _jildNum = int(_match.group(1)) if _match else 0
                            for _ in range(4):
                                line = next(infile, None)
                                if line is None:
                                    print("Warning: Unexpected end of file.")
                                    break
                            if line and '‌باب الألف' in line:
                                _jildOneStart = True
                                _skipping = False
                                continue

                        if '* * *' in line and _bookStart:
                            _skipping = True
                            continue

                        if 'تهذيب الكمال في أسماء الرجال - جـ 1' in line and _jildOneStart:
                            for _ in range(2):
                                line = next(infile, None)
                                if line is None:
                                    print("Warning: Unexpected end of file.")
                                    break
                            if line and '* * *' in line:
                                _skipping = False
                                continue
                        elif 'تهذيب الكمال في أسماء الرجال - جـ' in line and _jildNum != 1:
                            for _ in range(2):
                                line = next(infile, None)
                                if line is None:
                                    print("Warning: Unexpected end of file.")
                                    break
                            if line and '* * *' in line:
                                _skipping = False
                                continue

                        if not _skipping and (bool(re.search(r'\bمن اسمه\b', _cleanLine)) or bool(re.search(r'\bمن اسمه\b', line))):
                            line = _cleanLine.replace('من اسمه', "").strip().replace("\u200c", "")
                            _nameCategory.append(line.strip())
                            outfile.write(f'\n+++++==================== من اسمه {_nameCategory[-1]} ====================+++++\n')
                            continue

                        if not _skipping:
                            if line:
                                if _jildNum == 1 and (_arabic_count + "-") in line:
                                    outfile.write(f'++-------------------- {_arabic_count} --------------------++\n')
                                    _arabic_count = self.increment_arabic_number(_arabic_count)
                                    _c += 1
                                elif _jildNum != 1 and _arabic_count in line:
                                    outfile.write(f'++-------------------- {_arabic_count} --------------------++\n')
                                    _arabic_count = self.increment_arabic_number(_arabic_count)
                                outfile.write(line.strip() + '\n')
                    except Exception as e:
                        print(f"Error processing line: {line}. Error: {e}")

            print(_jildNum, _nameCategory, len(_nameCategory))
            return {"success": True }

        except FileNotFoundError:
            print(f"Error: The file '{input_file}' was not found.")
            return {"success": False, "error": "File not found"}

        except IOError as e:
            print(f"IOError: {e}")
            return {"success": False, "error": str(e)}

        except Exception as e:
            print(f"Unexpected error: {e}")
            return {"success": False, "error": str(e)}
    
    

    def extract_json(self,response_text):
        
        match = re.search(r'```json\n(.*?)\n```', response_text, re.DOTALL)
        
        if match:
            json_content = match.group(1)  
            try:
                return json.loads(json_content) 
            except json.JSONDecodeError as e:
                print("Error decoding JSON:", e)
                return None
        else:
            print("No valid JSON found in response.")
            return None
    
    def extract_section(self,file_path, count)->str:
        arabic_count=self.int_to_arabic(count)

        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()

            arabic_count_str = self.int_to_arabic(arabic_count)
            next_arabic_count_str = self.increment_arabic_number(arabic_count_str)
            start_marker = f"++-------------------- {arabic_count_str} --------------------++"
            end_marker = f"++-------------------- {next_arabic_count_str} --------------------++"
            start_index = content.find(start_marker)
            end_index = content.find(end_marker)
            if start_index == -1:
                return f"Start marker '{start_marker}' not found."
            if end_index == -1:
                return f"End marker '{end_marker}' not found."
            section = content[start_index:end_index].strip()
            return section

        except FileNotFoundError:
            return f"File '{file_path}' not found."
        except Exception as e:
            return f"An error occurred: {e}"
    

    # def fetch_narrator_data(self, file_path: str, arabic_count: int) -> dict:
    #     _current_dir = os.getcwd()
    #     _narrator_dir = os.path.join(_current_dir, "NarratorFiles")
    #     file_input_name= os.path.splitext(os.path.basename(file_path))[0]
    #     input_file = os.path.join(_narrator_dir, f"{file_input_name}_structured.txt")
    #     input_text = self.extract_section(input_file, arabic_count)
    #     headers = {
    #         "Authorization": f"Bearer {self.API_KEY}",
    #         "Content-Type": "application/json"
    #     }
    #     prompt_1 = f'''
    #     Create a JSON structure with 'narrator_name', 'learned_from' and 'learned_to' from the following text:
    #     - Narrator Name (the main subject of the entry)
    #     - Learned From: ("\u0631\u064E\u0648\u064E\u0649 \u0639\u064E\u0646") or ("رَوَى عَن") or ("عَن")
    #     - Learned To: ("\u0631\u064E\u0648\u064E\u0649 \u0639\u064E\u0646\u0647") or ("رَوَى عَنه") or ("عَنه")
        
    #     Here is the input text:
    #     {input_text}
    #     '''
    #     data_1 = {
    #         "model": self.LLM_MODEL,
    #         "messages": [{"role": "user", "content": prompt_1}],
    #     }
        
    #     response_1 = requests.post(self.API_URL, json=data_1, headers=headers)
        
    #     if response_1.status_code == 200:
    #         response_data_1 = response_1.json()
    #         answer_1 = response_data_1.get("choices", [{}])[0].get("message", {}).get("content", "{}")
    #         structured_data_1 = self.extract_json(answer_1)
    #         prompt_2 = f'''
    #         Create a JSON structure of all scholarly opinions about the narrator from the following text.
    #         The JSON should contain:
    #         - "narrator_name"
    #         - "opinions": List of objects with:
    #         - "scholar_name" (the scholar giving the opinion)
    #         - "opinion" (the scholar's opinion about the narrator)
            
            
    #         Here is the input text:
    #         {input_text}
    #         '''
    #         data_2 = {
    #             "model": self.LLM_MODEL,
    #             "messages": [{"role": "user", "content": prompt_2}],
    #         }
            
    #         response_2 = requests.post(self.API_URL, json=data_2, headers=headers)
            
    #         if response_2.status_code == 200:
    #             response_data_2 = response_2.json()
    #             answer_2 = response_data_2.get("choices", [{}])[0].get("message", {}).get("content", "{}")
    #             structured_data_2 = self.extract_json(answer_2)
    #             final_response = {
    #                 "response_1": structured_data_1,
    #                 "response_2": structured_data_2
    #             }
                
    #             return final_response
    #         else:
    #             return f"Failed to fetch scholars' opinions. Status Code: {response_2.status_code}"
        
    #     else:
    #         return f"Failed to fetch data from API. Status Code: {response_1.status_code}"
        
    def fetch_narrator_data(self, file_path: str, arabic_count: int) -> dict:
        _current_dir = os.getcwd()
        _narrator_dir = os.path.join(_current_dir, "NarratorFiles")
        file_input_name = os.path.splitext(os.path.basename(file_path))[0]
        input_file = os.path.join(_narrator_dir, f"{file_input_name}_structured.txt")
        input_text = self.extract_section(input_file, arabic_count)

        headers = {
            "Authorization": f"Bearer {self.API_KEY}",
            "Content-Type": "application/json"
        }

        # Prompt 1: Relationship extraction
        prompt_1 = f'''
        Create a JSON structure with 'narrator_name', 'learned_from' and 'learned_to' from the following text:
        - Narrator Name (the main subject of the entry)
        - Learned From: ("\u0631\u064E\u0648\u064E\u0649 \u0639\u064E\u0646") or ("رَوَى عَن") or ("عَن")
        - Learned To: ("\u0631\u064E\u0648\u064E\u0649 \u0639\u064E\u0646\u0647") or ("رَوَى عَنه") or ("عَنه")

        Here is the input text:
        {input_text}
        '''

        data_1 = {
            "model": self.LLM_MODEL,
            "messages": [
                {"role": "system", "content": "You are a helpful assistant extracting structured data of narrators from Arabic biographical texts."},
                {"role": "user", "content": prompt_1}
            ],
            "temperature": 0.0,
        }

        response_1 = requests.post(self.API_URL, json=data_1, headers=headers)

        if response_1.status_code == 200:
            answer_1 = response_1.json().get("choices", [{}])[0].get("message", {}).get("content", "{}")
            structured_data_1 = self.extract_json(answer_1)

            # Prompt 2: Scholar opinions
            prompt_2 = f'''
            Create a JSON structure of all scholarly opinions about the narrator from the following text.
            The JSON should contain:
            - "narrator_name"
            - "opinions": List of objects with:
            - "scholar_name" (the scholar giving the opinion)
            - "opinion" (the scholar's opinion about the narrator)

            Here is the input text:
            {input_text}
            '''

            data_2 = {
                "model": self.LLM_MODEL,
                "messages": [
                    {"role": "system", "content": "You are a helpful assistant extracting scholarly opinions of narrators."},
                    {"role": "user", "content": prompt_2}
                ],
                "temperature": 0.0,
            }

            response_2 = requests.post(self.API_URL, json=data_2, headers=headers)

            if response_2.status_code == 200:
                answer_2 = response_2.json().get("choices", [{}])[0].get("message", {}).get("content", "{}")
                structured_data_2 = self.extract_json(answer_2)

                return {
                    "response_1": structured_data_1,
                    "response_2": structured_data_2
                }
            else:
                return {
                    "error": f"Failed to fetch scholars' opinions. Status Code: {response_2.status_code}",
                    "details": response_2.text
                }
        else:
            return {
                "error": f"Failed to fetch relationship data. Status Code: {response_1.status_code}",
                "details": response_1.text
            }
    
    def getAllNarrators(self, page: int) -> dict:
        return self.__dalFascade.getAllNarrators(page)
    def sortNarrators(self,project_name: str,narrator_list: List[str],ascending: bool,authenticity:bool) -> List[str]:
        return self.__dalFascade.sortNarrators(project_name,narrator_list,ascending,authenticity)
    def combined_sentimentss(self,texts: List[str]) -> str:
        if not texts:
            return "NOT_KNOWN" 

        model_name = "CAMeL-Lab/bert-base-arabic-camelbert-mix-sentiment"
        tokenizer = AutoTokenizer.from_pretrained(model_name)
        model = AutoModelForSequenceClassification.from_pretrained(model_name)

        sentiment_pipeline = pipeline("sentiment-analysis", model=model, tokenizer=tokenizer)
        results = sentiment_pipeline(texts, truncation=True)

        sentiments = [res['label'] for res in results]
        sentiment_counts = Counter(sentiments)

        top_sentiments = sentiment_counts.most_common()

        if len(top_sentiments) == 0:
            return "NOT_KNOWN"
        if len(top_sentiments) > 1 and top_sentiments[0][1] == top_sentiments[1][1]:
            if "NEUTRAL" in sentiment_counts and sentiment_counts["NEUTRAL"] > top_sentiments[0][1]:
                return "NEUTRAL"
            else:
                return "NEUTRAL"

        return top_sentiments[0][0]
    
    def combined_sentiment(self, texts: List[str]) -> Tuple[str, float]:
        if not texts:
            return "not known", 0.0
        
        sentiment_pipeline = pipeline("sentiment-analysis", model=self.model, tokenizer=self.tokenizer)
        results = sentiment_pipeline(texts, truncation=True,max_length=512)
        sentiments = [res['label'].lower() for res in results]
        sentiment_counts = Counter(sentiments)
        total = sum(sentiment_counts.values())

        if not total:
            return "not known", 0.0

        top_sentiments = sentiment_counts.most_common()

        # Handle tie
        if len(top_sentiments) > 1 and top_sentiments[0][1] == top_sentiments[1][1]:
            if "neutral" in sentiment_counts and sentiment_counts["neutral"] >= top_sentiments[0][1]:
                return "neutral", sentiment_counts["neutral"] / total
            else:
                return "neutral", top_sentiments[0][1] / total

        dominant_sentiment = top_sentiments[0][0]
        percentage = top_sentiments[0][1] / total
        return dominant_sentiment, percentage

    def extract_actual_opinions(self, texts: list[str]) -> list[str]:
        if not texts:
            return []
            
        headers = {
            "Authorization": f"Bearer {self.API_KEY}",
            "Content-Type": "application/json"
        }
        
        prompt = f"""Extract ONLY Arabic scholarly opinions about Hadith narrators (evaluations of reliability/trustworthiness). 
        Exclude dates, places, and biographical details. Return as Python list.
        
        Input:
        {chr(10).join(texts)}
        """
        
        data = {
            "model": self.LLM_MODEL,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.0,
        }
        try:
            response = requests.post(self.API_URL, json=data, headers=headers, timeout=30)
            response.raise_for_status()
            content = response.json()["choices"][0]["message"]["content"]
            if '[' in content and ']' in content:
                return ast.literal_eval(content[content.find('['):content.find(']')+1])
            return []
        except Exception:
            return []



    def importNarratorDetails(self,narratorName:str,narratorTeacher:List[str],narratorStudent:List[str],opinion:List[str],scholar:List[str])->bool:
        print(opinion)
        op= self.extract_actual_opinions(opinion)
        print(op)
        sentiment, confidence = self.combined_sentiment(op)
        print(sentiment)
        nar=self.remove_diacritics(narratorName)
        result=self.__dalFascade.importNarratorDetails(nar,narratorTeacher,narratorStudent,opinion,scholar,sentiment,confidence)
        return result
    def getSimilarNarratorName(self,narratorName:str)->dict:
        nar=self.remove_diacritics(narratorName)
        CONNECTING_WORDS = {"بن", "ابي", "ابن", "ابو", "ام", "عن", "في", "ال", "وال", "فى"}

        name_parts = [part for part in nar.split() 
                    if part and part not in CONNECTING_WORDS]
        result_set = set()
        for part in name_parts:
            result = self.__dalFascade.getSimilarNarratorName(part)
            result_set.update(result.get("narratornames", []))

        return {"narratornames": list(result_set)}
    
    def associateHadithNarratorWithNarratorDetails(self, projectName: str, narrator_name: str, detailed_narrator_name: str) -> bool:
        return self.__dalFascade.associateHadithNarratorWithNarratorDetails(projectName,narrator_name,detailed_narrator_name)
    
    def getNarratorStudent(self, narratorName: str, projectName: str) -> List[str]:
        teacher_list=self.__dalFascade.getNarratorStudent(narratorName,projectName)
        return teacher_list.split(",")
    def getNarratorTeacher(self, narratorName: str, projectName: str) -> List[str]:
        student_list=self.__dalFascade.getNarratorTeacher(narratorName,projectName)
        return student_list.split(",")
    def updateHadithNarratorAssociation(self, projectName: str, narrator_name: str, new_detailed_narrator_name: str) -> bool:
        return self.__dalFascade.updateHadithNarratorAssociation(projectName,narrator_name,new_detailed_narrator_name)
    def deleteHadithNarratorAssociation(self, projectName: str, narrator_name: str) -> bool:
        return self.__dalFascade.deleteHadithNarratorAssociation(projectName,narrator_name)
    