const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  password: String,
  role: { type: String, default: "student" } // student hoặc admin
});

module.exports = mongoose.model("User", UserSchema);
