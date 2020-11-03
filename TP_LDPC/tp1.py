import pandas as pd 
import random as rd
import matplotlib.pyplot as plt
import numpy as np
import scipy.stats

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

        x = [None for _ in range(N)]
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
            sum = 0
            for j in range(dv):
                sum += Vvn[n][j][1]
            if m0[n] + sum > np.ceil((dv+1)/2) :
                #if k==L-1 : print("m0[i]=", m0[i], " sum=", sum, " m0[i]+sum=", m0[i]+sum, " >= np.ceil((dv+1)/2)=", np.ceil((dv+1)/2))
                x[n] = 1
            else:
                #if k==L-1 : print("m0[i]=", m0[i], " sum=", sum, " m0[i]+sum=", m0[i]+sum, "<= np.ceil((dv+1)/2)=", np.ceil((dv+1)/2))
                x[n] = 0
        
        check = paritycheck(H,pd.DataFrame(x).transpose())
        if check.transpose()[0].sum() == 0 :
            #print("early stop at k=", k, "check.sum=", check.transpose()[0].sum(),"x.sum=", pd.DataFrame(x)[0].sum())
            #if k!=0 : 
            print(k)
            return [x,True]
        # print("check=", check.transpose()[0])

    #print("Vvn=", Vvn, "Vcn=", Vcn)
    #print("reached end of iteration count.")
    print(k)
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

def testGallager(range_p,range_k,range_tests,H) :
    y = pd.DataFrame([0 for _ in range(H.shape[1])]).transpose()
    data = [[[0,0] for _ in range_p] for _ in range_k]
    print(data)
    pp = 0
    for p in range_p:
        kk = 0
        print("tests: ", range_tests[pp])
        for k in range_k:
            decoded = 0
            total = 0
            ber = []
            for _ in range(round(range_tests[pp])):
                yy = bsc(y,p)
                total += 1
                gallager = gallagerA(yy,H,k)
                ber.append(sum(gallager[0])/len(gallager[0]))
                #print(sum(gallager[0]))
                if gallager[1]== True:
                    decoded += 1
            data[kk][pp] = [((total-decoded)/total),sum(ber)/len(ber)]
            
            print("[k:",k,",p:",p,"] -> FER = ",((total-decoded)/total), " BER = ",sum(ber)/len(ber))
            kk += 1
        pp += 1
    return data

range_p = np.arange(0.010,0.4,0.004)
#print(range_p)
ap=0.05
poff=0.015
pfinal=0.1
Kp=(poff-pfinal)/(1-np.exp(ap*100))
Cp=(poff*np.exp(ap*100) -pfinal)/(poff-pfinal)

#range_p_exp = [ (0.1/(np.exp(a*100)-1))*(np.exp(a*x)-1) for x in range(101)]
#range_p = [Kp*(np.exp(ap*x)- Cp) for x in range(101)]

at=0.03
toff=450
tfinal=50
Kt=(tfinal-toff)/(1-np.exp(at*100))
Ct=(tfinal*np.exp(at*100) -toff)/(tfinal-toff)

range_t_exp = [Kt*(np.exp(at*(100-x))- Ct) for x in range(101)]
#print(range_p_exp)
#plt.plot(range(101),range_p_exp)
#plt.show()
#plt.plot(range(101),range_t_exp)
#plt.show()

range_k = [30]
#data = testGallager(range_p,range_k,range_t_exp,H1)
#H2:
#data = [[[0.0, 0.0], [0.0, 0.0], [0.004705882352941176, 0.002], [0.004830917874396135, 0.0008454106280193236], [0.0, 0.0], [0.0025575447570332483, 0.0012787723785166241], [0.02099737532808399, 0.0068241469816272965], [0.005405405405405406, 0.0018918918918918919], [0.011111111111111112, 0.0020833333333333333], [0.002857142857142857, 0.0005714285714285715], [0.005865102639296188, 0.0030791788856304987], [0.02108433734939759, 0.00858433734939759], [0.021671826625386997, 0.005417956656346749], [0.01910828025477707, 0.004936305732484076], [0.032679738562091505, 0.010294117647058822], [0.020202020202020204, 0.006565656565656565], [0.020689655172413793, 0.005862068965517241], [0.031914893617021274, 0.012411347517730497], [0.043795620437956206, 0.01186131386861314], [0.033707865168539325, 0.00898876404494382], [0.05, 0.016538461538461537], [0.05138339920948617, 0.019367588932806323], [0.06072874493927125, 0.019230769230769232], [0.075, 0.02291666666666666], [0.05555555555555555, 0.019230769230769232], [0.07456140350877193, 0.023464912280701758], [0.07207207207207207, 0.01689189189189189], [0.09259259259259259, 0.035416666666666666], [0.0947867298578199, 0.027725118483412324], [0.1073170731707317, 0.029024390243902447], [0.12, 0.029749999999999995], [0.08717948717948718, 0.02487179487179487], [0.12105263157894737, 0.04026315789473684], [0.08108108108108109, 0.025675675675675677], [0.143646408839779, 0.05441988950276243], [0.1534090909090909, 0.042045454545454546], [0.14534883720930233, 0.038081395348837206], [0.14285714285714285, 0.04553571428571429], [0.17073170731707318, 0.06036585365853659], [0.16875, 0.0540625], [0.16025641025641027, 0.044230769230769226], [0.17763157894736842, 0.06052631578947369], [0.1891891891891892, 0.07060810810810811], [0.20689655172413793, 0.06310344827586208], [0.23404255319148937, 0.08156028368794328], [0.16666666666666666, 0.05797101449275364], [0.25925925925925924, 0.0751851851851852], [0.16666666666666666, 0.05984848484848484], [0.23255813953488372, 0.07286821705426355], [0.23809523809523808, 0.08333333333333333], [0.24390243902439024, 0.07886178861788617], [0.325, 0.09125000000000003], [0.2033898305084746, 0.056355932203389816], [0.24347826086956523, 0.0773913043478261], [0.29464285714285715, 0.09955357142857146], [0.2909090909090909, 0.1068181818181818], [0.2523364485981308, 0.08551401869158881], [0.3619047619047619, 0.10714285714285712], [0.3883495145631068, 0.11844660194174758], [0.36633663366336633, 0.12128712871287131], [0.36363636363636365, 0.11565656565656564], [0.3917525773195876, 0.1402061855670103], [0.35789473684210527, 0.10789473684210528], [0.41935483870967744, 0.12258064516129033], [0.3626373626373626, 0.1120879120879121], [0.4157303370786517, 0.1410112359550562], [0.40229885057471265, 0.1235632183908046], [0.49411764705882355, 0.16176470588235295], [0.39285714285714285, 0.11964285714285713], [0.43902439024390244, 0.14390243902439026], [0.4444444444444444, 0.141358024691358], [0.43037974683544306, 0.12721518987341773], [0.46153846153846156, 0.1455128205128205], [0.4868421052631579, 0.15855263157894736], [0.4666666666666667, 0.15266666666666664], [0.5753424657534246, 0.18150684931506852], [0.5416666666666666, 0.17569444444444446], [0.5211267605633803, 0.17676056338028168], [0.5142857142857142, 0.19142857142857142], [0.4117647058823529, 0.1463235294117647], [0.6268656716417911, 0.20522388059701493], [0.5606060606060606, 0.17424242424242425], [0.49230769230769234, 0.1576923076923077], [0.5625, 0.20156250000000006], [0.5238095238095238, 0.1642857142857143], [0.532258064516129, 0.16693548387096774], [0.4918032786885246, 0.1639344262295082], [0.5166666666666667, 0.1683333333333333], [0.7288135593220338, 0.2423728813559322], [0.7413793103448276, 0.20862068965517244], [0.6140350877192983, 0.2140350877192982], [0.6071428571428571, 0.18392857142857144], [0.6964285714285714, 0.23035714285714276], [0.6181818181818182, 0.21090909090909088], [0.7037037037037037, 0.23703703703703702]]]
#H1:
data = [[[0.0, 0.0], [0.0, 0.0], [0.004705882352941176, 0.002235294117647059], [0.0024154589371980675, 0.0006038647342995169], [0.0024875621890547263, 0.0002487562189054727], [0.005115089514066497, 0.0008951406649616368], [0.02099737532808399, 0.005905511811023622], [0.02702702702702703, 0.007432432432432433], [0.03888888888888889, 0.010277777777777778], [0.04285714285714286, 0.011571428571428571], [0.04398826979472141, 0.013489736070381233], [0.0572289156626506, 0.013855421686746987], [0.05263157894736842, 0.0173374613003096], [0.06369426751592357, 0.02101910828025478], [0.10130718954248366, 0.03300653594771242], [0.10101010101010101, 0.032828282828282825], [0.09310344827586207, 0.02620689655172414], [0.1595744680851064, 0.05035460992907799], [0.14233576642335766, 0.045255474452554754], [0.18726591760299627, 0.0591760299625468], [0.19615384615384615, 0.07038461538461539], [0.18181818181818182, 0.056916996047430835], [0.21862348178137653, 0.0708502024291498], [0.2125, 0.06750000000000002], [0.2905982905982906, 0.08653846153846152], [0.30701754385964913, 0.08750000000000001], [0.22972972972972974, 0.07162162162162163], [0.27314814814814814, 0.08865740740740742], [0.3127962085308057, 0.10260663507109005], [0.34146341463414637, 0.10829268292682927], [0.365, 0.12149999999999997], [0.37948717948717947, 0.11282051282051284], [0.3894736842105263, 0.153421052631579], [0.43243243243243246, 0.14135135135135132], [0.5248618784530387, 0.16215469613259667], [0.35795454545454547, 0.12130681818181817], [0.4476744186046512, 0.15639534883720932], [0.5357142857142857, 0.17380952380952377], [0.5, 0.16128048780487805], [0.4875, 0.1628125], [0.5448717948717948, 0.16634615384615384], [0.5657894736842105, 0.18815789473684208], [0.6554054054054054, 0.21655405405405403], [0.5379310344827586, 0.1817241379310345], [0.6382978723404256, 0.21489361702127652], [0.6304347826086957, 0.21268115942028984], [0.6074074074074074, 0.20370370370370366], [0.6439393939393939, 0.21249999999999997], [0.7209302325581395, 0.2414728682170542], [0.6111111111111112, 0.2023809523809524], [0.7073170731707317, 0.23699186991869908], [0.7166666666666667, 0.23291666666666655], [0.7288135593220338, 0.23050847457627122], [0.7043478260869566, 0.23956521739130437], [0.6696428571428571, 0.21026785714285715], [0.7454545454545455, 0.2595454545454546], [0.7757009345794392, 0.2700934579439253], [0.8, 0.2690476190476191], [0.7087378640776699, 0.24951456310679618], [0.8217821782178217, 0.26683168316831685], [0.7777777777777778, 0.2702020202020202], [0.7835051546391752, 0.2804123711340205], [0.6947368421052632, 0.2363157894736842], [0.7956989247311828, 0.3043010752688171], [0.7912087912087912, 0.28681318681318685], [0.8089887640449438, 0.28146067415730336], [0.7931034482758621, 0.28965517241379307], [0.8470588235294118, 0.3058823529411765], [0.8571428571428571, 0.29464285714285704], [0.8170731707317073, 0.28963414634146345], [0.8024691358024691, 0.28827160493827164], [0.8607594936708861, 0.2974683544303797], [0.8846153846153846, 0.31025641025641015], [0.8552631578947368, 0.28421052631578947], [0.88, 0.31333333333333335], [0.8493150684931506, 0.2664383561643835], [0.8333333333333334, 0.3152777777777779], [0.8732394366197183, 0.3007042253521127], [0.9285714285714286, 0.32214285714285723], [0.8529411764705882, 0.3441176470588236], [0.8805970149253731, 0.3253731343283583], [0.8636363636363636, 0.3416666666666667], [0.8923076923076924, 0.3392307692307692], [0.9375, 0.31953125000000004], [0.9047619047619048, 0.3484126984126984], [0.8548387096774194, 0.30806451612903235], [0.9016393442622951, 0.3836065573770492], [0.8666666666666667, 0.3433333333333333], [0.8983050847457628, 0.35169491525423713], [0.9482758620689655, 0.35775862068965514], [0.9298245614035088, 0.35438596491228064], [0.9285714285714286, 0.3267857142857142], [0.9821428571428571, 0.3544642857142857], [0.8909090909090909, 0.3381818181818182], [0.9259259259259259, 0.34814814814814815], [0.8867924528301887, 0.369811320754717], [0.9622641509433962, 0.3556603773584906], [0.8653846153846154, 0.36346153846153845]]]
print(data)

p_ber_y = []

p_fer_y = []
#print("len(data)=",len(data))
#print("len(data[0])=", len(data[0]))

for k in range(len(data)):
    for p in range(len(data[0])):
        p_ber_y.append(data[k][p][1])
        p_fer_y.append(data[k][p][0])

plt.plot(range_p, p_ber_y,"r+") #range_p_exp
#plt.plot(range(len(data[0])), p_fer_y,"b")

range_p_log = [np.log(y) for y in range_p] #range_p_exp
lr = scipy.stats.linregress(range_p_log,p_ber_y)

print("correlation=",lr[2])
y = []
for x in range_p_log:
    y.append(x*lr[0] + lr[1])


plt.plot(range_p,y,"b") #range_p_exp

plt.yscale("log")
plt.show()




