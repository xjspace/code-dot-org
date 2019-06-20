const AWS = require('aws-sdk');

exports.handler = async (event) => {
    console.log(event);

    const rds = new AWS.RDS();

    await rds.deleteDBInstance({
        DBInstanceIdentifier: event.dbInstanceId,
        SkipFinalSnapshot: true
    }).promise();

    return null;
};
