#!/bin/bash
ROOT=$WORKSPACE/Root
WOPROJECT=woproject.jar
JOB_ROOT=${WORKSPACE}/../..
FRAMEWORKS_REPOSITORY=${HUDSON_HOME}/WOFrameworksRepository

echo "WO Revision: ${WO_VERSION}"
echo "WOnder Version: ${WONDER_REVISION}"

if [ "$WORKSPACE" == "" ]; then
	echo "You must provide a workspace setting."
	exit 1
fi

if [ "$WO_VERSION" == "" ]; then
	echo "You must provide a WO version."
	exit 1
fi

WONDER_BRANCH_DIRECTORY=${WONDER_BRANCH}
echo "WOnder Branch Directory: ${WONDER_BRANCH_DIRECTORY}"

if [ "$WONDER_REVISION" == "" ]; then
	WONDER_REVISION_DIRECTORY="Head"
else
	WONDER_REVISION_DIRECTORY=${WONDER_REVISION//@/};
fi

if [ "$BRANCHES_TAGS_TRUNK" == "trunk" ]; then
	BRANCH_TAG_DELIMITER=""
elif [ "$BRANCHES_TAGS_TRUNK" == "" ]; then
	BRANCH_TAG_DELIMITER=""
else
	BRANCH_TAG_DELIMITER="_"
fi

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
    echo "${SCRIPT_NAME}: Unable to access uname executable!  Terminating."
    echo "If running on Windows, Quit it."
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
    *Windows*)  echo "Quit using Windows!  Terminating."
                exit 1
                ;;
    *winnt*)    echo "Quit using Windows!  Terminating"
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
if [ "${PLATFORM_TYPE}" = "Rhapsody" ]
then
    LOCAL_PATH_PREFIX=/Local
    SYSTEM_PATH_PREFIX=/System
elif [ "$PLATFORM_TYPE" = "Darwin" ]
then
    LOCAL_PATH_PREFIX=
    SYSTEM_PATH_PREFIX=/System
else
    LOCAL_PATH_PREFIX=/Local
    SYSTEM_PATH_PREFIX=
fi

# Make sure the Libraries folder exists
mkdir -p ${WORKSPACE}/Libraries

# Cleanout the Root directory of the project from the last build
rm -rf ${ROOT}

# Look for and link to the WOBootstrap.jar
echo "Look for: ${ROOT}${SYSTEM_PATH_PREFIX}/Library/WebObjects/JavaApplications/wotaskd.woa/WOBootstrap.jar"
if [ -e "${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library/WebObjects/JavaApplications/wotaskd.woa" ]; then
	mkdir -p ${ROOT}${SYSTEM_PATH_PREFIX}/Library/WebObjects/JavaApplications
	echo "ln -sfn ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library/WebObjects/JavaApplications/wotaskd.woa ${ROOT}${SYSTEM_PATH_PREFIX}/Library/WebObjects/JavaApplications/"
	(ln -sfn ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library/WebObjects/JavaApplications/wotaskd.woa ${ROOT}${SYSTEM_PATH_PREFIX}/Library/WebObjects/JavaApplications/)	
else
	echo "WOBootsrap.jar NOT FOUND!"
	echo "This build cannot run without it. Verify that the installWebObjects.sh script is using ${FRAMEWORKS_REPOSITORY} for its FRAMEWORKS_REPOSITORY variable."
	exit 1
fi

# Verify that the requested version of Wonder has been built and installed in the FRAMEWORKS_REPOSITORY
echo "Look for: ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WONDER_REVISION_DIRECTORY}/${WO_VERSION}"
if [ -e "${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WONDER_REVISION_DIRECTORY}/${WO_VERSION}" ]; then
	echo "${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WONDER_REVISION_DIRECTORY}/${WO_VERSION} Found!"
else
	echo "${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WONDER_REVISION_DIRECTORY}/${WO_VERSION} NOT found! You must build Wonder with the same WONDER_REVISION (${WONDER_REVISION}) and WO_VERSION (${WO_VERSION})"
	exit 1
fi	

# Link to the Frameworks that are on the classpath of this project. 
# (This does not copy the frameworks, it just links to them so it is very fast)

# Setup Directories for System and Local Frameworks
mkdir -p ${ROOT}${LOCAL_PATH_PREFIX}/Library/Frameworks
mkdir -p ${ROOT}${LOCAL_PATH_PREFIX}/Library/WebObjects/Extensions
mkdir -p ${ROOT}${SYSTEM_PATH_PREFIX}/Library/Frameworks

# Get all the Projects that have been checked out as part of this deployment
PROJECTS=`ls ${WORKSPACE}/Projects/`

# Step through them to get the list of WO frameworks on their Classpath.
for PROJECT in $PROJECTS; do
	if [ "${PROJECT}" == "${PROJECT_NAME}" ]; then
        echo "${PROJECT} is the requested project."
        FRAMEWORKS=`cat ${WORKSPACE}/Projects/${PROJECT}/.classpath  | grep WOFramework/ | sed 's#.*WOFramework/\([^"]*\)"/>#\1#'`
        # Step through each WOFramework in the .classpath and link to it in the FRAMEWORKS_REPOSITORY instead of copying it.
        for FRAMEWORK in $FRAMEWORKS; do
            FRAMEWORK_LINK_SUCCESSFUL="false"
            echo "Framework: ${FRAMEWORK}"
            
            # Check to see if the Framework is a System framework (WebObjects core frameworks) by checking for it in the System frameworks path of the repository
            echo "Look for: ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library/Frameworks/${FRAMEWORK}.framework"
            if [ -e "${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library/Frameworks/${FRAMEWORK}.framework" ]; then
                echo "ln -sfn ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library/Frameworks/${FRAMEWORK}.framework ${ROOT}${SYSTEM_PATH_PREFIX}/Library/Frameworks/"
                (ln -sfn ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library/Frameworks/${FRAMEWORK}.framework ${ROOT}${SYSTEM_PATH_PREFIX}/Library/Frameworks/)
                FRAMEWORK_LINK_SUCCESSFUL="true"
            fi
    
            # Check to see if the Framework is a WOnder framework by checking for it in the WOnder frameworks path of the repository
            # NOTE: The same framework name can exist in both (JavaWOExtensions.framework, for example) so this is not either/or situation
            # and we must link to both. The Local version will be used automatically by WO if it exists.
            echo "Look for: ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WONDER_REVISION_DIRECTORY}/${WO_VERSION}${LOCAL_PATH_PREFIX}/Library/Frameworks/${FRAMEWORK}.framework"
            if [ -e "${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WONDER_REVISION_DIRECTORY}/${WO_VERSION}${LOCAL_PATH_PREFIX}/Library/Frameworks/${FRAMEWORK}.framework" ]; then
                echo "ln -sfn ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WONDER_REVISION_DIRECTORY}/${WO_VERSION}${LOCAL_PATH_PREFIX}/Library/Frameworks/${FRAMEWORK}.framework ${ROOT}${LOCAL_PATH_PREFIX}/Library/Frameworks/"
                (ln -sfn ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WONDER_REVISION_DIRECTORY}/${WO_VERSION}${LOCAL_PATH_PREFIX}/Library/Frameworks/${FRAMEWORK}.framework ${ROOT}${LOCAL_PATH_PREFIX}/Library/Frameworks/)
                FRAMEWORK_LINK_SUCCESSFUL="true"
            fi	
    
            # Check to see if the Framework is a Hudson-Built framework by checking for it in the Jobs directory for properly named Hudson jobs.
            # NOTE: We may create and/or build our own version of a Wonder or System framework, so we need to check for that last too, so this
            # Can't be an elseif, it must be an if.
            echo "Look for: ${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}/lastSuccessful/archive/Projects/Application/dist/${FRAMEWORK}.tar.gz"
            if [ -e "${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}/lastSuccessful/archive/Projects/Application/dist/${FRAMEWORK}.tar.gz" ]; then
                echo "Look for: ${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}/lastSuccessful/archive/Projects/Application/dist/${FRAMEWORK}.tar.gz"
                if [ -e "${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}/lastSuccessful/archive/Projects/Application/dist/${FRAMEWORK}.framework" ]; then
                    echo "${FRAMEWORK}.tar.gz has already been extracted. Don't extract it again, that would just be silly."
                else
                    echo "${FRAMEWORK}.tar.gz has not been extracted. Do it."
                    echo "tar -C ${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}/lastSuccessful/archive/Projects/Application/dist/ -xf ${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}/lastSuccessful/archive/Projects/Application/dist/${FRAMEWORK}.tar.gz"
                    tar -C ${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}/lastSuccessful/archive/Projects/Application/dist/ -xf ${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}/lastSuccessful/archive/Projects/Application/dist/${FRAMEWORK}.tar.gz
                fi
                echo "ln -sfn ${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}/lastSuccessful/archive/Projects/Application/dist/${FRAMEWORK}.framework ${ROOT}${LOCAL_PATH_PREFIX}/Library/Frameworks/"
                (ln -sfn ${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}/lastSuccessful/archive/Projects/Application/dist/${FRAMEWORK}.framework ${ROOT}${LOCAL_PATH_PREFIX}/Library/Frameworks/)
                FRAMEWORK_LINK_SUCCESSFUL="true"
            fi
            
            if [ "${FRAMEWORK_LINK_SUCCESSFUL}" = "false" ]; then
                echo "Could not sucessfully link to ${FRAMEWORK}.framework. This framework must be available at one of the following locations:"
                echo "	1) In the WebObjects Frameworks at: ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library/Frameworks/${FRAMEWORK}.framework"
                echo "	2) In the Wonder Frameworks at: ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_BRANCH_DIRECTORY}/${WONDER_REVISION_DIRECTORY}/${WO_VERSION}${LOCAL_PATH_PREFIX}/Library/Frameworks/${FRAMEWORK}.framework"
                echo "	3) As a Hudson job named *exactly*: ${FRAMEWORK}${BRANCH_TAG_DELIMITER}${APPLICATION_BRANCH_TAG}"
                exit 1
            fi
        done
	fi
done

echo "\nLink to ${WOPROJECT} so Ant can build the WO project."
mkdir -p ${ROOT}/lib
ln -sf ${FRAMEWORKS_REPOSITORY}/WOProject/${WOPROJECT} ${ROOT}/lib/${WOPROJECT}

echo "\nSetup ${ROOT}/build.properties for Ant to use for building"
cat > ${ROOT}/build.properties << END
wo.system.root=${ROOT}${SYSTEM_PATH_PREFIX}
wo.system.frameworks=${ROOT}${SYSTEM_PATH_PREFIX}/Library/Frameworks

wo.local.root=${ROOT}${LOCAL_PATH_PREFIX}
wo.local.frameworks=${ROOT}${LOCAL_PATH_PREFIX}/Library/Frameworks

wo.extensions=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebObjects/Extensions

wo.bootstrapjar=${ROOT}${SYSTEM_PATH_PREFIX}/Library/WebObjects/JavaApplications/wotaskd.woa/WOBootstrap.jar
wo.apps.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebObjects/Applications

wolips.properties=${ROOT}/build.properties

project.name=${APPLICATION_NAME}

ant.build.javac.target=${JAVA_COMPATIBILITY_VERSION}
END

if [ "$BUILD_TYPE" == "Test Build" ]; then
cat ${ROOT}/build.properties > ${ROOT}/build.properties.temp1
cat > ${ROOT}/build.properties.temp2 << END

embed.Local=false
embed.Project=false
embed.System=false
embed.Network=false
END
cat ${ROOT}/build.properties.temp1 ${ROOT}/build.properties.temp2 > ${ROOT}/build.properties
rm ${ROOT}/build.properties.*
fi
