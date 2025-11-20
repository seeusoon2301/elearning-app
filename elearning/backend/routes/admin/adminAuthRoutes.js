// routes/admin/adminAuthRoutes.js
const express = require('express');
const router = express.Router();
const adminAuth = require('../../controllers/admin/adminAuthController');

router.post('/login', adminAuth.login);

module.exports = router;
