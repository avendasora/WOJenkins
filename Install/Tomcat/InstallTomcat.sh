#!/bin/bash
#Script that downloads and installs tomcat
#

APP_DIR=/usr/local
WOJENKINS_TOMCAT_DIR=`dirname "$0"`

if [ `whoami` != "root" ]; then
	echo "Please run as with sudo."
	exit 1;
fi

if [[ -e $APP_DIR/tomcat ]]; then
	echo "Tomcat is already installed."
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


#Get the Tomcat URL
TOMCAT_URL=`curl -s -L http://tomcat.apache.org/download-60.cgi | grep '.tar.gz\"' | grep -v 'src' | grep -v 'deployer' | head -1 | perl -lne 'print $1 if /<a href="([^"]*)(.*)">/i;'`
TOMCAT=`echo ${TOMCAT_URL} | perl -lne 'print $1 if /(apache-tomcat-(.*).tar.gz)$/;'`
TOMCAT_DIR=`echo ${TOMCAT_URL} | perl -lne 'print $1 if /(apache-tomcat-(.*)).tar.gz$/;'`



#Download Tomcat
echo "Downloading Tomcat"
cd /tmp/
curl ${TOMCAT_URL} -# -o ${TOMCAT}
tar xfz ${TOMCAT}

echo "Installing Tomcat"
mv ${TOMCAT_DIR} ${APP_DIR}/tomcat

if [ "$PLATFORM_TYPE" = "Darwin" ]; then
	#Install the launchd script
	if [ ! -a ${APP_DIR}/tomcat/bin/launchd_tomcat.sh ]; then cp $WOJENKINS_TOMCAT_DIR/launchd/launchd_tomcat.sh ${APP_DIR}/tomcat/bin/; fi
	
	#Install the launchd plist
	if [ ! -a /Library/LaunchDaemons/org.apache.tomcat.plist ]; then cp $WOJENKINS_TOMCAT_DIR/launchd/org.apache.tomcat.plist /Library/LaunchDaemons/org.apache.tomcat.plist; fi
	
	echo "Starting Tomcat..."
	sudo launchctl stop org.apache.tomcat
	launchctl unload /Library/LaunchDaemons/org.apache.tomcat.plist
	launchctl load /Library/LaunchDaemons/org.apache.tomcat.plist
	launchctl start org.apache.tomcat
fi
