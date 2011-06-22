#!/bin/bash
FRAMEWORKS_REPOSITORY=${HUDSON_HOME}/WOFrameworksRepository

echo "Repository: ${FRAMEWORKS_REPOSITORY}"
echo "WO Version: ${WO_VERSION}"

if [ "${FRAMEWORKS_REPOSITORY}" == "" ]; then
	echo "You must provide a FRAMEWORK_REPOSITORY setting."
	exit 1
fi

if [ "${WO_VERSION}" == "" ]; then
	echo "You must provide a WO version."
	exit 1
fi

# Make sure the WebObjects & WOProject folders exist
mkdir -p ${FRAMEWORKS_REPOSITORY}/WebObjects
mkdir -p ${FRAMEWORKS_REPOSITORY}/WOProject

# Check to see if the WOInstaller.jar has been put in the Frameworks Repository
if [ ! -e "${FRAMEWORKS_REPOSITORY}/WebObjects/WOInstaller.jar" ]; then
    echo "WOInstaller.jar is not in the Frameworks Repository (${FRAMEWORKS_REPOSITORY}/WebObjects). It will be downloaded from http://webobjects.mdimension.com/wolips/WOInstaller.jar"
	cd ${FRAMEWORKS_REPOSITORY}/WebObjects/
	curl -O http://webobjects.mdimension.com/wolips/WOInstaller.jar
fi

# Check to see if the woproject.jar has been put in the Frameworks Repository
if [ ! -e "${FRAMEWORKS_REPOSITORY}/WOProject/woproject.jar" ]; then
    echo "woproject.jar is not in the Frameworks Repository (${FRAMEWORKS_REPOSITORY}/WOProject). It will be downloaded from http://webobjects.mdimension.com/hudson/job/WOLips36Current/lastSuccessfulBuild/artifact/woproject.jar"
	cd ${FRAMEWORKS_REPOSITORY}/WOProject/
	curl -O http://webobjects.mdimension.com/hudson/job/WOLips36Current/lastSuccessfulBuild/artifact/woproject.jar
fi

# Check to see if the specified version of WebObjects has been installed in the Frameworks Repository
if [ ! -d "${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}" ]; then
	echo "Downloading and Installing WebObjects ${WO_VERSION} in the Frameworks Repository"
	java -jar ${FRAMEWORKS_REPOSITORY}/WebObjects/WOInstaller.jar ${WO_VERSION} ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}
fi
