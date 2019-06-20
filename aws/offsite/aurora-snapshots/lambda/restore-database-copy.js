const AWS = require('aws-sdk');

const DB_SNAPSHOT_IDENTIFIER_PREFIX = process.env.DB_SNAPSHOT_IDENTIFIER_PREFIX;
const DB_SUBNET_GROUP_NAME = process.env.DB_SUBNET_GROUP_NAME;
const DB_INSTANCE_CLASS = process.env.DB_INSTANCE_CLASS;
const DB_ENGINE = process.env.DB_ENGINE;

exports.handler = async (event) => {
    console.log(event);

    const DB_CLUSTER_IDENTIFIER = event.dbClusterId;
    const DB_INSTANCE_IDENTIFIER = event.dbInstanceId;

    const rds = new AWS.RDS();

    // Ignore snapshots with 'retain' in the name or any automated snapshots
    const snapshotFilterFunction = function (snapshot) {
        return snapshot.DBClusterSnapshotIdentifier.indexOf('retain') === -1 &&
            snapshot.DBClusterSnapshotIdentifier.indexOf(DB_SNAPSHOT_IDENTIFIER_PREFIX) !== -1 &&
            snapshot.Status === 'available' &&
            snapshot.SnapshotType === 'manual';
    };

    // Orders newer snapshots first
    const snapshotSortFunction = function (a, b) {
        return b.SnapshotCreateTime - a.SnapshotCreateTime;
    };

    const getMostRecentSnapshot = function (unfilteredUnsortedList) {
        const filtered = unfilteredUnsortedList.filter(snapshotFilterFunction);
        return filtered.sort(snapshotSortFunction)[0];
    };

    const describeResult = await rds.describeDBClusterSnapshots({}).promise();
    const mostRecentSnapshot = getMostRecentSnapshot(describeResult.DBClusterSnapshots);

    const restoreClusterParams = {
        DBClusterIdentifier: DB_CLUSTER_IDENTIFIER,
        SnapshotIdentifier: mostRecentSnapshot.DBClusterSnapshotIdentifier,
        Engine: DB_ENGINE,
        DBSubnetGroupName: DB_SUBNET_GROUP_NAME
    };
    await rds.restoreDBClusterFromSnapshot(restoreClusterParams).promise();

    const createInstanceParams = {
        DBInstanceClass: DB_INSTANCE_CLASS,
        DBClusterIdentifier: DB_CLUSTER_IDENTIFIER,
        DBInstanceIdentifier: DB_INSTANCE_IDENTIFIER,
        Engine: DB_ENGINE
    };

    await rds.createDBInstance(createInstanceParams).promise();

    return null;
};
