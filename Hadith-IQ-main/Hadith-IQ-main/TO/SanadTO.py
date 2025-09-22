class SanadTO:
    def __init__(self, sanad: str, sanadAuthenticity: str, hadithTO):
        self.__sanad = sanad
        self.__sanadAuthenticity = sanadAuthenticity
        self.__hadithTO = hadithTO

    @property
    def sanad(self):
        return self.__sanad

    @property
    def sanadAuthenticity(self):
        return self.__sanadAuthenticity

    @property
    def hadithTO(self):
        return self.__hadithTO

    def __repr__(self):
        return f"SanadTO(sanad={self.__sanad}, sanadAuthenticity={self.__sanadAuthenticity}, hadithTO={self.__hadithTO})"
