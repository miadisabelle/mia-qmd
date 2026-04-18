FROM jgwill/ubuntu:22-py3.11-node
#jgwill/ubuntu:py3.11
#jgwill/ubuntu:22-py3.11-node
#jgwill/ubuntu:py-node

WORKDIR /app

# Install Bun system-wide. The bun.sh installer only edits ~/.bashrc,
# which Docker's non-interactive RUN shell does NOT source — so without
# BUN_INSTALL=/usr/local + ENV PATH, later RUN steps and runtime shells
# hit "bash: bun: command not found".
ENV BUN_INSTALL="/usr/local"
ENV PATH="/usr/local/bin:${PATH}"

WORKDIR /workspace/repos/miadisabelle/mia-qmd
COPY . .
#RUN npm install
WORKDIR /workspace/repos/miadisabelle/mia-qmd/scripts
RUN ./40-bun-install.sh && bun --version
#RUN ./41-sqlite-dev-install.sh
RUN npm install -g @tobilu/qmd
#RUN ./42-qmd-install.sh
#RUN ./43-qmd-dev-setup.sh
WORKDIR /workspace/repos/miadisabelle/mia-qmd
RUN npm install && npm run build
#RUN apt update && apt install nvim -y

#COPY ./create_user_mia.sh .
#RUN bash create_user_mia.sh
#RUN chown -R mia .
#USER mia
# Add user jgi
#RUN useradd -ms /bin/bash jgi
#RUN echo "jgi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

#USER jgi
#WORKDIR /work


#!/bin/bash

# Define variables for UID, GID, and username
#USERNAME="mia"
#UID_VAL="1111"
#GID_VAL="1111"
#COMMENT="Mia User"
#HOME_DIR="/home/$USERNAME"

# Check if the group already exists, if not, create it
#if ! getent group "$GID_VAL" > /dev/null; then
#    echo "Creating group $USERNAME with GID $GID_VAL..."
RUN groupadd -g 1000 jgi
RUN groupadd -g 1008 mia
RUN groupadd -g 1111 bears
RUN groupadd -g 1212 ava
RUN groupadd -g 1414 tushell
  
# Check if the user already exists, if not, create it

RUN    useradd -u 1007 -g 1008 -c "Mia user" -m -d "/home/mia" -s /bin/bash mia
RUN    useradd -u 1212 -g 1212 -c "Ava user" -m -d "/home/ava" -s /bin/bash ava
RUN    useradd -u 1000 -g 1000 -c "JGI user" -m -d "/home/jgi" -s /bin/bash jgi
RUN    useradd -u 1414 -g 1414 -c "Tushell user" -m -d "/home/tushell" -s /bin/bash tushell

#add users in others and common group
RUN usermod -aG jgi mia
RUN usermod -aG jgi tushell
RUN usermod -aG jgi ava
RUN usermod -aG bears mia
RUN usermod -aG bears tushell
RUN usermod -aG bears ava
RUN usermod -aG bears jgi
RUN usermod -aG ava mia
RUN usermod -aG ava tushell
RUN usermod -aG ava jgi
RUN usermod -aG mia ava
RUN usermod -aG mia tushell
RUN usermod -aG mia jgi
RUN usermod -aG tushell jgi
RUN usermod -aG tushell mia
RUN usermod -aG tushell ava



#add mia to sudoers
RUN echo "mia ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "jgi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "ava ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "tushell ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN chown -R mia:bears .
RUN chmod -R g+rw .
# bun already installed system-wide above at /usr/local/bin/bun —
# no per-user reinstall needed; PATH is set via ENV for all users.

#USER mia


