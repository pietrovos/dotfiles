---
name: tailor-resume
description: Use when the user asks to tailor, adapt, or customize Pietro's default resume for a job posting, URL, or pasted job description. Produce a role-specific Markdown, Typst, and PDF resume with the default filenames and a posting/application record in the same job directory. Use for resume-only requests; use the job skill when the user specifically wants project bundles copied or built.
---

# Tailor the default resume to a job

## Source and output

- Source of truth: `~/work/Resume/Default/Pietro_Adamvoski_Resume.md` and `Pietro_Adamvoski_Resume.typ` in the same directory. Keep the default files unchanged.
- Job output: `~/work/Resume/tailored/<company>/<role-and-posting-id>/`. Use lowercase company names and a readable role name plus the requisition or platform job ID. If no ID exists, use a short stable hash of the canonical posting URL; for pasted descriptions without a URL, use a distinctive role-and-location directory and avoid collisions.
- Inside **every** output directory, keep the exact default resume filenames: `Pietro_Adamvoski_Resume.md`, `Pietro_Adamvoski_Resume.typ`, `Pietro_Adamvoski_Resume.pdf`. Store `job-posting.md` in that same directory. Do not put resume files at the company root or in a generic `application/` subdirectory.
- Read `~/work/Resume/tailored/AGENTS.md` for any updated local conventions.
- School-project candidate inventory: `school-project-candidates.md` beside this skill. It records inspected source paths, publication gaps, and role matches; it is a lead list, not proof of a published or resume-ready project.

## Workflow

1. Identify company, exact role, location, posting ID, core requirements, and preferred qualifications from the user's posting. For a LinkedIn search URL with `currentJobId`, try the public canonical URL `https://www.linkedin.com/jobs/view/<id>/`; do not attempt to bypass sign-in or protected content. For other URLs, fetch the posting or use the user's supplied text. If the description cannot be obtained, ask for pasted text, a PDF, or a screenshot before tailoring.
2. Check existing job directories for the same posting ID or likely duplicate company/role. Reuse the matching directory and update its files rather than creating a second copy. Do not overwrite unrelated user edits without checking them.
3. Read both default resume sources. Consider existing projects under `~/projects/` and the candidates in `school-project-candidates.md` when selecting and ordering projects for the role. Recheck the relevant source, README, ownership, current state, and (if linking) actual public repository before using a school candidate. A proposed enhancement is not completed experience: only include implemented, verified work, and only link a repository that actually exists. If a promising candidate needs work first, record it as a follow-up in `job-posting.md`, not as a completed resume bullet. Make bullets specific and attributable, especially for team projects.
4. Rewrite the skills and project/experience bullets to foreground supported matches. Keep names, contact information, degree details, dates, and metrics accurate. Do not add unverified technologies, years of experience, certifications, employment, cloud experience, or job-specific platforms merely because they appear in the posting. The user is happy to study unfamiliar tools before an interview; put such tools in an interview-study section of the posting record rather than asserting current experience on the resume. After the user confirms actual study or a completed hands-on exercise, describe that level of familiarity accurately and update the resume if useful.
5. Create matching `.md` and `.typ` content in the job directory. Use the default Typst page style as the starting point. Compile the PDF with `typst compile Pietro_Adamvoski_Resume.typ Pietro_Adamvoski_Resume.pdf` from that directory. Check that Markdown, Typst, and PDF represent the same resume, the PDF is legible and preferably one page, and the full experience section appears in extracted PDF text. Revise spacing/content if it overflows.
6. Write `job-posting.md` alongside the resumes: canonical posting URL when available, company, role, ID, location, retrieved date, requirements and relevant notes, a relative link to `Pietro_Adamvoski_Resume.pdf`, and a simple application status/history. Add concrete interview-study targets for relevant gaps such as Kubernetes, messaging systems, or observability: suggest what to learn or build, label these as preparation rather than completed experience, and distinguish related existing work from direct experience. Use “not recorded” for submission dates and statuses that the user has not provided; never claim an application was submitted.
7. Verify final filenames, PDF page count, links, and directory structure. Report the PDF and posting record paths, a short summary of what actually changed from the default, and any material qualification gap.

## Scope

Tailor the resume and record the posting. Look at existing projects for evidence, but do not copy repositories, create portfolio projects, or modify original project code for a resume-only request. If the user explicitly requests project selection/copying/building, use the separate `job` skill for that work.
