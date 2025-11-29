const mongoose = require('mongoose');

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
        required: [true, "Password là bắt buộc"]
    },

    // 1 student —> nhiều Class
    courses: [
        { type: mongoose.Schema.Types.ObjectId, ref: "Class" }
    ]

}, {
    timestamps: true
});

module.exports = mongoose.model("Student", StudentSchema);
