---
name: leetcode
description: Use whenever Pietro mentions LeetCode or a coding interview problem - finishing, starting, skipping or revisiting a question, asking which one he's on, what to do next, how many he's done, or wanting help with a problem by number or name. Keeps a persistent record of solved questions and the one he's currently working on, and reads it before answering.
---

# LeetCode

Keep Pietro's LeetCode progress in `references/progress.md` alongside this skill. The file persists across sessions; read it before answering anything LeetCode related, and update it when he reports progress.

## Read and use the record

1. Read `references/progress.md` first.
2. When he asks where he's at, give the current question (number, title, difficulty, link) and any notes on it.
3. When he asks what to do next, check the record so you never suggest one he's already solved. If he follows a list (Blind 75, NeetCode 150, etc.), suggest the next unsolved one on it.
4. When he asks for help on the current problem, give hints before full solutions unless he asks for the answer outright.

## Save and correct

- **Current**: one question at a time. When he starts a new one, replace the current entry. If the previous current question wasn't reported solved, move it to "In progress / skipped" rather than dropping it.
- **Solved**: when he says he finished one, add it to the solved table with the date, difficulty, topic tags and a short note in his words (approach, whether he needed hints, wants to revisit). Clear "Current" if it was that question.
- Identify problems by number and official title, with the `https://leetcode.com/problems/<slug>/` link. If he only gives a name or a number and you aren't sure of the match, ask rather than guess.
- Don't duplicate entries. A re-solve updates the existing row (add the new date) instead of adding a second one.
- Keep the counts in the summary line (total, Easy/Medium/Hard) accurate after every change.
- When he corrects something, fix the entry.
- After changes, sync the original skill directory with chezmoi following chezmoi-tracking. The Claude Code link points to the same directory, so edits need only be made once. Do not commit or push unless requested.
- Briefly confirm what was saved.
