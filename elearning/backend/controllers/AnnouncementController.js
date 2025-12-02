const Announcement = require('../models/Announcement');
const Class = require('../models/Class'); // Cần model Class để kiểm tra quyền (nhưng logic kiểm tra đã bị loại bỏ)
const mongoose = require('mongoose');

// @desc    Đăng một bảng tin mới cho lớp học
// @route   POST /api/classes/:classId/announcements
// @access  Public (Không có xác thực quyền)
exports.createAnnouncement = async (req, res) => {
    // 🔑 Đã loại bỏ KIỂM TRA BẢO MẬT (req.user) theo yêu cầu đơn giản hóa
    
    // 1. Lấy thông tin cần thiết
    const { classId } = req.params;
    const { content } = req.body;
    
    // const userId = req.user._id; // Đã loại bỏ
    
    // Kiểm tra tính hợp lệ của classId
    if (!mongoose.Types.ObjectId.isValid(classId)) {
        return res.status(400).json({ success: false, message: 'ID lớp học không hợp lệ.' });
    }

    try {
        // 2. TÌM LỚP HỌC (vẫn cần để kiểm tra lớp có tồn tại không)
        const targetClass = await Class.findById(classId);
        
        if (!targetClass) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy lớp học.' });
        }

        // 3. ĐÃ LOẠI BỎ logic xác minh quyền: Giảng viên hay không
        
        // 4. Tạo bảng tin mới (Chỉ cần classId và content)
        const newAnnouncement = await Announcement.create({
            classId,
            content,
        });

        // 5. Trả về phản hồi thành công (Mã 201 Created)
        res.status(201).json({
            success: true,
            message: 'Đăng bảng tin thành công.',
            data: newAnnouncement,
        });

    } catch (error) {
        // Xử lý lỗi validation hoặc lỗi database khác
        if (error.name === 'ValidationError') {
            const messages = Object.values(error.errors).map(val => val.message);
            return res.status(400).json({ success: false, message: messages.join(', ') });
        }
        console.error("Lỗi khi tạo bảng tin:", error);
        res.status(500).json({ success: false, message: 'Lỗi máy chủ nội bộ.' });
    }
};

// @desc    Lấy danh sách bảng tin của một lớp học
// @route   GET /api/admin/classes/:classId/announcements
// @access  Public (Không có xác thực quyền)
exports.getAnnouncementsByClass = async (req, res) => {
    // 🔑 Đã loại bỏ KIỂM TRA BẢO MẬT (req.user) theo yêu cầu đơn giản hóa
    
    const { classId } = req.params;
    // const userId = req.user._id; // Đã loại bỏ

    // Kiểm tra tính hợp lệ của classId
    if (!mongoose.Types.ObjectId.isValid(classId)) {
        return res.status(400).json({ success: false, message: 'ID lớp học không hợp lệ.' });
    }

    try {
        // 1. TÌM LỚP HỌC (vẫn cần để kiểm tra lớp có tồn tại không)
        const targetClass = await Class.findById(classId);

        if (!targetClass) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy lớp học.' });
        }
        
        // 2. ĐÃ LOẠI BỎ logic xác minh quyền: Giảng viên hoặc Sinh viên của lớp
        
        // 3. Thiết lập điều kiện truy vấn (filter)
        const filter = { classId };
        
        // 4. Thực hiện truy vấn: Lấy tất cả bảng tin, sắp xếp theo thời gian mới nhất (createdAt: -1)
        const announcements = await Announcement.find(filter)
            .sort({ createdAt: -1 }) 
            .limit(50); 

        // 5. Trả về phản hồi thành công
        res.status(200).json({
            success: true,
            count: announcements.length,
            data: announcements,
        });

    } catch (error) {
        console.error("Lỗi khi tải bảng tin:", error);
        res.status(500).json({ success: false, message: 'Lỗi máy chủ nội bộ.' });
    }
};