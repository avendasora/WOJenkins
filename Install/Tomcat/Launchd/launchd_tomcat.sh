#!/bin/bash
# Shell script to launch a process that doesn't quit after launching the JVM
# This is required to interact with launchd correctly.
# 

function shutdown()
{
        $CATALINA_HOME/bin/catalina.sh stop
}

export TOMCAT_JVM_PID=/tmp/$$
export CATALINA_BASE=/usr/local/tomcat
export CATALINA_HOME=/usr/local/tomcat
export CATALINA_TMPDIR=/usr/local/tomcat/temp
export JRE_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/CurrentJDK/Home
export CLASSPATH=/usr/local/tomcat/bin/bootstrap.jar
#export HUDSON_HOME=/Library/Hudson
export JENKINS_HOME=/Library/Jenkins
export JAVA_OPTS="-Djava.awt.headless=true"

. $CATALINA_HOME/bin/catalina.sh start

# Wait here until we receive a signal that tells Tomcat to stop..
trap shutdown HUP INT QUIT ABRT KILL ALRM TERM TSTP

wait `cat $TOMCAT_JVM_PID`

