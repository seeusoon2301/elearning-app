const Class = require('../models/Class');
const Student = require('../models/Student'); // Cần model Student để populate
const mongoose = require('mongoose');
// =========================================================================
// HÀM LẤY DANH SÁCH SINH VIÊN TRONG MỘT LỚP HỌC (GET /api/admin/classes/:classId/students)
// =========================================================================
exports.getStudentsInClass = async (req, res) => {
    try {
        const { classId } = req.params;

        // 1. Tìm lớp học theo ID và sử dụng .populate('students')
        // để thay thế mảng IDs bằng các đối tượng Student hoàn chỉnh.
        // Chọn các trường thông tin cần thiết của Student (ví dụ: mssv, name, email)
        const classData = await Class.findById(classId)
            .populate({
                path: 'students',
                select: 'mssv name email avatar', // Chọn các trường bạn muốn trả về
            })
            .select('students name -_id'); // Chỉ cần students, name và loại bỏ _id của Class

        if (!classData) {
            return res.status(404).json({
                success: false,
                message: 'Không tìm thấy lớp học.'
            });
        }

        // 2. Trả về mảng students đã được populate (điền đầy đủ thông tin)
        res.status(200).json({
            success: true,
            message: `Danh sách sinh viên trong lớp ${classData.name}`,
            data: classData.students // Trả về mảng student
        });

    } catch (error) {
        console.error("Lỗi khi lấy danh sách sinh viên:", error);
        // Xử lý lỗi server (ví dụ: ID không đúng định dạng MongoDB)
        res.status(500).json({
            success: false,
            message: error.message || 'Lỗi server khi lấy danh sách sinh viên.'
        });
    }
};

// =========================================================================
// HÀM LẤY DANH SÁCH LỚP HỌC THEO ID SINH VIÊN (GET /api/student/:studentId/classes)
// =========================================================================
exports.getClassesByStudentId = async (req, res) => {
    // ⭐️ LẤY studentId TỪ PARAMETER CỦA URL
    const { studentId } = req.params; 
    // ⭐️ LẤY semesterId TỪ QUERY PARAMETER (TÙY CHỌN)
    const { semesterId } = req.query;

    // Kiểm tra tính hợp lệ của studentId
    if (!mongoose.Types.ObjectId.isValid(studentId)) {
        return res.status(400).json({ success: false, message: 'ID sinh viên không hợp lệ.' });
    }

    try {
        // 1. Khởi tạo điều kiện lọc cho các khóa học
        let matchCondition = {};
        if (semesterId && mongoose.Types.ObjectId.isValid(semesterId)) {
            // Nếu có semesterId hợp lệ, thêm điều kiện lọc theo semester
            matchCondition = { semester: semesterId };
        } else if (semesterId) {
            // Xử lý trường hợp semesterId được cung cấp nhưng không hợp lệ
            return res.status(400).json({ success: false, message: 'ID học kỳ không hợp lệ.' });
        }


        // 2. TÌM STUDENT theo ID và Populate mảng 'courses'
        // Sử dụng matchCondition trong quá trình populate
        const studentData = await Student.findById(studentId)
            .select('courses') 
            .populate({
                path: 'courses', 
                model: 'Class', 
                // ⭐️ THÊM ĐIỀU KIỆN LỌC (MATCH)
                match: matchCondition, 
                // Populate thêm thông tin Giảng viên (tên và email)
                populate: {
                    path: 'instructor', 
                    select: 'name email' 
                }
            }); 
            
        if (!studentData) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy thông tin sinh viên.' });
        }

        // 3. Trả về mảng courses
        // Lưu ý: Mongoose populate với match có thể trả về null trong mảng courses
        // nếu một courseId không khớp với điều kiện. Cần lọc bỏ các giá trị null.
        const filteredCourses = studentData.courses.filter(course => course !== null);
        
        res.status(200).json({
            success: true,
            data: filteredCourses 
        });

    } catch (error) {
        console.error("Lỗi khi tải lớp học của sinh viên:", error);
        res.status(500).json({ success: false, message: 'Lỗi server khi tải danh sách lớp học.' });
    }
};