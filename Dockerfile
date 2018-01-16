FROM nvidia/cuda:8.0-devel
#TODO upgrade to 9.1 when nvidia drivers are out on apt-get for ubuntu
#https://github.com/NVIDIA/nvidia-docker/wiki/CUDA#requirements
LABEL maintainer="Pascal Brokmeier <public@pascalbrokmeier.de>"

# 0 installing CUDA all the way
RUN apt-get update && \
	apt-get install wget && \
	cd / && \
	wget http://developer2.download.nvidia.com/compute/machine-learning/cudnn/secure/v7.0.5/prod/9.1_20171129/cudnn-9.1-linux-x64-v7.tgz?UddKP02dApNzWOK4JXcflhJz1B1j6YMSPiCNVsyllmIWgZq3po9SNmUIlWURrBgqMuJJB-xWXbB7LDpMiYDau3_ej0qws7AGeCrVvT63UyCePh_MQ93vNiuqx-RHi9lB90j83lPmqx_ZhcG0alHk-HoGJqqsCAS7LP00E2dvRUYKNBz-ACAeRvjoRB5VnhwBd-R8sa_uR6M
#Installing Python, Jupyter, Tensorflow, OpenAI Gym
###################################################
# 1. installing python2 and python3
RUN apt-get update && \
	apt install -y --no-install-recommends python3-pip python-pip python3 python
# 1.1 uppgrade pip and pip3
RUN pip3 install --upgrade pip setuptools && pip install --upgrade pip

# 2. installing jupyter, and a bunch of Science Python Packages
# packages taken from https://hub.docker.com/r/jupyter/datascience-notebook/
RUN pip3 install jupyter pandas matplotlib scipy seaborn scikit-learn scikit-Image sympy cython patsy statsmodels cloudpickle dill numba bokeh

# 3. installing Tensorflow (GPU)
# see here https://www.tensorflow.org/install/install_linux#InstallingNativePip
RUN pip3 install tensorflow-gpu

# 4. installing OpenAI Gym (plus dependencies)
RUN pip3 install gym pyopengl
# 4.1 installing roboschool and its dependencies. We love FOSS
RUN apt-get install -y --no-install-recommends cmake ffmpeg pkg-config qtbase5-dev libqt5opengl5-dev libassimp-dev libpython3.5-dev libboost-python-dev libtinyxml-dev
# This got some dependencies, so let's get going
# https://github.com/openai/roboschool
WORKDIR /gym
ENV ROBOSCHOOL_PATH="/gym/roboschool"
# installing bullet (the physics engine of roboschool) and its dependencies
RUN apt-get install -y --no-install-recommends git gcc g++ && \
	git clone https://github.com/openai/roboschool && \
	git clone https://github.com/olegklimov/bullet3 -b roboschool_self_collision && \
	mkdir bullet3/build && \
	cd    bullet3/build && \
	cmake -DBUILD_SHARED_LIBS=ON -DUSE_DOUBLE_PRECISION=1 -DCMAKE_INSTALL_PREFIX:PATH=$ROBOSCHOOL_PATH/roboschool/cpp-household/bullet_local_install -DBUILD_CPU_DEMOS=OFF -DBUILD_BULLET2_DEMOS=OFF -DBUILD_EXTRAS=OFF  -DBUILD_UNIT_TESTS=OFF -DBUILD_CLSOCKET=OFF -DBUILD_ENET=OFF -DBUILD_OPENGL3_DEMOS=OFF .. && \
	make -j4 && \
	make install

WORKDIR /gym/roboschool
RUN	pip3 install -e ./

# 5. installing X and xvfb so we can SEE the action using a remote desktop access (VNC)
# and because this is the last apt, let's clean up after ourselves
RUN apt-get install -y x11vnc xvfb fluxbox wmctrl && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*


# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888
# VNC Server
EXPOSE 5900

COPY run.sh /
CMD ["/run.sh", "--allow-root"]
