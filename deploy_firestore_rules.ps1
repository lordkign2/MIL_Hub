# PowerShell script to deploy Firestore security rules
# Run this script from the project root directory

Write-Host "🚀 Deploying Firestore Security Rules..." -ForegroundColor Green

# Check if Firebase CLI is installed
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Firebase CLI is not installed!" -ForegroundColor Red
    Write-Host "Please install it with: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Check if user is logged in
$loginStatus = firebase projects:list 2>&1
if ($loginStatus -match "Error") {
    Write-Host "❌ You are not logged in to Firebase!" -ForegroundColor Red
    Write-Host "Please login with: firebase login" -ForegroundColor Yellow
    exit 1
}

# Set the Firebase project
Write-Host "🔧 Setting Firebase project to mil-hub..." -ForegroundColor Blue
firebase use mil-hub

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to set Firebase project!" -ForegroundColor Red
    Write-Host "Please make sure you have access to the 'mil-hub' project." -ForegroundColor Yellow
    exit 1
}

# Deploy Firestore rules
Write-Host "📋 Deploying Firestore rules and indexes..." -ForegroundColor Blue
firebase deploy --only firestore

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Firestore rules deployed successfully!" -ForegroundColor Green
    Write-Host "🎉 Your community features should now work properly!" -ForegroundColor Cyan
    Write-Host "" 
    Write-Host "🔍 What was deployed:" -ForegroundColor Yellow
    Write-Host "  • Simplified security rules (testing-friendly)" -ForegroundColor White
    Write-Host "  • Database indexes for optimal performance" -ForegroundColor White
    Write-Host "  • Permissions for posts, comments, and likes" -ForegroundColor White
    Write-Host ""
    Write-Host "🧪 Try these actions in your app:" -ForegroundColor Yellow
    Write-Host "  • Create a new post" -ForegroundColor White
    Write-Host "  • Like a post" -ForegroundColor White
    Write-Host "  • Add a comment" -ForegroundColor White
    Write-Host "  • View the community feed" -ForegroundColor White
} else {
    Write-Host "❌ Failed to deploy Firestore rules!" -ForegroundColor Red
    Write-Host "Please check your Firebase project configuration." -ForegroundColor Yellow
    Write-Host "" 
    Write-Host "🔧 Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "  1. Check if you have the correct permissions" -ForegroundColor White
    Write-Host "  2. Verify the project ID is 'mil-hub'" -ForegroundColor White
    Write-Host "  3. Try: firebase login --reauth" -ForegroundColor White
}

# Optional: Test the rules
Write-Host ""
Write-Host "🧪 To test rules locally, run:" -ForegroundColor Blue
Write-Host "firebase emulators:start --only firestore" -ForegroundColor White