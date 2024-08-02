import numpy as np
import nibabel as nb
from scipy import stats
from collections import Counter
from scipy.ndimage import binary_fill_holes
from scipy.ndimage.measurements import label


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



def clean(parc,gm,wm):
  im=nb.load(parc)
  p=im.get_fdata().astype(int)
  gm=nb.load(gm).get_fdata().astype(int)
  wm=nb.load(wm).get_fdata().astype(int)

  

  # remove CSF and but not ventricles
  p[np.where( (gm==0) & (wm==0) & (p!=4) )]=0

  
  # clean ventricle label
  p[np.where( (gm==1) & (p==4) )]=0
  p[np.where( (wm==1) & (p==4) )]=0


  # remove WM label from GM voxels
  p[np.where( (gm==1) & (p==2) )]=0


  # remove GM label from WM voxels
  p[np.where( (wm==1) & (p!=2) & (p!=7) & (p!=8) & (p!=10) & (p!=15) & (p!=16) & (p!=28) )]=2


  # fixing cerebellum parcellation
  p[np.where( (wm==1) & (p==8) )]=7
  p[np.where( (gm==1) & (p==7) )]=8
  


  # connected components
  st=np.zeros((3,3,3),dtype=int)
  st[1,1,1]=1
  st[0,1,1]=1
  st[2,1,1]=1
  st[1,0,1]=1
  st[1,2,1]=1
  st[1,1,0]=1
  st[1,1,2]=1
  un=np.unique(p)
  un=un[un>0]
  un=un[un!=8]
  un=un[un!=7]
  for uu in un:
    sek=np.zeros(p.shape)
    sek[p==uu]=1
    labeled,ncomponents=label(sek,st)
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
        p[labeled==ids[i]]=0

  # extension of cerebellum WM
  tmq=[]
  tmp=np.zeros(p.shape,dtype=int)
  tmp[p==7]=1
  pts=topts(tmp)
  for i in range(0,pts.shape[0]):
    tmq.append((pts[i,0],pts[i,1],pts[i,2]))
  while len(tmq)>0:
    print(len(tmq))
    q=np.copy(p)
    tmr=[]
    for i in range(0,len(tmq)):
      for dx in range(-1,2):
        for dy in range(-1,2):
          for dz in range(-1,2):
            xx=tmq[i][0]+dx
            yy=tmq[i][1]+dy
            zz=tmq[i][2]+dz
            if q[xx,yy,zz]==0 and wm[xx,yy,zz]==1:
              q[xx,yy,zz]=7
              tmr.append((xx,yy,zz))
    p=np.copy(q)
    tmq=tmr

  # extension of cerebellum GM
  tmp=np.zeros(p.shape,dtype=int)
  tmp[np.where( (gm==1) & (p==0) )]=1
  pts=topts(tmp)
  print(pts.shape)
  ra=3
  for i in range(0,pts.shape[0]):
    xa=max(0,pts[i,0]-ra)
    xb=min(gm.shape[0],pts[i,0]+ra+1)
    ya=max(0,pts[i,1]-ra)
    yb=min(gm.shape[1],pts[i,1]+ra+1)
    za=max(0,pts[i,2]-ra)
    zb=min(gm.shape[2],pts[i,2]+ra+1)
    pa=p[xa:xb,ya:yb,za:zb]
    if len(pa[pa==7])>5:
      p[pts[i,0],pts[i,1],pts[i,2]]=8
      


  # SAVE
  nb.save(nb.Nifti1Image(p,im.affine,im.header),parc)




################################################################################
if __name__ == "__main__":
	from argparse import ArgumentParser, RawTextHelpFormatter
	parser = ArgumentParser(description="Remove CSF and isolated components from a parcellation.",formatter_class=RawTextHelpFormatter)
	parser.add_argument("-p", "--parcellation",help="Parcellation (nifti).", required=True)
	parser.add_argument("-gm", "--gm",help="Nifti file with the grey matter mask.", required=True)
	parser.add_argument("-wm", "--wm",help="Nifti file with the white matter mask.", required=True)
	args = parser.parse_args()
	clean(args.parcellation,args.gm,args.wm)



