import nibabel as nb
import numpy as np
from scipy.ndimage import binary_fill_holes
#from scipy.ndimage.measurements import label


def core(image,di):
  di=int(di)
  im=nb.load(image)
  p=im.get_fdata().astype(int)
  
  if di==0:
    for i in range(0,p.shape[0]):
      p[i,:,:]=binary_fill_holes(p[i,:,:]).astype(int)
  elif di==1:
    for i in range(0,p.shape[1]):
      p[:,i,:]=binary_fill_holes(p[:,i,:]).astype(int)
  else:
    for i in range(0,p.shape[2]):
      p[:,:,i]=binary_fill_holes(p[:,:,i]).astype(int)

  nb.save(nb.Nifti1Image(p,im.affine,im.header),image)


################################################################################
if __name__ == "__main__":
	from argparse import ArgumentParser, RawTextHelpFormatter
	parser = ArgumentParser(description="Input image ",formatter_class=RawTextHelpFormatter)
	parser.add_argument("-i", "--image",help="NIFTI image", required=True)
	parser.add_argument("-d", "--direction",help="direction for inpainting", required=False,default='0')
	args = parser.parse_args()
	core(args.image,args.direction)


