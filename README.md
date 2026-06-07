# 📓 Starry Note  </br> [![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev) [![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=flat&logo=Dart&logoColor=white)](https://dart.dev) [![SQLite](https://img.shields.io/badge/SQLite-%2307405E.svg?style=flat&logo=sqlite&logoColor=white)](https://sqlite.org) </br> [![iOS](https://img.shields.io/badge/-000000?style=flat&logo=ios&logoColor=white)](https://developer.apple.com/ios/) [![Android](https://img.shields.io/badge/Android-3DDC84?style=flat&logo=android&logoColor=white)](https://www.android.com/)

Starry Note is a user-friendly digital note-taking application built with Flutter and powered by SQLite for secure, localized database storage. Inspired by the idea of infinite possibilities, the application is designed for students, professionals, and lifelong learners to help them manage notes, connect complex concepts visually, organize tasks, and track study progress efficiently.

## 🚀 Key Features

### 1. Note Hierarchy Structure
Organize your materials efficiently through an intuitive, multi-level file drawer system, users can freely add, rename, move, or delete elements within this hierarchy:
* **Notebooks:** The top-level containers used to group different subjects or major topics.
- **Sections / Chapters:** Sub-categories created within individual notebooks to separate chapters or modules.
* **Pages:** Individual canvas spaces inside sections where note-taking takes place. 

### 2. Concept Visualization (Mind Mapping)
Go beyond traditional text logs by mapping out relationships between different subjects:
* **On-Page Concept Labels:** Create and place dedicated concept labels anywhere on your note canvas. These labels act as customizable focal points that can be linked directly into your map, allowing you to brainstorm and connect ideas right where you take notes.
* **Custom Nodes:** Automatically or manually represent your notebooks, sections, pages, or free-standing concept labels as nodes using distinct shapes and colors.
* **Interactive Graphs:** Automatically generate an interconnected visual mind map of your notes and concepts with the press of a button.
* **Custom Linkage:** Connect different nodes and labels using directional arrows, customize node titles, and add annotations to clarify complex relationships or subject topics.
* **Seamless Navigation:** Click on any node or label inside the mind map to instantly view its explicit location within your notebooks or quickly jump in to edit its details.

### 3. Note-Reviewing System
Boost information retention with a structured revision tracking system:
* **Review Labels:** Tag specific parts of your notes that require periodic review, allowing you to record key takeaways, main points, and assign priority levels directly alongside your canvas content.
* **Priority Color:** Track and prioritize your review materials methodically based on urgency:
  * 🔴 **High Priority:** Red color
  * 🟠 **Medium Priority:** Orange color
  * ⚫ **Low Priority:** Black color
* **Centralized Review List:** Automatically aggregates all marked content and their summary points into a unified master study list.
* **Smart Organization:** Filter and sort your review items dynamically by subject, category, chapter, creation date, or priority level.
* **Keyword Search:** Instantly locate specific revision sections across your workspace using a dedicated keyword search tool.
* **Quick-Jump:** Tap on any item in the master Review List to jump directly back to the exact page layout and canvas location where the review label was originally created.

### 4. Interactive Task Calendar
Keep your schedule and study tasks organized in one unified view:
* **Task Scheduler:** Add personal tasks with names, descriptions, dates, times, and priority levels.
* **Note Interlinking:** Hyperlink calendar tasks directly to review labels from specific pages. Clicking the task instantly redirects you to the corresponding note location.
* **Smart Notifications:** Receive timely push alerts and reminders to prepare for upcoming tasks or scheduled review sessions.
* **Workload Indicators:** The calendar displays color-coded indicators beneath dates to visually reflect your upcoming task volume and preparation window:
  * 🔴 **Red Indicator:** High urgency / heavy workload (Tasks are due daily or back-to-back).
  * 🟠 **Orange Indicator:** Moderate urgency (Tasks are spaced out with only 1 to 2 preparation days in between).
  * 🟢 **Green Indicator:** Manageable workload (Tasks are comfortably spaced with 3 to 4 preparation days in between).
  * ⚫ **Black Indicator:** Low urgency / clear schedule (Tasks are far out with more than 5 preparation days available).

### 5. Dedicated Question List
Never lose track of what you need to ask your instructors or classmates:
* **In-Note Question Tagging:** Quickly place a question label (using a "?" tag) next to any confusing note content or slide, then enter your specific question details and assign a priority level right where you are studying.
* **Priority Color:** Categorize your inquiries into three distinct levels to track unresolved problems methodically:
  * 🔴 **High Priority:** Red color
  * 🟠 **Medium Priority:** Orange color
  * ⚫ **Low Priority:** Black color
* **Question Ledger:** Automatically syncs your tagged notes into a master Question List, neatly sorted by subject or category.
* **Smart Organization:** Filter and sort your questions dynamically by subject, category, chapter, creation date, or priority level.
* **Keyword Search:** Instantly locate specific questions across your entire workspace using a dedicated keyword search tool.
* **Quick-Jump:** Tap on any item in the master Question List to jump directly back to the exact page layout and canvas location where the question was originally flagged.

---

## 🛠️ Fundamental Note-Editing Tools

* **Infinite Canvas & Zoom:** Enjoy unlimited screen space to write and draw freely. Pinch to zoom in or out infinitely to observe complex notes or view high-level overviews.
* **PDF Integration:** Insert external PDF files directly onto your note canvas to write and annotate on top of course materials.
* **Electronic Pen & Highlighter:** Create custom drawing tools by adjusting stroke thickness, transparency, and a vibrant color palette.
* **Advanced Erasers:** Choose between a **Stroke Eraser** (to delete an entire line instantly) and a **Point Eraser** (to erase specific micro-areas precisely).
* **Lasso Tool:** Draw a loop around handwritten strokes to select and drag them freely across the canvas.
* **Text Mode:** Insert text boxes anywhere on the page with adjustable font sizing and color configurations.
* **Accessibility Controls:** Quick-access buttons like **Undo** (to reverse structural modifications) and **Back to Top** (to instantly center focus back to the top of the loaded canvas).

---

## 💻 Tech Stack Overview
* **Frontend Framework:** Flutter (Dart)
* **Local Storage Layer:** SQLite (Database metadata tracking) & JSON (Flexible note element/stroke mapping)
