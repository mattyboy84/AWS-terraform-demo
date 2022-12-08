const AWS = require('aws-sdk');
const S3 = new AWS.S3();

async function handler(event, context) {
    console.log(JSON.stringify(context, null, 4))
    console.log(JSON.stringify(event, null, 4));
}

module.exports = {
    handler,
}