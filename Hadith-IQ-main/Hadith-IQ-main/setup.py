from setuptools import setup, find_packages

setup(
    name="HadithIQ",
    version="1.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "numpy",
        "fastapi",
        "uvicorn",
        "sqlalchemy",
        "camel-tools",
        "camel_data download --install -f all" # can be done pip install camel-tools -f https://download.pytorch.org/whl/torch_stable.html
        # to download morphology data base for lammatisation
        "psycopg2",
        "html2text",
        "pip install faiss-cpu --upgrade",
        "pip install transformers camel-tools torch ",
        "pip install nltk ", #for roots 
    ],
)


