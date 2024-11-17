require('dotenv').config();
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const { execSync } = require('child_process');
const { expect } = require('chai');

// Load environment variables and paths
const LIVE_FUNCTION_URL = process.env.G_FUNCTION_URL;

const PUBLIC_KEY_PATH = path.join(process.env.KEYS_DIR, 'public_key.pem');
const JWT_PATH = path.join(process.env.JWTS_DIR, 'generated_jwt.txt');

describe('Live JWT Verification Test', () => {
  // Check if the public key and JWT exist
  before(() => {
    if (!fs.existsSync(PUBLIC_KEY_PATH)) {
      throw new Error(`Public key file not found at ${PUBLIC_KEY_PATH}`);
    }
    if (!fs.existsSync(JWT_PATH)) {
      throw new Error(`JWT file not found at ${JWT_PATH}. Run generate-jwt.js first to generate a JWT.`);
    }
  });

  it('should verify a valid JWT successfully', async () => {
    // Read the JWT and public key from files
    const JWT = fs.readFileSync(JWT_PATH, 'utf-8').trim();
    const PUBLIC_KEY = fs.readFileSync(PUBLIC_KEY_PATH, 'utf-8').trim();

    try {
      const response = await axios.post(
        LIVE_FUNCTION_URL,
        {
          token: JWT,
          publicKey: PUBLIC_KEY
        },
        {
          headers: { 'Content-Type': 'application/json' }
        }
      );

      // Expect a successful response with a 200 status code
      expect(response.status).to.equal(200);
      console.log('Live test passed: JWT was successfully verified.');
    } catch (error) {
      const status = error.response ? error.response.status : 'No response';
      const data = error.response ? JSON.stringify(error.response.data, null, 2) : error.message;
      console.error(`Live test failed: Expected 200 but got ${status}: ${data}`);
      throw new Error(`Expected 200 but got ${status}: ${data}`);
    }
  });
});
