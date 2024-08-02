import numpy as np
import nibabel as nb
from scipy.ndimage.measurements import label



def core(mask,out,con):
  img=nb.load(mask)
  ma=img.get_fdata().astype(int)
  con=int(con)
  
  mas=np.zeros((3,3,3),dtype=int)
  mas[1,1,1]=1
  if con>=6:
    mas[0,1,1]=1
    mas[2,1,1]=1
    mas[1,0,1]=1
    mas[1,2,1]=1
    mas[1,1,0]=1
    mas[1,1,2]=1

  labeled,ncomponents=label(ma,mas)
  sz=np.zeros((ncomponents),dtype=int)
  for i in range(0,ncomponents):
    sz[i]=len(labeled[labeled==(i+1)])
  ie=np.argmax(sz)
  ma=np.zeros(ma.shape,dtype=int)
  ma[labeled==(ie+1)]=1

  nb.save(nb.Nifti1Image(ma,img.affine,img.header),out)


################################################################################
if __name__ == "__main__":
  from argparse import ArgumentParser, RawTextHelpFormatter
  parser = ArgumentParser(description="",formatter_class=RawTextHelpFormatter)
  parser.add_argument("-m", "--mask",help="Input mask", required=True)
  parser.add_argument("-o", "--out",help="Mask with only main component", required=True)
  parser.add_argument("-c", "--connectivity",help="connectivity", required=False,default='6')
  args = parser.parse_args()
  core(args.mask,args.out,args.connectivity)



