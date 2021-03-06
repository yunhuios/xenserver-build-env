#!/bin/sh

set -e

cd $HOME

SRPM_MOUNT_DIR=/mnt/docker-SRPMS/
LOCAL_SRPM_DIR=$HOME/local-SRPMs

case $GIT_BRANCH in
	trunk-pvs-direct)
		XS_REPO_KEY=aHR0cDovL3hzLXl1bS1yZXBvcy5zMy13ZWJzaXRlLXVzLWVhc3QtMS5hbWF6b25hd3MuY29tLzhlZmIzZWUtM2M3ZC0xMWU2LWI5NWUtMzNkZTkzOTJkZGYyL2RvbWFpbjA=
		;;
	dundee-bugfix)
		XS_REPO_KEY=aHR0cDovL3hzLXl1bS1yZXBvcy5zMy13ZWJzaXRlLXVzLWVhc3QtMS5hbWF6b25hd3MuY29tL2Q4YmM4ZWRmLWU4YzItNGI2ZC1iODJmLTI0ZDY3NDJlYThiYy9kb21haW4w
		;;
	trunk-car-2245)
		XS_REPO_KEY=aHR0cDovL3hzLXl1bS1yZXBvcy5zMy13ZWJzaXRlLXVzLWVhc3QtMS5hbWF6b25hd3MuY29tLzYwYWUxZjc3LWQzMGUtNDcyZi1iZDdkLWJjNmMzZGNmMjU4NS9kb21haW4w
		;;
	*)
		XS_REPO_KEY=aHR0cDovL3hzLXl1bS1yZXBvcy5zMy13ZWJzaXRlLXVzLWVhc3QtMS5hbWF6b25hd3MuY29tLzQ0OWU1MmE0LTI3MWEtNDgzYS1iYWE3LTI0YmYzNjI4NjZmNy9kb21haW4w
		;;
esac

if [ ! -z $XS_BRANCH ]
then
    sudo mv /etc/yum.conf /etc/yum.conf.backup
    sudo mv /etc/yum.conf.xs /etc/yum.conf

    sed -e "s/@XS_BRANCH@/${XS_BRANCH}/" /tmp/Citrix.repo.in > $HOME/Citrix.repo
    sudo mv $HOME/Citrix.repo /etc/yum.repos.d.xs/Citrix.repo
else
    XS_REPO=`python -c "import base64; import re; \
        print re.escape(base64.b64decode('${XS_REPO_KEY}'))"`
    sed -e "s/@XS_REPO@/${XS_REPO}/" /tmp/xs.repo.in > $HOME/xs.repo
    sudo mv $HOME/xs.repo /etc/yum.repos.d/xs.repo
    sudo yum --enablerepo=xs clean metadata
fi

mkdir -p $LOCAL_SRPM_DIR

# Download the source for packages specified in the environment.
if [ -n "$PACKAGES" ]
then
    for PACKAGE in $PACKAGES
    do
        yumdownloader --destdir=$LOCAL_SRPM_DIR --source $PACKAGE
    done
fi

# Copy in any SRPMs from the directory mounted by the host.
if [ -d $SRPM_MOUNT_DIR ]
then
    cp $SRPM_MOUNT_DIR/*.src.rpm $LOCAL_SRPM_DIR

fi

# Install deps for all the SRPMs.
SRPMS=`find $LOCAL_SRPM_DIR -name *.src.rpm`

for SRPM in $SRPMS
do
    sudo yum-builddep -y $SRPM
done

# double the default stack size
ulimit -s 16384

touch $HOME/.setup-complete

if [ ! -z "$COMMAND" ]
then
    $COMMAND
else
    /bin/sh --login
fi
