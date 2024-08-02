import numpy as np
import nibabel as nb

import tensorflow as tf
import tensorflow.keras.backend as K
from keras.layers import Input, Dense, Reshape, Flatten, Dropout, Lambda, Dot, Concatenate, Conv2DTranspose, Conv2D, LeakyReLU, concatenate, BatchNormalization
from tensorflow.keras.activations import sigmoid
from keras.models import Sequential, Model
from tensorflow.keras.optimizers import Adam, SGD, Nadam, RMSprop
from tensorflow.keras.optimizers import schedules
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras import regularizers



def application(a,b,model,ori,strides):
    aa=[np.squeeze(a),np.squeeze(b)]
    b=np.zeros(a.shape)
    cpts=np.zeros(a.shape)
    config=model.get_config()
    siz=config["layers"][0]["config"]["batch_input_shape"][1]
    m=len(aa)
	
    if ori=='x':
      p=0
      for i in range(0,a.shape[0]):
        for j in range(0,a.shape[1]-siz,strides):
          for k in range(0,a.shape[2]-siz,strides):
            p=p+1
        for j in range(0,a.shape[1]-siz,strides):
          p=p+1
        for k in range(0,a.shape[2]-siz,strides):
          p=p+1
      p=p+1
      pos=np.zeros((p,3),dtype=int)
      da=np.zeros((p,siz,siz,m))
      p=0
      for i in range(0,a.shape[0]):
        for j in range(0,a.shape[1]-siz,strides):
          for k in range(0,a.shape[2]-siz,strides):
            for kk in range(0,m):
              da[p,:,:,kk]=np.squeeze(aa[kk][i,j:(j+siz),k:(k+siz)])
            pos[p,:]=[i,j,k]
            p=p+1
        for j in range(0,a.shape[1]-siz,strides):
          for kk in range(0,m):
            da[p,:,:,kk]=np.squeeze(aa[kk][i,j:(j+siz),(a.shape[2]-siz):])
          pos[p,:]=[i,j,a.shape[2]-siz]
          p=p+1
        for k in range(0,a.shape[2]-siz,strides):
          for kk in range(0,m):
            da[p,:,:,kk]=np.squeeze(aa[kk][i,(a.shape[1]-siz):,k:(k+siz)])
          pos[p,:]=[i,a.shape[1]-siz,k]
          p=p+1
      for kk in range(0,m):
        da[p,:,:,kk]=np.squeeze(aa[kk][i,(a.shape[1]-siz):,(a.shape[2]-siz):])
      pos[p,:]=[i,a.shape[1]-siz,a.shape[2]-siz]
      p=p+1
      r=np.squeeze(model.predict(da))
      sl=np.ones((siz,siz))
      for i in range(0,pos.shape[0]):
        b[pos[i,0],pos[i,1]:(pos[i,1]+siz),pos[i,2]:(pos[i,2]+siz)]=b[pos[i,0],pos[i,1]:(pos[i,1]+siz),pos[i,2]:(pos[i,2]+siz)]+r[i,:,:]
        cpts[pos[i,0],pos[i,1]:(pos[i,1]+siz),pos[i,2]:(pos[i,2]+siz)]=cpts[pos[i,0],pos[i,1]:(pos[i,1]+siz),pos[i,2]:(pos[i,2]+siz)]+sl


    elif ori=='y':
      p=0
      for i in range(0,a.shape[1]):
        for j in range(0,a.shape[0]-siz,strides):
          for k in range(0,a.shape[2]-siz,strides):
            p=p+1
        for j in range(0,a.shape[0]-siz,strides):
          p=p+1
        for k in range(0,a.shape[2]-siz,strides):
          p=p+1
      p=p+1
      pos=np.zeros((p,3),dtype=int)
      da=np.zeros((p,siz,siz,m))
      p=0
      for i in range(0,a.shape[1]):
        for j in range(0,a.shape[0]-siz,strides):
          for k in range(0,a.shape[2]-siz,strides):
            for kk in range(0,m):
              da[p,:,:,kk]=np.squeeze(aa[kk][j:(j+siz),i,k:(k+siz)])
            pos[p,:]=[j,i,k]
            p=p+1
        for j in range(0,a.shape[0]-siz,strides):
          for kk in range(0,m):
            da[p,:,:,kk]=np.squeeze(aa[kk][j:(j+siz),i,(a.shape[2]-siz):])
          pos[p,:]=[j,i,a.shape[2]-siz]
          p=p+1
        for k in range(0,a.shape[2]-siz,strides):
          for kk in range(0,m):
            da[p,:,:,kk]=np.squeeze(aa[kk][(a.shape[0]-siz):,i,k:(k+siz)])
          pos[p,:]=[a.shape[0]-siz,i,k]
          p=p+1
      for kk in range(0,m):
        da[p,:,:,kk]=np.squeeze(aa[kk][(a.shape[0]-siz):,i,(a.shape[2]-siz):])
      pos[p,:]=[a.shape[0]-siz,i,a.shape[2]-siz]
      p=p+1
      r=np.squeeze(model.predict(da))
      sl=np.ones((siz,siz))
      for i in range(0,pos.shape[0]):
        b[pos[i,0]:(pos[i,0]+siz),pos[i,1],pos[i,2]:(pos[i,2]+siz)] =np.squeeze(b[pos[i,0]:(pos[i,0]+siz),pos[i,1],pos[i,2]:(pos[i,2]+siz)]) +r[i,:,:]
        cpts[pos[i,0]:(pos[i,0]+siz),pos[i,1],pos[i,2]:(pos[i,2]+siz)] =np.squeeze(cpts[pos[i,0]:(pos[i,0]+siz),pos[i,1],pos[i,2]:(pos[i,2]+siz)]) +sl


    elif ori=='z':
      p=0
      for i in range(0,a.shape[2]):
        for j in range(0,a.shape[0]-siz,strides):
          for k in range(0,a.shape[1]-siz,strides):
            p=p+1
        for j in range(0,a.shape[0]-siz,strides):
          p=p+1
        for k in range(0,a.shape[1]-siz,strides):
          p=p+1
      p=p+1
      pos=np.zeros((p,3),dtype=int)
      da=np.zeros((p,siz,siz,m))
      p=0
      for i in range(0,a.shape[2]):
        for j in range(0,a.shape[0]-siz,strides):
          for k in range(0,a.shape[1]-siz,strides):
            for kk in range(0,m):
              da[p,:,:,kk]=np.squeeze(aa[kk][j:(j+siz),k:(k+siz),i])
            pos[p,:]=[j,k,i]
            p=p+1
        for j in range(0,a.shape[0]-siz,strides):
          for kk in range(0,m):
            da[p,:,:,kk]=np.squeeze(aa[kk][j:(j+siz),(a.shape[1]-siz):,i])
          pos[p,:]=[j,a.shape[1]-siz,i]
          p=p+1
        for k in range(0,a.shape[1]-siz,strides):
          for kk in range(0,m):
            da[p,:,:,kk]=np.squeeze(aa[kk][(a.shape[0]-siz):,k:(k+siz),i])
          pos[p,:]=[a.shape[0]-siz,k,i]
          p=p+1
      for kk in range(0,m):
        da[p,:,:,kk]=np.squeeze(aa[kk][(a.shape[0]-siz):,(a.shape[1]-siz):,i])
      pos[p,:]=[a.shape[0]-siz,a.shape[1]-siz,i]
      p=p+1
      r=np.squeeze(model.predict(da))
      sl=np.ones((siz,siz))
      for i in range(0,pos.shape[0]):
        b[pos[i,0]:(pos[i,0]+siz),pos[i,1]:(pos[i,1]+siz),pos[i,2]] =np.squeeze(b[pos[i,0]:(pos[i,0]+siz),pos[i,1]:(pos[i,1]+siz),pos[i,2]]) +r[i,:,:]
        cpts[pos[i,0]:(pos[i,0]+siz),pos[i,1]:(pos[i,1]+siz),pos[i,2]]=np.squeeze(cpts[pos[i,0]:(pos[i,0]+siz),pos[i,1]:(pos[i,1]+siz),pos[i,2]])+sl


    else:
      print('wrong orientation: '+ori)


    b=np.divide( b,np.maximum(cpts,np.ones(a.shape)) )
    return b


def normalization(r):
	mi=0.0
	ma=np.quantile(r,0.999)
	r=(np.maximum(np.minimum(r,ma),mi)-mi)/(ma-mi)
	return r

def segmentation(mx,my,mz,t1,t2,output):
	strides=5
	modelx=keras.models.load_model(mx)
	modely=keras.models.load_model(my)
	modelz=keras.models.load_model(mz)
	a=nb.load(t1).get_fdata()
	b=nb.load(t2).get_fdata()

	a=normalization(a)
	b=normalization(b)
	
	vx=application(a,b,modelx,'x',strides)
	vy=application(a,b,modely,'y',strides)
	vz=application(a,b,modelz,'z',strides)
	
	im=nb.load(t1)
	r=vx+vy+vz
	nb.save(nb.Nifti1Image(r,im.affine,im.header),output)
	
################################################################################
if __name__ == "__main__":
	from argparse import ArgumentParser, RawTextHelpFormatter
	parser = ArgumentParser(description="Deepmir model application.",formatter_class=RawTextHelpFormatter)
	parser.add_argument("-mx", "--modelx",help="Model for the first orientation (x).", required=True)
	parser.add_argument("-my", "--modely",help="Model for the second orientation (y).", required=True)
	parser.add_argument("-mz", "--modelz",help="Model for the third orientation (z).", required=True)
	parser.add_argument("-t1", "--t1",help="T1 MRI scan", required=True)
	parser.add_argument("-t2", "--t2",help="T2 MRI scan", required=True)
	parser.add_argument("-o", "--output",help="Output mask", required=True)
	args = parser.parse_args()
	segmentation(args.modelx,args.modely,args.modelz,args.t1,args.t2,args.output)


