// generate-keys.js
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Define the directory where keys will be saved
const JVS_KEYS_DIR = process.env.JVS_KEYS_DIR;

// Ensure JVS_KEYS_DIR exists
if (!fs.existsSync(JVS_KEYS_DIR)) {
  fs.mkdirSync(JVS_KEYS_DIR, { recursive: true });
}

// Define paths for the keys
const privateKeyPath = path.join(JVS_KEYS_DIR, 'private_key.pem');
const publicKeyPath = path.join(JVS_KEYS_DIR, 'public_key.pem');

// Generate an RSA key pair
crypto.generateKeyPair(
  'rsa',
  {
    modulusLength: 2048, // Key size
    publicKeyEncoding: {
      type: 'pkcs1', // Public Key Cryptography Standards #1
      format: 'pem', // Save as .pem file
    },
    privateKeyEncoding: {
      type: 'pkcs1',
      format: 'pem',
    },
  },
  (err, publicKey, privateKey) => {
    if (err) {
      console.error('Error generating keys:', err);
      process.exit(1);
    }

    // Write the keys to files
    fs.writeFileSync(privateKeyPath, privateKey);
    console.log(`Private key saved to ${privateKeyPath}`);

    fs.writeFileSync(publicKeyPath, publicKey);
    console.log(`Public key saved to ${publicKeyPath}`);
  }
);
