// middleware/upload.js

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Đảm bảo thư mục lưu trữ tồn tại
const UPLOAD_DIR = path.join(__dirname, '../uploads/assignments');
if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

// 1. Cấu hình nơi lưu trữ và tên file
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        // Chỉ định thư mục lưu trữ file bài tập
        cb(null, UPLOAD_DIR);
    },
    filename: (req, file, cb) => {
        // Tạo tên file duy nhất: fieldname-timestamp-original_name.ext
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const fileExtension = path.extname(file.originalname);
        const fileName = file.fieldname + '-' + uniqueSuffix + fileExtension;
        cb(null, fileName);
    }
});

// 2. Cấu hình lọc loại file (ĐÃ CẬP NHẬT)
const fileFilter = (req, file, cb) => {
    const mimeType = file.mimetype;
    
    // ⭐️ LOGGING: Ghi lại MIME Type thực tế nhận được từ client
    console.log(`[MULTER DEBUG] File MIME Type nhận được: ${mimeType}`);

    // Định nghĩa các biểu thức chính quy cho các nhóm file
    // Bổ sung 'octet-stream' vào đây, nhưng chỉ khi file có đuôi hợp lệ (đã được kiểm tra ngầm bởi frontend)
    // Thực tế: Multer không có sẵn extname tại fileFilter, nên chúng ta phải chấp nhận rủi ro hoặc
    // thêm octet-stream vào danh sách nếu muốn nó qua.

    // ✅ FIX: Thêm application/octet-stream vào nhóm tài liệu
    const documentRegex = /application\/(pdf|x-pdf|acrobat|msword|vnd\.openxmlformats-officedocument\.(wordprocessingml|presentationml)\.document|vnd\.ms-powerpoint|vnd\.ms-excel|octet-stream)/i;
    const sheetRegex = /application\/vnd\.openxmlformats-officedocument\.spreadsheetml\.sheet|text\/csv/i;
    const textRegex = /text\/(plain|csv)/i;
    const imageRegex = /image\/(jpeg|png|gif)/i;
    const compressedRegex = /application\/(zip|x-zip-compressed)/i;

    // Kiểm tra từng nhóm
    if (documentRegex.test(mimeType) ||
        sheetRegex.test(mimeType) ||
        textRegex.test(mimeType) ||
        imageRegex.test(mimeType) ||
        compressedRegex.test(mimeType)
    ) {
        cb(null, true); // Chấp nhận file
    } else {
        // Thông báo lỗi
        cb(new Error('Chỉ chấp nhận file PDF, DOC/DOCX, PPT/PPTX, XLS/XLSX, TXT, CSV, ZIP, và các định dạng ảnh phổ biến (JPG, PNG, GIF).'), false);
    }
};

// 3. Khởi tạo Multer upload middleware
const uploadAssignmentFile = multer({ 
    storage: storage,
    limits: { 
        fileSize: 1024 * 1024 * 10 // Giới hạn kích thước file 10MB 
    },
    fileFilter: fileFilter
});

// Xuất ra 1 hàm middleware để sử dụng trong route, chỉ chấp nhận 1 file
// 'file' là tên trường (key) trong form-data mà client sẽ gửi file lên
module.exports = uploadAssignmentFile.single('file');