#!/bin/sh

echo -e "\n================================================"
echo -e "Deploying apps for the demo"
echo -e "=================================================\n"

#DEMO 1: Simple app
echo -e "\n================================================"
echo -e "Deploying app-01"
echo -e "=================================================\n"

oc new-project demo-app-01
oc new-app centos/httpd-24-centos7~https://github.com/sclorg/httpd-ex --name='demo-app-01'

#DEMO 2: App with PVC attached using Snapshots
echo -e "\n================================================"
echo -e "Deploying app-02"
echo -e "=================================================\n"

oc new-project demo-app-02
oc new-app centos/httpd-24-centos7~https://github.com/sclorg/httpd-ex --name='demo-app-02'
sleep 30
oc set volume deployment/demo-app-02 --add --claim-name=pvc-demo-app-02 --claim-mode='ReadWriteOnce' --name=pvc-demo-app-02 -t pvc --claim-size=1G -m /tmp

#DEMO 3: App with PVC attached using Kopia
echo -e "\n================================================"
echo -e "Deploying app-03"
echo -e "=================================================\n"

oc new-project demo-app-03
oc new-app centos/httpd-24-centos7~https://github.com/sclorg/httpd-ex --name='demo-app-03'
sleep 30
oc set volume deployment/demo-app-03 --add --claim-name=pvc-demo-app-03 --claim-mode='ReadWriteOnce' --name=pvc-demo-app-03 -t pvc --claim-size=1G -m /tmp

#DEMO 4: App with PVC attached using Snapshot and DataMover
echo -e "\n================================================"
echo -e "Deploying app-04"
echo -e "=================================================\n"

oc new-project demo-app-04
oc new-app centos/httpd-24-centos7~https://github.com/sclorg/httpd-ex --name='demo-app-04'
sleep 30
oc set volume deployment/demo-app-04 --add --claim-name=pvc-demo-app-04 --claim-mode='ReadWriteOnce' --name=pvc-demo-app-04 -t pvc --claim-size=1G -m /tmp

