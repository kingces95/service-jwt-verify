// generate-jwt.js
const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');

// Define the directory where jwt will be saved
const JVS_JWTS_DIR = process.env.JVS_KEYS_DIR;

// Ensure JVS_JWTS_DIR exists
if (!fs.existsSync(JVS_JWTS_DIR)) {
  fs.mkdirSync(JVS_JWTS_DIR, { recursive: true });
}

// Use environment variables for directories
const privateKeyPath = path.join(process.env.JVS_KEYS_DIR, 'private_key.pem');
const jwtOutputPath = path.join(process.env.JVS_JWTS_DIR, 'generated_jwt.txt');

// Check for the private key file
if (!fs.existsSync(privateKeyPath)) {
  console.error("Error: Private key file not found at", privateKeyPath);
  process.exit(1);
}

// Load the private key
const privateKey = fs.readFileSync(privateKeyPath, 'utf-8');

// Generate a JWT
const token = jwt.sign({ sub: '1234567890', name: 'John Doe' }, privateKey, { algorithm: 'RS256' });

// Save the JWT to a file
fs.writeFileSync(jwtOutputPath, token, 'utf-8');
console.log(`JWT generated and saved to ${jwtOutputPath}`);
