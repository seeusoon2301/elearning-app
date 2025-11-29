const Class = require('../models/Class');
const Student = require('../models/Student'); // Cần model Student để populate

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
                select: 'mssv name email', // Chọn các trường bạn muốn trả về
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

// Lưu ý: Các hàm khác liên quan đến Class (nếu có, như createClass, deleteClass)
// sẽ được thêm vào đây hoặc giữ nguyên trong classRoutes nếu bạn thích.
// Trong trường hợp này, tôi chỉ tạo hàm mới.