#!/bin/sh

echo -e "\n================================================"
echo -e "Installing OADP Operator..."
echo -e "=================================================\n"

#Check if openshift-adp namespace exists, and if not create it.
if ! (oc get project/openshift-adp) &> /dev/null; then
    echo -e "Creating openshift-adp namespace..."
    oc apply -f operator-install/namespace.yaml
else
    echo -e "Already in openshift-adp project"
fi

#Install Operator
echo -e "\nCreating oadp operatorgroup..."
oc apply -f operator-install/operatorgroup.yaml

echo -e "\nCreating oadp subscription..."
oc apply -f operator-install/subscription.yaml

#Wait for the operator to be installed:
echo -e "\nWaiting for the operator to finish install..."
sleep 10
oc wait csv oadp-operator.v1.3.0 -n openshift-adp --for=jsonpath='{.status.phase}'="Succeeded"
#sleep 90

#Creating blob Azure:
./operator-install/create-blob-azure.sh


#Create OpenShift Data Protection Application instance.
echo -e "\nCreating OpenShift Data Protection Application instance..."
oc apply -f operator-install/dpa.yaml

#Wait for the dpa instance to be reconciled:
echo -e "\nWaiting for the DPA instance to be reconciled..."
oc wait DataProtectionApplication  velero-sample -n openshift-adp --for=jsonpath='{.status.conditions[].type}'="Reconciled"

#Wait for the BackupStorageLocation to be available:
echo -e "\nWaiting for the BackupStorageLocation to be available..."
sleep 60
oc wait BackupStorageLocation velero-sample-1 -n openshift-adp --for=jsonpath='{.status.phase}'="Available"

#Label VolumeSnapshotClass to use Data Mover 
echo -e "\nLabel VolumeSnapshotClass to use Data Mover"
oc label volumesnapshotclass ocs-storagecluster-cephfsplugin-snapclass metadata.labels.velero.io/csi-volumesnapshot-class="true"

#With ODF Set as unique default Storage Class ocs-storagecluster-cephfs 
oc patch storageclass ocs-storagecluster-cephfs -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
oc patch storageclass thin-csi -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'