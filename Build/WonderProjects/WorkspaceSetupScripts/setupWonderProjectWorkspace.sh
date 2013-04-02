#!/bin/bash
ROOT="$WORKSPACE/Root"
WOPROJECT="woproject.jar"
JOB_ROOT="${WORKSPACE}/../.."
FRAMEWORKS_REPOSITORY="${JENKINS_HOME}/WOFrameworksRepository"

echo "             Project Name: ${PROJECT_NAME}"
if [ "${DEPLOYED_APPLICATION_NAME}" == "" ]; then
	DEPLOYED_APPLICATION_NAME="${PROJECT_NAME}"
fi
echo "Deployed Application Name: ${DEPLOYED_APPLICATION_NAME}"

echo "              WO Revision: ${WO_VERSION}"
if [ "$WO_VERSION" == "" ]; then
	echo "You must provide a WO version."
	exit 1
fi

echo "           WOnder Version: ${WONDER_GIT_REFERENCE}"
if [ "$WONDER_GIT_REFERENCE" == "" ]; then
	echo "You must provide a Git Reference for Wonder."
	exit 1
fi

if [ "$PROJECT_BRANCHES_TAGS_TRUNK" == "trunk" ]; then
	BRANCH_TAG_DELIMITER=""
elif [ "$PROJECT_BRANCHES_TAGS_TRUNK" == "" ]; then
	BRANCH_TAG_DELIMITER=""
else
	BRANCH_TAG_DELIMITER="_"
fi

#
# Configure the environment based on the platform information.
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
	echo "If you are running on Windows, Stop it! This script isn't Windows compatible"
	exit 1
fi

case "${PLATFORM_NAME}" in
    "Darwin")   PLATFORM_DESCRIPTOR="MacOS"
                	  PLATFORM_TYPE="Darwin"
                ;;
    "Mac OS")   PLATFORM_DESCRIPTOR="MacOS"
                	  PLATFORM_TYPE="Darwin"
                ;;
    "Rhapsody") PLATFORM_DESCRIPTOR="MacOS"
                	  PLATFORM_TYPE="Rhapsody"
                ;;
    *Windows*)  echo "Windows?! Really?!! Shesh. This script only works with MacOS/Linux/UNIX. Terminating."
                exit 1
                ;;
    *winnt*)    echo "Windows?! Really?!! Shesh. This script only works with MacOS/Linux/UNIX. Terminating."
                exit 1
                ;;
    *)          PLATFORM_DESCRIPTOR="UNIX"
                	  PLATFORM_TYPE="Other"
                ;;
esac
echo "            Platform Type: ${PLATFORM_TYPE}"

#
# Depending upon the platform, provide default values for the path abstractions
#
if [ "${PLATFORM_TYPE}" = "Rhapsody" ]; then
    LOCAL_PATH_PREFIX="/Local"
    SYSTEM_PATH_PREFIX="/System"
elif [ "$PLATFORM_TYPE" = "Darwin" ]; then
    LOCAL_PATH_PREFIX=""
    SYSTEM_PATH_PREFIX="/System"
else
    LOCAL_PATH_PREFIX="/Local"
    SYSTEM_PATH_PREFIX=""
fi
echo "        Local Path Prefix: ${LOCAL_PATH_PREFIX}"
echo "       System Path Prefix: ${SYSTEM_PATH_PREFIX}"

	  WEBOBJECTS_ROOT_IN_FRAMEWORKS_REPOSITORY="${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}"
	WO_JAVA_APPS_ROOT_IN_FRAMEWORKS_REPOSITORY="${WEBOBJECTS_ROOT_IN_FRAMEWORKS_REPOSITORY}/Library/WebObjects/JavaApplications"
			  WOTASKD_IN_FRAMEWORKS_REPOSITORY="${WO_JAVA_APPS_ROOT_IN_FRAMEWORKS_REPOSITORY}/wotaskd.woa"
WEBOBJECTS_FRAMEWORKS_IN_FRAMEWORKS_REPOSITORY="${WEBOBJECTS_ROOT_IN_FRAMEWORKS_REPOSITORY}/Library/Frameworks"

		  WONDER_ROOT_IN_FRAMEWORKS_REPOSITORY="${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_GIT_REFERENCE}/${WO_VERSION}"
	WONDER_FRAMEWORKS_IN_FRAMEWORKS_REPOSITORY="${WONDER_ROOT_IN_FRAMEWORKS_REPOSITORY}/Library/Frameworks"

				 WO_SYSTEM_ROOT_FOR_THIS_BUILD="${ROOT}${SYSTEM_PATH_PREFIX}"
		   WO_SYSTEM_FRAMEWORKS_FOR_THIS_BUILD="${WO_SYSTEM_ROOT_FOR_THIS_BUILD}/Library/Frameworks"
			  WO_JAVA_APPS_ROOT_FOR_THIS_BUILD="${WO_SYSTEM_ROOT_FOR_THIS_BUILD}/Library/WebObjects/JavaApplications"
			   WO_BOOTSTRAP_JAR_FOR_THIS_BUILD="${WO_JAVA_APPS_ROOT_FOR_THIS_BUILD}/wotaskd.woa/WOBootstrap.jar"

				  WO_LOCAL_ROOT_FOR_THIS_BUILD="${ROOT}${LOCAL_PATH_PREFIX}"
			WO_LOCAL_FRAMEWORKS_FOR_THIS_BUILD="${WO_LOCAL_ROOT_FOR_THIS_BUILD}/Library/Frameworks"
				  WO_EXTENSIONS_FOR_THIS_BUILD="${WO_LOCAL_ROOT_FOR_THIS_BUILD}/Library/WebObjects/Extensions"
				   WO_APPS_ROOT_FOR_THIS_BUILD="${WO_LOCAL_ROOT_FOR_THIS_BUILD}/Library/WebObjects/Applications"


# Make sure the Libraries folder exists
mkdir -p ${WORKSPACE}/Libraries

# Cleanout the Root directory of the project from the last build
rm -rf ${ROOT}

# Look for and link to the WOBootstrap.jar
echo " "
echo "Look for: ${WOTASKD_IN_FRAMEWORKS_REPOSITORY}"
if [ -e "${WOTASKD_IN_FRAMEWORKS_REPOSITORY}" ]; then
	mkdir -p ${WO_JAVA_APPS_ROOT_FOR_THIS_BUILD}
	echo "    Found wotaskd.woa in the Framworks Repository."
	echo "        Linking: ln -sfn ${WOTASKD_IN_FRAMEWORKS_REPOSITORY}"
	echo "                         ${WO_JAVA_APPS_ROOT_FOR_THIS_BUILD}"
	(ln -sfn ${WOTASKD_IN_FRAMEWORKS_REPOSITORY} ${WO_JAVA_APPS_ROOT_FOR_THIS_BUILD})
else
	echo "    WOBootstrap.jar NOT FOUND!"
	echo "        This build cannot run without it. Verify that WebObjects has been installed"
	echo "        with WOJenkins and the WOJenkins installWebObjects.sh script is using"
	echo "        ${FRAMEWORKS_REPOSITORY}"
	echo "        for its FRAMEWORKS_REPOSITORY variable."
	exit 1
fi

# Verify that the requested version of Wonder has been built and installed in the FRAMEWORKS_REPOSITORY
echo "Look for: ${WONDER_FRAMEWORKS_IN_FRAMEWORKS_REPOSITORY}"
if [ -e "${WONDER_FRAMEWORKS_IN_FRAMEWORKS_REPOSITORY}" ]; then
	echo "    Project WOnder Frameworks Found."
else
	echo "    Project WOnder Frameworks not found! You must build Wonder with"
	echo "    WONDER_REVISION = ${WONDER_GIT_REFERENCE} and WO_VERSION = ${WO_VERSION}"
	exit 1
fi

# Link to the Frameworks that are on the classpath of this project.
# (This does not copy the frameworks, it just links to them so it is very fast)

# Setup Directories for System and Local Frameworks
mkdir -p ${WO_SYSTEM_FRAMEWORKS_FOR_THIS_BUILD}
mkdir -p ${WO_LOCAL_FRAMEWORKS_FOR_THIS_BUILD}
mkdir -p ${WO_EXTENSIONS_FOR_THIS_BUILD}

# Get all the Projects that have been checked out as part of this job
PROJECTS=`ls ${WORKSPACE}/Projects/`

# Step through them to get the list of WO frameworks on their Classpath.
for PROJECT in $PROJECTS; do
	if [ "${PROJECT}" == "${PROJECT_NAME}" ]; then
		echo " "
		echo "Parsing ${WORKSPACE}/Projects/**/.classpath to determine WOFramework dependencies"
		FRAMEWORKS=`cat ${WORKSPACE}/Projects/**/.classpath | grep WOFramework/ | sed 's#.*WOFramework/\([^"]*\)"/>#\1#'`
		echo "WOFrameworks required by ${PROJECT} :"
		echo "$FRAMEWORKS"
		echo "Find them and create Symbolic Links to them (much faster than copying!)"
		# Step through each WOFramework in the .classpath and try to find it
		# in one of the following places:
		#	1) In the projects checked out by this project in the ${WORKSPACE}/Projects directory
		#	2) WebObjects Frameworks in the WOFrameworksRepository
		#	3) Project WOnder Frameworks in the WOFrameworksRepository
		#	4) Other Jenkins jobs with matching names - very limiting.
		#		(TODO: This should look for other jobs that have this job's name
		#			   in the <childProjects> tag of their config.xml file.)
		for FRAMEWORK in $FRAMEWORKS; do
			FRAMEWORK_LINK_SUCCESSFUL="false"
			echo " "
			echo "Look For: ${FRAMEWORK}"
			FRAMEWORK_IN_SAME_JOB_PROJECT="${WORKSPACE}/Projects/${FRAMEWORK}"
			FRAMEWORK_NAME_IN_SAME_JOB_INSTALL="${WORKSPACE}/Projects/${FRAMEWORK}/dist/${FRAMEWORK}.framework"
			FRAMEWORK_NAME_IN_WEBOBJECTS_INSTALL="${WEBOBJECTS_FRAMEWORKS_IN_FRAMEWORKS_REPOSITORY}/${FRAMEWORK}.framework"
			FRAMEWORK_NAME_IN_WONDER_INSTALL="${WONDER_FRAMEWORKS_IN_FRAMEWORKS_REPOSITORY}/${FRAMEWORK}.framework"
			JENKINS_FRAMEWORK_JOB_DIST="${JOB_ROOT}/${FRAMEWORK}${BRANCH_TAG_DELIMITER}${PROJECT_BRANCH_TAG}/lastSuccessful/archive/Projects/${FRAMEWORK}/dist"
			FRAMEWORK_ARTIFACT_PATH_IN_JENKINS_JOB="${JENKINS_FRAMEWORK_JOB_DIST}/${FRAMEWORK}.tar.gz"

			# Check to see if the Framework is being built as
			# part of this job. Of course, this job will need
			# to ensure that it is building things in the right
			# sequence, i.e., dependency order (frameworks
			# before Applications).
			if [ -e "${FRAMEWORK_IN_SAME_JOB_PROJECT}" ]; then
				echo "    Found in this job's Workspace/Projects directory. Assuming it will be built and installed in: ${FRAMEWORK_NAME_IN_SAME_JOB_INSTALL}"
				if [ ! -e "${FRAMEWORK_NAME_IN_SAME_JOB_INSTALL}" ]; then
					echo "            ${FRAMEWORK_NAME_IN_SAME_JOB_INSTALL} doesn't yet exist, make it and link to it."
					echo "            mkdir -p ${FRAMEWORK_NAME_IN_SAME_JOB_INSTALL}"
					mkdir -p ${FRAMEWORK_NAME_IN_SAME_JOB_INSTALL}
				fi
				echo "        Linking: ln -sfn ${FRAMEWORK_NAME_IN_SAME_JOB_INSTALL}"
				echo "                         ${WO_LOCAL_FRAMEWORKS_FOR_THIS_BUILD}"
				(ln -sfn ${FRAMEWORK_NAME_IN_SAME_JOB_INSTALL} ${WO_LOCAL_FRAMEWORKS_FOR_THIS_BUILD})
				FRAMEWORK_LINK_SUCCESSFUL="true"
			else
				echo "    Not found in this job's Workspace/Projects directory: ${FRAMEWORK_IN_SAME_JOB_PROJECT}"

				# Check to see if the Framework is a System framework
				# (WebObjects core frameworks) by checking for it in the
				# System frameworks path of the repository
				if [ -e "${FRAMEWORK_NAME_IN_WEBOBJECTS_INSTALL}" ]; then
					echo "    Found in WebObjects."
					echo "        Linking: ln -sfn ${FRAMEWORK_NAME_IN_WEBOBJECTS_INSTALL}"
					echo "                         ${WO_SYSTEM_FRAMEWORKS_FOR_THIS_BUILD}"
					(ln -sfn ${FRAMEWORK_NAME_IN_WEBOBJECTS_INSTALL} ${WO_SYSTEM_FRAMEWORKS_FOR_THIS_BUILD})
					FRAMEWORK_LINK_SUCCESSFUL="true"
				else
					echo "    Not found in WebObjects: ${FRAMEWORK_NAME_IN_WEBOBJECTS_INSTALL}"
				fi

				# Check to see if the Framework is a WOnder framework by
				# checking for it in the WOnder frameworks path of the
				# repository NOTE: The same framework name can exist in both
				# (JavaWOExtensions.framework, for example) so this is not
				# either/or situation and we must link to both. The Local
				# version will be used automatically by WO if it exists.
				if [ -e "${FRAMEWORK_NAME_IN_WONDER_INSTALL}" ]; then
					echo "    Found in Project WOnder."
					echo "        Linking: ln -sfn ${FRAMEWORK_NAME_IN_WONDER_INSTALL}"
					echo "                         ${WO_LOCAL_FRAMEWORKS_FOR_THIS_BUILD}"
					(ln -sfn ${FRAMEWORK_NAME_IN_WONDER_INSTALL} ${WO_LOCAL_FRAMEWORKS_FOR_THIS_BUILD})
					FRAMEWORK_LINK_SUCCESSFUL="true"
				else
					echo "    Not found in Project WOnder: ${FRAMEWORK_NAME_IN_WONDER_INSTALL}"
				fi

				# Check to see if the Framework is a Jenkins-Built framework
				# by checking for it in the Jobs directory for properly
				# named Hudson jobs. NOTE: We may create and/or build our
				# own version of a Wonder or System framework, so we need to
				# check for that last too, so this Can't be an elseif, it
				# must be an if.
				if [ -e "${FRAMEWORK_ARTIFACT_PATH_IN_JENKINS_JOB}" ]; then
					echo "    Found in Jenkins Job: ${JENKINS_URL}job/${FRAMEWORK}/lastSuccessfulBuild/artifact/Projects/${FRAMEWORK}/dist"
					echo "        ${FRAMEWORK_ARTIFACT_PATH_IN_JENKINS_JOB}"
					if [ -e "${JENKINS_FRAMEWORK_JOB_DIST}/${FRAMEWORK}.framework" ]; then
						echo "    ${FRAMEWORK}.tar.gz has already been extracted."
					else
						echo "    ${FRAMEWORK}.tar.gz has not been extracted. Extracting now."
						echo "        tar -C ${JENKINS_FRAMEWORK_JOB_DIST}"
						echo "            -xf ${FRAMEWORK_ARTIFACT_PATH_IN_JENKINS_JOB}"
						tar -C ${JENKINS_FRAMEWORK_JOB_DIST} -xf ${FRAMEWORK_ARTIFACT_PATH_IN_JENKINS_JOB}
					fi
					echo "        Linking: ln -sfn ${JENKINS_FRAMEWORK_JOB_DIST}/${FRAMEWORK}.framework"
					echo "                         ${WO_LOCAL_FRAMEWORKS_FOR_THIS_BUILD}"
					(ln -sfn ${JENKINS_FRAMEWORK_JOB_DIST}/${FRAMEWORK}.framework ${WO_LOCAL_FRAMEWORKS_FOR_THIS_BUILD})
					FRAMEWORK_LINK_SUCCESSFUL="true"
				else
					echo "    Not found in other build job: ${FRAMEWORK_ARTIFACT_PATH_IN_JENKINS_JOB}"
				fi
			fi

			if [ "${FRAMEWORK_LINK_SUCCESSFUL}" = "false" ]; then
				echo "Could not sucessfully link to ${FRAMEWORK}.framework."
				echo "    ${FRAMEWORK}.framework must be available at one of the following locations:"
				echo "        1) As another project checked out by this job into the workspace Projects directory: ${FRAMEWORK_IN_SAME_JOB_PROJECT}"
				echo "           and built (most likely by its own ant task) into: ${FRAMEWORK_NAME_IN_SAME_JOB_INSTALL}"
				echo "        2) In the WebObjects Frameworks at: ${FRAMEWORK_NAME_IN_WEBOBJECTS_INSTALL}"
				echo "        3) In the Wonder Frameworks at: ${FRAMEWORK_NAME_IN_WONDER_INSTALL}"
				echo "        4) As a Jenkins job that has at least one successful Build and"
				echo "           an artifact path of *exactly*: ${FRAMEWORK_ARTIFACT_PATH_IN_JENKINS_JOB}"
				exit 1
			fi
		done
	fi
done

echo "Link to ${WOPROJECT} so Ant can build the WO project."
mkdir -p ${ROOT}/lib
ln -sf ${FRAMEWORKS_REPOSITORY}/WOProject/${WOPROJECT} ${ROOT}/lib/${WOPROJECT}

echo "Setup ${ROOT}/jenkins.build.properties for Ant to use for building"
cat > ${ROOT}/jenkins.build.properties << END
# DO NOT EDIT THIS FILE!!!
#
# This file was dynamically generated by
# ${WORKSPACE}/WOJenkins/Build/WonderProjects/WorkspaceSetupScripts/setupWonderProjectWorkspace.sh
# based on values defined in the "${JOB_NAME}" Jenkins job and will be overwritten the next time
# the job is run.
#
# Changes to the job can be made by opening ${JOB_URL}/configure in a web browser.

project.name=${PROJECT_NAME}

wo.system.root=${WO_SYSTEM_ROOT_FOR_THIS_BUILD}
wo.system.frameworks=${WO_SYSTEM_FRAMEWORKS_FOR_THIS_BUILD}

wo.local.root=${WO_LOCAL_ROOT_FOR_THIS_BUILD}
wo.local.frameworks=${WO_LOCAL_FRAMEWORKS_FOR_THIS_BUILD}

wo.extensions=${WO_EXTENSIONS_FOR_THIS_BUILD}

wo.bootstrapjar=${WO_BOOTSTRAP_JAR_FOR_THIS_BUILD}
wo.apps.root=${WO_APPS_ROOT_FOR_THIS_BUILD}

wolips.properties=${ROOT}/jenkins.build.properties

ant.build.javac.target=${JAVA_COMPATIBILITY_VERSION}
END

if [ "$BUILD_TYPE" == "Test Build" ]; then
cat ${ROOT}/jenkins.build.properties > ${ROOT}/jenkins.build.properties.temp1
cat > ${ROOT}/jenkins.build.properties.temp2 << END

embed.Local=false
embed.Project=false
embed.System=false
embed.Network=false
END
cat ${ROOT}/jenkins.build.properties.temp1 ${ROOT}/jenkins.build.properties.temp2 > ${ROOT}/jenkins.build.properties
rm ${ROOT}/jenkins.build.properties.*
fi

# Backward Compatibility!
echo "Create link for backward compatibility with old build.properties file name since old build jobs will still be pointing to it."
echo "ln -sfn ${ROOT}/jenkins.build.properties ${ROOT}/build.properties"
(ln -sfn ${ROOT}/jenkins.build.properties ${ROOT}/build.properties)
