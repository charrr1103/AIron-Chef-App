# 🍳 AIron Chef – Intelligent Recipe Generator Mobile App

AIron Chef is a Flutter-based mobile application designed to help users decide what to cook based on the ingredients they already have. By combining image recognition, voice input, manual entry, and smart recipe recommendations, AIron Chef reduces decision fatigue and minimizes food waste — making cooking easier, smarter, and more enjoyable.

---

## 📌 Overview

AIron Chef acts as a personal cooking assistant that helps users:

- Detect ingredients using **YOLOv8 object detection**
- Convert speech to ingredient lists via **speech-to-text**
- Store and organize pantry items using **SQLite**
- Retrieve real recipes through the **Spoonacular API**
- Generate recipes based on available ingredients
- Track expiry dates and avoid spoiled or wasted items  
- Create dynamic shopping lists for missing ingredients

---

## ✨ Key Features

### 🔐 User Authentication
- Email & password login  
- Google login option  
- Guest mode (no signup required)  
- Managed via Firebase Authentication  

---

### 🧭 Onboarding
- Clean, simple onboarding carousel  
- Introduces main features  
- Skippable for quick access  

---

## 🥕 Ingredient Input Methods

### 📷 1. Image Input (YOLOv8 Detection)
- Take a photo or upload an image  
- Automatically detects ingredients using YOLOv8  
- User confirms items before storing  
- Helps identify ingredients quickly  

### 🎤 2. Voice Input
- Speak ingredient names  
- Transcribed via speech-to-text  
- User confirms detected text  
- Fast and hands-free experience  

### ⌨️ 3. Manual Input
- Add items manually with:
  - Name  
  - Category  
  - Quantity  
  - Expiry date  
- Duplicate ingredient detection  
- Perfect for items not detected via image or voice  

---

## 🧺 Pantry Management
- Stores all ingredients locally using SQLite  
- Filter by:
  - Expiry date
  - Category
  - Quantity levels
- Select ingredients to generate recipes  
- Reduce food waste through expiry tracking  

---

## 🍽️ Recipe Features

### 📚 All Recipes Page
- Browse a variety of recipes  
- Smart search suggestions  
- Filters:
  - Cuisine type
  - Dietary preferences
  - Cooking time
  - Skill level  

### 🔖 Saved Recipes
- Bookmark favorite recipes  
- Quick access to saved list  
- Works offline (stored locally)

### 📘 Recipe Detail Page
- Full ingredient list  
- Step-by-step instructions  
- Highlights ingredients you already have  
- Auto-generated shopping list for missing items  
- Adjustable serving size  
- Text-to-speech “read-aloud” recipe mode  

---

## 🛒 Shopping List
- Automatically generated based on missing ingredients  
- Users can add custom items  
- Drag-and-drop reordering  
- Check off purchased items  
- Download/share list with others  

---

## 👤 User Profile
- Update profile picture, name, and email  
- View About section  
- Logout securely  
- Guest users encouraged to register for personalization  

---

## 🧭 Bottom Navigation
- Smooth navigation across:
  - Home  
  - Pantry  
  - Recipes  
  - Shopping List  
  - Profile  

---

## 🏗 System Architecture

AIron Chef integrates multiple technologies:

- **YOLOv8** → Ingredient detection  
- **Speech-to-text** → Voice ingredient capture  
- **SQLite** → Local offline storage  
- **Spoonacular API** → Recipe retrieval  
- **Firebase Authentication** → User login system  

---

## 🛠 Tech Stack

### **Frontend**
- Flutter  
- Dart  

### **Backend / Services**
- Firebase Authentication  
- SQLite  
- YOLOv8 (TensorFlow Lite)  
- Spoonacular REST API  

### **Dev Tools**
- Android Studio  
- Flutter SDK  
- Firebase Console  
