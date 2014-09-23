#!/bin/sh
#
# command line options:
# -c FOLDERNAME --- change to test source folder
# -t TEST --- execute test
#
# try the following 
#   git bisect run tck_findbadargs.sh -p src/com/sun/ts/tests/ejb30/lite/interceptor/singleton/business/annotated -t "ant runclient -Dtest=allInterceptors_from_ejblitejsf"
#

if [ "x$TS_HOME" = "x" ]; then
    echo "TS_HOME is not set"
    TS_HOME=$PWD/../tck7/trunk
    JAVAEE_HOME_RI=$PWD/../glassfish4
    DERBY_HOME=$JAVAEE_HOME_RI/javadb
else
    echo "TS_HOME is set to $TS_HOME"    
fi

# current directory should be application server git source
BUILD_FOLDER=$PWD

JBOSS_OPTS=""

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
  sed "s%javaee.home=.*%javaee.home=${BUILD_FOLDER}/build/target/jboss-as-${appserverversion}%" -i ts.jte
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
  appserverversion=`grep --after-context=1 jboss-as-parent pom.xml | grep version | sed -e 's/<[^>]*>//g' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//'`
  echo "using app server version $appserverversion"
  JBOSS_HOME=$BUILD_FOLDER/build/target/jboss-as-$appserverversion
  echo "$JBOSS_HOME"
  JAVAEE_HOME=$JBOSS_HOME
 
fi

}

buildAppServer
shutdownWildFly

prepareForTckRun

startWildFly

while getopts p:c:t: option
do
    case $option in 
        startRI)
            echo "Starting RI for interop tests"
            cd $TS_HOME/bin
            ant config.ri
            RI_STARTED=$?
            ;;
        enableTXInterop)
            echo "enabling tx interop"
            cd $TS_HOME/bin
            ant enable.ri.tx.interop 
            ;;
        disableTXInterop)            
            echo "disabling tx interop"
            cd $TS_HOME/bin
            ant disable.ri.tx.interop 
            ;;
        enablecsiv2)
            cd $TS_HOME/bin
            ant enable.csiv2
            cd $TS_HOME/jee7tck-mods
            ant csiv2-certs
            ;;
        enablejaspic)
            cd $TS_HOME/bin
            ant enable.jaspic
            ;;
        enablejacc)
            cd $TS_HOME/bin
            ant enable.jacc
            ;;
        enablejaxrs)
            cd $TS_HOME/bin
            ant update.jaxrs.wars
            ;;
        enableconnector)
            JBOSS_OPTS="$JBOSS_OPTS -P file:///$JBOSS_HOME/bin/jca-tck-properties.txt"
            shutdownWildFly
            startWildFly
            ;;
        deployconnector)
            cd $TS_HOME/bin
            ant -f xml/impl/wildfly/deploy.xml deploy.all.rars
            ;;
        deployconnectorxa)
            cd $TS_HOME/bin
            ant -f xml/impl/wildfly/deploy.xml deploy.all.rars
            ant -f xml/impl/wildfly/deploy.xml deploy.Tsr.ear
            ;;
        startrmiiiop)
            cd $TS_HOME/bin
            ant start.rmiiiop.server &> /dev/null &
            sleep 5
            ;;
        enablewebservices)
            cd $TS_HOME/bin
            ant -Dbuild.vi=true tsharness
            cd $TS_HOME/src/com/sun/ts/tests/$OPTARG
            ant -Dts.home=$TS_HOME -Dbuild.vi=true clean build
            ;;
        enablewebservices12)
            cd $TS_HOME/bin
            ant -Dbuild.vi=true tsharness
            ant build.special.webservices.clients -Dbuild.vi=true
            ;;
        enableejb30datasources)    
            cd $TS_HOME/bin
            ant configure.datasource.tests
            ;;
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
            ;;
    esac
done
    
shutdownWildFly
echo "exit from script with $status"
exit $status
