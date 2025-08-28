import mailjet from 'node-mailjet';

const handler = async (event, context) => {

  const api = mailjet.Client.apiConnect("fcba887b9861f6a70b1b6409857e8d75", "3f9e53d38217cde1a4d4b94b7de6d4e9")
  console.log("EVENT: \n" + JSON.stringify(event, null, 2));
  const body = JSON.parse(event.body);
  try {
    const response = await api
      .post("send", {'version': 'v3.1'})
      .request({
        "Messages":[
          {
            "From": {
              "Email": "admin@schoolsmart.co.uk",
              "Name": "SchoolSmart Admin"
            },
            "To": [
              {
                "Email": "info@schoolsmart.co.uk",
                "Name": "SchoolSmart Enquiries"
              },
              {
                "Email": "admin@schoolsmart.co.uk",
                "Name": "SchoolSmart Admin"
              }
            ],
            "Subject": body.type === "enquiry" ? "Website Enquiry" : "Tutor Registration",
            "TextPart": `First Name: ${body.firstName || ''}\n`
              + `Last Name: ${body.lastName || ''}\n`
              + `Email: ${body.email}\n`
              + `Address: ${body.address || ''}\n`
              + `Postcode: ${body.postcode || ''}\n`
              + (body.type === "tutor" ? '' : `Child Names: ${body.names || ''}\n`)
              + (body.type === "tutor" ? '' :  `Child Ages: ${body.ages || ''}\n`)
              + `Message: ${body.message || ''}\n`
          }
        ]
      });
    console.log(`Email sent: ${JSON.stringify(response.body)}`);
    return {
      "statusCode": 200,
      "headers": {
        "Content-Type": "application/json"
      },
      "body": JSON.stringify(response.body)
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
