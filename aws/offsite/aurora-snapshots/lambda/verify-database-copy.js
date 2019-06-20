const AWS = require('aws-sdk');
const mysqlPromise = require('promise-mysql');

const DB_NAME = process.env.DB_NAME;

exports.handler = async (event) => {
    console.log(event);

    const rds = new AWS.RDS();

    const describeResponse = await rds.describeDBInstances({
        DBInstanceIdentifier: event.dbInstanceId
    }).promise();
    const masterUsername = describeResponse.DBInstances[0].MasterUsername;
    const password = event.password;
    const endpoint = describeResponse.DBInstances[0].Endpoint.Address;

    const mysqlConnection = await mysqlPromise.createConnection({
        host: endpoint,
        database: DB_NAME,
        user: masterUsername,
        password: password
    });

    try {
        const rows = mysqlConnection.query('SELECT count(*) AS number_of_users, max(updated_at) AS last_updated_at FROM users');

        const statusMessage = 'Successfully queried offsite backup of database.  ' +
            'Number of Users = ' + rows[0].number_of_users +
            ', Last Updated = ' + rows[0].last_updated_at;
        console.log(statusMessage);
    } finally {
        mysqlConnection.end();
    }

    return null;
};
