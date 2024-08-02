import nibabel as nb
import numpy as np



def erosion(atlas,labels):
	im=nb.load(atlas)
	a=im.get_fdata()
	p=nb.load(labels).get_fdata()
	q=np.zeros(p.shape,dtype=int)
	r=np.zeros(p.shape,dtype=int)
	q[p==7]=1
	q[p==8]=1
	r[p>20]=1

	s=np.copy(r)

	for i in range(0,15):
		r=np.copy(s)
		s[1:,:,:]=np.maximum(s[1:,:,:],r[:-1,:,:])
		s[:,1:,:]=np.maximum(s[:,1:,:],r[:,:-1,:])
		s[:,:,1:]=np.maximum(s[:,:,1:],r[:,:,:-1])
		s[:-1,:,:]=np.maximum(s[:-1,:,:],r[1:,:,:])
		s[:,:-1,:]=np.maximum(s[:,:-1,:],r[:,1:,:])
		s[:,:,:-1]=np.maximum(s[:,:,:-1],r[:,:,1:])

	q=q*s
	a[q>0]=0
	p[q>0]=0
	nb.save(nb.Nifti1Image(a,im.affine,im.header),atlas)
	nb.save(nb.Nifti1Image(p,im.affine,im.header),labels)



################################################################################
if __name__ == "__main__":
	from argparse import ArgumentParser, RawTextHelpFormatter
	parser = ArgumentParser(description="",formatter_class=RawTextHelpFormatter)
	parser.add_argument("-a", "--atlas",help="Atlas", required=True)
	parser.add_argument("-l", "--labels",help="Labels", required=True)
	args = parser.parse_args()
	erosion(args.atlas,args.labels)


