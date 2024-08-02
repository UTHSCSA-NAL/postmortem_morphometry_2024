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



#  e:
#  cd e:\\HOME\\postmortem\\models 
#  python checkSize.py


model=keras.models.load_model('all_multi_x_model.h5')
model.summary()


