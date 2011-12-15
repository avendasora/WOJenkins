#!/bin/bash

echo "Job Name: ${JOB_NAME}"
if [ "${JOB_NAME}" == "" ]; then
	echo "You must provide a JOB_NAME."
	exit 1
fi

echo "Repository Type: ${REPOSITORY_TYPE}"
if [ "${REPOSITORY_TYPE}" == "" ]; then
	echo "You must provide a REPOSITORY_TYPE."
	exit 1
fi

echo "Job Type: ${JOB_TYPE}"
if [ "${JOB_TYPE}" == "Install WebObjects and Project WOnder" ]; then
	JOB_DEFINITION="WOJenkins_Job_InstallWOAndWOnder"
elif [ "${JOB_TYPE}" == "WebObjects Framework or Application" ]; then
	JOB_DEFINITION="WOJenkins_Job_WOProject_${REPOSITORY_TYPE}"
else
	echo "You must select a job type of either 'Install WebObjects and Project WOnder' or 'WebObjects Framework or Application'"
	exit 1
fi

GIT_INSTALL_DIR="/usr/bin/git/bin"
if [ ! -e "/usr/local/git/bin" ]; then
	GIT_INSTALL_DIR="/usr/local/git/bin"
fi

# Clone the Job Definition
if [ ! -e "${JENKINS_HOME}/jobs/${JOB_NAME}" ]; then
    echo "${GIT_INSTALL_DIR}/git clone git://github.com/avendasora/${JOB_DEFINITION} ${JENKINS_HOME}/jobs/${JOB_NAME}"
	git clone git://github.com/avendasora/${JOB_DEFINITION} ${JENKINS_HOME}/jobs/${JOB_NAME}
	curl -O ${JENKINS_URL}/reload
else
	echo "A job already exists with the name ${JOB_NAME}. You must delete the existing job, or chose a different name."
	exit 1
fi
