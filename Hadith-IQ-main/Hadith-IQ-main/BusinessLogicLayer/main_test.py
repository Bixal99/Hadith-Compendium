from BusinessLogicLayer.Fascade.BLLFascade import BLLFascade
from BusinessLogicLayer.Hadith.HadithBO import HadithBO
from BusinessLogicLayer.Narrator.NarratorBO import NarratorBO
from BusinessLogicLayer.Project.ProjectBO import ProjectBO
from BusinessLogicLayer.Sanad.SanadBO import SanadBO
from DataAccessLayer.Book.BookDAO import BookDAO
from DataAccessLayer.Fascade.DALFascade import DALFascade
from DataAccessLayer.DbConnection import DbConnectionModel
from DataAccessLayer.Hadith.HadithDAO import HadithDAO
from DataAccessLayer.Narrator.NarratorDAO import NarratorDAO
from DataAccessLayer.Project.ProjectDAO import ProjectDAO
from DataAccessLayer.Sanad.SanadDAO import SanadDAO
from DataAccessLayer.UtilDAO import UtilDao
from camel_tools.morphology.database import MorphologyDB
import time

def main():
    # Initiallizing DAL
    dbConnection = DbConnectionModel()
    utilDAO = UtilDao(dbConnection)
    hadithDAO = HadithDAO(dbConnection, utilDAO)
    narratorDAO = NarratorDAO(dbConnection, utilDAO)
    projectDAO = ProjectDAO(dbConnection, utilDAO)
    bookDAO = BookDAO(dbConnection, utilDAO)
    sanadDAO = SanadDAO(dbConnection, utilDAO)
    dalFascade = DALFascade(projectDAO, bookDAO, hadithDAO, sanadDAO, narratorDAO)

    # Initializing BLL
    hadithBO = HadithBO(dalFascade)
    narratorBO = NarratorBO(dalFascade)
    projectBO = ProjectBO(dalFascade)
    sanadBO = SanadBO(dalFascade)
    bllFascade = BLLFascade(hadithBO, sanadBO, projectBO, narratorBO)
    start = time.time()
    #result = bllFascade.importHadithFile("test",r"D:\Updated_FYP\صحيح البخاري.csv")
    hadith = ['{matn: احيي اتي مثل صلصل جرس هو اشد علي فصم عن وقد وعي ما قال احيي تمثل لي ملك رجل كلم عيي ما قال, similarity: 0.9385322988830216}']
    #result = bllFascade.semanticSearch("احيي اتي مثل صلصل جرس هو اشد علي فصم عن وقد وعي ما قال احيي تمثل لي ملك رجل كلم عيي ما قال","test",20)
    result = bllFascade.expandSearch(hadith,"test",0.30)
    end = time.time()
    print(end-start)
    print('\n')
    print(result)    

def testing():
   try:
    # This will automatically download the database if missing
    db = MorphologyDB.builtin_db()
    print("MorphologyDB loaded successfully.") 
   except FileNotFoundError as e:
    print(f"Error: {e}")

if __name__ == "__main__":
   main()

    ## Sample input data for the search
    #hadithList = [
     #   "وَبِهَذَا السَّنَدِ فِي رِوَايَةٍ أُخْرَى عَنْهُ عَلَيْهِ السَّلامُ  وَبِهَذَا السَّنَدِ فِي رِوَايَةٍ أُخْرَى عَنْهُ عَلَيْهِ السَّلامُ  قَالَ :  إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ وَلِكُلِّ امْرِئٍ مَا نَوَى",
     #   "عَنِ النَّبِيِّ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ قَالَ :  يَقُولُ اللَّهُ تَبَارَكَ وَتَعَالَى : مَنْ عَمِلَ عَمَلا أَشْرَكَ فِيهِ غَيْرِي فَهُوَ لَهُ كُلُّهُ  وَأَنَا أَغْنَى الشُّرَكَاءِ عَنِ الشِّرْكِ",
     #   "قَالَ : كُنْتُ مَعَ رَسُولِ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ حَتَّى إِذَا أَرَادَ الْقِيَامَ إِلَى حَاجَةِ الإِنْسَانِ قَالَ :  ائْتِنِي بِالأَحْجَارِ   قَالَ : فَأَتَيْتُهُ بِحَجَرَيْنِ وَرَوْثَةٍ  فَاسْتَنْجَى بِالْحَجَرَيْنِ وَأَلْقَى الرَّوْثَةَ  وَقَالَ :  إِنَّهَا رِكْسٌ"
    #]
    #sample_hadith = "إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ"
    #project_name = "Temp"

    # Call the semantic search function
    #try:
     #   path = r"C:\Users\Syed Ali\Downloads\مسند الربيع بن حبيب.csv"
     #   bllFascade.semanticSearch(sample_hadith, project_name, 0.3)
    #except Exception as e:
     #   print(f"Error during file import: {e}")"""
