# English AI Chat

<img src="assets/images/englishaichat_logo.png" width="200" alt="English AI Chat Logo">

**English AI Chat** is a Flutter app that allows users to practice English conversation with a friendly AI assistant using voice input and output, designed to simulate natural conversation for learning purposes.

---

## ✨ Features

✅ Real-time speech recognition
✅ AI-powered responses (OpenAI & Gemini fallback)
✅ Text-to-Speech with adjustable speed
✅ Friendly animated robot interface
✅ Clean architecture with SOLID principles
✅ Ready for extension with Riverpod or Bloc

---

## 🚀 Getting Started

### ⚙️ **Prerequisites**

- Flutter 3.10 or above
- Dart SDK
- Android Studio / Xcode for simulator or device testing

### 🔑 **API Keys**

Create a `.env` file in the project root with:

OPENAI_API_KEY=your_openai_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here

---

### 🛠️ **Installation**

```bash
git clone https://github.com/jodaias/EnglishVoiceAIClean.git
cd english_voice_ai_clean
flutter pub get
flutter run

💡 Project Structure
lib/
 ┣ features/
 ┃ ┗ voice_chat/
 ┃   ┣ voice_chat_page.dart
 ┃   ┣ voice_chat_controller.dart
 ┃   ┗ services/
 ┃     ┣ ai_service.dart
 ┃     ┣ speech_service.dart
 ┃     ┗ tts_service.dart
 ┣ main.dart

----------------------------------------------------------

🔧 Technologies Used
Flutter

Dart

speech_to_text

flutter_tts

http

Lottie animations

------------------------------------------------------------

📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

🤝 Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

👤 Autor
Feito com 💚 por Jodaías B. S.

📫 Contact
feel free to contact me!

<a href="https://www.linkedin.com/in/jodaias-barreto">Linkedin</a> • <a href="https://github.com/jodaias">Github</a>
```
