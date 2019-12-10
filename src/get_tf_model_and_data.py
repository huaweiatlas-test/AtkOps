# ============================================================================
#
# Copyright (C) 2019, Huawei Technologies Co., Ltd. All Rights Reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   1 Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
#   2 Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
#   3 Neither the names of the copyright holders nor the names of the
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ============================================================================

import os
import numpy as np
import tensorflow as tf

'''
This file is used to obtain the pb model and data for the operator.
There are four steps to this file.
One example is shown in the following.
'''


def TFGenModelData(gen_pb_model=True):
    os.environ["CUDA_VISIBLE_DEVICES"] = ''

    with tf.Session(graph=tf.Graph()) as sess:
        '''
        STEP 1: plz input the tensor shapes
        shapes must be 4D, and the first dim means batch_size
        '''
        shape_x = (7, 2, 3, 4)
        shape_y = (7, 2, 3, 4)
        coor_x = tf.placeholder(tf.float32, shape=shape_x, name='x')
        coor_y = tf.placeholder(tf.float32, shape=shape_y, name='y')

        '''
        STEP 2: plz input the OP name
        '''
        name = "pow"

        '''
        STEP 3: plz input the specific tensorflow OP function
        '''
        tf_op = tf.pow(coor_x, coor_y, name=name)

        '''
        STEP 4:  plz config the OP data
        '''

        # input_x = np.random.rand(*shape_x).astype(np.float32, copy=False)\
        #  - 0.5
        # input_y = np.random.rand(*shape_y).astype(np.float32, copy=False)

        input_x = np.random.randint(1, 5, size=shape_x).astype(np.float32,
                                                               copy=False) - 8
        input_y = np.random.randint(1, 5, size=shape_y).astype(np.float32,
                                                               copy=False)

        feed_dict = {coor_x: input_x, coor_y: input_y}
        # feed_dict = {x: input_x}
        sess.run(tf.global_variables_initializer())
        expect = sess.run(tf_op, feed_dict)

        if gen_pb_model:
            current_path = os.getcwd()
            os.chdir("./common/op_verify_files/tensorflow_files")
            # ensure that there is only one om and pb in the
            # tensorflow_files directory
            for filename in os.listdir("./"):
                if filename.endswith(".om") or filename.endswith(".pb"):
                    os.remove(filename)
            graph = tf.compat.v1.graph_util.convert_variables_to_constants(
                sess, sess.graph_def, [name])
            with tf.gfile.FastGFile('tf_' + name + '.pb', mode='wb') as g_f:
                g_f.write(graph.SerializeToString())
            os.chdir(current_path)

    return [input_x, input_y], [expect, ]


if __name__ == "__main__":
    TFGenModelData()
