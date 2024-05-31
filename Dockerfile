FROM centos:7

# Update the base image and install sudo
RUN yum -y update && \
    yum install -y sudo && \
    yum clean all

RUN yum install -y neovim vim git wget

ENV USER=dhkimc

# Add user dhkim and add to wheel group for sudo privileges
RUN adduser $USER && \
    usermod -aG wheel $USER && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set the user to dhkim
USER $USER

# Ensure the working directory exists and has correct permissions
WORKDIR /home/$USER

COPY ./install-build-requirements.sh .

RUN source ./install-build-requirements.sh

COPY ./.cubrid_env.sh .

RUN echo 'source $HOME/.cubrid_env.sh' >> .bashrc

# RUN ./install-build-requirements.sh

# Set the entrypoint to bash
CMD ["/bin/bash"]

