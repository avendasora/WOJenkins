#!/bin/bash
ROOT=$WORKSPACE/Root
WOPROJECT=woproject.jar
JOB_ROOT=${WORKSPACE}/../..
FRAMEWORKS_REPOSITORY=${HUDSON_HOME}/WOFrameworksRepository

echo "WO Version: ${WO_VERSION}"

if [ "$WO_VERSION" == "" ]; then
	echo "You must provide a WO_VERSION."
	exit 1
elif [ "$WO_VERSION" == "5.4.3" ]; then
	WO_ALT_VERSION=54
fi

WONDER_BRANCH_DIRECTORY = ${WONDER_BRANCH}
echo "WOnder Branch Directory: ${WONDER_BRANCH_DIRECTORY}"

#
# Configure the launch environment based on the platform information.
#
# Expected uname values:
#   Darwin
#   Mac OS
#   Rhapsody  (this is for things like JavaConverter, which need to run on Mac OS X Server 1.2)
#   *Windows* (this prints out an error message)
#   *winnt*   (ditto)
#
# Everything else is treated as "UNIX", the default.
#
PLATFORM_NAME="`uname -s`"

if [ "${PLATFORM_NAME}" = "" ]; then
    echo ${SCRIPT_NAME}: Unable to access uname executable!  Terminating.	
    echo If running on Windows, Quit it.
    exit 1	
fi

case "${PLATFORM_NAME}" in
    "Darwin")   PLATFORM_DESCRIPTOR=MacOS
                PLATFORM_TYPE=Darwin
                ;;
    "Mac OS")   PLATFORM_DESCRIPTOR=MacOS
                PLATFORM_TYPE=Darwin
                ;;
    "Rhapsody") PLATFORM_DESCRIPTOR=MacOS
                PLATFORM_TYPE=Rhapsody
                ;;
    *Windows*)  echo Windows?! Really?!! Shesh. This script only works with Linux/UNIX. Terminating.
                exit 1
                ;;
    *winnt*)    echo Windows?! Really?!! Shesh. This script only works with Linux/UNIX. Terminating.
                exit 1
                ;;
    *)          PLATFORM_DESCRIPTOR=UNIX
                PLATFORM_TYPE=Other
                ;;
esac

#
# Depending upon the platform, provide default values for the path
# abstractions (we call these values "shorthands").
#
if [ "${PLATFORM_TYPE}" = "Rhapsody" ]; then
    LOCAL_PATH_PREFIX=/Local
    SYSTEM_PATH_PREFIX=/System
elif [ "$PLATFORM_TYPE" = "Darwin" ]; then
    LOCAL_PATH_PREFIX=
    SYSTEM_PATH_PREFIX=/System
else
    LOCAL_PATH_PREFIX=/Local
    SYSTEM_PATH_PREFIX=
fi

# Make sure the Libraries folder exists
mkdir -p ${WORKSPACE}/Libraries

# Setup Root
rm -rf ${ROOT}
echo "mkdir -p ${ROOT}${LOCAL_PATH_PREFIX}"
mkdir -p ${ROOT}${LOCAL_PATH_PREFIX}
echo "mkdir -p ${ROOT}${SYSTEM_PATH_PREFIX}"
mkdir -p ${ROOT}${SYSTEM_PATH_PREFIX}

# Look for and link to WebObjects 
echo "Look for: ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library"
if [ -e "${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library" ]; then
	echo "ln -sfn ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library ${ROOT}${SYSTEM_PATH_PREFIX}"
	(ln -sfn ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library ${ROOT}${SYSTEM_PATH_PREFIX})	
else
	echo "WebObjects Version ${WO_VERSION} NOT FOUND!"
	echo "This build cannot run without it. Verify that the installWebObjects.sh script is being run and is using ${FRAMEWORKS_REPOSITORY} for its FRAMEWORKS_REPOSITORY variable."
	exit 1
fi

# Setup and link to Wonder frameworks repository directory
echo "Look for: ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WO_VERSION}${LOCAL_PATH_PREFIX}/Library"
if [ -e "${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WO_VERSION}${LOCAL_PATH_PREFIX}/Library" ]; then
	echo "This version of Wonder has already been built. I'll link to it instead of creating the directory."
else
	mkdir -p ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WO_VERSION}${LOCAL_PATH_PREFIX}/Library
fi
echo "ln -sfn ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WO_VERSION}${LOCAL_PATH_PREFIX}/Library ${ROOT}${LOCAL_PATH_PREFIX}"
(ln -sfn ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WO_VERSION}${LOCAL_PATH_PREFIX}/Library ${ROOT}${LOCAL_PATH_PREFIX})	

# Link to the woproject.jar so Ant can use it for building
mkdir -p ${ROOT}/lib
ln -sf ${FRAMEWORKS_REPOSITORY}/WOProject/${WOPROJECT} ${ROOT}/lib/${WOPROJECT}

# Setup wolips.properties for Ant to use for building
cat > ${ROOT}/hudson.build.properties << END
build.root=${ROOT}/Roots
wonder.patch=${WO_ALT_VERSION}
include.source=true

wonder.framework.install.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/Frameworks
web.framework.install.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebServer/Documents/WebObjects/Frameworks

wonder.application.install.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebObjects/Applications
web.application.install.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebServer/Documents/WebObjects

wo.local.root=${ROOT}${LOCAL_PATH_PREFIX}
wo.local.frameworks=${ROOT}${LOCAL_PATH_PREFIX}/Library/Frameworks

wo.system.root=${ROOT}${SYSTEM_PATH_PREFIX}
wo.system.frameworks=${ROOT}${SYSTEM_PATH_PREFIX}/Library/Frameworks

wo.extensions=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebObjects/Extensions

wo.bootstrapjar=${ROOT}${SYSTEM_PATH_PREFIX}/Library/WebObjects/JavaApplications/wotaskd.woa/WOBootstrap.jar
wo.apps.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebObjects/Applications
END
