const express = require("express");
const router = express.Router();
const User = require("../models/user");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

// REGISTER
router.post("/register", async (req, res) => {
  try {
    const { name, email, password } = req.body;

    const hash = await bcrypt.hash(password, 10);

    const user = await User.create({ name, email, password: hash });
    // REGISTER SUCCESS
    res.json({ message: "User registered", user });
  } catch (e) {
    res.status(400).json({ error: "Email already exists" });
  }
});

// LOGIN
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email });
  if (!user) return res.status(400).json({ error: "Email not found" });

  const ok = await bcrypt.compare(password, user.password);
  if (!ok) return res.status(400).json({ error: "Wrong password" });

  const token = jwt.sign(
    { userId: user._id, role: user.role },
    "SECRET",
    { expiresIn: "7d" }
  );

  res.json({
    message: "Login success",
    token,
    user: { name: user.name, email: user.email, role: user.role }
  });
});

module.exports = router;
