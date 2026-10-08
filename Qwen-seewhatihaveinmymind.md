# Product Requirements Document  
## Working Title: **Donkey Calendar**  
### AI Study Calendar / Deadline Capture Assistant  
**Version:** 1.0  
**Date:** October 8, 2026  
**Status:** Ready for Build  
**Platform:** Flutter / Android-first MVP  
**Base Codebase:** `donkey-chat` Flutter app  
**AI Backend:** Existing Donkey Chat / Sboomtools-compatible API integration  

---

## 1. Executive Summary

**Donkey Calendar** is an AI-first calendar app for students. Instead of manually adding deadlines, the user tells the app what happened in natural language:

> “mam told she is gonna see the leetcode problems on 9th”

The AI understands the sentence, extracts the event, saves it to a **custom in-app calendar**, and sets a **proactive reminder**.

The app also supports image input:

> User uploads a photo of an exam timetable.  
> AI extracts multiple exams/deadlines.  
> User confirms them.  
> Events are added to the calendar with reminders.

The MVP is built on top of the existing **Donkey Chat** Flutter architecture, reusing the API client, chat UI, image upload flow, and streaming logic. The major new addition is a **Calendar AI layer** that intercepts AI responses, detects structured tool calls, and writes events into a local database.

---

## 2. Core Problem

Students often receive deadlines verbally or through messy messages:

- “Submit this by the 9th.”
- “We will check LeetCode problems on Monday.”
- “Exam timetable is in this image.”
- “Bring physics practical file next week.”
- “Assignment due after holidays.”

Existing calendar apps require too much manual effort:

1. Open calendar.
2. Tap create event.
3. Enter title.
4. Pick date.
5. Pick time.
6. Set reminder.
7. Save.

This creates friction. Students forget. Deadlines slip.

Big assistants also raise privacy concerns and often require rigid commands.

Donkey Calendar solves this by allowing the user to simply **dump information** into the app. The AI organizes it into calendar events.

---

## 3. Product Vision

**A private, low-friction AI calendar that turns messy student instructions into clear deadlines and reminders.**

The app should feel like texting a smart assistant:

- User says something casually.
- AI understands.
- Calendar updates.
- Reminder appears.
- User does not need to manually manage everything.

---

## 4. Target User

### Primary Persona: Student

**Age:** 14–24  
**Context:** School, college, university, coding courses, coaching classes  
**Pain Points:**

- Too many deadlines from teachers.
- Forgets verbal announcements.
- Does not want a complicated planner.
- Does not want aggressive auto-scheduling.
- Wants privacy.
- Wants quick capture.

### Example User Story

> A teacher says in class: “I will check your LeetCode problems on the 9th.”  
> The student opens Donkey Calendar and types:  
> “mam said she is gonna see leetcode problems on 9th”  
> The app creates an event called “LeetCode problems review” on the 9th and sets a reminder.

---

## 5. Core Value Proposition

### 5.1 Fast Capture

User can type casually:

- “physics exam on 14 oct 10am”
- “math assignment due friday”
- “maam said bring biology file tomorrow”
- “submit python project next monday”

The AI converts this into a structured calendar event.

### 5.2 Image-Based Deadline Capture

User can upload:

- Exam timetable photo.
- Screenshot of class schedule.
- Image of assignment list.
- Photo of whiteboard note.

The AI extracts events and presents them for confirmation.

### 5.3 Custom In-App Calendar

The MVP will not depend on native Android/iOS calendar sync.

Instead, it will use a **local, private, custom in-app calendar**.

Benefits:

- No invasive calendar permission required.
- Simpler MVP.
- Better privacy story.
- Full control over UI.
- Easier to iterate.

### 5.4 Proactive, Not Rigid

The app will not aggressively auto-block study time by default.

It will provide:

- Deadline tracking.
- Reminders.
- Event visibility.
- Optional manual edits.

The AI is a safety net, not a strict planner.

---

## 6. Product Goals

### Primary Goals

1. Allow students to capture deadlines in under 10 seconds.
2. Convert casual natural language into calendar events.
3. Extract events from timetable images.
4. Store events locally in a custom calendar.
5. Provide reliable reminders.
6. Avoid rigid automatic scheduling.
7. Reuse the existing Donkey Chat architecture as much as possible.

---

## 7. Non-Goals for MVP

The following are intentionally excluded from the MVP:

1. Native Android/iOS calendar sync.
2. Google Calendar sync.
3. Apple Calendar sync.
4. Automatic study-time blocking.
5. Syllabus PDF bulk import.
6. Multi-user collaboration.
7. Shared class calendars.
8. Cloud backup.
9. Cross-device sync.
10. Advanced recurring event rules.
11. Full voice assistant mode.
12. Task subtasks or project management.
13. Pomodoro timer.
14. Habit tracking.

These may be considered in future versions.

---

## 8. MVP Scope

The MVP must support:

### 8.1 Chat-Based Event Capture

User sends text:

> “mam said she is gonna see leetcode problems on 9th”

App creates:

- Event title: LeetCode problems review
- Date: nearest upcoming 9th
- Reminder: enabled
- Source: chat message

### 8.2 Image-Based Event Capture

User uploads an exam timetable image.

App extracts:

- Exam names.
- Dates.
- Times, if visible.
- Locations, if visible.

App shows a preview card before saving.

### 8.3 Custom Calendar View

User can open a calendar bottom sheet or screen with:

- Monthly view.
- Event indicators.
- Selected-day event list.
- Event details.
- Edit/delete options.

### 8.4 Local Notifications

The app schedules reminders for upcoming events.

### 8.5 AI Tool Execution

The AI may respond with structured tool calls. The app must intercept them and execute local actions.

Example:

```xml
<tool_call>
{
  "name": "create_event",
  "arguments": {
    "title": "LeetCode problems review",
    "date": "2026-10-09",
    "all_day": true,
    "reminder": true
  }
}
</tool_call>
```

The app must not show raw XML to the user.

---

## 9. Core User Journeys

---

## 9.1 Journey A: Quick Text Capture

### Trigger

Student remembers a teacher’s deadline.

### Steps

1. User opens Donkey Calendar.
2. User sees chat interface.
3. User types:
   > “mam said she is gonna see leetcode problems on 9th”
4. App sends message to AI with hidden calendar system prompt.
5. AI returns a tool call.
6. Dart-side parser intercepts the tool call.
7. Event is saved locally.
8. User sees an event card:
   - Title: LeetCode problems review
   - Date: Oct 9
   - Reminder: On
   - Buttons: Undo, Edit, View Calendar

### Success Outcome

Event is created without the user manually selecting date fields.

---

## 9.2 Journey B: Image Timetable Capture

### Trigger

Student receives exam timetable as image.

### Steps

1. User taps image button.
2. User selects image from gallery or camera.
3. Optional text:
   > “Extract exams from this timetable”
4. App sends image to AI.
5. AI extracts multiple events.
6. AI returns a batch tool call.
7. App displays a preview card:
   - Math Exam — Oct 14, 10:00 AM
   - Physics Exam — Oct 16, 10:00 AM
   - Computer Practical — Oct 18, 12:30 PM
8. User reviews events.
9. User taps “Confirm All”.
10. Events are saved.
11. Reminders are scheduled.
12. Calendar is updated.

### Success Outcome

Multiple deadlines are captured from one image with minimal manual work.

---

## 9.3 Journey C: View Calendar

### Trigger

User wants to see upcoming deadlines.

### Steps

1. User swipes up from chat screen or taps calendar icon.
2. Calendar bottom sheet opens.
3. Monthly calendar appears.
4. Dates with events show dots.
5. User selects a date.
6. Event list appears below.
7. User taps an event to view details.

### Success Outcome

User can quickly see what is due and when.

---

## 9.4 Journey D: Edit or Delete Event

### Trigger

Teacher changes deadline or user made a mistake.

### Steps

1. User opens calendar.
2. User taps event.
3. User taps edit.
4. User changes:
   - Title.
   - Date.
   - Time.
   - Reminder.
   - Notes.
5. User saves.
6. App updates local database.
7. App reschedules notification.

### Success Outcome

User maintains control over AI-generated events.

---

## 9.5 Journey E: Receive Reminder

### Trigger

Event is approaching.

### Steps

1. Local notification fires.
2. Notification title:
   > “LeetCode problems review tomorrow”
3. Notification body:
   > “Due on Oct 9. Tap to view.”
4. User taps notification.
5. App opens event detail screen.

### Success Outcome

User is proactively reminded without aggressive scheduling.

---

## 10. Functional Requirements

---

## FR-01: App Initialization

### Requirement

The app must initialize the existing Donkey Chat API service and authenticate with the backend.

### Behavior

- Reuse `ApiService.auth()`.
- Fetch available bots using `ApiService.fetchBots()`.
- Restore last selected bot if available.
- If authentication fails, show retry screen.

### Acceptance Criteria

- App boots into chat UI after successful auth.
- If auth fails, user sees error and retry button.
- No blank screen.

---

## FR-02: Chat Input

### Requirement

The app must allow text input and image attachment.

### Input Types

- Plain text.
- Image from gallery.
- Image from camera.

### Existing Components

- `ImagePicker`
- `_pendingImage`
- `_InputBar`

### Acceptance Criteria

- User can type a message.
- User can attach one image.
- User can remove attached image before sending.
- Send button disabled if no text and no image.

---

## FR-03: Calendar System Prompt Injection

### Requirement

Every message sent to the AI must include a hidden calendar assistant system prompt.

### Purpose

The AI needs to know:

- It is a calendar assistant.
- It must extract dates and deadlines.
- It must use tool calls.
- It must not invent information.
- It must ask for clarification if unsure.

### Implementation

The app should send a combined message to the API:

```text
[SYSTEM]
You are Donkey Calendar AI...
Today is {{CURRENT_DATE}}.
User timezone: {{TIMEZONE}}.
When user asks to add a deadline, respond using tool_call XML...
[/SYSTEM]

[USER]
mam said she is gonna see leetcode problems on 9th
```

### Acceptance Criteria

- User sees only their original message in chat UI.
- API request contains hidden instruction.
- Current date and timezone are injected dynamically.

---

## FR-04: AI Tool Call Parsing

### Requirement

The app must parse AI responses for structured tool calls.

### Tool Call Format

```xml
<tool_call>
{
  "name": "tool_name",
  "arguments": {
    ...
  }
}
</tool_call>
```

### Behavior

The Dart app must:

1. Buffer streamed AI text.
2. Detect `<tool_call>`.
3. Extract JSON using brace-depth parsing.
4. Validate JSON.
5. Execute the tool locally.
6. Remove raw tool call from visible chat text.
7. Show appropriate UI card.

### Acceptance Criteria

- Raw `<tool_call>` XML is never shown to the user.
- Multiple tool calls in one response are supported.
- Invalid JSON produces a graceful error card.
- Normal AI text still renders normally.

---

## FR-05: Create Single Event

### Requirement

The AI must be able to create one calendar event.

### Tool Name

```text
create_event
```

### Arguments

```json
{
  "title": "LeetCode problems review",
  "date": "2026-10-09",
  "start_time": null,
  "end_time": null,
  "all_day": true,
  "location": null,
  "course": null,
  "notes": "Teacher said she will check LeetCode problems",
  "reminder": true
}
```

### Required Fields

- `title`
- `date`

### Optional Fields

- `start_time`
- `end_time`
- `all_day`
- `location`
- `course`
- `notes`
- `reminder`

### Behavior

If the event is unambiguous:

- Save event automatically.
- Show saved event card.
- Provide Undo button.

If ambiguous:

- AI should ask clarifying question in plain text.

### Acceptance Criteria

- Event appears in calendar.
- Reminder is scheduled if enabled.
- User sees event card in chat.
- Undo deletes the event.

---

## FR-06: Create Events Batch

### Requirement

The AI must be able to create multiple events from one image or message.

### Tool Name

```text
create_events_batch
```

### Arguments

```json
{
  "events": [
    {
      "title": "Math Exam",
      "date": "2026-10-14",
      "start_time": "10:00",
      "all_day": false,
      "location": "Room 12"
    },
    {
      "title": "Physics Exam",
      "date": "2026-10-16",
      "start_time": "10:00",
      "all_day": false
    }
  ]
}
```

### Behavior

For batch events:

- Do not save immediately.
- Show preview card.
- Allow user to select/deselect events.
- Allow user to confirm all.
- Allow user to cancel.

### Acceptance Criteria

- User sees all extracted events before saving.
- User can deselect incorrect events.
- Confirm button saves selected events.
- Cancel button discards preview.
- Reminders are scheduled after confirmation.

---

## FR-07: Event Confirmation Card

### Requirement

The chat UI must render rich event cards instead of raw tool call output.

### Card Types

#### Single Saved Event Card

Displayed after automatic save.

Fields:

- Event title.
- Date.
- Time, if available.
- Reminder status.
- Source snippet.
- Buttons:
  - Undo
  - Edit
  - Open Calendar

#### Batch Preview Card

Displayed before saving multiple events.

Fields:

- List of events.
- Checkbox for each event.
- Select all / deselect all.
- Confirm button.
- Cancel button.

### Acceptance Criteria

- Cards match app dark theme.
- Cards are tappable.
- Card actions work.
- No raw JSON or XML is visible.

---

## FR-08: Custom In-App Calendar

### Requirement

The app must include a custom local calendar view.

### Recommended Package

```yaml
table_calendar: ^latest
```

### View Modes

Primary view:

- Monthly calendar grid.

Secondary components:

- Selected day event list.
- Event indicator dots.
- Drag handle.
- Add event button.

### Access

Calendar can be opened by:

- Calendar icon in app bar.
- Swipe-up bottom sheet.
- “Open Calendar” button on event card.

### Acceptance Criteria

- Calendar loads quickly.
- Dates with events show indicators.
- Selecting a date shows events.
- Empty days show friendly empty state.
- User can add event manually.

---

## FR-09: Event Detail Screen

### Requirement

Users must be able to view and edit an event.

### Editable Fields

- Title.
- Date.
- All-day toggle.
- Start time.
- End time.
- Location.
- Course.
- Notes.
- Reminder toggle.
- Reminder offset.

### Actions

- Save.
- Delete.
- Mark complete.

### Acceptance Criteria

- Event changes persist.
- Notification is updated after save.
- Delete removes event from database.
- Completed events are visually muted.

---

## FR-10: Manual Event Creation

### Requirement

Although the app is AI-first, users must be able to manually create events.

### Entry Point

- Floating action button in calendar view.
- “Add event” button.

### Fields

- Title.
- Date.
- Time optional.
- Reminder optional.
- Notes optional.

### Acceptance Criteria

- User can create event without AI.
- Event appears in calendar.
- Reminder is scheduled if enabled.

---

## FR-11: Local Notifications

### Requirement

The app must remind users about upcoming events.

### Recommended Packages

```yaml
flutter_local_notifications: ^latest
timezone: ^latest
```

### Default Reminder Rules

#### All-Day Deadline

Default reminder:

- 9:00 AM one day before.

Example:

> Event: LeetCode review  
> Date: Oct 9  
> Reminder: Oct 8 at 9:00 AM

#### Timed Event

Default reminder:

- 1 hour before event start.

Example:

> Event: Math Exam  
> Time: Oct 14, 10:00 AM  
> Reminder: Oct 14, 9:00 AM

### User Control

User can:

- Disable reminder.
- Change reminder offset.
- Add manual reminder later.

### Acceptance Criteria

- Notification appears at scheduled time.
- Tapping notification opens event detail.
- Editing event updates notification.
- Deleting event cancels notification.

---

## FR-12: Image Input for Timetable Extraction

### Requirement

The app must allow users to send images for AI processing.

### Supported Sources

- Gallery.
- Camera.

### Supported Formats

Minimum:

- JPEG.
- PNG.
- WEBP.

### Behavior

If user attaches image:

- Show image preview before sending.
- Allow optional instruction text.
- If no text provided, use default:
  > “Extract all deadlines, exams, and schedules from this image.”

### Acceptance Criteria

- Image preview appears.
- Image can be removed.
- Image is sent using existing multipart API flow.
- AI response is parsed for event tool calls.

---

## FR-13: Vision Model Selection

### Requirement

The app should choose an appropriate bot/model for image understanding.

### Selection Logic

1. Fetch bots from existing API.
2. Filter bots where:
   - `mime_support` is not empty.
   - `stream` is true or acceptable.
   - `type` is not purely image generation.
3. Prefer chat-capable bots that accept images.
4. If no suitable vision bot exists, use fallback.

### Fallback

If no vision-capable model is available:

- Use local OCR using ML Kit Text Recognition.
- Extract text from image.
- Send extracted text to standard chat model.
- Add note:
  > “Extracted from image using on-device OCR.”

### Acceptance Criteria

- Image is sent to a bot that can process images if available.
- If no vision bot exists, app still works via OCR fallback.
- User is not blocked by model selection failure.

---

## FR-14: Local Event Storage

### Requirement

All calendar events must be stored locally.

### Recommended Database

Use **Drift**.

Reasons:

- Robust.
- Type-safe.
- SQLite-based.
- Good for querying by date.
- Better long-term than SharedPreferences.

### Acceptance Criteria

- Events persist after app restart.
- Events can be queried by date range.
- Event edits and deletes persist.
- No calendar data requires cloud sync.

---

## FR-15: Undo Behavior

### Requirement

If a single event is auto-created, user must be able to undo quickly.

### Behavior

After event creation:

- Show snackbar or event card with Undo.
- Undo remains available for at least 10 seconds.
- Undo deletes the created event.
- Undo cancels scheduled notification.

### Acceptance Criteria

- Undo works within time window.
- Event disappears from calendar.
- Notification is cancelled.

---

## FR-16: Error Handling

### Requirement

The app must gracefully handle failures.

### Failure Cases

- Network failure.
- API authentication failure.
- AI returns invalid tool call.
- AI returns incomplete JSON.
- Image cannot be processed.
- Date cannot be parsed.
- Notification permission denied.

### UX Rules

- Do not crash.
- Do not show raw stack traces.
- Show actionable error message.
- Allow retry.
- Preserve user input when possible.

### Example Error Messages

- “Couldn’t understand that date. Try something like: ‘Math exam on 14 Oct at 10am’.”
- “Image processing failed. Please try a clearer photo.”
- “Network error. Your message was not sent.”
- “Notifications are disabled. Reminders may not appear.”

---

## 11. AI Behavior Specification

---

## 11.1 AI Role

The AI acts as a calendar extraction assistant.

It should:

- Understand casual language.
- Infer dates.
- Extract event titles.
- Detect deadlines.
- Parse timetable images.
- Avoid inventing information.
- Ask for clarification when needed.

It should not:

- Aggressively schedule study sessions.
- Create events without enough information.
- Guess exam times if not visible.
- Output raw tool XML to the user.
- Give long unrelated answers.

---

## 11.2 Date Interpretation Rules

The AI should receive the current date and timezone.

Example system context:

```text
Today is Thursday, 2026-10-08.
User timezone: Asia/Karachi.
```

### Rules

1. “today” → current date.
2. “tomorrow” → current date + 1 day.
3. “9th” without month:
   - If the 9th is still upcoming this month, use current month.
   - If the 9th has passed, use next month.
4. “next Monday”:
   - Use the next Monday after today.
5. “friday”:
   - Use the nearest upcoming Friday.
   - If today is Friday and context is unclear, ask or use today.
6. “next week”:
   - Ask for exact day if unclear.
7. Missing date:
   - Ask user for date.
8. Missing title:
   - Generate a short descriptive title from context if possible.
   - If impossible, ask user.

---

## 11.3 System Prompt Template

The app should inject a prompt similar to:

```text
You are Donkey Calendar AI, a private student calendar assistant.

Your job is to convert the user's messages and images into calendar events.

Today is {{CURRENT_DATE}}.
User timezone: {{TIMEZONE}}.

Rules:
1. Extract deadlines, exams, assignments, submissions, classes, and reviews.
2. Infer dates carefully.
3. Do not invent information.
4. If the date is unclear, ask a short clarifying question.
5. If the user wants to add an event, respond using tool_call XML only.
6. For one event, use create_event.
7. For multiple events, use create_events_batch.
8. Do not show raw JSON to the user.
9. Keep titles short and useful.
10. If the image is unreadable, say the image is unclear.
11. Do not create study blocks unless explicitly requested.
12. If no event is needed, reply normally.

Tool schema:
<tool_call>
{
  "name": "create_event",
  "arguments": {
    "title": "string, required",
    "date": "YYYY-MM-DD, required",
    "start_time": "HH:mm or null",
    "end_time": "HH:mm or null",
    "all_day": "boolean",
    "location": "string or null",
    "course": "string or null",
    "notes": "string or null",
    "reminder": "boolean"
  }
}
</tool_call>

<tool_call>
{
  "name": "create_events_batch",
  "arguments": {
    "events": [
      {
        "title": "string, required",
        "date": "YYYY-MM-DD, required",
        "start_time": "HH:mm or null",
        "end_time": "HH:mm or null",
        "all_day": "boolean",
        "location": "string or null",
        "course": "string or null",
        "notes": "string or null",
        "reminder": "boolean"
      }
    ]
  }
}
</tool_call>
```

---

## 11.4 Example AI Interaction

### User Input

```text
mam told she is gonna see the leetcode problems on 9th
```

### Expected AI Output

```xml
<tool_call>
{
  "name": "create_event",
  "arguments": {
    "title": "LeetCode problems review",
    "date": "2026-10-09",
    "start_time": null,
    "end_time": null,
    "all_day": true,
    "location": null,
    "course": null,
    "notes": "Teacher said she will check LeetCode problems",
    "reminder": true
  }
}
</tool_call>
```

### App Behavior

- Parse tool call.
- Save event.
- Show event card.
- Schedule reminder.

---

## 11.5 Example Image Interaction

### User Input

Image of exam timetable.

Optional text:

```text
Extract exams
```

### Expected AI Output

```xml
<tool_call>
{
  "name": "create_events_batch",
  "arguments": {
    "events": [
      {
        "title": "Math Exam",
        "date": "2026-10-14",
        "start_time": "10:00",
        "end_time": null,
        "all_day": false,
        "location": "Room 12",
        "course": "Math",
        "reminder": true
      },
      {
        "title": "Physics Exam",
        "date": "2026-10-16",
        "start_time": "10:00",
        "end_time": null,
        "all_day": false,
        "location": "Room 8",
        "course": "Physics",
        "reminder": true
      }
    ]
  }
}
</tool_call>
```

### App Behavior

- Show preview card.
- Let user confirm.
- Save selected events.
- Schedule reminders.

---

## 12. UX / UI Requirements

---

## 12.1 Design Language

The app should retain the existing Donkey Chat visual style:

- Dark theme.
- Minimal UI.
- Rounded cards.
- Soft borders.
- Accent color.
- Inter font family.
- Clean spacing.
- Subtle labels.

The calendar should feel calm and student-friendly, not corporate.

---

## 12.2 Home Screen

The home screen is the chat screen.

### Components

- App bar with app name.
- Chat message list.
- Input bar.
- Image attachment button.
- Camera button.
- Calendar icon.
- Settings icon.

### Empty State

Suggested empty state text:

> “Tell me what your teacher said.”  
> Example: “mam said leetcode problems on 9th”

Quick suggestion chips:

- “Add deadline”
- “Extract timetable image”
- “What’s due soon?”
- “Math exam on Friday”

---

## 12.3 Event Card UI

### Single Event Card

Layout:

```text
✅ Event added
LeetCode problems review
Oct 9 · All day · Reminder on

[Undo] [Edit] [Calendar]
```

### Batch Preview Card

Layout:

```text
Found 3 possible events

[✓] Math Exam — Oct 14, 10:00 AM
[✓] Physics Exam — Oct 16, 10:00 AM
[ ] Unclear entry — verify manually

[Cancel] [Confirm 2 events]
```

---

## 12.4 Calendar Bottom Sheet

The calendar should open as a draggable bottom sheet.

### Components

- Drag handle.
- Month header.
- Previous/next month arrows.
- Monthly grid.
- Event dots.
- Selected day event list.
- Add event FAB.

### Event List Item

```text
LeetCode problems review
Oct 9 · All day
Reminder: On
```

Tap opens event detail.

---

## 12.5 Event Detail Screen

Fields:

- Title.
- Date.
- All-day toggle.
- Start time.
- End time.
- Location.
- Course.
- Notes.
- Reminder toggle.
- Reminder time.

Buttons:

- Save.
- Delete.
- Mark complete.

---

## 12.6 Settings Screen

Settings should include:

- Default reminder time.
- Notification permission status.
- AI model selector.
- Clear local calendar data.
- About.
- Privacy note.

---

## 13. Technical Architecture

---

## 13.1 High-Level Architecture

```text
User Input
   ↓
Chat UI
   ↓
Calendar Prompt Builder
   ↓
Existing ApiService
   ↓
AI Backend
   ↓
Streamed AI Response
   ↓
Tool Call Stream Transformer
   ↓
Calendar Tool Executor
   ↓
Drift Local Database
   ↓
Reminder Scheduler
   ↓
Calendar UI / Event Cards / Notifications
```

---

## 13.2 Existing Components to Reuse

### `ApiService`

Reuse for:

- Authentication.
- Bot fetching.
- Sending messages.
- Image upload.
- Streaming responses.

Required changes:

- Allow message transformation before sending.
- Expose bot selection for vision tasks.
- Handle calendar-specific request metadata.

### `ChatScreen`

Reuse for:

- Message list.
- Input bar.
- Image picking.
- Streaming display.
- Message actions.

Required changes:

- Insert tool call stream transformer.
- Render event cards.
- Hide tool call XML.
- Add calendar access button.

### `StorageService`

Continue using for:

- Last selected bot.
- Lightweight UI preferences.

Do not use for calendar events.

### `BotModel`

Reuse for:

- Bot metadata.
- Image support detection.
- Model selection.

---

## 13.3 New Modules

### `CalendarEvent` Model

Represents an event.

### `AppDatabase`

Drift database.

### `CalendarRepository`

Handles CRUD operations.

### `CalendarPromptBuilder`

Builds hidden system prompt.

### `ToolCallParser`

Parses XML/JSON tool calls from streamed text.

### `CalendarToolExecutor`

Executes parsed tool calls.

### `ReminderScheduler`

Schedules and cancels local notifications.

### `CalendarScreen`

Displays calendar.

### `EventCard`

Displays event creation result.

### `EventPreviewCard`

Displays batch events before saving.

---

## 14. Data Model

---

## 14.1 CalendarEvent Table

Suggested Drift table:

```dart
class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get course => text().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(true))();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  TextColumn get sourceType => text()(); // chat, image, manual
  TextColumn get sourceMessageId => text().nullable()();
  TextColumn get rawAiPayload => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 14.2 Event Status Values

```text
active
completed
cancelled
```

---

## 14.3 Source Types

```text
chat_text
chat_image
manual
```

---

## 15. Notification Specification

---

## 15.1 Notification Title Examples

For all-day event:

```text
LeetCode problems review tomorrow
```

For timed event:

```text
Math Exam in 1 hour
```

---

## 15.2 Notification Body Examples

```text
Due on Oct 9. Tap to view.
```

```text
Starts at 10:00 AM. Tap to view.
```

---

## 15.3 Notification Tap Behavior

Tapping notification should:

1. Open app.
2. Navigate to event detail.
3. Highlight selected event.

---

## 15.4 Notification Rescheduling

Notifications must be rescheduled when:

- Event date changes.
- Event time changes.
- Reminder setting changes.
- Event is deleted.
- App is restarted.

On app startup:

- Load active events.
- Ensure pending notifications are valid.
- Reschedule missing notifications.

---

## 16. Privacy and Security Requirements

---

## 16.1 Local-First Calendar Data

Calendar events should be stored locally on the device.

No cloud sync in MVP.

---

## 16.2 AI Processing Disclosure

Users should be informed that:

- Text messages are sent to the AI backend for processing.
- Attached images are sent to the AI backend if image understanding is used.
- Calendar events themselves are stored locally.

Suggested privacy note:

> “Messages and images you send are processed by the AI to create calendar events. Your calendar entries are stored locally on this device.”

---

## 16.3 Permissions

The app must request only necessary permissions:

- Camera: optional, for capturing timetable.
- Photos/gallery: optional, for selecting timetable image.
- Notifications: required for reminders.
- Exact alarm permission on Android if required.

---

## 16.4 Secrets Handling

The current codebase contains embedded API constants. For long-term robustness:

- Avoid committing sensitive keys in public repositories.
- Move sensitive constants to build configuration if possible.
- Use obfuscation for release builds.
- Rotate any keys that have been exposed in research files.
- Consider routing requests through your own secure Donkey Chat gateway/proxy in a future version.

The PRD does not require exposing secrets in UI or logs.

---

## 17. Error and Edge Case Handling

---

## 17.1 Ambiguous Date

User says:

> “assignment due next week”

AI should ask:

> “Which day next week?”

No event should be created unless the user provides enough information.

---

## 17.2 Past Date

User says:

> “add event on 1st”

If parsed date is in the past:

- App should warn.
- Ask if user means next month or next year.
- Or allow manual correction.

---

## 17.3 Missing Title

User says:

> “reminder on 9th”

AI should ask:

> “What should I remind you about on the 9th?”

---

## 17.4 Unreadable Image

If AI cannot read timetable:

- Show error card.
- Suggest clearer photo.
- Offer manual add.

---

## 17.5 Duplicate Events

If event with same title and date exists:

- Show warning.
- Ask:
  > “This event may already exist. Add anyway?”

For MVP, simple duplicate detection is enough:

- Same normalized title.
- Same date.

---

## 17.6 Incomplete Tool Call

If AI response ends with incomplete `<tool_call>`:

- Do not execute.
- Show:
  > “The AI response was incomplete. Please try again.”

---

## 17.7 Invalid JSON

If tool call JSON is malformed:

- Try basic repair:
  - Remove trailing commas.
  - Extract first valid JSON object.
- If repair fails:
  - Show friendly error.
  - Allow retry.

---

## 17.8 Notification Permission Denied

If user denies notifications:

- App still works.
- Show non-blocking warning:
  > “Notifications are disabled. Events will be saved, but reminders may not appear.”

---

## 18. Performance Requirements

### App Startup

- Chat UI should appear within 2 seconds on mid-range Android devices after authentication.

### AI Response Streaming

- First streamed token should render as soon as available.
- Tool call parsing should not block UI.

### Calendar Loading

- Monthly calendar should load in under 300 ms for up to 500 local events.

### Image Upload

- Show progress indicator while sending image.
- If upload fails, preserve input and show retry.

---

## 19. Success Metrics

### Activation Metrics

- Percentage of users who create at least one event in first session.
- Percentage of users who send at least one AI message.

### Quality Metrics

- Percentage of AI responses that create valid events without raw XML leakage.
- Percentage of image extractions confirmed by user.
- Percentage of events edited after creation.
- Percentage of events deleted via Undo.

### Retention Metrics

- Number of events created per user per week.
- Number of calendar opens per week.
- Reminder tap-through rate.

### Error Metrics

- AI parsing failure rate.
- Image extraction failure rate.
- API failure rate.
- Notification scheduling failure rate.

---

## 20. MVP Acceptance Criteria

The MVP is complete when:

1. User can open the app and authenticate.
2. User can send a casual text message.
3. AI can create a calendar event via tool call.
4. Raw tool call XML is not visible.
5. Event appears in custom calendar.
6. User can undo a single auto-created event.
7. User can upload an image.
8. AI can extract multiple events from image.
9. User can preview and confirm batch events.
10. Local notifications are scheduled.
11. User can open calendar and see events.
12. User can edit/delete events.
13. Events persist after app restart.
14. App handles errors gracefully.
15. No raw JSON/XML is shown to users.

---

## 21. Suggested Implementation Plan

---

## Phase 1: Foundation

### Tasks

- Add Drift database.
- Create `CalendarEvent` model.
- Create `CalendarRepository`.
- Add local notification service.
- Add timezone handling.

### Deliverables

- Events can be created manually.
- Events persist locally.
- Notifications can be scheduled.

---

## Phase 2: AI Tool Parsing

### Tasks

- Create `ToolCallParser`.
- Implement brace-depth JSON extraction.
- Create stream transformer.
- Integrate with `ChatScreen`.
- Hide tool call output from UI.

### Deliverables

- AI tool calls are parsed.
- Raw XML is not shown.
- Tool calls can trigger local actions.

---

## Phase 3: Event Creation Flow

### Tasks

- Implement `create_event`.
- Implement `create_events_batch`.
- Build event card UI.
- Build batch preview card.
- Add Undo behavior.

### Deliverables

- Text input can create events.
- Batch image events can be previewed.
- User can confirm/cancel events.

---

## Phase 4: Calendar UI

### Tasks

- Add `table_calendar`.
- Build calendar bottom sheet.
- Build selected-day event list.
- Build event detail screen.
- Build manual add/edit screen.

### Deliverables

- User can view, edit, delete events.
- Calendar displays AI-created events.

---

## Phase 5: Image Extraction

### Tasks

- Reuse image picker.
- Add vision bot selection.
- Add default image instruction.
- Add OCR fallback if needed.
- Test timetable extraction.

### Deliverables

- User can upload timetable.
- AI extracts events.
- User confirms and saves events.

---

## Phase 6: Polish and Release

### Tasks

- Empty states.
- Error states.
- Loading states.
- Notification permission flow.
- Settings screen.
- Privacy note.
- QA testing.
- Release APK.

### Deliverables

- Stable MVP build.
- Test report.
- Release candidate.

---

## 22. Recommended Flutter Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Existing / likely already used
  http: any
  image_picker: any
  flutter_markdown: any
  shared_preferences: any
  uuid: any
  crypto: any
  http_parser: any

  # New calendar stack
  drift: any
  sqlite3_flutter_libs: any
  path_provider: any
  path: any
  table_calendar: any
  intl: any

  # Notifications
  flutter_local_notifications: any
  timezone: any

  # Optional OCR fallback
  google_mlkit_text_recognition: any
```

---

## 23. Suggested File Structure

```text
lib/
  main.dart
  theme.dart

  models/
    bot_model.dart
    chat_message.dart
    calendar_event.dart

  db/
    app_database.dart
    tables.dart

  services/
    api_service.dart
    storage_service.dart
    calendar_repository.dart
    calendar_prompt_builder.dart
    tool_call_parser.dart
    calendar_tool_executor.dart
    reminder_scheduler.dart
    vision_bot_selector.dart
    ocr_fallback_service.dart

  screens/
    chat_screen.dart
    calendar_screen.dart
    event_detail_screen.dart
    event_edit_screen.dart
    settings_screen.dart

  widgets/
    event_card.dart
    event_preview_card.dart
    calendar_bottom_sheet.dart
    message_bubble.dart
    input_bar.dart
```

---

## 24. Detailed AI Tool Contract

---

## 24.1 `create_event`

### Purpose

Create one event.

### Arguments

| Field | Type | Required | Notes |
|---|---:|---|---|
| title | string | yes | Short event name |
| date | string | yes | `YYYY-MM-DD` |
| start_time | string or null | no | `HH:mm` |
| end_time | string or null | no | `HH:mm` |
| all_day | boolean | no | Default true if no time |
| location | string or null | no | Optional |
| course | string or null | no | Optional |
| notes | string or null | no | Optional |
| reminder | boolean | no | Default true |

---

## 24.2 `create_events_batch`

### Purpose

Create multiple events from one image or message.

### Arguments

| Field | Type | Required | Notes |
|---|---:|---|---|
| events | array | yes | Array of event objects |

Each event object follows `create_event` schema.

---

## 24.3 Future Optional Tool

### `query_events`

Not required for MVP but recommended for future.

Purpose:

> “What’s due this week?”

Arguments:

```json
{
  "start_date": "2026-10-08",
  "end_date": "2026-10-15"
}
```

Future behavior:

- App fetches local events.
- App sends tool result back to AI.
- AI formats natural language response.

---

## 25. QA Test Cases

---

## 25.1 Text Parsing Tests

| Input | Expected Event |
|---|---|
| “mam said she is gonna see leetcode problems on 9th” | Event on nearest upcoming 9th |
| “physics exam 14 oct 10am” | Event on Oct 14 at 10:00 |
| “math assignment due tomorrow” | Event tomorrow |
| “submit project next monday” | Event next Monday |
| “reminder for friday” | Ask for title if unclear |
| “add event” | Ask for details |

---

## 25.2 Image Tests

| Image Type | Expected Behavior |
|---|---|
| Clear exam timetable | Batch preview with multiple events |
| Blurry image | Error or clarification |
| Image with no dates | Error or ask for details |
| Image with one event | Single event preview/save |
| Screenshot with table | Extract rows as events |

---

## 25.3 Calendar Tests

| Action | Expected Result |
|---|---|
| Create event | Appears on correct date |
| Edit event date | Calendar updates |
| Delete event | Removed from calendar |
| Complete event | Visually muted |
| Restart app | Events persist |
| Select date with events | Event list appears |

---

## 25.4 Notification Tests

| Action | Expected Result |
|---|---|
| Create event with reminder | Notification scheduled |
| Disable reminder | Notification cancelled |
| Change event time | Notification rescheduled |
| Delete event | Notification cancelled |
| Tap notification | Event detail opens |

---

## 25.5 AI Safety Tests

| Scenario | Expected Result |
|---|---|
| AI returns raw JSON | App parses or hides raw output |
| AI returns invalid JSON | Friendly error |
| AI returns multiple tool calls | All handled correctly |
| AI returns incomplete tool call | No partial event saved |
| AI hallucinates events from image | User preview prevents silent save |

---

## 26. Risks and Mitigations

---

## Risk 1: AI Does Not Follow Tool Format

### Impact

Events may not be created.

### Mitigation

- Strong system prompt.
- JSON repair layer.
- Regex fallback for simple date/title extraction.
- Retry button.
- Manual add fallback.

---

## Risk 2: Backend Vision Support Is Unclear

### Impact

Image extraction may fail.

### Mitigation

- Detect vision-capable bots dynamically.
- Use OCR fallback.
- Let user manually add events if image fails.

---

## Risk 3: API Changes

### Impact

Existing Donkey Chat integration may break.

### Mitigation

- Keep API layer isolated.
- Add error logging.
- Use configurable endpoints.
- Maintain adapter pattern.

---

## Risk 4: Notification Restrictions on Android

### Impact

Reminders may not fire reliably.

### Mitigation

- Request correct permissions.
- Use exact alarms where allowed.
- Show settings guidance.
- Reschedule notifications on app startup.

---

## Risk 5: Secrets in Client App

### Impact

API keys or signing constants could be extracted.

### Mitigation

- Avoid public exposure.
- Rotate leaked secrets.
- Use obfuscation.
- Long-term: route through private gateway/proxy.

---

## 27. Long-Term Roadmap Ideas

These are not MVP requirements.

### Version 1.1

- Query events with AI:
  > “What’s due this week?”
- Voice input via speech-to-text.
- Recurring events.
- Better duplicate detection.
- Event categories/colors.

### Version 1.2

- Syllabus PDF import.
- Bulk semester setup.
- Course-based color coding.
- Assignment status tracking.

### Version 1.3

- Optional cloud backup.
- Cross-device sync.
- Export calendar as `.ics`.
- Native calendar sync.

### Version 1.4

- Smart study reminders:
  > “Your exam is in 3 days. Want a 30-minute review reminder?”
- Gentle study suggestions without rigid scheduling.

---

## 28. Final Product Definition

### Donkey Calendar MVP is:

A Flutter-based AI calendar assistant for students that:

1. Reuses the Donkey Chat UI and API layer.
2. Accepts casual text input.
3. Accepts image input.
4. Uses AI to extract deadlines.
5. Uses structured tool calls to create events.
6. Stores events locally using Drift.
7. Displays events in a custom in-app calendar.
8. Schedules proactive local reminders.
9. Gives the user full edit/delete control.
10. Avoids rigid auto-scheduling.
11. Keeps the experience chat-first and calendar-second.

---

## 29. Recommended Build Priority

If development time is limited, build in this exact order:

1. Local Drift event storage.
2. Manual event creation and calendar view.
3. AI tool parser.
4. Single event creation from text.
5. Event card UI.
6. Local notifications.
7. Image upload extraction.
8. Batch preview/confirm flow.
9. Settings and polish.

This order ensures the app is useful even if AI behavior is unstable early in development.

---

## 30. Approval

This PRD defines the MVP for **Donkey Calendar**.

Recommended next step:

> Begin implementation with Phase 1: local calendar database, manual event creation, and calendar UI. Then integrate the AI tool execution layer on top of the existing Donkey Chat streaming architecture.
