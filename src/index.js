const jwt = require('jsonwebtoken');

exports.verifyJwtSignature = (req, res) => {
  try {
    // Check for missing 'token' argument
    if (!req.body.token) {
      return res.status(400).send({ error: 'Missing "token" in request body' });
    }

    // Check for missing 'publicKey' argument
    if (!req.body.publicKey) {
      return res.status(400).send({ error: 'Missing "publicKey" in request body' });
    }

    // Extract the token and public key from the request
    const { token, publicKey } = req.body;

    // Verify the JWT
    jwt.verify(token, publicKey, { algorithms: ['RS256'] }, (err, decoded) => {
      if (err) {
        // Capture and respond with detailed JWT verification error
        return res.status(401).send({ error: `JWT verification failed: ${err.message}` });
      }

      // If verification is successful, respond with the decoded payload
      return res.status(200).send(decoded);
    });
  } catch (error) {
    // Catch any other errors and respond with the error message
    console.error('Unexpected error during JWT verification:', error);
    return res.status(500).send({ error: `Internal server error: ${error.message}` });
  }
};
