const AWS = require('aws-sdk');

exports.handler = async (event) => {
    console.log(event);

    const rds = new AWS.RDS();

    await rds.deleteDBCluster({
        DBClusterIdentifier: event.dbClusterId,
        SkipFinalSnapshot: true
    }).promise();

    return null;
};
