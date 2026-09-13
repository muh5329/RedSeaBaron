"""Original procedural placeholder effects; no external samples."""
import math, pathlib, random, struct, wave
root=pathlib.Path(__file__).resolve().parents[1]/'assets/sfx'
root.mkdir(parents=True,exist_ok=True)
rng=random.Random(1947)
rate=22050
for name,duration in [('rifle',.28),('swing',.16),('hit',.2),('reload',.18),('step',.055),('jump',.16),('reward',.6),('engine',.6),('hurt',.22)]:
    pcm=[]
    for i in range(int(rate*duration)):
        t=i/rate; u=t/duration; n=rng.uniform(-1,1)
        if name=='rifle': value=(.65*n+.35*math.sin(t*2*math.pi*65))*math.exp(-u*10)
        elif name=='swing': value=n*math.sin(math.pi*u)*.22
        elif name=='hit': value=(math.sin(t*2*math.pi*780)+.5*math.sin(t*2*math.pi*1331)+n*.18)*math.exp(-u*9)*.45
        elif name=='reload': value=n*sum(math.exp(-((u-c)/.035)**2) for c in [.08,.4,.75])*.4
        elif name=='step': value=n*math.exp(-u*8)*.28
        elif name=='jump': value=math.sin(t*2*math.pi*(170+u*90))*math.sin(math.pi*u)*.22
        elif name=='reward': value=sum(math.sin(t*2*math.pi*f) for f in [392,494,587])*math.sin(math.pi*u)*math.exp(-u*3)*.18
        elif name=='engine': value=(math.sin(t*2*math.pi*80)+.3*math.sin(t*2*math.pi*160)+.12*math.sin(t*2*math.pi*240))*.3
        else: value=(.7*math.sin(2*math.pi*(130*t-30*t*t/duration))+.15*math.sin(2*math.pi*220*t)+n*.12)*math.exp(-u*7)*(1-math.exp(-t*160))*.5
        pcm.append(struct.pack('<h',int(max(-1,min(1,value))*28000)))
    with wave.open(str(root/(name+'.wav')),'wb') as output:
        output.setnchannels(1); output.setsampwidth(2); output.setframerate(rate); output.writeframes(b''.join(pcm))
