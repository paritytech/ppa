#!/bin/sh

depblatform=trusty
if [ -z "$BUILD_NUMBER" ]
	then BUILD_NUMBER=0
fi

distribution=${debplatform}
if [ -z "$distribution" ]
	then distribution=trusty
fi
echo "building for ${distribution}"
arch=amd64
mainrepo=parity
now=$(date +"%Y%m%d")
project="parity"
ppabranch=master
codebranch=${paritybranch}
pparepo=ethcore/ppa
if [ -z "$codebranch" ]; then
	codebranch=master
fi
echo codebranch=${codebranch}
echo pparepo=${pparepo}

#pparepo=arkadiy-c/coretest

keyid=build@ethcore.io
mainppa="http://ppa.launchpad.net/ethcore/ethcore/ubuntu"
devppa="http://ppa.launchpad.net/ethcore/ethcore-dev/ubuntu"
rocksdbppa="http://ppa.launchpad.net/giskou/librocksdb/ubuntu"

# clone source repo
#git clone https://github.com/ethcore/${mainrepo}.git -b ${codebranch} --recursive
git clone git@github.com:ethcore/${mainrepo}.git -b ${codebranch} --recursive
# create source tarball"
cd ${mainrepo}
version=`grep -oP "version = \"?\K[0-9.]+(?=\")"? Cargo.toml`
revision=`git rev-parse --short HEAD`

if [ "${codebranch}" = "release" ]; then 
    	debversion=${version}~${distribution}
    	debversion=${version}
    else
    	debversion=${version}-SNAPSHOT-${BUILD_NUMBER}-${now}-${revision}~${distribution}
    	debversion=${version}-SNAPSHOT-${BUILD_NUMBER}-${now}-${revision}
fi

echo debversion=${debversion}

tar --exclude .git -czf ../${project}_${debversion}.orig.tar.gz .

cp -R ../debian .

# get debian/ direcotry
# wget https://github.com/ethcore/ppa/archive/${ppabranch}.tar.gz -O- |
# tar -zx --exclude package.sh --exclude README.md --strip-components=1

# bump version
EMAIL="$keyid" dch -v ${debversion}-0 "git build of ${revision}"

# build source package
debuild -S -sa -us -uc

# set PPA dependencies for pbuilder
#echo "OTHERMIRROR=\"deb [trusted=yes] ${rocksdbppa} ${distribution} main|deb-src [trusted=yes] ${rocksdbppa} ${distribution} main\"" > ~/.pbuilderrc

# prepare .changes file for Launchpad
sed -i -e s/UNRELEASED/${distribution}/ -e s/urgency=medium/urgency=low/ ../*.changes

# sign the package
debsign -k ${keyid} ../${project}_${debversion}-0_source.changes

# upload
#dput ppa:${pparepo} ../${project}_${debversion}-0_source.changes

