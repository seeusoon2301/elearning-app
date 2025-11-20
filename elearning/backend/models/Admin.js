// models/Admin.js
const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema({
  name: { type: String, default: 'Admin' },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true } // đã hash
}, { timestamps: true });

module.exports = mongoose.model('Admin', adminSchema);
