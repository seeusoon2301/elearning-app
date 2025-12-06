const Student = require('../models/Student');
const mongoose = require('mongoose');
// 🛑 KHÔNG CẦN fs/path nữa vì không còn xử lý file cục bộ
// const fs = require('fs'); 
// const path = require('path'); 
const cloudinary = require('../config/cloudinary'); // 🌟 IMPORT CLOUDINARY ĐỂ XỬ LÝ VIỆC XÓA

// =========================================================================
// HÀM TIỆN ÍCH: Lấy Public ID từ URL Cloudinary
// =========================================================================
const getPublicIdFromUrl = (url) => {
    if (!url || !url.includes('cloudinary')) return null;

    // Phân tích URL: https://res.cloudinary.com/.../elearning_avatars/public_id.png
    const parts = url.split('/');
    // Thư mục Cloudinary của bạn (ví dụ: elearning_avatars)
    const folderNameIndex = parts.indexOf('elearning_avatars'); 
    
    if (folderNameIndex === -1 || folderNameIndex + 1 >= parts.length) {
        return null;
    }

    // Lấy phần 'elearning_avatars/public_id'
    const publicIdWithExtension = parts[folderNameIndex + 1];
    
    // Loại bỏ đuôi mở rộng (.png, .jpg)
    const publicId = publicIdWithExtension.split('.')[0]; 

    return `elearning_avatars/${publicId}`; 
};


// =========================================================================
// HÀM GỘP: CẬP NHẬT TÊN VÀ AVATAR (PUT /api/student/:studentId/profile)
// =========================================================================
exports.updateStudentProfile = async (req, res) => {
    const { studentId } = req.params;
    const { name } = req.body; 
    const avatarFile = req.file; // File avatar do CloudinaryStorage cung cấp

    const updateFields = {};
    let newAvatarUrl = null; 
    let oldAvatarUrl = null; 
    let student = null;
    const DEFAULT_AVATAR_PATH = 'default-avatar.png'; // Giả định chuỗi mặc định, không cần là URL đầy đủ

    // 1. Kiểm tra tính hợp lệ của ID
    if (!mongoose.Types.ObjectId.isValid(studentId)) {
        // Nếu có lỗi, cần xóa ảnh vừa upload lên Cloudinary ngay lập tức
        if (avatarFile) {
            await cloudinary.uploader.destroy(avatarFile.filename); 
        }
        return res.status(400).json({ success: false, message: 'ID sinh viên không hợp lệ.' });
    }

    try {
        // 2. Xử lý trường TÊN (nếu có)
        if (name && name.trim() !== '') {
            updateFields.name = name.trim();
        }

        // 3. Xử lý trường AVATAR (nếu có file được upload)
        if (avatarFile) {
            // Tìm student hiện tại để lấy URL avatar cũ
            student = await Student.findById(studentId).select('avatar');
            if (!student) {
                // Xóa file vừa upload lên Cloudinary nếu không tìm thấy sinh viên
                await cloudinary.uploader.destroy(avatarFile.filename);
                return res.status(404).json({ success: false, message: 'Không tìm thấy thông tin sinh viên.' });
            }
            
            oldAvatarUrl = student.avatar;
            // 🌟 LƯU URL CỦA CLOUDINARY VÀO DB
            // req.file.path (do multer-storage-cloudinary cung cấp) chính là secure_url
            newAvatarUrl = avatarFile.path; 
            updateFields.avatar = newAvatarUrl;
        } 
        else if (Object.keys(updateFields).length === 0) {
              return res.status(400).json({ success: false, message: 'Không có dữ liệu nào được cung cấp để cập nhật.' });
        }


        // 4. Cập nhật Student trong Database
        const updatedStudent = await Student.findByIdAndUpdate(
            studentId,
            updateFields,
            { 
                new: true, 
                runValidators: true, 
                select: 'mssv name email avatar' // 🌟 Đảm bảo 'avatar' được chọn để trả về
            } 
        );

        // 5. Nếu có avatar mới, XÓA AVATAR CŨ TRÊN CLOUDINARY
        if (newAvatarUrl && oldAvatarUrl && !oldAvatarUrl.includes(DEFAULT_AVATAR_PATH)) {
            try {
                // Lấy Public ID để xóa file cũ
                const publicId = getPublicIdFromUrl(oldAvatarUrl);
                if (publicId) {
                    const deletionResult = await cloudinary.uploader.destroy(publicId); 
                    console.log(`Đã xóa avatar cũ trên Cloudinary (${publicId}):`, deletionResult);
                }
            } catch (deleteError) {
                console.error('Lỗi khi xóa avatar cũ trên Cloudinary:', deleteError);
            }
        }

        // 6. Trả về kết quả
        // 🌟 updatedStudent.avatar đã chứa URL Cloudinary hoàn chỉnh
        res.status(200).json({
            success: true,
            message: 'Cập nhật thông tin sinh viên thành công.',
            data: updatedStudent, 
        });

    } catch (error) {
        console.error('Lỗi khi cập nhật profile:', error);
        
        // Xóa file vừa upload lên Cloudinary nếu có lỗi hệ thống (ví dụ: lỗi DB, lỗi kết nối)
        if (avatarFile) {
             await cloudinary.uploader.destroy(avatarFile.filename); 
        }
        res.status(500).json({ success: false, message: `Lỗi máy chủ: ${error.message}` });
    }
};