const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// MongoDB local hoặc Atlas
//mongoose.connect("mongodb://127.0.0.1:27017/classroom");

mongoose.connect("mongodb+srv://hoangthai2301_db_user:hoangthai2301@cluster0.ez8eahu.mongodb.net/users",
  { useNewUrlParser: true, useUnifiedTopology: true });

app.use("/api/auth", require("./src/routes/auth"));
app.use("/api/courses", require("./src/routes/course"));

app.get("/", (req, res) => {
  res.send("Server is running!");
});



app.listen(3000, () => console.log("API running on port 3000\nAPI LOGIN: http://localhost:3000/api/auth/login\nAPI REGISTER: http://localhost:3000/api/auth/login\nAPI COURSE: http://localhost:3000/api/courses"));
