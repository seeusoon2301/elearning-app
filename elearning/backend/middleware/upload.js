const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../config/cloudinary');

// =========================================================================
// CẤU HÌNH UPLOAD ASSIGNMENT (LƯU CỤC BỘ) - GIỮ NGUYÊN
// =========================================================================

// const ASSIGNMENT_UPLOAD_DIR = path.join(__dirname, '../uploads/assignments');
// if (!fs.existsSync(ASSIGNMENT_UPLOAD_DIR)) {
//     fs.mkdirSync(ASSIGNMENT_UPLOAD_DIR, { recursive: true });
// }

const assignmentCloudinaryStorage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
        folder: 'elearning_assignments', // Thư mục lưu bài tập trên Cloudinary
        resource_type: 'raw', // Tự động nhận diện loại resource (raw, image, video,...)
        public_id: (req, file) => {
            const fileExtension = path.extname(file.originalname);
            const fileNameWithoutExt = path.basename(file.originalname, fileExtension);
            // Tạo ID duy nhất dựa trên tên file và thời gian
            return `${fileNameWithoutExt.replace(/[^a-z0-9]/gi, '_')}-${Date.now()}${fileExtension}`;
        },
    },
});


const assignmentUpload = multer({
    storage: assignmentCloudinaryStorage,
    limits: { fileSize: 1000 * 1024 * 1024 }, // Giới hạn 10MB
    // Giữ nguyên file filter nếu cần giới hạn loại file (ví dụ: chỉ PDF, DOCX)
    // Nếu bạn muốn chấp nhận mọi loại file tài liệu, bạn có thể bỏ qua fileFilter
    // (tùy vào `assignmentFileFilter` cũ của bạn)
    
});

// ⭐️ NAMED EXPORT cho Assignment
exports.uploadAssignment = assignmentUpload.single('file');


// =========================================================================
// CẤU HÌNH UPLOAD AVATAR (CHUYỂN SANG CLOUDINARY)
// =========================================================================

// 1. Loại bỏ AVATAR_UPLOAD_DIR, fs.mkdirSync (không cần lưu cục bộ)
// 2. Định nghĩa storage sử dụng CloudinaryStorage
const avatarCloudinaryStorage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
        folder: 'elearning_avatars', // Thư mục lưu trên Cloudinary
        // 🌟 Định dạng file nên dùng dynamic (dựa vào file gốc) hoặc jpg/webp để tối ưu dung lượng.
        // Tuy nhiên, giữ nguyên 'png' như cấu hình của bạn.
        format: async (req, file) => 'png', 
        // Public ID giúp dễ dàng xóa file sau này, cần duy nhất
        public_id: (req, file) => `avatar-${req.params.studentId}-${Date.now()}`,
    },
});

const avatarFileFilter = (req, file, cb) => {
    const mimeType = file.mimetype;
    const imageRegex = /image\/(jpeg|png|gif|webp)/i;

    if (imageRegex.test(mimeType)) {
        cb(null, true);
    } else {
        cb(new Error('Chỉ chấp nhận file ảnh (JPG, PNG, GIF, WebP).'), false);
    }
};

// ⭐️ NAMED EXPORT cho Avatar sử dụng CloudinaryStorage
exports.uploadAvatar = multer({ 
    // Thay thế avatarStorage bằng avatarCloudinaryStorage
    storage: avatarCloudinaryStorage, 
    limits: { fileSize: 5 * 1024 * 1024 }, 
    fileFilter: avatarFileFilter,
}).single('newAvatar');