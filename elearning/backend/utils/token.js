// utils/token.js
const jwt = require('jsonwebtoken');
const SECRET = process.env.JWT_SECRET || 'CHANGE_THIS_SECRET';

function signAdmin(admin) {
  const payload = {
    adminId: admin._id,
    email: admin.email
  };
  return jwt.sign(payload, SECRET, { expiresIn: '7d' });
}

function verifyToken(token) {
  return jwt.verify(token, SECRET);
}

module.exports = { signAdmin, verifyToken };
