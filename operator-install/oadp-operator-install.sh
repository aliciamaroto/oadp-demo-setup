#!/bin/sh

echo -e "\n================================================"
echo -e "Installing OADP Operator..."
echo -e "=================================================\n"

#Check if openshift-adp namespace exists, and if not create it.
if ! (oc get project/openshift-adp) &> /dev/null; then
    echo -e "Creating openshift-adp namespace..."
    oc apply -f namespace.yaml
else
    echo -e "Already in openshift-adp project"
fi

#Install Operator
echo -e "\nCreating oadp operatorgroup..."
oc apply -f operatorgroup.yaml
echo -e "\nCreating oadp subscription..."
oc apply -f subscription.yaml

#sleep 60

#Creating blob Azure:
./create-blob-azure.sh
#sleep 60

#Create OpenShift Data Protection Application instance.
oc create secret generic cloud-credentials-azure -n openshift-adp --from-file cloud=credentials-velero
echo -e "\nCreating OpenShift Data Protection Applciation instance..."
oc apply -f dpa.yaml

#Label VolumeSnapshotClass to use Data Mover 
oc label volumesnapshotclass ocs-storagecluster-cephfsplugin-snapclass metadata.labels.velero.io/csi-volumesnapshot-class="true"
