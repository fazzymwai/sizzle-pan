# 🍳 Sizzle Pan

Sizzle Pan AI is a Flutter-based mobile application that helps users create, discover, and cook recipes with the help of AI.  
The app is designed for **non-technical users**, with a strong focus on **UI/UX, offline-first usage, and simplicity**.

This is a **portfolio project** built to practice clean Flutter architecture, state management, local persistence, and AI-assisted user experiences — without relying on paid APIs.

---

## ✨ Features

### 1. Ingredient-Based Recipe Generator
- Users input ingredients they already have
- AI generates multiple recipe ideas
- Recipes can be:
  - Saved locally
  - Edited (ingredients, steps, notes)
- Helps reduce food waste and inspire quick meals

---

### 2. Mood / Occasion Mode
Generate recipes based on:
- Mood (tired, lazy, excited, romantic)
- Occasion (family dinner, date night, quick lunch)
- Weather (cold, rainy, hot day)

Designed to require minimal typing and feel friendly and intuitive.

---

### 3. Recipe Search & AI Remix
- Search common recipes (e.g. pancakes, pilau, pasta)
- View standard recipe results
- Enhance recipes with AI:
  - Healthier versions
  - Faster alternatives
  - Localized or creative variations
- Save and edit recipes locally

---

### 4. Cooking Companion Mode ⭐
Once a recipe is saved, users can start cooking with an AI companion:
- Step-by-step guided cooking
- Ask questions like:
  - “What do I do next?”
  - “Can I substitute this ingredient?”
  - “How long should I cook this?”
- Designed to feel calm, supportive, and human

---

## 🧠 AI Approach (Free & Open)
This project avoids paid AI APIs.

- AI logic is abstracted behind a service layer
- Uses:
  - Prompt-based generation
  - Rule + template-driven responses
  - Optional open-source LLMs (e.g. Hugging Face / local inference)
- Easy to swap or upgrade AI providers later

---

## 🛠 Tech Stack

- **Flutter**
- **GoRouter** – navigation & routing
- **Provider** – state management
- **SQLite (sqflite)** – local offline storage
- **Material 3** – modern UI components

---

## 🎨 UX & Design Principles

- Designed for non-technical users
- Minimal text, large touch targets
- Friendly, human language
- Offline-first experience
- Light & dark mode support
- Focus on clarity and flow during cooking

---

## 📱 App Scope

To keep the project focused and polished:

- No user accounts or authentication
- No cloud sync
- No payments
- Single-device local storage only

---

## 🎯 Project Goals

- Build a realistic, user-focused Flutter app
- Practice clean architecture and state management
- Demonstrate AI-assisted UX design
- Create a strong, explainable portfolio project

---

## 🚀 Future Enhancements (Optional)

- Voice-guided cooking mode
- Favorites & tags
- Cloud sync
- Nutrition analysis
- Multi-language support

---

## 📄 License

This project is for learning and portfolio purposes.
