const handler = async (event, context) => {

  console.log("EVENT: \n" + JSON.stringify(event, null, 2));
  const {body} = event;

  try {

    console.log(`Got event: ${body}`);
    return {
      "statusCode": 200,
      "headers": {
        "Content-Type": "application/json"
      },
      "body": JSON.stringify({"success": true})
    }

  } catch (err) {
    console.error(`An error occurred: ${err.statusCode}`);
    return {
      "statusCode": 500,
      "headers": {
        "Content-Type": "application/json"
      },
      "body": JSON.stringify(err.statusCode)
    }
  }
}

export { handler };
