# Smart Study App – Architecture & Guide

## 1. Tech Stack
- Flutter (Material 3)
- Firebase:
  - Auth (optional in future), Firestore (users/materials), Realtime Database (exam topics/questions), Storage (PDFs)
  - Firebase Core initialized via `lib/firebase_options.dart`
- HTTP (Gemini API)

## 2. App Flow
1) Role Selection → 2) Login → 3) Role Home
- Student → `StudentPage`
- Teacher → `TeacherPage`
- Admin → `AdminPanel`

Routing in `lib/main.dart`.

## 3. Data Model (Firestore)
- `users/{prn}`: { name, prn, role: 'student'|'teacher'|'admin', year, branch, semester, password }
- `materials/{subject}/chapters/{chapter}`: { notesUrl?, questionBankUrl?, syllabusUrl?, timestamp }

Realtime Database (optional, for exam):
- `materials/{subject}/chapters/{chapter}/topics`
- `questions/{subject}/{chapter}/{topic}` → { question, answer, marks }

## 4. Key Features
- Role selection (scrollable), role-based navigation
- Signup with dropdowns: year (1–4), semester (1–8)
- Upload materials:
  - URL or PDF
  - Web: bytes upload; Mobile: file upload
  - Size validation (≤10MB) and 60s timeout
- Exam section: fetch from DB or generate via Gemini

## 5. Important Files
- `lib/main.dart`: routes and theme
- `lib/screens/role_selection_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/signup_screen.dart`
- `lib/role/student_page.dart`, `lib/role/teacher_page.dart`, `lib/role/admin_panel.dart`
- `lib/material/uploadmaterial_page.dart` (URL/PDF upload)
- `lib/services/storage_service.dart` (Storage + picker)
- `lib/role/exam/gemini_service.dart` (Gemini API with fallbacks)

## 6. Environment Setup
- Ensure `google-services.json` (Android) and Firebase project set up
- Enable Firestore and Storage in Firebase Console
- Storage rules (dev, relax temporarily):
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true; // tighten before prod
    }
  }
}
```

## 7. Build & Deploy
### Android APK
1. In `android/app/build.gradle`, set applicationId/version.
2. Build:
```
flutter clean
flutter pub get
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Web
1. Build:
```
flutter clean
flutter pub get
flutter build web --release
```
Output: `build/web`

### Firebase Hosting (Web)
```
npm i -g firebase-tools
firebase login
firebase init hosting  # select your project, public dir: build/web, SPA: y
firebase deploy
```

## 8. Future Improvements
- Auth with FirebaseAuth instead of PRN/password in Firestore
- Per-role Storage/Firestore security rules
- Materials filtered by student year/semester
- Admin: edit users, bulk uploads


