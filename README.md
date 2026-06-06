# Starry Note

Starry Note is a powerful, user-friendly digital note-taking application built with Flutter. Inspired by the idea of infinite possibilities, the application is designed for students, professionals, and lifelong learners to help them manage notes, connect complex concepts visually, organize tasks, and track study progress efficiently.

## 🚀 Key Features

### 1. Note Hierarchy Structure
Organize your materials efficiently through an intuitive, multi-level file drawer system:
* **Notebooks:** The top-level containers used to group different subjects or major topics.
* **Sections / Chapters:** Sub-categories created within individual notebooks to separate chapters or modules.
* **Pages:** Individual canvas spaces inside sections where note-taking takes place. Users can freely add, rename, move, or delete elements within this hierarchy.

### 2. Concept Visualization (Mind Mapping)
Go beyond traditional text logs by mapping out relationships between different subjects:
* **Custom Nodes:** Represent notebooks, sections, pages, or dedicated concept labels using distinct shapes and colors.
* **Interactive Graphs:** Automatically generate a visual mind map of your notes with the press of a button.
* **Custom Linkage:** Connect nodes using directional arrows, customize node titles, and add annotations to clarify complex topics.
* **Seamless Navigation:** Click on any node inside the mind map to view its explicit hierarchy location or quickly edit its details.

### 3. Note-Reviewing System
Boost information retention with a built-in revision tracking system:
* **Review Labels:** Tag specific parts of your notes that require periodic review.
* **Centralized Review List:** Automatically collects all marked content into a master study list.
* **Smart Organization:** Filter and sort your review items by subject, category, chapter, or custom priority.
* **Keyword Search:** Quickly find specific revision materials using a keyword search engine.

### 4. Interactive Task Calendar
Keep your schedule and study tasks organized in one unified view:
* **Task Scheduler:** Add personal tasks with names, descriptions, dates, times, and priority levels.
* **Note Interlinking:** Hyperlink calendar tasks directly to specific pages, notebooks, or review labels. Clicking the task instantly redirects you to the corresponding note location.
* **Smart Notifications:** Receive timely push alerts and reminders to prepare for upcoming tasks or scheduled review sessions.
* **Workload Indicators:** The calendar displays color-coded indicators beneath dates to represent task volume and priority layout for that day.

### 5. Dedicated Question List
Never forget what to ask your instructors or classmates:
* **In-Note Question Tagging:** Quickly place a question label (using a "?" tag) next to any confusing note content or slide.
* **Question Ledger:** Automatically syncs tagged items into a master Question List sorted by subject or category.
* **Priority Color-Coding:** Color-code questions to mark urgency and follow up on unresolved problems methodically.
* **Quick-Jump:** Tap on any item in the Question List to go directly back to the exact page layout where the question was flagged.

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
* **UI/UX Design Base:** Figma
