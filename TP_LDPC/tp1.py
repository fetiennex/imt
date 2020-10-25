import pandas as pd 
import random as rd
import matplotlib.pyplot as plt
import numpy as np

H1 = pd.read_csv("H1.csv",header=None)
H2 = pd.read_csv("H2.csv",header=None)
#print(H1)
def question1(H1,H2):
    dv1 = H1.sum(0)
    dc1 = H1.sum(1)

    dv2 = H2.sum(0)
    dc2 = H2.sum(1) 


    if len(set(dv1)) == 1 and len(set(dc1)) == 1:
        dv = dv1[0]
        dc = dc1[0]
        rate = 1 - dv/dc
        print('-'*60)
        print("H1 is regular : dv = ",dv," dc = ",dc, " Rate = ", rate)
        print('-'*60)

    if len(set(dv2)) == 1 and len(set(dc2)) == 1:
        dv = dv2[0]
        dc = dc2[0]
        rate = 1 - dv/dc
        print("H2 is regular : dv = ",dv," dc = ",dc, " Rate = ", rate)
        print('-'*60)


    #sparsity

    h1sparsity = dv1.sum(0)/H1.size
    h2sparsity = dv2.sum(0)/H2.size
    print("H1 sparsity = ", h1sparsity," H2 sparsity = ",h2sparsity)
    print(H1.shape)

def bsc(x,p) :
    x2 = []
    for i in x.values.tolist()[0] :
        r = rd.random()
        if r < p:
            x2.append((i+1) % 2)
        else:
            x2.append(i)
    return x2



def paritycheck(H,x) :
    Ht = H.transpose()
    return x.dot(Ht) % 2


x1 = pd.DataFrame([0 for _ in range(H1.shape[1])])
x1 = x1.transpose()
x2 = pd.DataFrame([0 for _ in range(H2.shape[1])])
x2 = x2.transpose()
#print(bsc(x,0.1))
#print(paritycheck(H1,x))

def gallagerA(y,H,L) :
    m0 = y
    mv = m0.copy()



    dv = H.sum(0)[0]
    dc = H.sum(1)[0]
    M,N = H.shape[0], H.shape[1]
    #print(M,N)
    Vcn = pd.DataFrame([[[0,0] for j in range(M)] for i in range(dc)])
    for j in range(M) :
        Ht = H.transpose()
        
        index = np.argwhere(Ht[j].values.tolist())
        for i in range(dc):
            Vcn[j][i] = [index[i][0],None]
    #print(Vcn)
    Vvn = pd.DataFrame([[[0,0] for j in range(N)] for i in range(dv)])
    for j in range(N):
        index = np.argwhere(H[j].values.tolist())
        for i in range(dv):
            Vvn[j][i] = [index[i][0],None]
    #print(Vvn)


    for k in range(L) :
        for m in range(M) :
            for i in range(dc):
                sum = 0
                for ii in range(dc):
                    if Vcn[m][i][0] != Vcn[m][ii][0] :
                        sum = (sum + mv[Vcn[m][ii][0]]) % 2   
                Vcn[m][i][1] =  sum
        #print(Vcn)

        
        for n in range(N) :
            for j in range(dv) :
                index = Vvn[n][j][0]  
                for ii in range(dc):
                    if Vcn[index][ii][0] == n:
                        Vvn[n][j][1] = Vcn[index][ii][1]
            i = 0
            for jj in range(dv):
                if Vvn[n][jj][1] != m0[n]:
                    i += 1
            if i >= dv-1:
                mv[n] = (m0[n] + 1)%2
            else:
                mv[n] = m0[n]
        #print(Vvn)
        x = [None for _ in range(N)]
        for i in range(N):
            sum = 0
            for j in range(dv):
                sum += Vvn[i][j][1]
            if m0[i] + sum > np.ceil((dv+1)/2) :
                #if k==L-1 : print("m0[i]=", m0[i], " sum=", sum, " m0[i]+sum=", m0[i]+sum, " >= np.ceil((dv+1)/2)=", np.ceil((dv+1)/2))
                x[i] = 1
            else:
                #if k==L-1 : print("m0[i]=", m0[i], " sum=", sum, " m0[i]+sum=", m0[i]+sum, "<= np.ceil((dv+1)/2)=", np.ceil((dv+1)/2))
                x[i] = 0
        
        check = paritycheck(H,pd.DataFrame(x).transpose())
        if check.transpose()[0].sum() == 0 :
            #print("early stop at k=", k, "check.sum=", check.transpose()[0].sum(),"x.sum=", pd.DataFrame(x)[0].sum())
            if k!=0 : 
                print(k)
            return [x,True]
        print("check=", check.transpose()[0])

    #print("Vvn=", Vvn, "Vcn=", Vcn)
    #print("reached end of iteration count.")
    return [x,False]
"""                
y1 = bsc(x1,0.1)
print("y1=",y1)
y2 = bsc(x2,0.015)
print("gallager1=" , gallagerA(y1,H1,500))
print(60*"-")
print("y2=",y2)
print("gallager2=", gallagerA(y2,H2,100))
"""

def testGallager(range_p,range_k,nb_tests,H) :
    y = pd.DataFrame([0 for _ in range(H.shape[1])]).transpose()
    data = [[[[0,0],[0,0]] for _ in range_p] for _ in range_k]
    print(data)
    pp = 0
    for p in range_p:
        kk = 0
        for k in range_k:
            decoded = 0
            total = 0
            ber = []
            for _ in range(nb_tests):
                yy = bsc(y,p)
                total += 1
                gallager = gallagerA(yy,H,k)
                if gallager[1] == False : ber.append(sum(gallager[0])/len(gallager[0]))
                #print(sum(gallager[0]))
                if gallager[1]== True:
                    decoded += 1
            data[kk][pp][0] = [k,p] 
            if len(ber)!= 0:
                data[kk][pp][1] = [((total-decoded)/total),sum(ber)/len(ber)]
            else:
                data[kk][pp][1] = [((total-decoded)/total),None]
            
            #print("[k:",k,",p:",p,"] -> FER = ",((total-decoded)/total), " BER = ",sum(ber)/len(ber))
            kk += 1
        pp += 1
            #print("Paramaters: p=",p,",k=",k," ---> FER = ", ((total-decoded)/total), " , BER = ", sum(ber)/len(ber) ) 
    return data

range_p = np.arange(0,0.1,0.001)
print(range_p)
range_k = [50]
data = testGallager(range_p,range_k,10,H1)
print(data)

p_ber_x = []
p_ber_y = []

p_fer_x = []
p_fer_y = []

for p in range(len(data)):
    #print("lendata =",len(data))
    #print("p=",p)
    for k in range(len(data[0])):
        #print("lendata[0] =",len(data[0]))
        #print("k=",k)
        if data[p][k][1][1] != None:
            p_ber_x.append(data[p][k][0][1])
            p_ber_y.append(data[p][k][1][1])  

        p_fer_x.append(data[p][k][0][1])
        p_fer_y.append(data[p][k][1][0])

plt.plot(p_ber_x, p_ber_y)
plt.yscale("log")
plt.show()




