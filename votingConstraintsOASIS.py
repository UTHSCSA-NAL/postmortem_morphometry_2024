import nibabel as nb
import numpy as np
from scipy import stats
from collections import Counter
from scipy.ndimage import binary_fill_holes
from scipy.ndimage.measurements import label


################################################################################
def loadFile(fil):
        fi=open(fil,'r')
        r=fi.readlines()
        fi.close()
        for i in range(0,len(r)):
                while r[i].endswith('\n') or r[i].endswith('\r') and len(r[i])>1:
                         r[i]=r[i][:-1]
                if r[i]=='\r' or r[i]=='\n':
                        r[i]=' '
        return r


################################################################################
def topts(m):
  n=len(m[m>0])
  r=np.zeros((n,3),dtype=int)
  n=0
  for x in range(0,m.shape[0]):
    for y in range(0,m.shape[1]):
      for z in range(0,m.shape[2]):
        if m[x,y,z]>0:
          r[n,0]=x
          r[n,1]=y
          r[n,2]=z
          n=n+1
  return r


def majorityVoting(li,ma,output,gm,wm,cons):
  lis=loadFile(li)
  #lis=lis[:1]
  
  ma=nb.load(gm).get_fdata().astype(int)
  gm=nb.load(gm).get_fdata().astype(int)
  wm=nb.load(wm).get_fdata().astype(int) 
  
  # constraints
  cons=loadFile(cons)
  excl={}
  for i in range(0,len(cons)):
    ie=int( cons[i][:cons[i].find(':')].strip() )
    tmp=cons[i][cons[i].find(':')+1:].split(',')
    tmq=[]
    for tm in tmp:
      tmq.append(int(tm.strip()))
    excl[ie]=tmq
  al=[]
  for exc in excl:
    al.extend(excl[exc])
  al=[*set(al)]
  al=np.array(al)
  incl={}
  for exc in excl:
    tmp=[]
    for a in al:
      if a not in excl[exc] :
        tmp.append(a)
    incl[exc]=tmp
  inclmaps={}
  for inc in incl:
    m={}
    for i in range(0,len(incl[inc])):
      m[incl[inc][i]]=i
    inclmaps[inc]=m

  # return parcellation
  r=np.zeros(wm.shape,dtype=int)

  # structural elements
  mas=np.zeros((3,3,3),dtype=int)
  mas[1,1,1]=1
  mas[0,1,1]=1
  mas[2,1,1]=1
  mas[1,0,1]=1
  mas[1,2,1]=1
  mas[1,1,0]=1
  mas[1,1,2]=1
  structure=mas
  
  
  # WM
  pts=topts(wm)
  print(pts.shape)
  cts=np.zeros((pts.shape[0],len(incl[2])))
  for ii in range(0,len(lis)):
    print('  '+str(ii)+'/'+str(len(lis)))
    li=lis[ii]
    a=nb.load(li).get_fdata().astype(int)
    for j in range(0,pts.shape[0]):
      x=pts[j,0]
      y=pts[j,1]
      z=pts[j,2]
      if a[x,y,z] in inclmaps[2]:
        ie=inclmaps[2][a[x,y,z]]
        cts[j,ie]=cts[j,ie]+1
  for j in range(0,len(pts)):
    r[pts[j,0],pts[j,1],pts[j,2]]=incl[2][np.argmax(cts[j,:])]

  # WM remove disconnected components
  for inc in incl[2]:
    sek=np.zeros(wm.shape,dtype=int)
    sek[r==inc]=1
    labeled,ncomponents=label(sek,structure)
    if ncomponents>1:
      szs=np.zeros((ncomponents))
      ids=np.zeros((ncomponents),dtype=int)
      for i in range(0,ncomponents):
        szs[i]=len(labeled[labeled==(i+1)])
        ids[i]=i+1
      ord=np.argsort(-szs)
      szs=szs[ord]
      ids=ids[ord]
      su=np.sum(szs)
      for i in range(1,ncomponents):
        r[labeled==ids[i]]=0
 
  # WM inpainting
  ra=3
  ptt=[]
  for j in range(0,pts.shape[0]):
    x=pts[j,0]
    y=pts[j,1]
    z=pts[j,2]
    if wm[x,y,z]==1 and r[x,y,z]==0:
      ptt.append((x,y,z))
  n=len(ptt)
  print(n)
  nn=n+1
  cpt=len(incl[2])
  while nn>n:
    nn=n
    rb=np.copy(r)
    for j in range(0,len(ptt)):
      xa=max(0,ptt[j][0]-ra)
      xb=min(wm.shape[0],ptt[j][0]+ra)
      ya=max(0,ptt[j][1]-ra)
      yb=min(wm.shape[1],ptt[j][1]+ra)
      za=max(2,ptt[j][2]-ra)
      zb=min(wm.shape[2],ptt[j][2]+ra)
      cpts=np.zeros((cpt))
      pa=r[xa:xb,ya:yb,za:zb]
      for i in range(0,len(incl[2])):
        cpts[i]=cpts[i]+len(pa[pa==incl[2][i]])
      ie=np.argmax(cpts)
      if cpts[ie]>0:
        rb[ptt[j][0],ptt[j][1],ptt[j][2]]=incl[2][ie]
    r=np.copy(rb)

    # update list of missing WM voxels
    ptu=[]
    for j in range(0,len(ptt)):
      x=ptt[j][0]
      y=ptt[j][1]
      z=ptt[j][2]
      if wm[x,y,z]==1 and r[x,y,z]==0:
        ptu.append((x,y,z))
    ptt=ptu 
    n=len(ptt)
    print(n)
  
  # WM voxels that cannot be inpainted are passed to GM
  gm[np.where( (wm==1) & (r==0) )]=1


  # cerebellum GM mask
  cere=np.zeros(wm.shape,dtype=int)
  for ii in range(0,len(lis)):
    print('  '+str(ii)+'/'+str(len(lis)))
    li=lis[ii]
    a=nb.load(li).get_fdata().astype(int)
    cere[a==8]=cere[a==8]+1
  cere[cere<len(lis)*0.25]=0
  cere[cere>len(lis)*0.2]=1
  print(len(cere[cere>0.5]))
  
  # GM majority voting
  pts=topts(gm)
  ipts=np.zeros(gm.shape,dtype=int)
  for i in range(0,pts.shape[0]):
    ipts[pts[i,0],pts[i,1],pts[i,2]]=i+1
  print(pts.shape)
  cts=np.zeros((pts.shape[0],len(incl[1])))
  dw=2
  ws=np.ones((2*dw+1,2*dw+1,2*dw+1))/98.0
  for dx in range(-dw,dw+1):
    for dy in range(-dw,dw+1):
      for dz in range(-dw,dw+1):
        ws[dx+dw,dy+dw,dz+dw]=np.exp( -(dx*dx+dy+dy+dz*dz)/4.0 )


  for ii in range(0,len(lis)):
    print('  '+str(ii)+'/'+str(len(lis)))
    li=lis[ii]
    a=nb.load(li).get_fdata().astype(int)
    for j in range(0,pts.shape[0]):
      x=pts[j,0]
      y=pts[j,1]
      z=pts[j,2]
      if a[x,y,z] in inclmaps[1]:
        ie=inclmaps[1][a[x,y,z]]
        for dx in range(-dw,dw+1):
          xx=pts[j,0]+dx
          if xx>=0 and xx<gm.shape[0]:
            for dy in range(-dw,dw+1):
              yy=pts[j,1]+dy
              if yy>=0 and yy<gm.shape[1]:
                for dz in range(-dw,dw+1):
                  zz=pts[j,2]+dz
                  if zz>=0 and zz<gm.shape[2]:
                    jj=ipts[xx,yy,zz]
                    if jj>0:
                      cts[jj-1,ie]=cts[jj-1,ie]+ws[dx+dw,dy+dw,dz+dw]
  for j in range(0,len(pts)):
    r[pts[j,0],pts[j,1],pts[j,2]]=incl[1][np.argmax(cts[j,:])] 
  
  print('Cerebellum GM correction')
  r[cere>0.5]=8

  # GM remove disconnected components
  #print('GM disconnected components')
  #for inc in incl[1]:
  #  sek=np.zeros(wm.shape,dtype=int)
  #  sek[r==inc]=1
  #  labeled,ncomponents=label(sek,structure)
  #  if ncomponents>1:
  #    szs=np.zeros((ncomponents))
  #    ids=np.zeros((ncomponents),dtype=int)
  #    for i in range(0,ncomponents):
  #      szs[i]=len(labeled[labeled==(i+1)])
  #      ids[i]=i+1
  #    ord=np.argsort(-szs)
  #    szs=szs[ord]
  #    ids=ids[ord]
  #    su=np.sum(szs)
  #    for i in range(1,ncomponents):
  #      r[labeled==ids[i]]=0
  
  
  # saving
  img=nb.load(lis[0])
  nb.save(nb.Nifti1Image(r,img.affine,img.header),output)



################################################################################
if __name__ == "__main__":
  from argparse import ArgumentParser, RawTextHelpFormatter
  parser = ArgumentParser(description="Majority voting.",formatter_class=RawTextHelpFormatter)
  parser.add_argument("-i", "--input",help="Text file with the name of the nifti files to combine.", required=True)
  parser.add_argument("-m", "--mask",help="Nifti file with the brain mask.", required=False,default='')
  parser.add_argument("-o", "--output",help="Output nifti file.", required=True)
  parser.add_argument("-gm", "--gm",help="GM map", required=True)
  parser.add_argument("-wm", "--wm",help="WM map", required=True)
  parser.add_argument("-c", "--constraints",help="Constraints (each line should be 'id:excl1,excl2,excl3')", required=True)
  args = parser.parse_args()
  majorityVoting(args.input,args.mask,args.output,args.gm,args.wm,args.constraints)




