from sqlalchemy import (
    create_engine, Column, Integer, String, Float, ForeignKey, Table, DateTime, Text, JSON
)
from datetime import datetime, timezone
from sqlalchemy.orm import relationship, sessionmaker, configure_mappers
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.dialects.postgresql import JSONB  

Base = declarative_base()

# Association Tables
book_project = Table(
    'book_project', Base.metadata,
    Column('projectid', Integer, ForeignKey('projects.projectid', ondelete="CASCADE"), primary_key=True),
    Column('bookid', Integer, ForeignKey('books.bookid', ondelete="NO ACTION"), primary_key=True),
)

hadith_book = Table(
    'hadith_book', Base.metadata,
    Column('bookid', Integer, ForeignKey('books.bookid', ondelete="CASCADE"), primary_key=True),
    Column('hadithid', Integer, ForeignKey('hadiths.hadithid', ondelete="CASCADE"), primary_key=True),
)

hadith_project = Table(
    'hadith_project', Base.metadata,
    Column('projectid', Integer, ForeignKey('projects.projectid', ondelete="CASCADE"), primary_key=True),
    Column('hadithid', Integer, ForeignKey('hadiths.hadithid', ondelete="NO ACTION"), primary_key=True),
)

sanad_project = Table(
    'sanad_project', Base.metadata,
    Column('projectid', Integer, ForeignKey('projects.projectid', ondelete="CASCADE"), primary_key=True),
    Column('sanadid', Integer, ForeignKey('sanad.sanadid', ondelete="NO ACTION"), primary_key=True),
)

hadith_sanad = Table(
    'hadith_sanad', Base.metadata,
    Column('hadithid', Integer, ForeignKey('hadiths.hadithid', ondelete="CASCADE"), primary_key=True),
    Column('sanadid', Integer, ForeignKey('sanad.sanadid', ondelete="CASCADE"), primary_key=True),
)

narrator_sanad = Table(
    'narrator_sanad', Base.metadata,
    Column('sanadid', Integer, ForeignKey('sanad.sanadid', ondelete="CASCADE"), primary_key=True),
    Column('narratorid', Integer, ForeignKey('narrators.narratorid', ondelete="CASCADE"), primary_key=True),
    Column('level', Integer, nullable=False),
)

narrator_opinion = Table(
    'narrator_opinion', Base.metadata,
    Column('narrator_detailed_id', Integer, ForeignKey('narrator_detailed.narrator_detailed_id', ondelete="CASCADE"), primary_key=True),
    Column('scholar_opinion_id', Integer, ForeignKey('scolar_opinion.scholar_opinion_id', ondelete="CASCADE"), primary_key=True)
)

project_narrator = Table(
    'project_narrator', Base.metadata,
    Column('project_id', Integer, ForeignKey('projects.projectid', ondelete="CASCADE"), primary_key=True),
    Column('narrator_id', Integer, ForeignKey('narrators.narratorid', ondelete="NO ACTION"), primary_key=True),
    Column('narrator_detailed_id', Integer, ForeignKey('narrator_detailed.narrator_detailed_id', ondelete="NO ACTION"), primary_key=True)
)

# Model Definitions
class Project(Base):
    __tablename__ = 'projects'

    projectid = Column(Integer, primary_key=True, autoincrement=True)
    projectname = Column(String(100), nullable=False, unique=True)
    lastupdated = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    createdat = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    books = relationship(
        'Book',
        secondary=book_project,
        back_populates='projects',
        cascade="all, delete"
    )
    hadiths = relationship(
        'Hadith',
        secondary=hadith_project,
        back_populates='projects',
        cascade="all, delete"
    )
    sanads = relationship(
        'Sanad',
        secondary=sanad_project,
        back_populates='projects',
        cascade="all, delete"
    )
    project_state = relationship("ProjectState", back_populates="projects")
    narrators = relationship(
        'Narrator',
        secondary=project_narrator,
        back_populates='projects'
    )
    narrator_detailed = relationship(
        'NarratorDetailed',
        secondary=project_narrator,
        back_populates='projects',
        overlaps="narrators"  # Added to silence warning
    )

    def __repr__(self):
        return f"<Project(projectid={self.projectid}, projectname='{self.projectname}', lastupdated={self.lastupdated}, createdat={self.createdat})>"
class ProjectState(Base):
    __tablename__ = 'project_state'
    
    projectid = Column(Integer, ForeignKey('projects.projectid', ondelete="CASCADE"), primary_key=True)
    query = Column(String(10000), nullable=False, unique=True)
    statedata = Column(JSONB, nullable=False)

    projects = relationship('Project', back_populates='project_state')

    def __repr__(self):
        return f"<ProjectState(projectid={self.projectid}, query='{self.query}', statedata='{self.statedata}')>"

class ScholarOpinion(Base):
    __tablename__ = 'scolar_opinion'
    
    scholar_id = Column(Integer, ForeignKey('scholars.scholar_id', ondelete="CASCADE"), primary_key=True)
    opinion_id = Column(Integer, ForeignKey('opinions.opinionid', ondelete="CASCADE"), primary_key=True)
    scholar_opinion_id = Column(Integer, nullable=False, primary_key=True,autoincrement=True)

    scholars = relationship('Scholars', back_populates='scolar_opinion')
    opinions = relationship('Opinions', back_populates='scolar_opinion')
    narrator_detailed = relationship(
        'NarratorDetailed',
        secondary=narrator_opinion,
        back_populates='scolar_opinion',
        cascade="all, delete"
    )

    def __repr__(self):
        return f"<ScholarOpinion(scholar_id={self.scholar_id}, opinion_id='{self.opinion_id}', scholar_opinion_id='{self.scholar_opinion_id}')>"

class Book(Base):
    __tablename__ = 'books'
    
    bookid = Column(Integer, primary_key=True, autoincrement=True)
    bookname = Column(String(200), nullable=False, unique=True)

    projects = relationship(
        'Project',
        secondary=book_project,
        back_populates='books'
    )
    hadiths = relationship(
        'Hadith',
        secondary=hadith_book,
        back_populates='books'
    )

    def __repr__(self):
        return f"<Book(bookid={self.bookid}, bookname='{self.bookname}')>"

class Hadith(Base):
    __tablename__ = 'hadiths'
    
    hadithid = Column(Integer, primary_key=True, autoincrement=True)
    matn = Column(String(5000), nullable=False, unique=True)
    embeddings = Column(Text, nullable=False)
    cleanedmatn = Column(String(5000), nullable=False)
    roots=Column(Text, nullable=False)
    matnwithoutarab=Column(Text, nullable=False)


    projects = relationship(
        'Project',
        secondary=hadith_project,
        back_populates='hadiths'
    )
    books = relationship(
        'Book',
        secondary=hadith_book,
        back_populates='hadiths'
    )
    sanads = relationship(
        'Sanad',
        secondary=hadith_sanad,
        back_populates='hadiths'
    )

    def __repr__(self):
        return f"<Hadith(hadithid={self.hadithid}, matn='{self.matn}', cleanedmatn='{self.cleanedmatn}',roots='{self.roots}',matnwithoutarab='{self.matnwithoutarab}')>"

class Sanad(Base):
    __tablename__ = 'sanad'
    
    sanadid = Column(Integer, primary_key=True, autoincrement=True)
    sanad = Column(String(5000), nullable=False, unique=True)
    sanadauthenticity = Column(Integer, nullable=False)

    projects = relationship(
        'Project',
        secondary=sanad_project,
        back_populates='sanads'
    )
    hadiths = relationship(
        'Hadith',
        secondary=hadith_sanad,
        back_populates='sanads'
    )
    narrators = relationship(
        'Narrator',
        secondary=narrator_sanad,
        back_populates='sanads',
        cascade="all, delete"
    )

    def __repr__(self):
        return f"<Sanad(sanadid={self.sanadid}, sanad='{self.sanad}', sanadauthenticity={self.sanadauthenticity})>"

class Narrator(Base):
    __tablename__ = 'narrators'
    
    narratorid = Column(Integer, primary_key=True, autoincrement=True)
    narratorname = Column(String(200), nullable=False, unique=True)
    cleanedname = Column(String(200), nullable=False)

    sanads = relationship(
        'Sanad',
        secondary=narrator_sanad,
        back_populates='narrators'
    )
    projects = relationship(
        'Project',
        secondary=project_narrator,
        back_populates='narrators',
        overlaps="narrator_detailed"  # Added to silence warning
    )

    def __repr__(self):
        return f"<Narrator(narratorid={self.narratorid}, narratorname='{self.narratorname}', cleanedname='{self.cleanedname}')>"

class NarratorDetailed(Base):
    __tablename__ = 'narrator_detailed'
    
    narrator_detailed_id = Column(Integer, primary_key=True, autoincrement=True)
    narrator_name = Column(String(200), nullable=False)
    final_opinion = Column(String(200), nullable=False)
    narrator_authenticity = Column(Float, nullable=False)

    scolar_opinion = relationship(
        'ScholarOpinion',
        secondary=narrator_opinion,
        back_populates='narrator_detailed'
    )
    projects = relationship(
        'Project',
        secondary=project_narrator,
        back_populates='narrator_detailed',
        overlaps="narrators,projects"  # Added to silence warning
    )
    narrator_teacher = relationship("NarratorTeacher", cascade="all, delete", foreign_keys="[NarratorTeacher.narratorid]", back_populates='narrator_detailed')
    narrator_student = relationship("NarratorStudent", cascade="all, delete",  foreign_keys="[NarratorStudent.narratorid]",back_populates='narrator_detailed')

    def __repr__(self):
        return f"<NarratorDetailed(narrator_detailed_id={self.narrator_detailed_id}, narrator_name='{self.narrator_name}', final_opinion='{self.final_opinion},narrator_authenticity={self.narrator_authenticity}')>"
    
class NarratorTeacher(Base):
    __tablename__ = 'narrator_teacher'
    __table_args__ = {'extend_existing': True}

    narratorid = Column(Integer, ForeignKey('narrator_detailed.narrator_detailed_id', ondelete="CASCADE"), primary_key=True)
    narratorteacher = Column(Text, nullable=False, primary_key=True)

    narrator_detailed = relationship("NarratorDetailed", back_populates="narrator_teacher",foreign_keys=[narratorid])

    def __repr__(self):
        return f"<NarratorTeacher(narratorid={self.narratorid}, narratorteacher='{self.narratorteacher}')>"

class NarratorStudent(Base):
    __tablename__ = 'narrator_student'
    __table_args__ = {'extend_existing': True}

    narratorid = Column(Integer, ForeignKey('narrator_detailed.narrator_detailed_id', ondelete="CASCADE"), primary_key=True)
    narratorstudent = Column(Text, nullable=False, primary_key=True)
    narrator_detailed = relationship("NarratorDetailed", back_populates="narrator_student",foreign_keys=[narratorid])

    def __repr__(self):
        return f"<NarratorStudent(narratorid={self.narratorid}, narratorstudent='{self.narratorstudent}')>"

class Scholars(Base):
    __tablename__ = 'scholars'
    
    scholar_id = Column(Integer, primary_key=True, autoincrement=True)
    scholar_name = Column(String(200), nullable=False)
    
    scolar_opinion = relationship('ScholarOpinion', back_populates='scholars')

    def __repr__(self):
        return f"<Scholars(scholar_id={self.scholar_id}, scholar_name='{self.scholar_name}')>"

class Opinions(Base):
    __tablename__ = 'opinions'
    
    opinionid = Column(Integer, primary_key=True, autoincrement=True)
    opinion = Column(String(200), nullable=False)

    scolar_opinion = relationship('ScholarOpinion', back_populates='opinions')

    def __repr__(self):
        return f"<Opinions(opinion_id={self.opinionid}, opinion='{self.opinion}')>"

class Progress(Base):
    __tablename__ = "import_progress"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    taskid = Column(String(50), unique=True, nullable=False)
    projectname = Column(String(100), nullable=False)
    progress = Column(Float, default=0.0)

    @staticmethod
    def init_db(db_url):
        """
        Initialize the database.
        :param db_url: Database URL (PostgreSQL URL)
        """
        engine = create_engine(db_url)
        Base.metadata.create_all(engine)
        configure_mappers()  # Ensure mappers are configured
        Session = sessionmaker(bind=engine)
        return Session