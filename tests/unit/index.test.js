// Load public and private keys
const path = require('path');
const srcPath = process.env.JVS_SRC_DIR;
const privateKeyPath = path.join(process.env.JVS_KEYS_DIR, 'private_key.pem');
const publicKeyPath = path.join(process.env.JVS_KEYS_DIR, 'public_key.pem');

const { expect } = require('chai');
const { verifyJwtSignature } = require(`${srcPath}/index`);  // Adjust path as needed
const fs = require('fs');
const jwt = require('jsonwebtoken');  // Ensure jsonwebtoken is installed

if (!fs.existsSync(publicKeyPath) || !fs.existsSync(privateKeyPath)) {
  throw new Error("Key files not found. Ensure keys are generated and placed in the correct location.");
}

const publicKey = fs.readFileSync(publicKeyPath, 'utf-8');
const privateKey = fs.readFileSync(privateKeyPath, 'utf-8');

describe('JWT Verification Function', () => {
  it('should successfully decode a valid JWT', () => {
    // Generate a valid JWT
    const token = jwt.sign({ sub: '1234567890', name: 'John Doe' }, privateKey, { algorithm: 'RS256' });

    const req = {
      body: {
        token: token,
        publicKey: publicKey
      }
    };
    
    const res = {
      status: (code) => ({
        send: (message) => {
          expect(code).to.equal(200);  // Expect a 200 for valid JWT
          expect(message).to.have.property('sub', '1234567890');  // Check payload contains expected data
        }
      })
    };

    verifyJwtSignature(req, res);
  });

  it('should return 400 if token is missing', () => {
    const req = {
      body: {
        publicKey: publicKey  // Only publicKey is provided, token is missing
      }
    };

    const res = {
      status: (code) => ({
        send: (message) => {
          expect(code).to.equal(400);  // Expect 400 for missing token
          expect(message).to.have.property('error');  // Check that an error property is returned
        }
      })
    };

    verifyJwtSignature(req, res);
  });

  it('should return 400 if publicKey is missing', () => {
    const req = {
      body: {
        token: 'dummy-token'  // Only token is provided, publicKey is missing
      }
    };

    const res = {
      status: (code) => ({
        send: (message) => {
          expect(code).to.equal(400);  // Expect 400 for missing publicKey
          expect(message).to.have.property('error');  // Check that an error property is returned
        }
      })
    };

    verifyJwtSignature(req, res);
  });

  it('should return 401 for an invalid JWT', () => {
    const req = {
      body: {
        token: 'invalid.token',  // Provide an invalid token
        publicKey: publicKey
      }
    };

    const res = {
      status: (code) => ({
        send: (message) => {
          expect(code).to.equal(401);  // Expect 401 for an invalid JWT
          expect(message).to.have.property('error');  // Check that an error property is returned
        }
      })
    };

    verifyJwtSignature(req, res);
  });
});
