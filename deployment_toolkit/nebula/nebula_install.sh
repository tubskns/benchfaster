#!/bin/bash

NEBULA_VERSION=$1
NEBULA_CONFIG=$2/benchfaster/deployment_toolkit/nebula/config
ARCH=$3
NEBULA_WORKER=$4
NEBULA_LIGHTHOUSE_IF=$5

if [ $NEBULA_WORKER = "lighthouse" ]; then echo `ip addr sh $NEBULA_LIGHTHOUSE_IF | grep 'inet ' | awk '{print substr($2, 1, length($2)-3)}'` > $2/benchfaster/lighthouse.ip ; fi
echo $(cat $2/benchfaster/lighthouse.ip) lighthouse | tee -a /etc/hosts

TMP="/tmp"

[ 1 = 2 ]
until [ $? -eq 0 ]; do
    wget https://github.com/slackhq/nebula/releases/download/v$NEBULA_VERSION/nebula-linux-$ARCH.tar.gz -P $TMP -q
done

cd $TMP
tar xvfz nebula-linux-$ARCH.tar.gz
rm $TMP/nebula-linux-$ARCH.tar.gz
mv $TMP/nebula /usr/local/bin/
mv $TMP/nebula-cert /usr/local/bin/

# Copying the configuration files and certificates
mkdir -p /etc/nebula

if [ $NEBULA_WORKER = "lighthouse" ]; then
    echo "Installing nebula lighthouse..."
    cp $NEBULA_CONFIG/lighthouse.yml /etc/nebula/nebula.yml
else
    echo "Installing nebula client..."
    cp $NEBULA_CONFIG/worker.yml /etc/nebula/nebula.yml
fi
cp $NEBULA_CONFIG/cert/$NEBULA_WORKER.crt /etc/nebula/nebula.crt
cp $NEBULA_CONFIG/cert/$NEBULA_WORKER.key /etc/nebula/nebula.key
cp $NEBULA_CONFIG/cert/ca.crt /etc/nebula/

#Creating and starting the service
cat << EOF > /etc/systemd/system/nebula.service
[Unit]
Description=nebula
Wants=basic.target
After=basic.target network.target
Before=sshd.service

[Service]
SyslogIdentifier=nebula
StandardOutput=syslog
StandardError=syslog
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nebula -config /etc/nebula/nebula.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start nebula
systemctl enable nebula

