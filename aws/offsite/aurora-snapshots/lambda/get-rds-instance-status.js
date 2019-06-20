const AWS = require('aws-sdk');

exports.handler = async (event) => {
    console.log(event);

    const rds = new AWS.RDS();

    var status;

    try {
        const describeResult = await rds.describeDBInstances({
            DBInstanceIdentifier: event.dbInstanceId
        }).promise();

        status = describeResult.DBInstances[0].DBInstanceStatus;
    } catch (error) {
        if ('code' in error && error.code === 'DBInstanceNotFound') {
            status = 'not-found';
        } else {
            throw error;
        }
    }

    return status;
};
