# 🔧 Firestore Setup and Troubleshooting Guide

## 🚨 Permission Error Fix

You're getting the permission error because the Firestore security rules need to be updated to allow the new community features. Here's how to fix it:

### Step 1: Deploy Security Rules

**Option A: Using PowerShell Script (Recommended)**
```powershell
# Run this in your project root directory
.\deploy_firestore_rules.ps1
```

**Option B: Manual Deployment**
```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project (if not done)
firebase init firestore

# Deploy the rules
firebase deploy --only firestore
```

### Step 2: Verify Rules Deployment

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your `mil-hub` project
3. Navigate to **Firestore Database** → **Rules**
4. Ensure the rules are updated with the new community permissions

### Step 3: Test the Community Features

After deploying the rules, try:
1. Creating a new post
2. Liking a post
3. Adding comments
4. Viewing posts

## 🔒 Security Rules Explanation

The new security rules allow:

### Posts (`communityPosts` collection):
- ✅ **Read**: Authenticated users can read public posts and their own posts
- ✅ **Create**: Authenticated users can create posts with valid data
- ✅ **Update**: Only post owners can update specific fields (likes, comments, etc.)
- ✅ **Delete**: Only post owners can delete their posts

### Comments (`comments` subcollection):
- ✅ **Read**: All authenticated users can read comments
- ✅ **Create**: Authenticated users can create comments with valid data
- ✅ **Update**: Only comment owners can update their comments
- ✅ **Delete**: Only comment owners can delete their comments

### Likes (`likes` subcollection):
- ✅ **Read**: All authenticated users can read likes
- ✅ **Create/Update/Delete**: Users can only manage their own likes

### User Stats (`userCommunityStats` collection):
- ✅ **Read**: Users can read their own stats or public stats
- ✅ **Create/Update**: Users can only update their own stats
- ❌ **Delete**: Stats cannot be deleted

## 🛠️ Troubleshooting Common Issues

### Issue 1: "Firebase CLI not found"
```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Or using yarn
yarn global add firebase-tools
```

### Issue 2: "Not logged in to Firebase"
```bash
firebase login
```

### Issue 3: "Project not found"
```bash
# List your projects
firebase projects:list

# Use the correct project
firebase use mil-hub
```

### Issue 4: "Index required" errors
The indexes are automatically created when you deploy. If you get index errors:
1. Click the provided link in the error message
2. Wait for the index to build (can take a few minutes)
3. Try the operation again

### Issue 5: Still getting permission errors
1. **Check user authentication**:
   ```dart
   final user = FirebaseAuth.instance.currentUser;
   print('User: ${user?.uid}'); // Should not be null
   ```

2. **Verify rules deployment**:
   - Check Firebase Console → Firestore → Rules
   - Rules should show the updated timestamp

3. **Clear app data and restart**:
   - Uninstall and reinstall the app
   - This clears any cached permissions

## 🧪 Testing Security Rules Locally

You can test the rules locally before deploying:

```bash
# Start the Firestore emulator
firebase emulators:start --only firestore

# In another terminal, run your tests
firebase emulators:exec --only firestore "flutter test"
```

## 📋 Required Fields Validation

The security rules validate that posts and comments have required fields:

### Post Requirements:
- `content`: String (1-1000 characters)
- `authorId`: String (must match authenticated user)
- `authorName`: String
- `type`: One of ['text', 'image', 'video', 'poll']
- `privacy`: One of ['public', 'friends', 'private']
- `tags`: Array (max 5 items)
- `likeCount`, `commentCount`, `shareCount`, `viewCount`: Non-negative integers
- `likedBy`: Array
- `createdAt`: Timestamp

### Comment Requirements:
- `content`: String (1-500 characters)
- `postId`: String
- `authorId`: String (must match authenticated user)
- `authorName`: String
- `type`: One of ['text', 'image', 'gif', 'sticker']
- `reactions`: Map
- `userReactions`: Map
- `replyCount`: Non-negative integer
- `createdAt`: Timestamp

## 🚀 Next Steps

After deploying the rules:

1. **Test all community features**
2. **Monitor Firebase Console for any errors**
3. **Add any additional collections you need**
4. **Consider adding admin rules for moderation**

## 📞 Support

If you continue to have issues:

1. **Check Firebase Console logs**
2. **Verify your Firebase project configuration**
3. **Ensure you're using the correct project ID: `mil-hub`**
4. **Test with a simple read/write operation first**

---

Remember: Always test security rules thoroughly before deploying to production!