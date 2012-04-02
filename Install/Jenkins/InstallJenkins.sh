#!/bin/bash
#Script that downloads and installs jenkins
#

APP_DIR=/usr/local

if [ `whoami` != "root" ]; then
	echo "Please run as with sudo."
	exit 1;
fi

if [[ -d $APP_DIR/tomcat/webapps/jenkins ]]; then
	echo "Jenkins is already installed."
	exit 1
fi

if [[ -d $APP_DIR/tomcat/webapps/hudson ]]; then
	echo "Jenkins is not installed, but it appears you have Hudson installed."
	exit 1
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
    *Windows*)  echo Quit using Windows!  Terminating.
                exit 1
                ;;
    *winnt*)    echo Quit using Windows!  Terminating
                exit 1
                ;;
    *)          PLATFORM_DESCRIPTOR=UNIX
                PLATFORM_TYPE=Other
                ;;
esac


if [ "$PLATFORM_TYPE" != "Darwin" ]; then
	echo "Only Mac OS X is currently supported"
	exit 1;
fi

#Download Jenkins
echo "Downloading Jenkins"
cd /tmp/
curl http://mirrors.jenkins-ci.org/war/latest/jenkins.war -L -# -o jenkins.war



echo "Installing Jenkins"
cp jenkins.war ${APP_DIR}/tomcat/webapps/

if [ "$PLATFORM_TYPE" = "Darwin" ]; then	
	echo "Restarting Tomcat..."
	launchctl stop org.apache.tomcat
	launchctl unload /Library/LaunchDaemons/org.apache.tomcat.plist
	launchctl load /Library/LaunchDaemons/org.apache.tomcat.plist
	launchctl start org.apache.tomcat
fi

#${APP_DIR}/tomcat/bin/startup.sh

rm -f /tmp/jenkins.war