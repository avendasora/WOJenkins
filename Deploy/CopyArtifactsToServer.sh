#!/bin/bash

echo "Copy up the server-side deployment script, we'll need it later."
echo "scp ${WORKSPACE}/WOJenkins/Deploy/ExtractAndDeployWOApplication.sh ${WOTASKD_USER}@${WOTASKD_HOST}:/tmp/"
scp ${WORKSPACE}/WOJenkins/Deploy/ExtractAndDeployWOApplication.sh ${WOTASKD_USER}@${WOTASKD_HOST}:/tmp/

# Get all the Projects that have been checked out as part of this deployment
PROJECTS=`ls ${WORKSPACE}/../lastSuccessful/archive/Projects/`

# Step through them to get the list of WO frameworks on their Classpath.
for PROJECT in $PROJECTS; do
	# Check to see if this is a deployment of a single Application, if so, replace it with
	# the name of the application from the job parameters.
	if [ "$PROJECT" == "Application" ]; then
		PROJECT=${APPLICATION_NAME}
	fi
	echo "PROJECT: ${PROJECT}"

	echo "Copy ${PROJECT} Artifacts to Deployment Server /tmp directory"

	echo "scp ${WORKSPACE}/../lastSuccessful/archive/Projects/${PROJECT}/dist/${PROJECT}-Application.tar.gz ${WOTASKD_USER}@${WOTASKD_HOST}:/tmp/"
	scp ${WORKSPACE}/../lastSuccessful/archive/Projects/${PROJECT}/dist/${PROJECT}-Application.tar.gz ${WOTASKD_USER}@${WOTASKD_HOST}:/tmp/

	echo "scp ${WORKSPACE}/../lastSuccessful/archive/Projects/${PROJECT}/dist/${PROJECT}-WebServerResources.tar.gz ${WOTASKD_USER}@${WOTASKD_HOST}:/tmp/"
	scp ${WORKSPACE}/../lastSuccessful/archive/Projects/${PROJECT}/dist/${PROJECT}-WebServerResources.tar.gz ${WOTASKD_USER}@$WOTASKD_HOST:/tmp/
	
	echo "Connect to Deployment Server"
	echo "ssh ${WOTASKD_USER}@${WOTASKD_HOST} \"(/tmp/ExtractAndDeployWOApplication.sh ${PROJECT} ${BUILD_NUMBER} ${BUILD_ID} ${MONITOR_HOST} ${MONITOR_PORT} ${APP_ROOT} ${WEB_ROOT})\""	
	ssh ${WOTASKD_USER}@${WOTASKD_HOST} "(/tmp/ExtractAndDeployWOApplication.sh ${PROJECT} ${BUILD_NUMBER} ${BUILD_ID} ${MONITOR_HOST} ${MONITOR_PORT} ${APP_ROOT} ${WEB_ROOT})"	
done
