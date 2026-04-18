ctlid=2604180513
dockertag=jgwill/zeus:mia-qmd-$ctlid
dockertag1=jgwill/zeus:mia-qmd
dockertag2=jgwill/zeus:qmd
dockertag3=jgwill/server:qmd

containername=mia-qmd
dkhostname=$containername

# PORT
#dkport=4000:4000

xmount=/workspace:/workspace
xmount2=/home/mia:/home/mia


dkcommand=bash #command to execute (default is the one in the dockerfile)
if [ "$srcroot" == "" ]; then
    srcroot="/src"
fi

#dkextra=" -v \$dworoot/x:/x -p 2288:2288 "
dkextra=" --memory=512MB \
    -v /opt:/opt \
    -v $srcroot:/src "

#dkmounthome=true


##########################
############# RUN MODE
#dkrunmode="bg" #default fg
#dkrestart="--restart" #default
#dkrestarttype="unless-stopped" #default


#########################################
################## VOLUMES
#dkvolume="myvolname220413:/app" #create or use existing one
#dkvolume="$containername:/app" #create with containername name



#dkecho=true #just echo the docker run


# Use TZ
#DK_TZ=1



#####################################
#Build related
#
##chg back to that user
#dkchguser=vscode

######################## HOOKS BASH
### IF THEY EXIST, THEY are Executed, you can change their names

dkbuildprebuildscript=dkbuildprebuildscript.sh
dkbuildbuildsuccessscript=dkbuildbuildsuccessscript.sh
dkbuildfailedscript=dkbuildfailedscript.sh
dkbuildpostbuildscript=dkbuildpostbuildscript.sh

###########################################
# Unset deprecated
unset DOCKER_BUILDKIT

