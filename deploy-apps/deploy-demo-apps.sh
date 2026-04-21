#!/bin/sh

echo -e "\n================================================"
echo -e "Deploying apps for the demo"
echo -e "=================================================\n"

#DEMO 1: Simple app
echo -e "\n================================================"
echo -e "Deploying app-01"
echo -e "=================================================\n"

oc new-project demo-app-01
#oc new-app centos/httpd-24-centos7~https://github.com/sclorg/httpd-ex --name='app-01'
oc new-app openshift/httpd:2.4-el8  --name='app-01'
sleep 30

oc expose svc app-01

#DEMO 2: App with PVC attached using Snapshots
echo -e "\n================================================"
echo -e "Deploying app-02"
echo -e "=================================================\n"

oc new-project demo-app-02
oc new-app openshift/httpd:2.4-el8  --name='app-02'
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
oc new-app openshift/httpd:2.4-el8 --name='app-03'
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
oc new-app openshift/httpd:2.4-el8 --name='app-04'
sleep 30
oc expose svc app-04
oc set volume deployment/app-04 --add --claim-name=pvc-demo-app-04 --claim-mode='ReadWriteOnce' --name=pvc-demo-app-04 -t pvc --claim-size=1G -m /tmp
sleep 20
POD4=$(oc get pods -l deployment=app-04 -n demo-app-04 -o jsonpath='{.items[0].metadata.name}')
oc -n demo-app-04 exec $POD4 -- /bin/bash -c 'echo "This is a pvc for demo 04" > /tmp/test-pvc-4.txt'


#DEMO 5: Database with PVC attached and using pre-hook and post-hook
echo -e "\n================================================"
echo -e "Deploying app-05"
echo -e "=================================================\n"

oc new-project demo-app-05
oc new-app openshift/mysql --name=app-05 MYSQL_USER=user MYSQL_PASSWORD=pass MYSQL_DATABASE=sakila -l db=mysql
sleep 30
oc expose svc app-05
oc set volume deployment/app-05 --add --claim-name=pvc-demo-app-05 --claim-mode='ReadWriteOnce' --name=pvc-demo-app-05 -t pvc --claim-size=10G -m /var/lib/mysql/data
sleep 20
POD5=$(oc get pods -l deployment=app-05 -n demo-app-05 -o jsonpath='{.items[0].metadata.name}')

echo -e "Copying sakila-schema.sql to the mysql data directory in the pod"
oc cp sakila-schema.sql demo-app-05/$POD5:/var/lib/mysql/data/sakila-schema.sql

echo -e "Copying sakila-data.sql to the mysql data directory in the pod"
oc cp sakila-data.sql demo-app-05/$POD5:/var/lib/mysql/data/sakila-data.sql

echo -e "Loading database schema and data into MySQL"
oc -n demo-app-05 exec $POD5 -- /bin/bash -c 'mysql -u user -p sakila < /var/lib/mysql/data/sakila-schema.sql'
oc -n demo-app-05 exec $POD5 -- /bin/bash -c 'mysql -u user -p sakila < /var/lib/mysql/data/sakila-data.sql'

#Annotate deployment with pre-hook and post-hook
oc patch deployment/app-05 -p '{"spec":{"template":{"metadata":{"annotations":{"pre.hook.backup.velero.io/command='["/bin/sh", "-c", "mysql -D sakila -u user --password=pass -e 'ALTER DATABASE sakila READ ONLY = 0;'"]'"}}}}}'
oc patch deployment/app-05 -p '{"spec":{"template":{"metadata":{"annotations":{post.hook.backup.velero.io/container: mysql}}}}}'
oc patch deployment/app-05 -p '{"spec":{"template":{"metadata":{"annotations":{"pre.hook.backup.velero.io/command='["/bin/sh", "-c", "mysql -D sakila -u user --password=pass -e 'ALTER DATABASE sakila READ ONLY = 1;'"]'"}}}}}'
oc patch deployment/app-05 -p '{"spec":{"template":{"metadata":{"annotations":{post.hook.backup.velero.io/container: mysql}}}}}'
oc patch deployment/app-05 -p '{"spec":{"template":{"metadata":{"annotations":{"pre.hook.backup.velero.io/timeout: 240s"}}}}}'