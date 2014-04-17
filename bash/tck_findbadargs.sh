#!/bin/sh

export TS_HOME=/home/smarlow/work/tck7/trunk
export JBOSS_HOME=/home/smarlow/work/as8/build/target/wildfly-8.1.0.CR1
echo "$JBOSS_HOME"
export JAVAEE_HOME=$JBOSS_HOME
export JAVAEE_HOME_RI=/home/smarlow/work/glassfish4
export DERBY_HOME=$JAVAEE_HOME_RI/javadb
export BUILD_FOLDER=$PWD

if [ "x$JUSTPRINT" = "x" ]; then
    echo "will execute script commands"
    JUSTPRINT=false
else
    JUSTPRINT=true
    echo "will skip script commands"    
fi

function shutdownWildFly {
    echo "stopping application server..."
    
if [ "$JUSTPRINT" = true ];
then
  echo "skipping stop of app server, JUSTPRINT=$JUSTPRINT"
else
  $JBOSS_HOME/bin/jboss-cli.sh --connect command=:shutdown
fi

}

function startWildFly {
if [ "$JUSTPRINT" = true ];
then
  echo "skipping start of app server, JUSTPRINT=$JUSTPRINT"
else
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
fi

}

function prepareForTckRun {
if [ "$JUSTPRINT" = true ];
then
  echo "skipping prepare for tck run, JUSTPRINT=$JUSTPRINT"
else
  echo "prepare for running the tck"
  cd $TS_HOME/bin
  sed "s%javaee.home=.*%javaee.home=/home/smarlow/work/as8/build/target/wildfly-${appserverversion}%" -i ts.jte
  grep javaee.home ts.jte
  ant config.vi
fi

}

function buildAppServer {
if [ "$JUSTPRINT" = true ];
then
  echo "skipping build of app server, JUSTPRINT=$JUSTPRINT"
else
  echo "build the application server in $BUILD_FOLDER"
  cd $BUILD_FOLDER
  # exit with success so that the "git bisect run" will stop when we fail to build the app server
  ./build.sh clean install -Dmaven.test.skip=true || exit 0
  appserverversion=`grep --after-context=1 wildfly-parent pom.xml | grep version | sed -e 's/<[^>]*>//g' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//'`
  echo "using app server version $appserverversion"
  export JBOSS_HOME=/home/smarlow/work/as8/build/target/wildfly-$appserverversion
  echo "$JBOSS_HOME"
  export JAVAEE_HOME=$JBOSS_HOME
 
fi

}

buildAppServer
shutdownWildFly

prepareForTckRun

startWildFly

# command line options:
# -c FOLDERNAME --- change to test source folder
# -t TEST --- execute test
#
# try the following 
#   git bisect run tckfindbadargs.sh -p src/com/sun/ts/tests/ejb32/lite/timer/schedule/expire -t "ant runclient -Dtest=dayOfWeekAll_from_ejbliteservlet2"

while getopts p:c:t: option
do
    case $option in 
        p)
            cd $TS_HOME/$OPTARG
            pwd
            ;;
        c)
            cd $OPTARG
            pwd
            ;;
        t)
            if [ "$JUSTPRINT" = true ];
            then
               echo "skipping action $OPTARG, JUSTPRINT=$JUSTPRINT"
               echo "will exit with zero for success"
               exit 0
            else
                $OPTARG
                status=$?
                if [ "$status" -eq "0" ]; then
                  echo "test passed (continue with other tests) " + $OPTARG
                else
                  echo "test failed (stop on first failure) " + $OPTARG
                  shutdownWildFly              
                  exit $status
                fi
            fi
    esac
done
    

#echo "run single tck test"
#cd $TS_HOME/src/com/sun/ts/tests/ejb32/lite/timer/schedule/expire
#ant runclient -Dtest=dayOfWeekAll_from_ejbliteservlet2 > /tmp/tcktest.log
#status=$?
#echo "run single tck test completed with status = $status"

shutdownWildFly
echo "exit from script with $status"
exit $status
