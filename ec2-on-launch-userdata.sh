#!/bin/bash

die() { status=$1; shift; echo "FATAL: $*"; exit $status; }

EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id || die \"wget instance-id has failed: $?\"`"
EC2_AVAIL_ZONE="`wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone || die \"wget availability-zone has failed: $?\"`"
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"

EIPID=`aws ec2 allocate-address --domain vpc --region ${EC2_REGION} | grep -m 1 'AllocationId' | awk -F : '{print $2}' | sed 's|^ "||' | sed 's|"||'`
IP=`ec2metadata --public-ipv4`
EIP=${IP}

if [ -n "$EIPID" ]
then
    conf=`aws ec2 associate-address --instance-id ${RESOURCE_ID} --allocation-id ${EIPID} --region ${REGION} | grep -m 1 'AssociationId' | awk -F : '{print $2}' | sed 's|^ "||' | sed 's|"||'`
    if [ -n "$conf" ]
    then
        while [ "$IP" == "$EIP" ]
        do
            EIP=`ec2metadata --public-ipv4`
            sleep 2
        done
        echo "Elastic IP ${EIPID} successfully mapped";      
        echo "ELASTIC_IP=\"${EIP}\"" | sudo tee -a /etc/environment
    else
        echo "Failed to map Elastic IP Address: ${EIPID}";
    fi
else
    echo "Failed to acquire Elastic IP address: ${EIPID}";
fi

wget https://raw.githubusercontent.com/Vitae-VPN/openvpn-install/master/openvpn-install.sh -O openvpn-install.sh && sudo bash openvpn-install.sh && sudo chown -R ubuntu:ubuntu /root/
