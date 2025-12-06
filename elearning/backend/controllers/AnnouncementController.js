const Announcement = require('../models/Announcement');
const Class = require('../models/Class');
const Student = require('../models/Student');
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
            .populate({
                    path: 'comments.user', // 👈 Đảm bảo path trỏ đúng đến 'user' trong mảng 'comments'
                    select: 'name mssv', // 👈 Chỉ lấy các trường cần thiết (ví dụ: tên và mssv)
                })
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

// @desc    Thêm bình luận vào một bảng tin
// @route   POST /api/classes/:classId/announcements/:announcementId/comments
// @access  Authenticated (Student/Instructor)
exports.addCommentToAnnouncement = async (req, res) => {
    // ⭐️ THAY ĐỔI: Lấy userId trực tiếp từ body
    const { content, userId } = req.body; 
    const { announcementId } = req.params;

    if (!content || !userId) {
        return res.status(400).json({ success: false, message: 'Nội dung bình luận và ID người dùng là bắt buộc.' });
    }
    
    // 1. Kiểm tra tính hợp lệ của ID
    if (!mongoose.Types.ObjectId.isValid(announcementId) || !mongoose.Types.ObjectId.isValid(userId)) {
        return res.status(400).json({ success: false, message: 'ID bảng tin hoặc ID người dùng không hợp lệ.' });
    }

    try {
        // Tùy chọn: Kiểm tra xem userId có tồn tại trong Student/User model không
        const userExists = await Student.findById(userId); // Hoặc model User của bạn
        if (!userExists) {
             return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng (userId) này.' });
        }

        // 2. Tìm và cập nhật bảng tin
        const announcement = await Announcement.findById(announcementId);

        if (!announcement) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy bảng tin.' });
        }

        // 3. Tạo đối tượng bình luận mới
        const newComment = {
            user: userId, // ID của sinh viên được gửi trong body
            content: content,
        };

        // 4. Thêm bình luận vào mảng và lưu
        announcement.comments.push(newComment);
        await announcement.save();

        // 5. Populate người dùng cho bình luận mới nhất trước khi trả về
        const latestComment = announcement.comments[announcement.comments.length - 1];
        
        // Populate (truy xuất thông tin người dùng)
        await Announcement.populate(latestComment, { path: 'user', select: 'name mssv email' }); 

        res.status(201).json({
            success: true,
            message: 'Bình luận đã được thêm thành công.',
            data: latestComment,
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: 'Lỗi server khi thêm bình luận.', error: error.message });
    }
};