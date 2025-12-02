const mongoose = require('mongoose');
const bcrypt = require('bcryptjs'); // Thư viện dùng để hash

const StudentSchema = new mongoose.Schema({
    mssv: {
        type: String,
        required: [true, "MSSV là bắt buộc"],
        unique: true
    },
    name: {
        type: String,
        required: [true, "Tên là bắt buộc"]
    },
    email: {
        type: String,
        required: [true, 'Email là bắt buộc'],
        unique: true,
        match: [
            /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
            'Vui lòng nhập email hợp lệ'
        ]
    },
    password: {
        type: String,
        required: [true, "Password là bắt buộc"],
        // Thêm select: false để không bao gồm trường này khi lấy dữ liệu
        select: false 
    },
    // 1 student —> nhiều Class
    courses: [
        { type: mongoose.Schema.Types.ObjectId, ref: "Class" }
    ]

}, {
    timestamps: true
});

// =========================================================================
// ⭐ LOGIC HASH MẬT KHẨU TRƯỚC KHI LƯU (MANDATORY)
// =========================================================================

// Hook 'pre' chạy trước sự kiện 'save' (trước khi document được lưu)
StudentSchema.pre('save', async function(next) {
    // Chỉ hash nếu mật khẩu đã được sửa đổi (hoặc mới tạo)
    if (!this.isModified('password')) {
        return next();
    }

    // Tạo salt (chuỗi ngẫu nhiên) với độ phức tạp 10
    const salt = await bcrypt.genSalt(10);
    
    // Hash mật khẩu và lưu lại vào trường 'password'
    this.password = await bcrypt.hash(this.password, salt);
    
    next();
});

// =========================================================================
// PHƯƠNG THỨC SO SÁNH MẬT KHẨU
// =========================================================================

// Thêm một phương thức vào StudentSchema để so sánh mật khẩu đăng nhập với mật khẩu đã hash
StudentSchema.methods.matchPassword = async function(enteredPassword) {
    // 'this.password' là mật khẩu đã hash trong DB (vì ta đã đặt select: false, 
    // bạn cần phải SELECT nó một cách rõ ràng trong controller để hàm này hoạt động)
    return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model("Student", StudentSchema);

// LƯU Ý: Bạn cần cài đặt thư viện bcryptjs:
// npm install bcryptjs