const AWS = require('aws-sdk');
const mysqlPromise = require('promise-mysql');
const Slack = require('slack-node');
const promisify = require('util-promisify');

const SLACK_WEBHOOK_URL = `https://hooks.slack.com/services/${process.env.SLACK_WEBHOOK_URL}`;
const SLACK_CHANNEL = process.env.SLACK_CHANNEL;

const DB_INSTANCE_IDENTIFIER = process.env.DB_INSTANCE_IDENTIFIER;
const DB_CLUSTER_IDENTIFIER = process.env.DB_CLUSTER_IDENTIFIER;
const DB_NAME = process.env.DB_NAME;
const DB_PASSWORD = process.env.DB_PASSWORD;
const STATUS_SNS_TOPIC = process.env.STATUS_SNS_TOPIC;

const publishStatus = function (message) {
    console.log('Posting status to Slack');

    var slack = new Slack();
    slack.setWebhook(SLACK_WEBHOOK_URL);
    var webhookPromise = promisify(slack.webhook);
    webhookPromise({
        channel: SLACK_CHANNEL,
        text: message
    }).then(response => {
        console.log(response);
    }).catch(error => {
        console.log(error);
    });

    var sns = new AWS.SNS();
    sns.publish({
        Message: message,
        Subject: 'code.org verify offsite copy of database',
        TopicArn: STATUS_SNS_TOPIC
    }).promise().then(data => {
        console.log(data);
    }).catch(error => {
        console.log(error);
    });
};

const setPasswordAndWait = async (rds, clusterId, sleepMs) => {

    // Update cluster password so we can connect without using production password.
    await rds.modifyDBCluster({
        DBClusterIdentifier: clusterId,
        MasterUserPassword: DB_PASSWORD,
        ApplyImmediately: true
    }).promise();

    // updating an RDS database master password typically takes 2-3 minutes, during which time the database transitions through several states:
    // 1) Available with old/unknown password.  Attempting to connect with new password will fail authentication
    // 2) Not Available (Status = resetting-master-credentials).  Attempt to connect as a mysql client or to invoke AWS describeDBInstances API fails
    // 3) Available with new password
    console.log('Modify database password request has been submitted successfully.  Sleep for (milliseconds): ' + sleepMs);
    await new Promise(done => setTimeout(done, sleepMs));
};

const verifyDb = async (event, context, rds) => {
    const eventMessage = JSON.parse(event.Records[0].Sns.Message);
    const eventID = eventMessage['Event ID'];
    const sourceID = eventMessage['Source ID'];
    var statusMessage;

    if (!eventID.endsWith('RDS-EVENT-0005') || sourceID !== DB_INSTANCE_IDENTIFIER) {
        statusMessage = 'Ignore trigger because it is not one that indicates RDS Snapshot restore is complete: ' + JSON.stringify(eventMessage);
        console.log(statusMessage);
        return statusMessage;
    }

    const describeResponse = await rds.describeDBInstances({
        DBInstanceIdentifier: DB_INSTANCE_IDENTIFIER
    }).promise();
    const masterUsername = describeResponse.DBInstances[0].MasterUsername;
    const endpoint = describeResponse.DBInstances[0].Endpoint.Address;
    // Wait until about 2 minutes before this Lambda function reaches its 5 minute timeout before attempting to connect to the database
    const sleepMs = context.getRemainingTimeInMillis() - 120000;

    await setPasswordAndWait(rds, DB_CLUSTER_IDENTIFIER, sleepMs);

    var connectParams = {
        host: endpoint,
        database: DB_NAME,
        user: masterUsername,
        password: DB_PASSWORD
    };
    console.log('Connect params: ' + JSON.stringify(connectParams));
    var mysqlConnection = await mysqlPromise.createConnection(connectParams);

    try {
        var rows = mysqlConnection.query('SELECT count(*) AS number_of_users, max(updated_at) AS last_updated_at FROM users');

        statusMessage = 'Successfully queried offsite backup of database.  ' +
            'Number of Users = ' + rows[0].number_of_users +
            ', Last Updated = ' + rows[0].last_updated_at;
        console.log(statusMessage);
        publishStatus(statusMessage);

        return statusMessage;
    } finally {
        mysqlConnection.end();
    }
};

exports.handler = async (event, context) => {
    console.log(JSON.stringify(event));
    var rds = new AWS.RDS();

    try {
        return await verifyDb(event, context, rds);
    } catch (error) {
        var statusMessage = JSON.stringify(error);
        console.log(statusMessage);
        publishStatus(statusMessage);
        throw error;
    } finally {
        // Always clean up restored RDS instance.

        await rds.deleteDBInstance({
            DBInstanceIdentifier: DB_INSTANCE_IDENTIFIER,
            SkipFinalSnapshot: true
        }).promise();

        await rds.waitFor('dBInstanceDeleted', {
            DBInstanceIdentifier: DB_INSTANCE_IDENTIFIER
        }).promise();

        await rds.deleteDBCluster({
            DBClusterIdentifier: DB_CLUSTER_IDENTIFIER
        }).promise();
    }
};
