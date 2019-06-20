const AWS = require('aws-sdk');

const DB_INSTANCE_IDENTIFIER = process.env.DB_INSTANCE_IDENTIFIER;
const DB_CLUSTER_IDENTIFIER = process.env.DB_CLUSTER_IDENTIFIER;
const DB_SNAPSHOT_IDENTIFIER_PREFIX = process.env.DB_SNAPSHOT_IDENTIFIER_PREFIX;
const DB_AVAILABILITY_ZONE = process.env.DB_AVAILABILITY_ZONE;
const DB_SUBNET_GROUP_NAME = process.env.DB_SUBNET_GROUP_NAME;
const DB_INSTANCE_CLASS = process.env.DB_INSTANCE_CLASS;
const DB_OPTION_GROUP_NAME = process.env.DB_OPTION_GROUP_NAME;
const DB_PORT = process.env.DB_PORT;
const DB_STORAGE_TYPE = process.env.DB_STORAGE_TYPE;
const DB_ENGINE = process.env.DB_ENGINE;
const DB_LICENSE_MODEL = process.env.DB_LICENSE_MODEL;

exports.handler = async (event) => {
    try {
        console.log(JSON.stringify(event));
        var rds = new AWS.RDS();

        // Ignore snapshots with 'retain' in the name or any automated snapshots
        var snapshotFilterFunction = function (snapshot) {
            return snapshot.DBClusterSnapshotIdentifier.indexOf('retain') === -1 &&
                snapshot.DBClusterSnapshotIdentifier.indexOf(DB_SNAPSHOT_IDENTIFIER_PREFIX) !== -1 &&
                snapshot.Status === 'available' &&
                snapshot.SnapshotType === 'manual';
        };

        // Orders newer snapshots first
        var snapshotSortFunction = function (a, b) {
            return b.SnapshotCreateTime - a.SnapshotCreateTime;
        };

        var getMostRecentSnapshot = function (unfilteredUnsortedList) {
            var filtered = unfilteredUnsortedList.filter(snapshotFilterFunction);
            return filtered.sort(snapshotSortFunction)[0];
        };

        var describeResult = await rds.describeDBClusterSnapshots({}).promise();
        var mostRecentSnapshot = getMostRecentSnapshot(describeResult.DBClusterSnapshots);

        var restoreClusterParams = {
            DBClusterIdentifier: DB_CLUSTER_IDENTIFIER,
            SnapshotIdentifier: mostRecentSnapshot.DBClusterSnapshotIdentifier,
            Engine: DB_ENGINE,
            DBSubnetGroupName: DB_SUBNET_GROUP_NAME,
            //AvailabilityZones: [DB_AVAILABILITY_ZONE],
            //CopyTagsToSnapshot: false,
            //DBInstanceClass: DB_INSTANCE_CLASS,
            //EnableIAMDatabaseAuthentication: true,
            //LicenseModel: DB_LICENSE_MODEL,
            //MultiAZ: false,
            //OptionGroupName: DB_OPTION_GROUP_NAME,
            //Port: DB_PORT,
            //PubliclyAccessible: false,
            //StorageType: DB_STORAGE_TYPE
        };
        await rds.restoreDBClusterFromSnapshot(restoreClusterParams).promise();

        var createInstanceParams = {
            DBInstanceClass: DB_INSTANCE_CLASS,
            DBClusterIdentifier: DB_CLUSTER_IDENTIFIER,
            DBInstanceIdentifier: DB_INSTANCE_IDENTIFIER,
            Engine: DB_ENGINE
        };

        try {
            await rds.createDBInstance(createInstanceParams).promise();
        } catch (error) {
            console.log('Creating DB instance failed: ' + JSON.stringify(error))
            console.log('Deleting DB cluster')

            var deleteClusterParams = {
                DBClusterIdentifier: DB_CLUSTER_IDENTIFIER,
                SkipFinalSnapshot: true
            };
            await rds.deleteDBCluster(deleteClusterParams).promise();

            throw error;
        }
    } catch (error) {
        console.log(error);
        throw error;
    }
    return null;
};
