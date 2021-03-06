#!/bin/bash -ex

OS_VERSION=$(rpm -qa | grep centos-release | cut -d "-" -f 3)

# Installing base packages
yum clean all
yum -y install \
cron \
epel-release \
freetype \
glibc-static \
libgomp \
libstdc++-static \
perl \
openssl \
wget

# Updating ca certs to get epel mirrors to work
yum -y upgrade ca-certificates --disablerepo=epel

yum -y groupinstall 'Development Tools'

# Installing condor
if [ $OS_VERSION -eq 7 ]; then
  CONDOR_URL=http://prod-exe.icecube.wisc.edu/htcondor/condor-8.7.2-x86_64_RedHat7-stripped.tar.gz
  CONDOR_VERSION=8.7.2
elif [ $OS_VERSION -eq 6 ]; then
  CONDOR_URL=http://parrot.cs.wisc.edu//symlink/20171108031502/8/8.7/8.7.3/419050e2acb5dbbb64a0e2d01a0fae0b/condor-8.7.3-x86_64_RedHat6-stripped.tar.gz
  CONDOR_VERSION=8.7.3
fi
useradd condor
su -c "wget ${CONDOR_URL}" - condor
su -c "mkdir ~/condor-${CONDOR_VERSION}; cd ~/condor-${CONDOR_VERSION}; mkdir local" - condor
su -c "cd ~/condor-${CONDOR_VERSION}; tar -z -x -f ~/condor-${CONDOR_VERSION}-*-stripped.tar.gz" - condor
su -c "cd ~/condor-${CONDOR_VERSION}; ./condor-${CONDOR_VERSION}-*-stripped/condor_install --local-dir /home/condor/condor-${CONDOR_VERSION}/local --make-personal-condor" - condor
rm -f /home/condor/condor-${CONDOR_VERSION}-*-stripped.tar.gz
chmod 755 /home/condor
chmod 755 /home/condor/condor-${CONDOR_VERSION}/condor.sh

# Installing pyglidein
useradd pyglidein
chmod 777 /home/pyglidein
yum -y install python-pip
pip install --upgrade setuptools
pip install ./pyglidein*

# Downloading pyglidein tarball
wget -O /opt/glidein.tar.gz -nv http://prod-exe.icecube.wisc.edu/glidein-RHEL_${OS_VERSION}_x86_64.tar.gz

# Installing Runit
wget http://smarden.org/runit/runit-2.1.2.tar.gz
tar xvzf runit-2.1.2.tar.gz
cd admin/runit-2.1.2/
./package/install
cd /
rm -f runit-2.1.2.tar.gz

# Installing CVMFS
yum -y install \
gawk \
fuse \
fuse-libs \
autofs \
attr \
gdb \
policycoreutils-python

rpm -ivh https://ecsft.cern.ch/dist/cvmfs/cvmfs-config/cvmfs-config-default-1.4-1.noarch.rpm
if [ $OS_VERSION -eq 7 ]; then
  CVMFS_RPM_NAME=cvmfs-2.3.5-1.el7.centos.x86_64.rpm
elif [ $OS_VERSION -eq 6 ]; then
  CVMFS_RPM_NAME=cvmfs-2.3.5-1.el6.x86_64.rpm
fi
rpm -ivh --nodeps https://ecsft.cern.ch/dist/cvmfs/cvmfs-2.3.5/${CVMFS_RPM_NAME}

# Adding automounter configs
echo "user_allow_other" >> /etc/fuse.conf
echo "/cvmfs /etc/auto.cvmfs" >> /etc/auto.master

# Adding icecube CVMFS configs
cat <<EOF >> /etc/cvmfs/default.local
CVMFS_REPOSITORIES='icecube.opensciencegrid.org'
CVMFS_HTTP_PROXY='DIRECT'
EOF

# Creating service links
mkdir /etc/service
ln -s /etc/sv/condor /etc/service/condor
ln -s /etc/sv/pyglidein_client /etc/service/pyglidein_client
ln -s /etc/sv/autofs /etc/service/autofs

# Creating data directory
mkdir /data/
mkdir /data/log
mkdir /data/log/condor
mkdir /data/log/pyglidein_client
mkdir /data/log/autofs

# Removing packages (fails in CentOS 6)
if [ $OS_VERSION -eq 7 ]
then
  yum -y groupremove 'Development Tools'
fi

# Removing root tarball
rm -f /root.tar.gz
