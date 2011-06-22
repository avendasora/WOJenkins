#!/bin/bash

PROJECT=$1
BUILD_NUMBER=$2
BUILD_ID=$3
MONITOR_HOST=$4
MONITOR_PORT=$5
APP_ROOT=$6
WEB_ROOT=$7

echo "	Create release directories"
echo "		mkdir -p ${APP_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}"
mkdir -p ${APP_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}
echo "		mkdir -p ${WEB_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/"
mkdir -p ${WEB_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/

echo "	Copy artifacts to release directories"
echo "		cp /tmp/${PROJECT}-Application.tar.gz ${APP_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/"
cp /tmp/${PROJECT}-Application.tar.gz ${APP_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/
echo "		cp /tmp/${PROJECT}-WebServerResources.tar.gz ${WEB_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/"
cp /tmp/${PROJECT}-WebServerResources.tar.gz ${WEB_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/

echo "	Extract Archives"
echo "		tar -xzf ${APP_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/${PROJECT}-Application.tar.gz -C ${APP_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/"
tar -xzf ${APP_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/${PROJECT}-Application.tar.gz -C ${APP_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/
echo "		tar -xzf ${WEB_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/${PROJECT}-WebServerResources.tar.gz  -C ${WEB_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/"
tar -xzf ${WEB_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/${PROJECT}-WebServerResources.tar.gz -C ${WEB_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/

echo "	Stop ${PROJECT}"
echo "		curl -# -d type=app -d name=${PROJECT} -X GET http://${MONITOR_HOST}:${MONITOR_PORT}/cgi-bin/WebObjects/JavaMonitor.woa/admin/stop"
(curl -# -d type=app -d name=${PROJECT} -X GET http://${MONITOR_HOST}:${MONITOR_PORT}/cgi-bin/WebObjects/JavaMonitor.woa/admin/stop)
echo "Wait 5 seconds for application to stop"
sleep 5

echo "	Relink Application Bundle"
echo "		rm ${APP_ROOT}/${PROJECT}.woa"
rm ${APP_ROOT}/${PROJECT}.woa
echo "		ln -s ${APP_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/${PROJECT}.woa ${APP_ROOT}/"
ln -s ${APP_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/${PROJECT}.woa ${APP_ROOT}/

echo "	Relink WebServerResources Bundle"
echo "		rm ${WEB_ROOT}/${PROJECT}.woa"
rm ${WEB_ROOT}/${PROJECT}.woa
echo "		ln -s ${WEB_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/${PROJECT}.woa ${WEB_ROOT}/"
ln -s ${WEB_ROOT}/releases/${PROJECT}/${BUILD_NUMBER}_${BUILD_ID}/${PROJECT}.woa ${WEB_ROOT}/

echo "	Start ${PROJECT}"
echo "		curl -# -d type=app -d name=${PROJECT} -X GET http://${MONITOR_HOST}:${MONITOR_PORT}/cgi-bin/WebObjects/JavaMonitor.woa/admin/start"
(curl -# -d type=app -d name=${PROJECT} -X GET http://${MONITOR_HOST}:${MONITOR_PORT}/cgi-bin/WebObjects/JavaMonitor.woa/admin/start)