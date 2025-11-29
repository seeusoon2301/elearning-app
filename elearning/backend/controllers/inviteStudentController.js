const Student = require('../models/Student');
const Class = require('../models/Class');

// ==========================
//  MỜI SINH VIÊN VÀO LỚP HỌC
// ==========================
exports.inviteStudent = async (req, res) => {
  try {
    const { classId } = req.params;
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: "Email là bắt buộc." });
    }

    // 1. Tìm student theo email
    const student = await Student.findOne({ email });

    if (!student) {
      return res.status(404).json({ error: "Student không tồn tại trong hệ thống." });
    }

    // 2. Tìm class
    const classData = await Class.findById(classId);

    if (!classData) {
      return res.status(404).json({ error: "Class không tồn tại." });
    }

    // 3. Kiểm tra nếu đã trong lớp
    if (classData.students.includes(student._id)) {
      return res.status(400).json({ error: "Student đã có trong lớp này." });
    }

    // 4. Thêm student vào lớp
    classData.students.push(student._id);
    await classData.save();
    student.courses.push(classId);
    await student.save();
    res.json({
      message: "Thêm học viên vào lớp thành công.",
      student: {
        id: student._id,
        name: student.name,
        mssv: student.mssv,
        email: student.email
      }
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
// ===============================================
// LẤY DANH SÁCH SINH VIÊN TRONG LỚP (API MỚI)
// ===============================================
exports.fetchStudents = async (req, res) => {
    try {
        const { classId } = req.params;

        // 1. Tìm class và populate (điền đầy) thông tin students
        const classData = await Class.findById(classId)
            // Lấy các trường cần thiết: name, email, và mssv từ model Student
            .populate('students', 'name email mssv') 
            .select('name students'); // Chỉ cần tên lớp và danh sách students

        if (!classData) {
            return res.status(404).json({ error: "Class không tồn tại." });
        }

        // Trả về danh sách students đã được populate
        // classData.students là một mảng các đối tượng Student hoàn chỉnh
        res.json({
            message: "Lấy danh sách học viên thành công.",
            students: classData.students
        });

    } catch (err) {
        // Xử lý lỗi khi ID không hợp lệ, lỗi server, v.v.
        console.error("Lỗi khi fetch students:", err);
        res.status(500).json({ error: err.message || "Lỗi server khi lấy danh sách học viên." });
    }
};