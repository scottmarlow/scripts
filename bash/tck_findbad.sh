#!/bin/sh
# git bisect run tck_findbad.sh
echo "build the application server"
./build.sh clean install -DskipTests=true || exit 125

echo "run the tck test now"
#export TS_HOME=/home/smarlow/work/tck7/trunk
#export JBOSS_HOME=/home/smarlow/work/as8/build/target/wildfly-8.0.1.Final-SNAPSHOT
#export JAVAEE_HOME=$JBOSS_HOME
#export JAVAEE_HOME_RI=/home/smarlow/work/glassfish4
#export DERBY_HOME=$JAVAEE_HOME_RI/javadb

# we start in the WildFly 8 source tree

echo "stopping application server..."
$JBOSS_HOME/bin/jboss-cli.sh --connect command=:shutdown

echo "prepare for running the tck"
cd $TS_HOME/bin
ant config.vi

echo "start the app server in the background"
cd $JBOSS_HOME/bin
./standalone.sh $JBOSS_OPTS &> /dev/null &

sleep 30

echo "app server should be running"
jps -l

echo "check whether the admin port (9999) is open, i.e. application server is up"
netstat -an | grep ':9999' | grep LISTEN > /dev/null || ADMIN_PORT_OPEN=$?
if [[ $ADMIN_PORT_OPEN == 1 ]]; then 
   echo "WildFly 8 failed to start up!" && exit 1
fi

echo "application server is up"

echo "run single tck test"
# cd $TS_HOME/src/com/sun/ts/tests/ejb32/lite/timer/basic/sharing
# ant runclient -Dtest=accessTimersSingleton_from_ejblitejsf > /tmp/tcktest.log
# cd $TS_HOME/src/com/sun/ts/tests/jpa/ee/propagation/cm/jta

cd $TS_HOME/src/com/sun/ts/tests/jaxrs/platform/managedbean
ant runclient runclient > /tmp/tcktest.log
status=$?
echo "run single tck test completed with status = $status"

echo "stopping application server..."
$JBOSS_HOME/bin/jboss-cli.sh --connect command=:shutdown
exit $status
