const AWS = require('aws-sdk');

exports.handler = async (event) => {
    console.log(event);

    const rds = new AWS.RDS();

    // Update cluster password so we can connect without using production password.
    await rds.modifyDBCluster({
        DBClusterIdentifier: event.dbClusterId,
        MasterUserPassword: event.password,
        ApplyImmediately: true
    }).promise();

    return null;
};
