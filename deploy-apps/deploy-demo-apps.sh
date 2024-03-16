#!/bin/sh

echo -e "\n================================================"
echo -e "Deploying apps for the demo"
echo -e "=================================================\n"

#DEMO 1: Simple app
echo -e "\n================================================"
echo -e "Deploying app-01"
echo -e "=================================================\n"

oc new-project demo-app-01
oc new-app centos/httpd-24-centos7~https://github.com/sclorg/httpd-ex --name='app-01'
sleep 30

oc expose svc app-01

#DEMO 2: App with PVC attached using Snapshots
echo -e "\n================================================"
echo -e "Deploying app-02"
echo -e "=================================================\n"

oc new-project demo-app-02
oc new-app centos/httpd-24-centos7~https://github.com/sclorg/httpd-ex --name='app-02'
sleep 30
oc expose svc app-02
oc set volume deployment/app-02 --add --claim-name=pvc-demo-app-02 --claim-mode='ReadWriteOnce' --name=pvc-demo-app-02 -t pvc --claim-size=1G -m /tmp
sleep 20
POD2=$(oc get pods -l deployment=app-02  -n demo-app-02 -o jsonpath='{.items[0].metadata.name}')
oc -n demo-app-02 exec $POD2 -- /bin/bash -c 'echo "This is a pvc for demo 02" > /tmp/test-pvc-2.txt'


#DEMO 3: App with PVC attached using Kopia
echo -e "\n================================================"
echo -e "Deploying app-03"
echo -e "=================================================\n"

oc new-project demo-app-03
oc new-app centos/httpd-24-centos7~https://github.com/sclorg/httpd-ex --name='app-03'
sleep 30
oc expose svc app-03
oc set volume deployment/app-03 --add --claim-name=pvc-demo-app-03 --claim-mode='ReadWriteOnce' --name=pvc-demo-app-03 -t pvc --claim-size=1G -m /tmp
sleep 20
POD3=$(oc get pods -l deployment=app-03 -n demo-app-03  -o jsonpath='{.items[0].metadata.name}')
oc -n demo-app-03 exec $POD3 -- /bin/bash -c 'echo "This is a pvc for demo 03" > /tmp/test-pvc-3.txt'

#DEMO 4: App with PVC attached using Snapshot and DataMover
echo -e "\n================================================"
echo -e "Deploying app-04"
echo -e "=================================================\n"

oc new-project demo-app-04
oc new-app centos/httpd-24-centos7~https://github.com/sclorg/httpd-ex --name='app-04'
sleep 30
oc expose svc app-04
oc set volume deployment/app-04 --add --claim-name=pvc-demo-app-04 --claim-mode='ReadWriteOnce' --name=pvc-demo-app-04 -t pvc --claim-size=1G -m /tmp
sleep 20
POD4=$(oc get pods -l deployment=app-04 -n demo-app-04 -o jsonpath='{.items[0].metadata.name}')
oc -n demo-app-04 exec $POD4 -- /bin/bash -c 'echo "This is a pvc for demo 04" > /tmp/test-pvc-4.txt'
