// config/db.js
const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://hoangthai2301_db_user:hoangthai2301@cluster0.ez8eahu.mongodb.net/elearning';

module.exports = function connectDB() {
  mongoose.connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
  }).then(() => console.log('MongoDB connected'))
    .catch(err => {
      console.error('MongoDB connection error', err.message);
      process.exit(1);
    });
};
