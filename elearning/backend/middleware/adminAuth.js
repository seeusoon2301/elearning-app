// middleware/adminAuth.js
const jwt = require('jsonwebtoken');
const SECRET = process.env.JWT_SECRET || 'CHANGE_THIS_SECRET';

module.exports = function (req, res, next) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) return res.status(401).json({ error: 'No token' });
  const token = auth.split(' ')[1];
  try {
    const data = jwt.verify(token, SECRET);
    req.admin = { id: data.adminId, email: data.email };
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};
