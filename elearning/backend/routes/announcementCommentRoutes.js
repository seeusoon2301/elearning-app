
const express = require('express');
const router = express.Router();
const { addCommentToAnnouncement } = require('../controllers/AnnouncementController');

router.post(
    '/:classId/announcements/:announcementId/comments',
    addCommentToAnnouncement
);

module.exports = router;