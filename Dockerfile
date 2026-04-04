FROM jgwill/ubuntu:22-py3.11-node
#jgwill/ubuntu:py3.11
#jgwill/ubuntu:22-py3.11-node
#jgwill/ubuntu:py-node

WORKDIR /app

WORKDIR /workspace/repos/miadisabelle/mia-qmd
COPY . .
#RUN npm install
WORKDIR /workspace/repos/miadisabelle/mia-qmd/scripts
RUN ./40-bun-install.sh
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
  
# Check if the user already exists, if not, create it

RUN    useradd -u 1007 -g 1008 -c "Mia user" -m -d "/home/mia" -s /bin/bash mia
RUN    useradd -u 1000 -g 1000 -c "JGI user" -m -d "/home/jgi" -s /bin/bash jgi
#add mia to jgi group
RUN usermod -aG jgi mia
RUN usermod -aG bears mia
RUN usermod -aG jgi mia
#add mia to sudoers
RUN echo "mia ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN chown -R mia:mia .

USER mia


