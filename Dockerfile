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


# Copy scripts and ensure they have execute permissions
COPY --chown=$USER:$USER ./install-build-requirements.sh ./install-build-requirements.sh
COPY --chown=$USER:$USER ./.cubrid_env.sh ./.cubrid_env.sh

# Make sure the scripts have execute permissions
RUN chmod +x ./install-build-requirements.sh ./install-build-requirements.sh

# Run the install-build-requirements script
RUN ./install-build-requirements.sh

# Source .cubrid_env.sh in .bashrc
RUN echo 'source $HOME/.cubrid_env.sh' >> .bashrc

# Set the entrypoint to bash
CMD ["/bin/bash"]
