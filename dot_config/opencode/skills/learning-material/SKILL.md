---
name: learning-material
description: Use whenever Pietro asks to learn, study, or be taught a topic, or asks for learning material of any kind - a guide, course, lesson, tutorial, explainer, study notes, cheat sheet, or "explain X from scratch". Applies his preferences for how teaching material is built, above all practice questions right after every concept, and records new preferences he states.
---

# Learning material for Pietro

Build every piece of teaching material for Pietro to these preferences. Read the whole list before planning the material. When he states a new preference about learning material, or corrects one, update this file (see "Keeping this skill current").

## Stated preferences (his own words drive these)

1. **Practice questions right after every concept.** He has to answer questions immediately after learning something. Every taught section ends with its own practice block. Never collect the questions only at the end of a chapter or page.
   - The questions must test "every edge of understanding", not just recall:
     - **Trace:** run the algorithm or idea by hand on a concrete input and give the exact result.
     - **Edge case:** empty input, a single element, duplicates, boundaries, the smallest n, invalid assumptions.
     - **Pitfall:** the realistic bug or misconception people actually hit.
     - **Complexity / cost:** time and space, and why.
     - **Concept / why:** the reasoning behind a step, not only what the step is.
     - **Pattern / application:** pick the right tool for a described problem.
   - Every answer gets an explanation, shown whether he got it right or wrong. For wrong typed answers, show the correct answer.
   - Mix question types: single choice, select-all-that-apply, and typed answers. Typed answers should accept equivalent forms (e.g. `O(n log n)` = `nlogn`, `n²` = `n^2`, `3,4,2` = `3 4 2`).
   - Aim for roughly 4–8 questions per section; dense or trace-heavy sections get more.
   - Work every trace answer out by hand and put the working in the explanation. Never ship a question whose answer you haven't verified.
2. **From scratch.** Assume no prior knowledge of the topic. Start at first principles and build up in a sensible order.
3. **Beautiful visualizations.** Show the mechanism with real diagrams and animations rather than walls of text.
4. **HTML files, saved where he says.** Default to standalone `.html` pages in the directory he names. Splitting into multiple pages is fine when the topic is large.

## Established defaults (from the DSA guide he built on, `~/Learning/DSA/timeComplexity/`)

He accepted these without changes. Keep them unless he says otherwise:

- **Structure.** Use one page per chapter plus an `index.html` start page with a roadmap. Share `assets/style.css` and `assets/common.js` across pages. The sidebar lists the chapters and the current page's sections, and every page has previous/next links.
- **Step-through animations.** Use reset / back / play-pause / step / speed controls, a progress bar, a message line explaining the current step, and the matching code line highlighted beside the visual.
- **Interactive inputs.** Let him change the input (values, n, target, strings) and watch the result change.
- **Analogies.** Pair each core idea with a short real-world analogy.
- **Code samples.** Write them in Python unless the topic is tied to another language.
- **Summary tables and cheat sheets.** Use them where comparison helps, e.g. complexity tables.
- **Layout and themes.** Support light and dark themes. Pages must work at phone width with no horizontal scroll.
- **Practice engine.** Reuse `assets/common.js` from the DSA guide as the reference implementation of the step-through player and the practice engine. Question data lives in `assets/practice/NN.js` via `DSA.practice({ "section-slug": [ ... ] })`. Answers persist per browser, with a Retry button and a sidebar progress bar.

## Verify before handing over

- Load every page in a browser and check there are no console errors.
- Step every animation to its end.
- Click every control.
- Answer every practice question correctly and confirm each is graded correct. Confirm a wrong answer is graded wrong.
- Check phone width.
- Report what was tested.
- Clean up any test servers and screenshots afterwards.

## Keeping this skill current

- When Pietro states a new preference about how he learns or how material should look, add it under "Stated preferences". Use his wording where possible, and add a short "why" if he gave one.
- When a default above is overridden, move it to "Stated preferences" with his correction, or edit it.
- Edit the original directory (`~/.config/opencode/skills/learning-material/`). The Claude Code link points to the same files. Then sync with chezmoi following `chezmoi-tracking`. Don't commit or push unless he asks.
- Briefly confirm what changed.
