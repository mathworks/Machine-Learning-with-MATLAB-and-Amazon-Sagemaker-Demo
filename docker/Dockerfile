# Copyright 2023 The MathWorks, Inc.
ARG MATLAB_RELEASE=r2023a

FROM docker.io/mathworks/matlab-deps:${MATLAB_RELEASE}

ARG MATLAB_RELEASE
ENV MATLAB_RELEASE=${MATLAB_RELEASE} MATLAB_DESTINATION=/opt/mathworks/matlab/${MATLAB_RELEASE}

# DL4006: Set the SHELL option -o pipefail before RUN with a pipe in
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install MATLAB, Parallel Computing Toolbox and Statistics and Machine Learning Toolbox.
# Any additional products required will be installed by the entrypoint
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm &&\
    chmod +x ./mpm &&\
    ./mpm install --no-gpu --release=${MATLAB_RELEASE}  --destination=${MATLAB_DESTINATION} --products MATLAB Parallel_Computing_Toolbox Statistics_and_Machine_Learning_Toolbox &&\
    rm ./mpm && \
    ln -s $MATLAB_DESTINATION/bin/matlab /usr/bin/matlab

# Install matlab-batch to enable the use of MATLAB batch licensing tokens.
RUN wget -qO- --retry-connrefused https://ssd.mathworks.com/supportfiles/ci/matlab-batch/v0/install.sh | bash -s

# Copy "sagemaker-training" folder
COPY matlab /opt/mathworks/sagemaker-training
ENV MATLABPATH /opt/mathworks/sagemaker-training

COPY entrypoint.sh /opt/mathworks/entrypoint.sh
ENTRYPOINT ["/opt/mathworks/entrypoint.sh"]
