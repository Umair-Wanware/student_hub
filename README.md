# 🎓 Student Hub

**A student productivity app designed to help students organize their academic life in one place.**

Student Hub is a Flutter-based application that brings task management, attendance tracking, study sessions, and note-taking together in a single interface. It combines a modern user experience with backend API integration to help students stay organized and focused.

## ✨ Features

- **🔐 Authentication** — Sign in and manage your account.
- **📊 Dashboard** — Access key features from a central dashboard.
- **✅ Task Management** — Create, update, search, complete, and delete tasks.
- **📅 Attendance Tracking** — Keep track of academic attendance.
- **⏱️ Focus Zone** — Organize study sessions and support focused learning.
- **📝 Notes** — Manage study notes in one place.
- **👤 Profile Management** — Access and manage your profile.
- **🎨 Modern UI** — Dark-themed design with gradient accents, frosted-glass panels, and interactive elements.

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application UI |
| Dart | Application programming language |
| REST API | Communication with the backend |
| Dio | HTTP requests and API integration |
| Cookie management | Handling API session cookies |

**Backend API:** [Student Hub API](https://student-hub-dckn.onrender.com)

> The backend URL is included as the project endpoint. Confirm that the service is currently running and that it is the correct public endpoint before publishing.

## 🖼️ Screenshots

Add screenshots of your actual application here to showcase its interface.

| Dashboard | My Tasks |
|---|---|
| Add dashboard screenshot | Add tasks screenshot |

| Attendance | Focus Zone |
|---|---|
| Add attendance screenshot | Add focus-session screenshot |

| Notes | Profile |
|---|---|
| Add notes screenshot | Add profile screenshot |

To add screenshots, create a `screenshots/` directory in the repository and replace the placeholders above with Markdown image links, for example:

`![Student Hub Dashboard](screenshots/dashboard.png)`

## 🚀 Getting Started

### Prerequisites

Install the following before running the project:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Git](https://git-scm.com/)
- An IDE such as [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)

Verify your Flutter installation:

```bash
flutter doctor
```

### Installation

1. Clone the repository:

   ```bash
   git clone <YOUR_GITHUB_REPOSITORY_URL>
   ```

2. Navigate to the Flutter project directory:

   ```bash
   cd student_hub
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Check for project issues:

   ```bash
   flutter analyze
   ```

5. Run the application:

   ```bash
   flutter run
   ```

Choose a connected device, Android emulator, or supported desktop target when prompted.

## ⚙️ Backend Configuration

Student Hub communicates with a backend API.

Current API base URL:

```text
https://student-hub-dckn.onrender.com
```

If the backend URL is configured in the source code, verify that it is correct for your deployment. For easier maintenance, consider moving environment-specific configuration into a dedicated configuration file or build-time environment variable.

**Important:** Never commit passwords, API secrets, private keys, or other credentials to GitHub.

## 📁 Project Structure

The following is an illustrative structure. Adjust it to match the actual folders and files in your repository.

```text
student_hub/
├── lib/
│   ├── core/
│   │   └── widgets/
│   │       └── glass_panel.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── tasks_screen.dart
│   │   ├── attendance_screen.dart
│   │   ├── focus_screen.dart
│   │   ├── notes_screen.dart
│   │   └── profile_screen.dart
│   └── main.dart
├── test/
├── pubspec.yaml
└── README.md
```

## 🧪 Testing and Quality Checks

Run the following commands from the Flutter project directory:

```bash
flutter analyze
flutter test
```

These commands help identify static-analysis issues and run automated tests. Their successful completion should be verified before describing the project as fully tested.

## 🔮 Future Improvements

Potential enhancements include:

- Animated page transitions and task interactions
- Push notifications for upcoming tasks
- Calendar integration
- Offline support and data synchronization
- Improved analytics for attendance and study habits
- Automated testing for key user flows

## 🤝 Contributing

Contributions, suggestions, and bug reports are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Commit your changes with a descriptive message.
4. Open a pull request describing your changes.

## 📄 License

No license is specified here. Add a license file if you intend to publish the project under a particular open-source license.

## 👨‍💻 Author

**Umair Wanware**

- GitHub: [@Umair-Wanware](https://github.com/Umair-Wanware)

---

*Built with Flutter to make student life more organized, productive, and focused.*
