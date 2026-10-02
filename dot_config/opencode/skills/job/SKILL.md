---
name: job
description: Job posting project matcher. Use when the user gives a software engineering job posting link and wants resume/portfolio projects selected, reused, copied, or created for that posting.
---

# Job Project Match

Use this skill when the user provides a job posting link and wants projects that best match that job. The goal is to produce a job-specific project bundle that can support a resume/application.

## Core Intent

Given one job posting URL:

1. Analyze the job posting for required skills, role type, technologies, seniority, domain, and keywords.
2. Inspect the user's existing projects before suggesting new projects.
3. Recommend the three best projects for that job.
4. Reuse existing projects when they are already at least a 75% match.
5. Prefer reusable flagship projects and targeted adaptations over creating job-specific one-off projects.
6. Create a per-job directory with a unique identifier connected to the job posting.
7. Put the job posting link in that directory.
8. Copy or create the selected projects inside that directory.
9. Detect whether the user has already processed the same or likely-equivalent job posting.

## Portfolio Strategy

Job postings should guide selection, positioning, and small adaptations. They should not cause three large new projects to be built for every application.

Maintain a reusable portfolio with three project tiers:

- Flagship projects: larger end-to-end projects that can support many applications in a target role family.
- Supporting projects: smaller projects that prove one important skill clearly.
- Job-specific polish: README edits, resume bullets, demo scripts, tests, diagrams, or small feature extensions made only inside the job-target copy.

Prefer creating or improving a reusable flagship project when the same gap appears across multiple similar postings. Prefer job-specific polish when the gap is only about wording, framing, documentation, or a small missing proof point.

Do not create three large new projects for one job posting. If no existing project fits, create the smallest reusable project asset that would also help with future similar postings, then use supporting projects or documented gaps for the rest.

## Portfolio Coverage Target

The long-term goal is to cover about 90% of the user's target postings with a small reusable portfolio, not to create a new portfolio for every company.

Aim for 3 to 5 flagship projects across the user's target role families. Add another flagship only when repeated job postings show a material capability gap that existing flagships cannot credibly cover with small adaptations.

Use this decision rule:

- If one job needs a skill gap, document it or add job-specific polish.
- If two or three similar jobs need the same gap, add a supporting project or extend an existing flagship.
- If many target jobs need the same gap and no flagship covers it, create a new flagship.

Prefer broad flagships that can be positioned multiple ways. A good flagship should cover several of these dimensions:

- role family: backend, full-stack, frontend, data/AI, DevOps/cloud, security, embedded/systems
- production depth: auth, persistence, testing, deployment, observability, performance, security
- domain angle: hiring, finance, health, education, commerce, infrastructure, developer tools
- adaptation surface: README positioning, demo data, small feature flags, tests, diagrams, or deployment notes

When the user has no flagship projects, do not immediately build three job-specific projects. First recommend or create the first reusable flagship project for the user's most common target role family, then use supporting projects only where needed.

## Default Locations

Existing projects are usually under:

```text
~/projects/
```

Create job-specific bundles under:

```text
~/projects/job-targets/
```

Maintain a job index at:

```text
~/projects/job-targets/job-index.md
```

Use this index to detect duplicate or likely duplicate postings before creating a new bundle.

If the user gives a different project root or output root, use their paths instead.

## Directory Naming

For each job posting, create a unique directory name using:

```text
<company-or-domain>-<role-keywords>-<short-hash>
```

Example:

```text
~/projects/job-targets/ciena-embedded-software-4f2a9c/
```

The short hash should come from the job posting URL. Six to eight hex characters is enough.

Inside the directory, create:

```text
job-posting.md
project-selection.md
bundle-manifest.md
projects/
```

`job-posting.md` must include:

```md
# Job Posting

- URL: <job posting URL>
- Retrieved: <date if known>
- Company: <company if known>
- Role: <role if known>
- Normalized signature: <company>|<role>|<location>|<posting-id-or-url-hash>
```

`project-selection.md` must include:

```md
# Project Selection

## Job Requirements Summary

## Selected Projects

## Existing Project Match Scores

## Gaps Covered By New Projects Or Adaptations

## Resume Positioning Notes
```

`bundle-manifest.md` must include:

```md
# Bundle Manifest

## Copied Projects

## Newly Created Projects

## Omitted Files And Folders

## Verification Commands

## Notes
```

## Duplicate Posting Detection

Before creating a new job-target directory, check whether the posting was already processed.

Look for duplicates using, in order:

1. Exact URL match.
2. Same canonical URL after removing tracking parameters like `utm_*`, `ref`, `src`, `source`, `gh_src`, and session IDs.
3. Same ATS/job ID from platforms like Workday, Greenhouse, Lever, Ashby, SmartRecruiters, Job Bank, LinkedIn, or Indeed.
4. Same company, role title, location, and substantially similar job description.
5. Same company and role title where the user has already processed another posting recently, even if the opening/requisition ID differs.

If it is an exact duplicate, stop and tell the user where the existing bundle is. Do not create a new directory unless the user explicitly asks.

If it is likely the same role but a different opening/requisition, tell the user that it may be a duplicate and explain why. Ask whether to reuse the existing bundle or create a separate one.

Update `job-index.md` whenever a new bundle is created. Include:

```md
| Date | Company | Role | Location | Posting ID | URL | Bundle |
|---|---|---|---|---|---|---|
```

When possible, extract a posting ID from the URL or page. Examples include Workday requisition IDs, Greenhouse job IDs, Lever posting IDs, LinkedIn currentJobId, Indeed jk values, Job Bank job numbers, and Ashby posting IDs.

Normalize titles before comparing by lowercasing and removing extra words such as `new`, `hiring`, `remote`, `hybrid`, `co-op`, punctuation, and duplicated whitespace. Keep seniority words like `junior`, `senior`, `staff`, and `principal` because they change the role.

Normalize company names by lowercasing and removing suffixes like `inc`, `corp`, `corporation`, `ltd`, `limited`, and punctuation.

Normalize URLs by removing query tracking parameters and fragments unless the fragment contains the actual job ID.

## Existing Project First Rule

Before suggesting new projects, inspect existing projects.

For each candidate project, inspect:

- README and stated purpose
- primary languages/frameworks from package/config files
- source structure and runnable entry points
- tests or verification commands
- deployment, build, CI, or container files
- evidence of complexity or production readiness
- secrets, generated files, databases, or large artifacts that should not be copied

For each candidate project, score it from 0 to 100 against the job posting:

- Role/domain alignment: 25 points
- Technology match: 25 points
- Demonstrated depth/complexity: 20 points
- Resume relevance for this job: 20 points
- Polish/documentation/tests: 10 points

If a project scores 75 or higher, it is good enough to reuse. Do not suggest a replacement unless the user asks.

If an existing project scores 65 to 74, prefer improving that project inside the job-target copy over creating a new project when the gap can be closed with small README, test, demo, cleanup, or positioning changes. Do not modify the original project unless the user explicitly asks.

If three existing projects score 75 or higher, select those three and do not create new projects.

If one or two existing projects score 75 or higher, reuse them and fill the remaining slots with supporting projects, targeted adaptations, or one reusable new project asset when there is a real portfolio gap.

If no existing projects score 75 or higher, do not create three large one-off projects. Create or specify one reusable flagship or supporting project that addresses the strongest repeatable gap, then document the remaining gaps and recommend future portfolio work.

Use this table in `project-selection.md` for comparable scoring:

```md
| Project | Existing/New | Score | Matched Requirements | Gaps | Action |
|---|---:|---:|---|---|---|
```

## Stop Or Confirm Conditions

Stop and ask one short question before copying, creating, or modifying project bundles when:

- the posting appears unsuitable for the user, such as senior-only, clearance-only, location-ineligible, or requiring unavailable hardware;
- an existing project is very large or has unclear generated artifacts;
- the best action would require modifying an original project;
- the project would require paid APIs, private credentials, protected data, or external services that are not available;
- the job posting looks like a likely duplicate but not an exact duplicate.

## Project Selection Rules

The three projects should be complementary, not three versions of the same idea.

Prefer this spread when possible:

- One flagship or strongest existing project that directly matches the job's core role.
- One project that proves adjacent production skill: testing, deployment, observability, security, performance, or data.
- One project that shows domain-specific initiative or deeper technical interest.

If the selected flagship project is broad enough, use the other two slots to show focused proof rather than more large end-to-end systems.

Examples:

- Embedded posting: firmware simulator, network protocol tool, hardware-facing diagnostics dashboard.
- Backend posting: API/service project, queue/cache/reliability project, security/auth/data project.
- Frontend posting: polished UI/product project, accessibility/performance project, full-stack integration project.
- Security posting: network monitor, vulnerable app with fixes, static/dynamic analysis tool.
- Data/AI posting: pipeline project, model/RAG deployment, monitoring/evaluation project.

## Copying Existing Projects

When reusing existing projects, copy them into:

```text
<job-target-dir>/projects/<project-name>/
```

Preserve their files. Do not modify the original project unless the user explicitly asks.

Avoid copying generated/heavy folders when possible:

```text
.git/
node_modules/
.venv/
venv/
__pycache__/
build/
dist/
target/
*.db
```

If a project is very large or contains unclear generated artifacts, ask one short question before copying it.

After copying an existing project, verify at least one lightweight command when feasible, such as a test command, build command, lint command, or documented smoke test. If verification is not feasible, record why in `bundle-manifest.md`.

## Creating New Projects Or Adaptations

When a new project or adaptation is needed, create it inside:

```text
<job-target-dir>/projects/<new-project-name>/
```

Create a practical runnable asset by default, not just a scaffold and not an overbuilt system. Include:

- `README.md`
- runnable source code
- tests when reasonable
- short design notes
- usage instructions

Keep new projects scoped to what would be credible for a student/new graduate to build and explain.

Before creating a new project, decide whether the need is:

- a reusable flagship project for a repeated target role family;
- a supporting project that proves one concrete skill;
- a job-specific adaptation inside the copied bundle;
- a documentation/resume positioning change only.

Only build a large end-to-end project when it is reusable across future applications. For a single job posting, prefer small adaptations inside the job-target copy.

Do not stop at a scaffold when a small runnable MVP can be implemented in the current session. If a proposed project is too large to implement as a runnable MVP, reduce the scope to a smaller MVP that still demonstrates the job requirement.

Only create a scaffold instead of a runnable MVP when:

- the user explicitly asks for scaffolds/specs only;
- required external services, paid APIs, private credentials, or hardware are unavailable;
- implementation would be unsafe or inappropriate;
- the project cannot reasonably be built in the current session even after reducing scope.

If only a scaffold/spec is created, label it clearly as a scaffold or planned project and explain why it was not fully implemented.

For each new runnable MVP, verify at least one command before reporting completion. Prefer standard-library implementations when they are enough. If dependencies are needed, document them clearly.

## Job Posting Analysis

Extract and summarize:

- Company
- Role title
- Location/remote status
- Seniority/new-grad suitability
- Core responsibilities
- Required languages/frameworks/tools
- Domain signals
- Nice-to-have skills
- Resume keywords
- Project implications

If the role appears unsuitable or risky for the user, call that out before creating anything. Examples include roles that are clearly too senior, require professional certifications the user does not have, require security clearance, require relocation the user cannot do, or depend on hardware/services unavailable in the workspace.

If the job posting URL cannot be fetched, ask the user to paste the posting text or provide a PDF/screenshot/HTML export.

## Output To User

After finishing, respond with:

- The created job-target directory path.
- The three selected projects.
- Which projects were reused vs newly created.
- Each project's match score and why it was selected.
- Any remaining gaps for that job.
- Resume bullet or positioning notes for each selected project.
- Next recommended improvement.

Keep the response concise, but include enough detail for the user to understand the choices.

## Safety And Honesty

- Do not claim the user has completed a project that was only scaffolded.
- Do not alter original projects unless explicitly requested.
- Do not scrape or bypass protected job boards. If a posting blocks access, ask the user to paste the text.
- Do not include secrets, tokens, `.env` files, private databases, or local credentials in copied project bundles.
- If a project is copied from an existing git repo, avoid copying the `.git` directory unless the user specifically wants full history preserved.

## Suggested Workflow

1. Fetch or read the job posting.
2. Summarize job requirements.
3. Inspect `~/projects/` for existing projects.
4. Score existing projects.
5. Decide whether to reuse or create projects.
6. Create the unique job-target directory.
7. Write `job-posting.md`, `project-selection.md`, and `bundle-manifest.md`.
8. Copy existing matching projects or create new project directories.
9. Run a basic verification command for each copied or newly created project when feasible.
10. Verify the resulting directory structure.
11. Report the final selection to the user.
