#!/bin/bash -x

################################################################################
# Script that is run on each EC2 instance on boot. It is passed in the EC2 user
# data, so should not exceed 16K in size.
#
# This script is executed by /etc/init.d/ec2-run-user-data, and output is
# logged to /var/log/messages.
################################################################################

################################################################################
# Initialize variables
################################################################################

# Substitute environment variables passed by the client
export %ENV%

if [ -z "$MASTER_HOST" ]; then
  IS_MASTER=true
  MASTER_HOST=`wget -q -O - http://169.254.169.254/latest/meta-data/public-hostname`
else
  IS_MASTER=false
fi

# Install a list of packages on debian or redhat as appropriate
function install_packages() {
  if which dpkg &> /dev/null; then
    apt-get update
    apt-get -y install $@
  elif which rpm &> /dev/null; then
    yum install -y $@
  else
    echo "No package manager found."
  fi
}

# Install any user packages specified in the USER_PACKAGES environment variable
function install_user_packages() {
  if [ "$USER_PACKAGES" != "" ]; then
    install_packages $USER_PACKAGES
  fi
}

# Install Hadoop packages and dependencies
function install_hadoop() {
  if which dpkg &> /dev/null; then
    apt-get update
    apt-get -y install hadoop${HADOOP_VERSION:+-${HADOOP_VERSION}} # prefix with a dash if set
    cp -r /etc/hadoop/conf.empty /etc/hadoop/conf.dist
    update-alternatives --install /etc/hadoop/conf hadoop-conf /etc/hadoop/conf.dist 90
    apt-get -y install pig${PIG_VERSION:+-${PIG_VERSION}}
    apt-get -y install hive${HIVE_VERSION:+-${HIVE_VERSION}}
    apt-get -y install policykit # http://www.bergek.com/2008/11/24/ubuntu-810-libpolkit-error/
  elif which rpm &> /dev/null; then
    yum install -y hadoop${HADOOP_VERSION:+-${HADOOP_VERSION}}
    cp -r /etc/hadoop/conf.empty /etc/hadoop/conf.dist
    alternatives --install /etc/hadoop/conf hadoop /etc/hadoop/conf.dist 90
    yum install -y hadoop-pig${PIG_VERSION:+-${PIG_VERSION}}
    yum install -y hadoop-hive${HIVE_VERSION:+-${HIVE_VERSION}}
  fi
}

function prep_disk() {
  mount=$1
  device=$2
  automount=${3:-false}

  echo "warning: ERASING CONTENTS OF $device"
  mkfs.xfs -f $device
  if [ ! -e $mount ]; then
    mkdir $mount
  fi
  mount -o defaults,noatime $device $mount
  if $automount ; then
    echo "$device $mount xfs defaults,noatime 0 0" >> /etc/fstab
  fi
}

function wait_for_mount {
  mount=$1
  device=$2

  mkdir $mount

  i=1
  echo "Attempting to mount $device"
  while true ; do
    sleep 10
    echo -n "$i "
    i=$[$i+1]
    mount -o defaults,noatime $device $mount || continue
    echo " Mounted."
    break;
  done
}

function make_hadoop_dirs {
  for mount in "$@"; do
    if [ ! -e $mount/hadoop ]; then
      mkdir -p $mount/hadoop
      chown hadoop:hadoop $mount/hadoop
    fi
  done
}

# Configure Hadoop by setting up disks and site file
function configure_hadoop() {

  install_packages xfsprogs # needed for XFS

  INSTANCE_TYPE=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-type`

  if [ -n "$EBS_MAPPINGS" ]; then
    # EBS_MAPPINGS is like "/ebs1,/dev/sdj;/ebs2,/dev/sdk"
    DFS_NAME_DIR=''
    FS_CHECKPOINT_DIR=''
    DFS_DATA_DIR=''
    for mapping in $(echo "$EBS_MAPPINGS" | tr ";" "\n"); do
      # Split on the comma (see "Parameter Expansion" in the bash man page)
      mount=${mapping%,*}
      device=${mapping#*,}
      wait_for_mount $mount $device
      DFS_NAME_DIR=${DFS_NAME_DIR},"$mount/hadoop/hdfs/name"
      FS_CHECKPOINT_DIR=${FS_CHECKPOINT_DIR},"$mount/hadoop/hdfs/secondary"
      DFS_DATA_DIR=${DFS_DATA_DIR},"$mount/hadoop/hdfs/data"
      FIRST_MOUNT=${FIRST_MOUNT-$mount}
      make_hadoop_dirs $mount
    done
    # Remove leading commas
    DFS_NAME_DIR=${DFS_NAME_DIR#?}
    FS_CHECKPOINT_DIR=${FS_CHECKPOINT_DIR#?}
    DFS_DATA_DIR=${DFS_DATA_DIR#?}

    DFS_REPLICATION=3 # EBS is internally replicated, but we also use HDFS replication for safety
  else
    case $INSTANCE_TYPE in
    m1.xlarge|c1.xlarge)
      DFS_NAME_DIR=/mnt/hadoop/hdfs/name,/mnt2/hadoop/hdfs/name
      FS_CHECKPOINT_DIR=/mnt/hadoop/hdfs/secondary,/mnt2/hadoop/hdfs/secondary
      DFS_DATA_DIR=/mnt/hadoop/hdfs/data,/mnt2/hadoop/hdfs/data,/mnt3/hadoop/hdfs/data,/mnt4/hadoop/hdfs/data
      ;;
    m1.large)
      DFS_NAME_DIR=/mnt/hadoop/hdfs/name,/mnt2/hadoop/hdfs/name
      FS_CHECKPOINT_DIR=/mnt/hadoop/hdfs/secondary,/mnt2/hadoop/hdfs/secondary
      DFS_DATA_DIR=/mnt/hadoop/hdfs/data,/mnt2/hadoop/hdfs/data
      ;;
    *)
      # "m1.small" or "c1.medium"
      DFS_NAME_DIR=/mnt/hadoop/hdfs/name
      FS_CHECKPOINT_DIR=/mnt/hadoop/hdfs/secondary
      DFS_DATA_DIR=/mnt/hadoop/hdfs/data
      ;;
    esac
    FIRST_MOUNT=/mnt
    DFS_REPLICATION=3
  fi

  case $INSTANCE_TYPE in
  m1.xlarge|c1.xlarge)
    prep_disk /mnt2 /dev/sdc true &
    disk2_pid=$!
    prep_disk /mnt3 /dev/sdd true &
    disk3_pid=$!
    prep_disk /mnt4 /dev/sde true &
    disk4_pid=$!
    wait $disk2_pid $disk3_pid $disk4_pid
    MAPRED_LOCAL_DIR=/mnt/hadoop/mapred/local,/mnt2/hadoop/mapred/local,/mnt3/hadoop/mapred/local,/mnt4/hadoop/mapred/local
    MAX_MAP_TASKS=8
    MAX_REDUCE_TASKS=4
    CHILD_OPTS=-Xmx680m
    CHILD_ULIMIT=1392640
    ;;
  m1.large)
    prep_disk /mnt2 /dev/sdc true
    MAPRED_LOCAL_DIR=/mnt/hadoop/mapred/local,/mnt2/hadoop/mapred/local
    MAX_MAP_TASKS=4
    MAX_REDUCE_TASKS=2
    CHILD_OPTS=-Xmx1024m
    CHILD_ULIMIT=2097152
    ;;
  c1.medium)
    MAPRED_LOCAL_DIR=/mnt/hadoop/mapred/local
    MAX_MAP_TASKS=4
    MAX_REDUCE_TASKS=2
    CHILD_OPTS=-Xmx550m
    CHILD_ULIMIT=1126400
    ;;
  *)
    # "m1.small"
    MAPRED_LOCAL_DIR=/mnt/hadoop/mapred/local
    MAX_MAP_TASKS=2
    MAX_REDUCE_TASKS=1
    CHILD_OPTS=-Xmx550m
    CHILD_ULIMIT=1126400
    ;;
  esac

  make_hadoop_dirs `ls -d /mnt*`

  # Create tmp directory
  mkdir /mnt/tmp
  chmod a+rwxt /mnt/tmp

  ##############################################################################
  # Modify this section to customize your Hadoop cluster.
  ##############################################################################
  cat > /etc/hadoop/conf.dist/hadoop-site.xml <<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
  <name>dfs.block.size</name>
  <value>134217728</value>
  <final>true</final>
</property>
<property>
  <name>dfs.data.dir</name>
  <value>$DFS_DATA_DIR</value>
  <final>true</final>
</property>
<property>
  <name>dfs.datanode.du.reserved</name>
  <value>1073741824</value>
  <final>true</final>
</property>
<property>
  <name>dfs.datanode.handler.count</name>
  <value>3</value>
  <final>true</final>
</property>
<!--property>
  <name>dfs.hosts</name>
  <value>/etc/hadoop/conf.dist/dfs.hosts</value>
  <final>true</final>
</property-->
<!--property>
  <name>dfs.hosts.exclude</name>
  <value>/etc/hadoop/conf.dist/dfs.hosts.exclude</value>
  <final>true</final>
</property-->
<property>
  <name>dfs.name.dir</name>
  <value>$DFS_NAME_DIR</value>
  <final>true</final>
</property>
<property>
  <name>dfs.namenode.handler.count</name>
  <value>5</value>
  <final>true</final>
</property>
<property>
  <name>dfs.permissions</name>
  <value>true</value>
  <final>true</final>
</property>
<property>
  <name>dfs.replication</name>
  <value>$DFS_REPLICATION</value>
</property>
<property>
  <name>fs.checkpoint.dir</name>
  <value>$FS_CHECKPOINT_DIR</value>
  <final>true</final>
</property>
<property>
  <name>fs.default.name</name>
  <value>hdfs://$MASTER_HOST/</value>
</property>
<property>
  <name>fs.trash.interval</name>
  <value>1440</value>
  <final>true</final>
</property>
<property>
  <name>hadoop.tmp.dir</name>
  <value>/mnt/tmp/hadoop-\${user.name}</value>
  <final>true</final>
</property>
<property>
  <name>io.file.buffer.size</name>
  <value>65536</value>
</property>
<property>
  <name>mapred.child.java.opts</name>
  <value>$CHILD_OPTS</value>
</property>
<property>
  <name>mapred.child.ulimit</name>
  <value>$CHILD_ULIMIT</value>
  <final>true</final>
</property>
<property>
  <name>mapred.job.tracker</name>
  <value>$MASTER_HOST:8021</value>
</property>
<property>
  <name>mapred.job.tracker.handler.count</name>
  <value>5</value>
  <final>true</final>
</property>
<property>
  <name>mapred.local.dir</name>
  <value>$MAPRED_LOCAL_DIR</value>
  <final>true</final>
</property>
<property>
  <name>mapred.map.tasks.speculative.execution</name>
  <value>true</value>
</property>
<property>
  <name>mapred.reduce.parallel.copies</name>
  <value>10</value>
</property>
<property>
  <name>mapred.reduce.tasks</name>
  <value>10</value>
</property>
<property>
  <name>mapred.reduce.tasks.speculative.execution</name>
  <value>false</value>
</property>
<property>
  <name>mapred.submit.replication</name>
  <value>10</value>
</property>
<property>
  <name>mapred.system.dir</name>
  <value>/hadoop/system/mapred</value>
</property>
<property>
  <name>mapred.tasktracker.map.tasks.maximum</name>
  <value>$MAX_MAP_TASKS</value>
  <final>true</final>
</property>
<property>
  <name>mapred.tasktracker.reduce.tasks.maximum</name>
  <value>$MAX_REDUCE_TASKS</value>
  <final>true</final>
</property>
<property>
  <name>tasktracker.http.threads</name>
  <value>46</value>
  <final>true</final>
</property>
<property>
  <name>mapred.jobtracker.taskScheduler</name>
  <value>org.apache.hadoop.mapred.FairScheduler</value>
</property>
<property>
  <name>mapred.fairscheduler.allocation.file</name>
  <value>/etc/hadoop/conf.dist/fairscheduler.xml</value>
</property>
<property>
  <name>mapred.output.compression.type</name>
  <value>BLOCK</value>
</property>
<property>
  <name>hadoop.rpc.socket.factory.class.default</name>
  <value>org.apache.hadoop.net.StandardSocketFactory</value>
  <final>true</final>
</property>
<property>
  <name>hadoop.rpc.socket.factory.class.ClientProtocol</name>
  <value></value>
  <final>true</final>
</property>
<property>
  <name>hadoop.rpc.socket.factory.class.JobSubmissionProtocol</name>
  <value></value>
  <final>true</final>
</property>
<property>
  <name>io.compression.codecs</name>
  <value>org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.GzipCodec</value>
</property>
<property>
  <name>fs.s3.awsAccessKeyId</name>
  <value>$AWS_ACCESS_KEY_ID</value>
</property>
<property>
  <name>fs.s3.awsSecretAccessKey</name>
  <value>$AWS_SECRET_ACCESS_KEY</value>
</property>
<property>
  <name>fs.s3n.awsAccessKeyId</name>
  <value>$AWS_ACCESS_KEY_ID</value>
</property>
<property>
  <name>fs.s3n.awsSecretAccessKey</name>
  <value>$AWS_SECRET_ACCESS_KEY</value>
</property>
</configuration>
EOF

  cat > /etc/hadoop/conf.dist/fairscheduler.xml <<EOF
<?xml version="1.0"?>
<allocations>
</allocations>
EOF

  # Keep PID files in a non-temporary directory
  sed -i -e "s|# export HADOOP_PID_DIR=.*|export HADOOP_PID_DIR=/var/run/hadoop|" \
    /etc/hadoop/conf.dist/hadoop-env.sh
  mkdir -p /var/run/hadoop
  chown -R hadoop:hadoop /var/run/hadoop

  # Hadoop logs should be on the /mnt partition
  rm -rf /var/log/hadoop
  mkdir /mnt/hadoop/logs
  chown hadoop:hadoop /mnt/hadoop/logs
  ln -s /mnt/hadoop/logs /var/log/hadoop
  chown -R hadoop:hadoop /var/log/hadoop

}

# Sets up small website on cluster.
# TODO(philip): Add links/documentation.
function setup_web() {

  if which dpkg &> /dev/null; then
    apt-get -y install thttpd
    WWW_BASE=/var/www
  elif which rpm &> /dev/null; then
    yum install -y thttpd
    chkconfig --add thttpd
    WWW_BASE=/var/www/thttpd/html
  fi

  # Access to Hadoop ports should be through the proxy.
  LOCAL_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
  PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

  cat > $WWW_BASE/index.html << END
<html>
<head>
<title>Hadoop EC2 Cluster</title>
</head>
<body>
<h1>Hadoop EC2 Cluster</h1>
The links below work if you have a proxy configured.
Start the proxy with <tt>hadoop-ec2 proxy &lt;cluster_name&gt;</tt>,
and point your browser to <a href="ec2.pac">this Proxy Auto-Configuration (PAC)</a> file.  To manage multiple proxy configurations, you may wish
to use <a href="https://addons.mozilla.org/en-US/firefox/addon/2464">FoxyProxy</a>.
<ul>
<li><a href="http://$LOCAL_IP:50070/">NameNode</a>
<li><a href="http://$LOCAL_IP:50030/">JobTracker</a>
</ul>
</body>
</html>
END

  cat > $WWW_BASE/ec2.pac << END
function FindProxyForURL(url, host) {
  // Assume all nodes are in the same Class B
  if (isInNet(host, "$LOCAL_IP", "255.255.0.0")) {
        return "SOCKS localhost:6666";
  }
  return "DIRECT";
}
END

  service thttpd start

}

function start_hadoop_master() {

  if which dpkg &> /dev/null; then
    AS_HADOOP="su -s /bin/bash - hadoop -c"
    # Format HDFS
    [ ! -e $FIRST_MOUNT/hadoop/hdfs ] && $AS_HADOOP 'hadoop namenode -format'
    HADOOP_VERSION_SUFFIX=${HADOOP_VERSION:+-${HADOOP_VERSION}}
    apt-get -y install hadoop-namenode$HADOOP_VERSION_SUFFIX
    apt-get -y install hadoop-secondarynamenode$HADOOP_VERSION_SUFFIX
    apt-get -y install hadoop-jobtracker$HADOOP_VERSION_SUFFIX
  elif which rpm &> /dev/null; then
    AS_HADOOP="/sbin/runuser -s /bin/bash - hadoop -c"
    # Format HDFS
    [ ! -e $FIRST_MOUNT/hadoop/hdfs ] && $AS_HADOOP 'hadoop namenode -format'
    chkconfig --add hadoop-namenode
    chkconfig --add hadoop-secondarynamenode
    chkconfig --add hadoop-jobtracker
  fi

  service hadoop-namenode start
  service hadoop-secondarynamenode start
  service hadoop-jobtracker start

  $AS_HADOOP 'hadoop dfsadmin -safemode wait'
  $AS_HADOOP '/usr/bin/hadoop fs -mkdir /user'
  # The following is questionable, as it allows a user to delete another user
  # It's needed to allow users to create their own user directories
  $AS_HADOOP '/usr/bin/hadoop fs -chmod +w /user'

  # Create temporary directory for Pig and Hive in HDFS
  $AS_HADOOP '/usr/bin/hadoop fs -mkdir /tmp'
  $AS_HADOOP '/usr/bin/hadoop fs -chmod +w /tmp'
  $AS_HADOOP '/usr/bin/hadoop fs -mkdir /user/hive/warehouse'
  $AS_HADOOP '/usr/bin/hadoop fs -chmod +w /user/hive/warehouse'
}

function run_trendingtopics_batch() {

  MYBUCKET=trendingtopics
  MYSERVER=db.trendingtopics.org
  MAILTO=pete@datawrangling.com
  # set the default number of reducers using the following formula:
  # number of concurrent reducers per node * number of nodes * 1.75
  # for 20 c1.medium instances = 2 * 20 * 1.75 = 70
  NUMREDUCERS=70  
  
  cd /mnt
  # git clone the trendingtopics code  
  git clone git://github.com/datawrangling/trendingtopics.git
  cd trendingtopics
  git checkout --track -b experimental origin/experimental
  cd ../

  bash trendingtopics/lib/scripts/run_daily_merge.sh $MYBUCKET $MYSERVER $MAILTO $NUMREDUCERS
  # tail -f /var/log/syslog to see progress

}


function start_hadoop_slave() {

  HADOOP_VERSION_SUFFIX=${HADOOP_VERSION:+-${HADOOP_VERSION}}
  if which dpkg &> /dev/null; then
    apt-get -y install hadoop-datanode$HADOOP_VERSION_SUFFIX
    apt-get -y install hadoop-tasktracker$HADOOP_VERSION_SUFFIX
  elif which rpm &> /dev/null; then
    yum install -y hadoop-datanode$HADOOP_VERSION_SUFFIX
    yum install -y hadoop-tasktracker$HADOOP_VERSION_SUFFIX
    chkconfig --add hadoop-datanode
    chkconfig --add hadoop-tasktracker
  fi

  service hadoop-datanode start
  service hadoop-tasktracker start
}

install_user_packages
install_hadoop
configure_hadoop

if $IS_MASTER ; then
  setup_web
  start_hadoop_master
else
  start_hadoop_slave
fi
