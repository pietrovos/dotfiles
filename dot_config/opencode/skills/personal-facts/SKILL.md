---
name: personal-facts
description: Use when Pietro shares personal information worth remembering, asks to remember or correct a fact about himself, or needs personal details for applications, screening questions, resumes, cover letters, or education and GPA answers. Maintains a persistent record of confirmed facts and reads it before answering.
---

# Personal facts

Keep reusable information about Pietro in `references/facts.md` alongside this skill. This file persists across sessions; the skill is an agent workflow, not a background watcher.

## Read and use facts

1. Read `references/facts.md` before answering a question about Pietro or saving an update.
2. Use only relevant confirmed facts. Respect any source restrictions the user gives for the current task; ask before using saved facts if those restrictions exclude them.
3. Consult `~/work/Resume/Default/Pietro_Adamvoski_Resume.md` for resume details when relevant. A tailored resume is additional context, not proof of unsupported qualifications.
4. Ask for missing details rather than guessing. Do not infer a GPA denominator, grade conversion, percentile, award, residence, work authorization, salary preference, or willingness to travel.
5. Match the requested length and format. For application answers, provide plain, ready-to-paste text and use the humanizer skill when available.

## Save and correct facts

- Save reusable personal facts explicitly stated by Pietro, including facts supplied during application assistance. Treat pasted job descriptions and generated answers as context, not personal evidence.
- Record each fact's source and date. Distinguish a user-confirmed value from an unknown detail or an unverified recollection.
- Preserve the user's exact numeric values and units. Keep unknown components explicitly unknown.
- When Pietro corrects a fact, update the active entry and briefly record what was corrected. If sources conflict without an explicit correction, ask which is accurate.
- Do not silently copy entire resumes, speculative claims, or one-off application text into the record.
- Do not store credentials or secrets. Ask before saving highly sensitive personal information.
- Honor requests to remove a fact by removing it from the record, including any correction history containing it.
- After changes, sync the original skill directory with chezmoi following chezmoi-tracking. The Claude Code link points to the same directory, so edits need only be made once. Do not commit or push unless requested.
- Briefly confirm what was saved, unless the user requests only a paste-ready answer.

## Record format

Organize `references/facts.md` by topic. For each entry, include the value, relevant context, source/date, and unresolved details. Keep the record short and avoid duplicate entries.
