RAM="4096MB"
. ../../_env.sh
ctlid=2604072340
_user="$(basename $(realpath .))"
dockertag=$dockertag-user-$_user
unset dockertag1
unset dockertag2
unset dockertag3

containername=$_user'-qmd'
dkhostname=$containername

# PORT
#dkport=4000:4000

xmount=/workspace:/workspace
xmount2=/home:/home

creative_repo_root=/cesaret
_creative_repo_root_realpath="$(cd $creative_repo_root && realpath .)"
echo "Creative repo realpath: $_creative_repo_root_realpath will be mounted in $creative_repo_root"

dkcommand=bash #command to execute (default is the one in the dockerfile)
if [ "$srcroot" == "" ]; then
    srcroot="/src"
fi
_srcroot_realpath="$(cd $srcroot && realpath .)"

#dkextra=" -v \$dworoot/x:/x -p 2288:2288 "
dkextra=" --memory=$RAM \
    -v /opt:/opt \
    -v $_srcroot_realpath:/src \
    -v /a/src:/a/src \
    -v /etc/claude-code:/etc/claude-code \
    -v $_creative_repo_root_realpath:$creative_repo_root "



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

