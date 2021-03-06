import math
import numpy as np
import pandas as pd
import pyximport; pyximport.install()
from scipy.stats import norm, t
from Returns import CholeskyDecomp
from Distributions import InvStdCumNormal
from LowDiscrepancyNumberGenerators cimport SobolNumbers
cimport numpy as np
FDTYPE = np.float
cdef np.ndarray[FDTYPE_t,ndim=1] SharedCopulaAlgoWork(P, SobolNumbers LowDiscNumbers):
    if LowDiscNumbers is None:
            raise TypeError
    A = CholeskyDecomp(P)
    # A = np.linalg.cholesky(P)
    # cdef int d = A.shape[0]
    #Xtilda = np.random.uniform(size=A.shape[0])
    #Xtilda = norm.ppf(Xtilda)
    #todo: Use the random number generator to generate the normal vals here. Read Jaeckel
    cdef np.ndarray[FDTYPE_t,ndim=1] LowDiscU 
    cdef np.ndarray[FDTYPE_t,ndim=1] IndptXtilda
    cdef np.ndarray[FDTYPE_t,ndim=1] CorrlelatedX
    LowDiscU = LowDiscNumbers.Generate()
    IndptXtilda = np.fromiter(map(lambda u: InvStdCumNormal(u),LowDiscU),dtype=FDTYPE)
    # IndptXtilda = norm.rvs(size=len(LowDiscU))
    #IndependentXtilda = np.random.randn(A.shape[0])
    CorrlelatedX = np.matmul(A.transpose(),IndptXtilda)
    return CorrlelatedX

cpdef np.ndarray[FDTYPE_t,ndim=1] MultVarGaussianCopula(P,SobolNumbers LowDiscNumbers):
    cdef np.ndarray[FDTYPE_t,ndim=1] CorrlelatedX
    CorrlelatedX = SharedCopulaAlgoWork(P,LowDiscNumbers)
    cdef np.ndarray[FDTYPE_t,ndim=1] U = norm.cdf(CorrlelatedX)
    return U

#http://support.sas.com/documentation/cdl/en/etsug/63939/HTML/default/viewer.htm#etsug_copula_sect016.htm
cpdef np.ndarray[FDTYPE_t,ndim=1] MultVarTDistnCopula(P,int df,SobolNumbers LowDiscNumbers):
    cdef np.ndarray[FDTYPE_t,ndim=1] CorrlelatedX
    CorrlelatedX = SharedCopulaAlgoWork(P,LowDiscNumbers)
    # u = SobolNumbers()
    # u.initialise(1)
    cdef np.ndarray uRand= np.zeros(df,dtype=float)
    cdef int i
    cdef float epsilon
    for i in range(0,df):
        uRand[i] = math.pow(np.random.uniform(0,1,1),2)
    epsilon = sum(uRand)
    cdef np.ndarray[FDTYPE_t,ndim=1] U = t.cdf(CorrlelatedX/math.sqrt(epsilon/df),df)
    return U

cpdef FDTYPE_t TCopulaDensity(np.ndarray U, int df):
    cdef int i
    cdef np.ndarray[FDTYPE_t,ndim=1] tdistX = np.zeros(shape=(len(U)),dtype=FDTYPE)
    for i in range(0,len(U)):
        tdistX[i]=t.ppf(U[i],df)
    print(tdistX)        
    return t.cdf(tdistX,df)
