import express from "express";
import cors from "cors";
import admin from "firebase-admin";
import { readFileSync } from "fs";

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(
    JSON.parse(readFileSync("./serviceAccountKey.json", "utf8"))
  ),
});

const db = admin.firestore();
const app = express();
app.use(cors());
app.use(express.json());

// Middleware: verify Firebase token an dparse user into req.user
async function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).send("Unauthorized");
  }
  const token = authHeader.split(" ")[1];
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).send("Invalid token");
  }
}

// Middleware: verify admin role
async function verifyAdmin(req, res, next) {
  try {
    const userDoc = await db.collection('users').doc(req.user.uid).get();
    if (!userDoc.exists) {
      return res.status(403).send('User profile not found');
    }
    
    const userData = userDoc.data();
    if (userData.role !== 'admin' && userData.role !== 'moderator') {
      return res.status(403).send('Admin privileges required');
    }
    
    req.userRole = userData.role;
    next();
  } catch (err) {
    return res.status(500).send('Error verifying admin status');
  }
}

// =============================================================================
// USER PROGRESS APIs (might be handled with firebase and flutter)
// =============================================================================

// Example protected API: get user progress
app.get("/progress", verifyToken, async (req, res) => {
  const userId = req.user.uid;
  const doc = await db.collection("userProgress").doc(userId).get();
  
  if (!doc.exists) {
    return res.json({ progress: 0, badges: [], recentActivity: [] });
  }
  
  res.json(doc.data());
});

// Example update route
app.post("/progress", verifyToken, async (req, res) => {
  const userId = req.user.uid;
  const { progress, badges, recentActivity } = req.body;

  await db.collection("userProgress").doc(userId).set({
    progress,
    badges,
    recentActivity,
  }, { merge: true });

  res.send("Progress updated!");
});

// =============================================================================
// ADMINISTRATIVE APIs
// =============================================================================

// Get system statistics
app.get('/admin/stats', verifyToken, verifyAdmin, async (req, res) => {
  try {
    const stats = await getSystemStats();
    res.json(stats);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all users with pagination
app.get('/admin/users', verifyToken, verifyAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, role, status } = req.query;
    const offset = (page - 1) * limit;
    
    let query = db.collection('users');
    
    if (role) {
      query = query.where('role', '==', role);
    }
    
    if (status) {
      query = query.where('status', '==', status);
    }
    
    const snapshot = await query
      .orderBy('joinedDate', 'desc')
      .limit(parseInt(limit))
      .offset(offset)
      .get();
    
    const users = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      // Remove sensitive data
      email: doc.data().email ? doc.data().email.replace(/(.{2}).*(@.*)/, '$1***$2') : null
    }));
    
    // Get total count
    const totalSnapshot = await db.collection('users').count().get();
    const total = totalSnapshot.data().count;
    
    res.json({
      users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user role or status
app.patch('/admin/users/:userId', verifyToken, verifyAdmin, async (req, res) => {
  try {
    const { userId } = req.params;
    const { role, status, reason } = req.body;
    
    const updates = {};
    if (role) updates.role = role;
    if (status) updates.status = status;
    
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'No valid updates provided' });
    }
    
    // Log the admin action
    await db.collection('adminActions').add({
      adminId: req.user.uid,
      action: 'user_update',
      targetUserId: userId,
      changes: updates,
      reason: reason || 'No reason provided',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    
    await db.collection('users').doc(userId).update({
      ...updates,
      lastModified: admin.firestore.FieldValue.serverTimestamp(),
      modifiedBy: req.user.uid
    });
    
    res.json({ success: true, message: 'User updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get reported content
app.get('/admin/reports', verifyToken, verifyAdmin, async (req, res) => {
  try {
    const { status = 'pending', limit = 20 } = req.query;
    
    const snapshot = await db.collection('reports')
      .where('status', '==', status)
      .orderBy('reportedAt', 'desc')
      .limit(parseInt(limit))
      .get();
    
    const reports = await Promise.all(
      snapshot.docs.map(async (doc) => {
        const reportData = doc.data();
        
        // Get reporter info (anonymized)
        const reporterDoc = await db.collection('users').doc(reportData.reportedBy).get();
        const reporterName = reporterDoc.exists ? reporterDoc.data().displayName || 'Anonymous' : 'Unknown';
        
        // Get content data based on type
        let contentData = null;
        if (reportData.contentType === 'post') {
          const postDoc = await db.collection('communityPosts').doc(reportData.contentId).get();
          if (postDoc.exists) {
            const postData = postDoc.data();
            contentData = {
              content: postData.content.substring(0, 100) + '...',
              authorId: postData.authorId,
              createdAt: postData.createdAt
            };
          }
        } else if (reportData.contentType === 'comment') {
          // Find comment across all posts (this could be optimized with better data structure)
          const postsSnapshot = await db.collection('communityPosts').get();
          for (const postDoc of postsSnapshot.docs) {
            const commentDoc = await db.collection('communityPosts')
              .doc(postDoc.id)
              .collection('comments')
              .doc(reportData.contentId)
              .get();
            if (commentDoc.exists) {
              const commentData = commentDoc.data();
              contentData = {
                content: commentData.content.substring(0, 100) + '...',
                authorId: commentData.authorId,
                createdAt: commentData.createdAt,
                postId: postDoc.id
              };
              break;
            }
          }
        }
        
        return {
          id: doc.id,
          ...reportData,
          reporterName,
          contentData
        };
      })
    );
    
    res.json(reports);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Handle report (approve/reject)
app.patch('/admin/reports/:reportId', verifyToken, verifyAdmin, async (req, res) => {
  try {
    const { reportId } = req.params;
    const { action, reason } = req.body; // action: 'approve', 'reject', 'dismiss'
    
    if (!['approve', 'reject', 'dismiss'].includes(action)) {
      return res.status(400).json({ error: 'Invalid action' });
    }
    
    const reportDoc = await db.collection('reports').doc(reportId).get();
    if (!reportDoc.exists) {
      return res.status(404).json({ error: 'Report not found' });
    }
    
    const reportData = reportDoc.data();
    
    // Update report status
    await db.collection('reports').doc(reportId).update({
      status: action === 'approve' ? 'approved' : action === 'reject' ? 'rejected' : 'dismissed',
      resolvedBy: req.user.uid,
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      resolution: reason || 'No reason provided'
    });
    
    // If approved, take action on the content
    if (action === 'approve') {
      if (reportData.contentType === 'post') {
        await db.collection('communityPosts').doc(reportData.contentId).update({
          isReported: true,
          moderatedBy: req.user.uid,
          moderatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      } else if (reportData.contentType === 'comment') {
        // Find and update comment
        const postsSnapshot = await db.collection('communityPosts').get();
        for (const postDoc of postsSnapshot.docs) {
          const commentRef = db.collection('communityPosts')
            .doc(postDoc.id)
            .collection('comments')
            .doc(reportData.contentId);
          const commentDoc = await commentRef.get();
          if (commentDoc.exists) {
            await commentRef.update({
              isReported: true,
              content: '[Content removed by moderator]',
              moderatedBy: req.user.uid,
              moderatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            break;
          }
        }
      }
    }
    
    // Log admin action
    await db.collection('adminActions').add({
      adminId: req.user.uid,
      action: 'report_resolved',
      reportId: reportId,
      resolution: action,
      reason: reason || 'No reason provided',
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    
    res.json({ success: true, message: `Report ${action}d successfully` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get community analytics
app.get('/admin/community-stats', verifyToken, verifyAdmin, async (req, res) => {
  try {
    const { period = '7d' } = req.query;
    const days = period === '7d' ? 7 : period === '30d' ? 30 : 90;
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    
    // Get posts count
    const postsSnapshot = await db.collection('communityPosts')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
      .get();
    
    // Get total users count
    const usersSnapshot = await db.collection('users').count().get();
    
    // Get active users (posted or commented in period)
    const activeUserIds = new Set();
    postsSnapshot.docs.forEach(doc => {
      activeUserIds.add(doc.data().authorId);
    });
    
    // Get comments count
    let totalComments = 0;
    for (const postDoc of postsSnapshot.docs) {
      const commentsSnapshot = await db.collection('communityPosts')
        .doc(postDoc.id)
        .collection('comments')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .get();
      totalComments += commentsSnapshot.size;
      
      // Add comment authors to active users
      commentsSnapshot.docs.forEach(commentDoc => {
        activeUserIds.add(commentDoc.data().authorId);
      });
    }
    
    res.json({
      period,
      totalUsers: usersSnapshot.data().count,
      activeUsers: activeUserIds.size,
      totalPosts: postsSnapshot.size,
      totalComments,
      engagementRate: usersSnapshot.data().count > 0 ? (activeUserIds.size / usersSnapshot.data().count * 100).toFixed(2) : 0
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get admin action logs
app.get('/admin/logs', verifyToken, verifyAdmin, async (req, res) => {
  try {
    const { limit = 50 } = req.query;
    
    const snapshot = await db.collection('adminActions')
      .orderBy('timestamp', 'desc')
      .limit(parseInt(limit))
      .get();
    
    const logs = await Promise.all(
      snapshot.docs.map(async (doc) => {
        const logData = doc.data();
        
        // Get admin info
        const adminDoc = await db.collection('users').doc(logData.adminId).get();
        const adminName = adminDoc.exists ? adminDoc.data().displayName || 'Unknown Admin' : 'Unknown';
        
        return {
          id: doc.id,
          ...logData,
          adminName,
          timestamp: logData.timestamp?.toDate() || null
        };
      })
    );
    
    res.json(logs);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

async function getSystemStats() {
  try {
    // Get total users
    const usersSnapshot = await db.collection('users').count().get();
    const totalUsers = usersSnapshot.data().count;
    
    // Get total posts
    const postsSnapshot = await db.collection('communityPosts').count().get();
    const totalPosts = postsSnapshot.data().count;
    
    // Get pending reports
    const reportsSnapshot = await db.collection('reports')
      .where('status', '==', 'pending')
      .count()
      .get();
    const pendingReports = reportsSnapshot.data().count;
    
    // Get user roles distribution
    const rolesSnapshot = await db.collection('users').get();
    const roleDistribution = {};
    rolesSnapshot.docs.forEach(doc => {
      const role = doc.data().role || 'student';
      roleDistribution[role] = (roleDistribution[role] || 0) + 1;
    });
    
    // Get recent activity (last 7 days)
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    
    const recentPostsSnapshot = await db.collection('communityPosts')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(weekAgo))
      .count()
      .get();
    const recentPosts = recentPostsSnapshot.data().count;
    
    const recentUsersSnapshot = await db.collection('users')
      .where('joinedDate', '>=', admin.firestore.Timestamp.fromDate(weekAgo))
      .count()
      .get();
    const newUsers = recentUsersSnapshot.data().count;
    
    return {
      totalUsers,
      totalPosts,
      pendingReports,
      roleDistribution,
      recentActivity: {
        newUsers,
        newPosts: recentPosts
      },
      systemHealth: {
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
      }
    };
  } catch (error) {
    throw new Error(`Failed to get system stats: ${error.message}`);
  }
}

app.listen(5000, () => console.log("🚀 Node.js API running at http://localhost:5000"));
