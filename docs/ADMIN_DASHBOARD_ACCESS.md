# Admin Dashboard Access Guide

This document provides detailed information on how to access and use the Admin Dashboard in the MIL Hub application.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Accessing the Admin Dashboard](#accessing-the-admin-dashboard)
4. [Admin Dashboard Features](#admin-dashboard-features)
5. [Admin Roles and Permissions](#admin-roles-and-permissions)
6. [Troubleshooting](#troubleshooting)

## Overview

The Admin Dashboard is a specialized interface within the MIL Hub application that provides administrative users with tools to manage the platform, monitor system performance, and oversee user activities. It is only accessible to users with proper administrative privileges.

## Prerequisites

To access the Admin Dashboard, you must meet the following requirements:

1. **Admin Account**: You must be logged in with an account that has administrative privileges
2. **Backend Server**: The Node.js administrative server must be running (`http://localhost:5000`)
3. **Network Connectivity**: Stable internet connection to communicate with Firebase and the admin server
4. **Authentication**: Valid Firebase authentication session

## Accessing the Admin Dashboard

### Step-by-Step Access Process

1. **Login with Admin Credentials**
   - Open the MIL Hub application
   - Log in using credentials associated with an admin account
   - Ensure you're using an account with the proper role/permissions

2. **Navigate to User Dashboard**
   - After successful authentication, you'll be directed to your personal dashboard
   - The dashboard automatically checks your permissions

3. **Locate Admin Panel Widget**
   - On the Enhanced User Dashboard, look for the "Admin Panel" card
   - This card only appears for users with administrative privileges
   - The card features:
     - Admin panel icon
     - Title: "Admin Panel"
     - Description: "Manage users, review reports & system analytics"
     - Forward arrow indicator

4. **Access the Dashboard**
   - Tap/click on the "Admin Panel" card
   - You'll be navigated to the full Admin Dashboard with a smooth transition animation
   - The dashboard will load system statistics and analytics

### Technical Implementation Details

The admin access system works through the following components:

- **AdminAccessWidget**: A widget that checks user permissions and displays the admin panel card
- **AdminService.isAdmin()**: Method that verifies admin privileges by making an API call to `/admin/stats`
- **AdminDashboard**: The main administrative interface screen

## Admin Dashboard Features

### System Overview
- **Total Users**: Displays the total number of registered users with recent signups
- **Total Posts**: Shows community posts count with recent activity
- **Pending Reports**: Highlights content reports awaiting moderation
- **System Health**: Indicates overall system status and uptime

### Quick Actions
- **Manage Users**: Access user management interface
- **Review Reports**: View and process content reports
- **View Logs**: Access administrative activity logs
- **Export Data**: Initiate data export processes

### Community Analytics
- Interactive charts showing community engagement metrics
- Filterable by time periods (7 days, 30 days, 90 days)

### System Status
- Real-time display of system component statuses
- Manual refresh capability

## Admin Roles and Permissions

The admin system supports different levels of administrative access:

1. **Super Admin**: Full access to all administrative features
2. **Content Moderator**: Access to user management and content moderation
3. **Analytics Viewer**: Read-only access to system analytics and reports

Permissions are verified through the backend API, which checks the user's role in the Firebase authentication system.

## Troubleshooting

### Common Issues and Solutions

1. **Admin Panel Not Visible**
   - Ensure you're logged in with an admin account
   - Verify the backend server is running
   - Check network connectivity
   - Try refreshing the dashboard

2. **Dashboard Loading Errors**
   - Check that the Node.js server is running on port 5000
   - Verify Firebase authentication is working
   - Ensure the user has proper admin privileges

3. **Permission Denied Errors**
   - Confirm your account has administrative privileges
   - Contact system administrator to verify role assignment
   - Check Firebase user claims for admin role

### Server Requirements

For the admin dashboard to function properly:
- Node.js server must be running (`npm start` in the server directory)
- Firebase service account key must be properly configured
- Network access to `http://localhost:5000` must be available

## Security Considerations

- Admin access is protected by role-based authentication
- All admin API calls require valid Firebase authentication tokens
- Sensitive operations are logged for audit purposes
- Data exports require explicit user confirmation

## Additional Resources

- [Main README](../README.md)
- [Architecture Documentation](ARCHITECTURE_STATUS.md)
- [Security Features](SECURITY_FEATURES_SUMMARY.md)