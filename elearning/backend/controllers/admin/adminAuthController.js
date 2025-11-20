// controllers/admin/adminAuthController.js
const Admin = require('../../models/Admin');
const bcrypt = require('bcryptjs');
const { signAdmin } = require('../../utils/token');

async function ensureDefaultAdmin() {
  const existing = await Admin.findOne({ email: 'admin' });
  if (!existing) {
    const hash = await bcrypt.hash('admin', 10);
    await Admin.create({ name: 'Administrator', email: 'admin', password: hash });
    console.log('Default admin account created: admin / admin');
  }
}

// Call once on module load
ensureDefaultAdmin().catch(err => console.error(err));

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });

    const admin = await Admin.findOne({ email });
    if (!admin) return res.status(400).json({ error: 'Admin not found' });

    const ok = await bcrypt.compare(password, admin.password);
    if (!ok) return res.status(400).json({ error: 'Wrong password' });

    const token = signAdmin(admin);
    res.json({ message: 'Login success', token, admin: { id: admin._id, name: admin.name, email: admin.email } });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'Server error' });
  }
};
