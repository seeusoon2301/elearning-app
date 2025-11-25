// server.js
const express = require('express');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const classRoutes = require('./routes/classRoutes');
const authRoutes = require('./routes/authRoutes');
const semesterRoutes = require('./routes/semesterRoutes');
const cors = require('cors');
// Tải biến môi trường từ file .env
dotenv.config();

// Kết nối Database
connectDB();

const app = express();
app.use(cors());
// Middleware: Cho phép Express đọc JSON body
app.use(express.json());

app.use('/api/auth', authRoutes);
// Định nghĩa Routes
app.use('/api/admin/classes', classRoutes);
// Học kỳ
app.use('/api/admin/semesters', semesterRoutes);

// Khởi động server
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
    console.log(`Test API endpoint: \n  Login Admin POST: http://localhost:5000/api/auth/login\n  Create Class POST http://localhost:${PORT}/api/admin/classes/create\n  Show all class GET http://localhost:5000/api/admin/classes\n  Delete 1 Class http://localhost:5000/api/admin/classes/delete/:id`);
});