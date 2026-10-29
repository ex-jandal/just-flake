/**
 * md-log — mirror the session to a readable lesson file.
 *
 * Designed for long teaching/learning sessions where the terminal is hard on
 * the eyes and markdown/math/code don't render. The linked file is meant to be
 * viewed *rendered*, in an editor that renders it natively — Doom Emacs, in
 * either of its two good modes:
 *
 *   .md  → markdown-mode: headings fold, code fences fontify natively.
 *          Emacs renders no math in markdown, so `$...$` stays source there.
 *   .org → org-mode: headings fold, #+begin_src fontifies natively, `$...$`
 *          and `$$...$$` preview as real formulas (C-c C-x C-l), and inline
 *          images render (C-c C-x C-v). This is the intended target.
 *
 * The format is chosen from the linked file's extension, so the same command
 * covers both. Output is a stream of flat blocks:
 *
 *   * YOU / * PI / * QUIZ / * ANSWER — the speaker or event
 *
 * Captures only reading-relevant content:
 *   - user prompts
 *   - assistant text (lesson prose)
 *   - quiz / ask_user_question / ask_user_question_for_teach Q&A blocks
 * Other tools (bash, read, write, edit, ...) are omitted.
 *
 * Quiz/ask questions are written BEFORE the user answers (on tool_call), so the
 * reader sees the question appear live; the answer + feedback are appended on
 * tool_result. The question block NEVER contains the correct answer or
 * explanation (the user reads this file live).
 *
 * Because the model writes markdown, the org backend translates it on the way
 * in: fences become #+begin_src, `#` headings become `*` headings one level
 * deeper, `*`/`+` bullets become `-`, and inline `code`, **bold**, _italic_
 * become org `~code~`, *bold*, /italic/. LaTeX is passed through untouched
 * (org renders it) and code blocks are never rewritten.
 *
 * Obsidian-only syntax is translated too: `![[pic.png|500]]` embeds and
 * `[[note]]` wikilinks are resolved to real file paths so Emacs can open them.
 *
 * Commands:
 *   /md-log <filepath>            — Link a file and backfill the session.
 *   /md-log --create <filepath>   — Same, creating the file if it is missing.
 *   /md-unlog                     — Stop logging.
 *
 * Append-only. No send-back-to-agent functionality (that lived in the old
 * .md-link extension this was modeled on).
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

// Question-asking tools. The built-in `ask_user_question` takes
// `{ questions: [{ question, header, options }] }` and returns
// `{ answers: [{ questionIndex, question, kind, answer }], cancelled }`;
// `ask_user_question_for_teach` (a custom extension) takes the single-question
// `{ question, details, options }` form and returns
// `{ status, answers: [{ type, label, value, index }] }`. Both are normalized
// below, so neither shape is assumed. The prefix match also catches future
// variants of the custom tool.
const isAskTool = (name: string) => /^ask_user_question/.test(name);
const isQaTool = (name: string) => name === "quiz" || isAskTool(name);

/** One question, in a shape both ask-tools can be normalized into. */
type QuestionItem = {
	question: string;
	/** The built-in tool's short chip label ("Format", "Library", ...). */
	header?: string;
	context?: string;
	options: Array<{ label: string }>;
};

/** Output dialect, chosen from the linked file's extension. */
type Fmt = "md" | "org";

/**
 * A reading-relevant piece of the session. Renderers are format-specific, so
 * everything upstream of rendering stays markup-agnostic.
 */
type Block =
	| { kind: "user"; text: string }
	| { kind: "assistant"; text: string }
	| { kind: "question"; label: string; items: QuestionItem[] }
	| { kind: "quizAnswer"; details: any }
	| { kind: "askAnswer"; details: any };

export default function mdLog(pi: ExtensionAPI) {
	let logFile: string | null = null;
	let sessionCwd: string | null = null;
	let fmt: Fmt = "md";

	function formatFor(file: string): Fmt {
		return path.extname(file).toLowerCase() === ".org" ? "org" : "md";
	}

	// `path.resolve' does not expand `~', so `/md-log ~/notes/x.org' used to
	// land in `$PWD/~/notes/x.org'. Only a leading `~' (or bare `~') expands.
	function expandHome(p: string): string {
		if (p === "~") return os.homedir();
		if (p.startsWith("~/")) return path.join(os.homedir(), p.slice(2));
		return p;
	}

	// --- State restoration on session restart ---

	pi.on("session_start", async (_event, ctx) => {
		sessionCwd = ctx.cwd ?? sessionCwd;
		let lastLinkData: { file: string | null } | undefined;
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === "md-log") {
				lastLinkData = entry.data as { file: string | null } | undefined;
			}
		}
		if (lastLinkData?.file) {
			logFile = lastLinkData.file;
			fmt = formatFor(logFile);
			const theme = ctx.ui.theme;
			ctx.ui.setStatus(
				"md-log",
				theme.fg("accent", "🗒 ") + theme.fg("dim", path.basename(logFile)),
			);
		}
	});

	// --- Serialization: events can fire close together; keep appends ordered ---

	let writeLock: Promise<void> = Promise.resolve();
	function withLock<T>(fn: () => T | Promise<T>): Promise<T> {
		const prev = writeLock;
		let release: () => void;
		writeLock = new Promise<void>((r) => {
			release = r;
		});
		return prev.then(fn).finally(() => release!());
	}

	// Appends instead of read-modify-write: a long lesson file grows with every
	// block, and rewriting the whole thing per message is quadratic. Only the
	// last couple of bytes are inspected to decide whether a blank-line gap is
	// needed first.
	function appendToFile(text: string): void {
		if (!logFile) return;
		try {
			let gap = "";
			let size = 0;
			try {
				size = fs.statSync(logFile).size;
			} catch {
				size = 0;
			}
			if (size > 0) {
				const fd = fs.openSync(logFile, "r");
				try {
					const buf = Buffer.alloc(2);
					const n = fs.readSync(fd, buf, 0, 2, Math.max(0, size - 2));
					if (n === 0) gap = "\n\n";
					else if (buf[n - 1] !== 0x0a) gap = "\n\n";
					else if (size > 1 && buf[n - 2] !== 0x0a) gap = "\n";
				} finally {
					fs.closeSync(fd);
				}
			}
			fs.appendFileSync(logFile, gap + text + "\n", "utf-8");
		} catch {
			// File may have been deleted externally; ignore.
		}
	}

	function appendBlock(block: Block): void {
		const text = renderBlock(block, fmt);
		if (text.trim().length > 0) appendToFile(text);
	}

	// --- Image / wikilink resolution ---

	// The visualize skill tells the maker to drop pictures in `<cwd>/viz/` and
	// reports only a filename, and Obsidian resolves `![[name.png]]` anywhere in
	// the vault. Emacs has no vault, so the name has to become a real path.
	// Positive hits are cached; misses are not (the maker may still be writing).
	const imageCache = new Map<string, string>();

	function isFile(p: string): boolean {
		try {
			return fs.statSync(p).isFile();
		} catch {
			return false;
		}
	}

	function searchShallow(root: string, name: string, depth: number): string | null {
		let frontier = [root];
		let visited = 0;
		for (let d = 0; d < depth && frontier.length > 0; d++) {
			const next: string[] = [];
			for (const dir of frontier) {
				let entries: fs.Dirent[];
				try {
					entries = fs.readdirSync(dir, { withFileTypes: true });
				} catch {
					continue;
				}
				for (const e of entries) {
					if (e.name.startsWith(".") || e.name === "node_modules") continue;
					const full = path.join(dir, e.name);
					if (e.isFile()) {
						if (e.name === name) return full;
					} else if (e.isDirectory()) {
						next.push(full);
						if (++visited > 4000) return null;
					}
				}
			}
			frontier = next;
		}
		return null;
	}

	function findImage(name: string): string | null {
		const cached = imageCache.get(name);
		if (cached) return cached;

		// Exact hits first: beside the log, in a `viz/` folder, and up a few
		// ancestors (a lesson note usually lives one or two levels below the
		// directory the agent is running in).
		const bases: string[] = [];
		const addUp = (start: string, up: number) => {
			let dir = start;
			for (let i = 0; i <= up; i++) {
				if (!bases.includes(dir)) bases.push(dir);
				const parent = path.dirname(dir);
				if (parent === dir) break;
				dir = parent;
			}
		};
		if (logFile) addUp(path.dirname(logFile), 3);
		if (sessionCwd) addUp(sessionCwd, 1);

		for (const base of bases) {
			for (const candidate of [path.join(base, name), path.join(base, "viz", name)]) {
				if (isFile(candidate)) {
					imageCache.set(name, candidate);
					return candidate;
				}
			}
		}

		// Then a shallow sweep, but only from the two roots that are actually
		// plausible — searching an ancestor like $HOME three levels deep would be
		// both slow and wrong.
		const roots = [logFile ? path.dirname(logFile) : null, sessionCwd].filter(
			(r): r is string => !!r,
		);
		for (const root of roots) {
			const hit = searchShallow(root, name, 3);
			if (hit) {
				imageCache.set(name, hit);
				return hit;
			}
		}
		return null;
	}

	function resolveTarget(target: string): string {
		const clean = target.trim();
		if (/^(https?:|mailto:|file:)/i.test(clean)) return clean;
		if (path.isAbsolute(clean) && isFile(clean)) return clean;
		return findImage(clean) ?? findImage(path.basename(clean)) ?? clean;
	}

	function embedBlock(
		target: string,
		width: string | undefined,
		f: Fmt,
		// `#+attr_org` is an affiliated keyword: it must sit on its own line,
		// immediately above the link. Only safe when the embed *is* the line —
		// an embed in the middle of a sentence would split that paragraph (and
		// inside a list item would break the item), so inline embeds lose it.
		allowWidth = false,
	): string {
		const resolved = resolveTarget(target);
		if (f === "org") {
			const w = width?.trim();
			const attr = allowWidth && w && /^\d+$/.test(w) ? `#+attr_org: :width ${w}\n` : "";
			return `${attr}[[file:${resolved}]]`;
		}
		return `![${path.basename(target)}](${resolved})`;
	}

	// Obsidian syntax is resolved only when it IS the line (optionally as a list
	// item). Prose that merely *mentions* `![[pic.png]]` — documentation, or a
	// question about this very extension — must survive verbatim: rewriting it
	// invents links to files nobody asked for.
	const EMBED_LINE = /^(\s*(?:[-+*]\s+)?)!\[\[([^\]|\n]+?)(?:\|([^\]\n]*))?\]\]\s*$/;
	const WIKI_LINE = /^(\s*(?:[-+*]\s+)?)\[\[([^\]|\n]+?)(?:\|([^\]\n]*))?\]\]\s*$/;
	const MD_IMAGE_LINE = /^(\s*(?:[-+*]\s+)?)!\[([^\]]*)\]\(([^)\s]+)\)\s*$/;

	function wikiLink(target: string, alias: string | undefined, f: Fmt): string {
		const raw = target.trim();
		const found = findImage(raw) ?? findImage(path.basename(raw));
		const label = alias?.trim() || (found ? path.basename(found) : raw);
		// Not a file we can find — treat it as a note name and keep it a link.
		if (!found) return f === "org" ? `[[${raw}][${label}]]` : `[${label}](${raw})`;
		return f === "org" ? `[[file:${found}][${label}]]` : `[${label}](${found})`;
	}

	/** Resolves a standalone embed/wikilink line; `null` when the line is prose. */
	function convertStandalone(line: string, f: Fmt): string | null {
		const embed = EMBED_LINE.exec(line);
		if (embed) {
			const prefix = embed[1];
			// `#+attr_org` needs a line of its own, so only a bare embed (no list
			// bullet in front) keeps the width.
			return prefix + embedBlock(embed[2], embed[3], f, prefix.length === 0);
		}
		const wiki = WIKI_LINE.exec(line);
		if (wiki) {
			const target = wiki[2].trim();
			if (/^(file:|https?:|mailto:)/i.test(target)) return null;
			return wiki[1] + wikiLink(wiki[2], wiki[3], f);
		}
		const mdImage = MD_IMAGE_LINE.exec(line);
		if (mdImage) return f === "org" ? `${mdImage[1]}[[file:${mdImage[3]}]]` : null;
		return null;
	}

	/** Inline markdown links → org links. Markdown needs no rewriting. */
	function convertInlineLinks(line: string, f: Fmt): string {
		if (f !== "org") return line;
		return line.replace(
			/(^|[^!\]])\[([^\[\]\n]+)\]\(([^)\s]+)\)/g,
			(_m, pre: string, label: string, src: string) => `${pre}[[${src}][${label}]]`,
		);
	}

	// --- Markdown → Org translation ---

	// Inline code spans and math must survive verbatim — `![[pic.png]]` written as
	// an example *inside* backticks is documentation, not an embed, and org's
	// emphasis rules would turn `$x_i + y_i$` into italics. Both are lifted out
	// before any rewriting and put back afterwards, so rewriting may still match
	// *across* them (`**bold with `code` inside**`).
	const INLINE_PROTECTED = /(\$\$[^$]*\$\$|\$[^$\n]+\$|`[^`\n]+`)/g;

	function maskInline(
		line: string,
		plain: (s: string) => string,
		code: (s: string) => string = (s) => s,
	): string {
		const saved: string[] = [];
		const masked = line.replace(INLINE_PROTECTED, (m) => {
			saved.push(m);
			return `\u0000${saved.length - 1}\u0000`;
		});
		const out = plain(masked).replace(/\u0000(\d+)\u0000/g, (_m, i: string) => {
			const original = saved[Number(i)] ?? "";
			// Math (starts with `$`) is returned untouched; code spans get the
			// dialect's own delimiter.
			return original.startsWith("$") ? original : code(original);
		});
		return out;
	}

	// The model writes markdown. Inside org, `**bold**` shows its asterisks,
	// `` `code` `` shows its backticks, a `#` heading is not a heading, and a
	// `* item` bullet at column 0 is a headline that would wreck the file's
	// top-level structure. Translate the cheap, unambiguous cases only.
	function orgEmphasis(segment: string): string {
		return segment
			.replace(/\*\*([^*\n]+)\*\*/g, "*$1*")
			.replace(/__([^_\n]+)__/g, "*$1*")
			.replace(/(^|[\s("'])_([^_\s][^_\n]*)_(?=$|[\s).,;:!?'"])/g, "$1/$2/");
	}

	function orgLine(line: string): string {
		// Prose that itself looks like an Org keyword (`#+begin_quote`, `#+end_src`,
		// a pasted block) would nest or terminate the block it sits in — the user
		// quoting a broken log is exactly how that happens. Org's own escape for a
		// literal keyword line is a leading comma.
		if (/^\s*#\+/.test(line)) return line.replace(/^(\s*)(#\+)/, "$1,$2");
		// A picture alone on its line keeps its width as an org attribute; the
		// attribute must sit immediately above the link, so this only applies when
		// nothing else is on the line.
		// markdown table rule row: `| --- | --- |` → org's `|---+---|`
		if (/^\s*\|[-:|\s]+\|\s*$/.test(line) && line.includes("-")) {
			const cells = line.trim().split("|").slice(1, -1).map(() => "----");
			if (cells.length > 0) return `|${cells.join("+")}|`;
		}
		// horizontal rule: `---` is not one in org (needs 5+)
		if (/^\s*([-*_])(\s*\1){2,}\s*$/.test(line)) return "-----";
		// ATX heading, demoted one level so it nests under the block's `* TITLE`
		const h = /^(#{1,6})\s+(.*?)\s*#*\s*$/.exec(line);
		if (h) return "*".repeat(Math.min(h[1].length + 1, 6)) + " " + h[2];
		const standalone = convertStandalone(line, "org");
		// bullets: `*` (a headline!) and `+` → `-`
		const debullet = (t: string) => t.replace(/^(\s*)[*+]\s+/, "$1- ");
		if (standalone !== null) return debullet(standalone);
		return maskInline(
			line,
			(t) => orgEmphasis(debullet(convertInlineLinks(t, "org"))),
			// a code span keeps its contents but gets org's `~verbatim~` delimiter
			(s) => s.replace(/^`([^`\n]+)`$/, "~$1~"),
		);
	}

	// Org is whitespace-sensitive around blocks: an affiliated keyword such as
	// `#+attr_org` and any `#+begin_*` need a blank line before them, and text
	// directly after `#+end_*` can swallow the next keyword. Model prose does not
	// guarantee either, so normalize once here.
	function normalizeOrg(lines: string[]): string {
		const isStart = (l: string) => /^#\+(begin_|attr_)/.test(l);
		const isEnd = (l: string) => /^#\+end_/.test(l);
		const out: string[] = [];
		for (const line of lines) {
			const prev = out.length > 0 ? out[out.length - 1] : null;
			if (line === "") {
				if (prev !== null && prev !== "") out.push(""); // collapse blank runs
				continue;
			}
			if (prev !== null && prev !== "" && !isEnd(line) && !isStart(prev) && (isStart(line) || isEnd(prev))) {
				out.push("");
			}
			out.push(line);
		}
		while (out.length > 0 && out[0] === "") out.shift();
		while (out.length > 0 && out[out.length - 1] === "") out.pop();
		return out.join("\n");
	}

	function orgBody(text: string): string {
		const lines = text.split("\n");
		const out: string[] = [];
		let fence: { lang: string } | null = null;
		let math = false;
		for (let i = 0; i < lines.length; i++) {
			const raw = lines[i];
			if (!math) {
				const fenceMatch = /^\s*(`{3,}|~{3,})\s*(.*)$/.exec(raw);
				if (fenceMatch) {
					if (!fence) {
						// First token of the info string; drop attributes like `{1,3}`.
						const lang = (fenceMatch[2].trim().split(/[\s{]/)[0] || "").replace(/[^\w+#.-]/g, "");
						fence = { lang };
						out.push(`#+begin_src${fence.lang ? " " + fence.lang : ""}`);
					} else {
						fence = null;
						out.push("#+end_src");
					}
					continue;
				}
			}
			if (fence) {
				out.push(raw);
				continue;
			}
			if (raw.trim() === "$$") {
				math = !math;
				out.push(raw.trim());
				continue;
			}
			if (math) {
				out.push(raw);
				continue;
			}
			// `> quoted` runs become real org quote blocks; a bare `>` line has no
			// meaning in org and would just sit there as punctuation.
			const quoted = /^\s{0,3}>\s?(.*)$/.exec(raw);
			if (quoted) {
				const inner: string[] = [quoted[1]];
				while (i + 1 < lines.length) {
					const next = /^\s{0,3}>\s?(.*)$/.exec(lines[i + 1]);
					if (!next) break;
					inner.push(next[1]);
					i++;
				}
				out.push("#+begin_quote", orgBody(inner.join("\n")), "#+end_quote");
				continue;
			}
			out.push(orgLine(raw));
		}
		if (fence) out.push("#+end_src");
		return normalizeOrg(out);
	}

	// --- Rendering ---

	function mdBody(text: string): string {
		return text
			.split("\n")
			.map((line) => convertStandalone(line, "md") ?? line)
			.join("\n")
			.trim();
	}

	function mdBlock(title: string, body: string): string {
		return body ? `## ${title}\n\n${body}` : `## ${title}`;
	}

	function orgBlock(title: string, body: string): string {
		return body ? `* ${title}\n\n${body}` : `* ${title}`;
	}

	function optionsList(options: Array<{ label: string }>): string {
		return options.map((o, i) => `${i + 1}. ${o.label}`).join("\n");
	}

	function normalizeOptions(raw: any): Array<{ label: string }> {
		if (!Array.isArray(raw)) return [];
		return raw
			.map((o: any) => (typeof o === "string" ? o : (o?.label ?? o?.value ?? o?.text)))
			.filter((l: any): l is string => typeof l === "string" && l.trim().length > 0)
			.map((l: string) => ({ label: l.trim() }));
	}

	// `{ questions: [...] }` (built-in) or `{ question, details, options }`
	// (ask_user_question_for_teach, and the older single-question built-in form).
	function extractQuestions(input: any): QuestionItem[] {
		const items: QuestionItem[] = [];
		if (Array.isArray(input?.questions)) {
			for (const q of input.questions) {
				items.push({
					question: String(q?.question ?? q?.prompt ?? "").trim(),
					header: typeof q?.header === "string" && q.header.trim() ? q.header.trim() : undefined,
					context:
						typeof q?.details === "string" && q.details.trim()
							? q.details.trim()
							: typeof q?.context === "string" && q.context.trim()
								? q.context.trim()
								: undefined,
					options: normalizeOptions(q?.options),
				});
			}
		} else if (input && (input.question || input.options)) {
			items.push({
				question: String(input.question ?? "").trim(),
				context:
					typeof input.details === "string" && input.details.trim()
						? input.details.trim()
						: typeof input.context === "string" && input.context.trim()
							? input.context.trim()
							: undefined,
				options: normalizeOptions(input.options),
			});
		}
		// An empty question with no options is not worth a headline.
		return items.filter((i) => i.question.length > 0 || i.options.length > 0);
	}

	function renderQuestions(block: Extract<Block, { kind: "question" }>, f: Fmt): string {
		const base = block.label.toUpperCase();
		const many = block.items.length > 1;
		return block.items
			.map((item, i) => {
				// The built-in tool labels each question with a short header
				// ("Format", "Library"); it makes a better heading than a number.
				const title = item.header ? `${base} — ${item.header}` : many ? `${base} ${i + 1}` : base;
				const body: string[] = [];
				if (item.question) body.push(f === "org" ? orgBody(item.question) : mdBody(item.question));
				if (item.context) body.push(f === "org" ? orgBody(item.context) : mdBody(item.context));
				if (item.options.length > 0) body.push(optionsList(item.options));
				const text = body.filter((p) => p.length > 0).join("\n\n");
				if (!text) return "";
				return f === "org" ? orgBlock(title, text) : mdBlock(title, text);
			})
			.filter((t) => t.length > 0)
			.join("\n\n");
	}

	/**
	 * Answer lines for either ask-tool result shape. `lines` are plain prose
	 * (no markup translation). Both shapes are read defensively: an unknown
	 * field yields no line rather than the string "undefined".
	 */
	function askAnswerParts(details: any): { title: string; lines: string[] } {
		const status = details?.status;
		if (status === "cancelled" || details?.cancelled === true)
			return { title: "ANSWER — skipped", lines: ["(user skipped)"] };
		if (status === "unavailable")
			return { title: "ANSWER — unavailable", lines: [details?.message || "(unavailable)"] };

		const raw: any[] = Array.isArray(details?.answers) ? details.answers : [];
		const lines: string[] = [];
		for (const a of raw) {
			if (!a || typeof a !== "object") continue;

			// built-in: `answer` holds the chosen label (an array for multi-select)
			if ("answer" in a) {
				const value = (Array.isArray(a.answer) ? a.answer.join(", ") : String(a.answer ?? "")).trim();
				if (!value) continue;
				const text = a.kind === "other" ? `Other: ${value}` : value;
				const question = typeof a.question === "string" ? a.question.trim() : "";
				const n = typeof a.questionIndex === "number" ? a.questionIndex + 1 : lines.length + 1;
				// Several questions in one call: keep each answer distinguishable.
				lines.push(raw.length > 1 && question ? `${n}. ${question} → ${text}` : text);
				continue;
			}

			// ask_user_question_for_teach: `{ type, label, value, index }`
			const label = String(a.label ?? a.value ?? "").trim();
			if (!label) continue;
			if (a.type === "other") lines.push(`Other: ${label}`);
			else if (a.type === "text") lines.push(label);
			else if (typeof a.index === "number") lines.push(`${a.index}. ${label}`);
			else lines.push(label);
		}
		return { title: "ANSWER", lines };
	}

	/**
	 * Speaker/event heading + metadata lines for a quiz answer. `lines` are
	 * plain prose (no markup translation), `explanation` is model markdown.
	 */
	function quizAnswerParts(details: any): { title: string; lines: string[]; explanation?: string } {
		const status = details?.status;
		if (status === "cancelled") return { title: "ANSWER — skipped", lines: ["(user skipped)"] };
		if (status === "unavailable")
			return { title: "ANSWER — unavailable", lines: [details?.message || "(unavailable)"] };

		// "I don't know" is neither correct nor incorrect — it's a distinct
		// signal, so it never renders as a red ✗.
		const dontKnow = details?.dontKnow === true;
		const correct = details?.correct === true;
		const title = dontKnow
			? "ANSWER — I don't know"
			: correct
				? "ANSWER ✓"
				: "ANSWER ✗";

		const lines: string[] = [];
		if (dontKnow) {
			lines.push("Your answer: I don't know");
		} else {
			const answers: any[] = details?.answers || [];
			lines.push(`Your answer: ${answers.map((a) => `${a.index}. ${a.label}`).join(", ") || "(none)"}`);
		}
		const correctIndices: number[] = details?.correctIndices || [];
		lines.push(`Correct answer: ${correctIndices.join(", ")}`);

		// Optional free-text note the user typed in the always-present note field.
		if (details?.note) {
			const noteLines = String(details.note).split("\n");
			lines.push(`Note: ${noteLines[0]}`);
			for (let i = 1; i < noteLines.length; i++) lines.push(noteLines[i]);
		}
		const explanation = details?.explanation ? String(details.explanation) : undefined;
		return { title, lines, explanation };
	}

	function renderBlock(block: Block, f: Fmt): string {
		const org = f === "org";
		switch (block.kind) {
			case "user":
				return org
					? `* YOU\n#+begin_quote\n${orgBody(block.text)}\n#+end_quote`
					: mdBlock("YOU", mdBody(block.text));
			case "assistant":
				return org ? orgBlock("PI", orgBody(block.text)) : mdBlock("PI", mdBody(block.text));
			case "question":
				return renderQuestions(block, f);
			case "quizAnswer": {
				const a = quizAnswerParts(block.details);
				if (org) {
					const body = [a.lines.join("\n")];
					if (a.explanation) body.push("-----", orgBody(a.explanation));
					return `* ${a.title}\n#+begin_quote\n${body.join("\n\n")}\n#+end_quote`;
				}
				// One paragraph per fact: markdown joins bare lines into a single
				// run-together paragraph inside a heading block.
				const body = a.lines.join("\n\n");
				return mdBlock(a.title, a.explanation ? `${body}\n\n${mdBody(a.explanation)}` : body);
			}
			case "askAnswer": {
				const a = askAnswerParts(block.details);
				// Nothing recognisable in the result: write nothing at all rather
				// than an empty ANSWER headline.
				if (a.lines.length === 0) return "";
				return org
					? `* ${a.title}\n#+begin_quote\n${a.lines.join("\n")}\n#+end_quote`
					: mdBlock(a.title, a.lines.join("\n\n"));
			}
		}
		return "";
	}

	// --- Message → blocks ---

	function messageText(content: any): string {
		if (typeof content === "string") return content;
		if (Array.isArray(content))
			return content
				.filter((c: any) => c.type === "text")
				.map((c: any) => c.text)
				.join("\n");
		return "";
	}

	// Skill declarations (`<skill name="..." ...> ...whole SKILL.md... </skill>`)
	// are system-injected context, not user prose. Replace each with a compact
	// marker noting the skill was loaded, so the log keeps the signal without
	// the noise. Runs on already-trimmed text.
	function stripSkillBlocks(text: string, f: Fmt): string {
		return text.replace(/<skill\b([^>]*)>[\s\S]*?<\/skill>/g, (_match, attrs: string) => {
			const name = /name="([^"]+)"/.exec(attrs)?.[1] ?? "(unknown)";
			return f === "org" ? `/${name}/` : `*${name}*`;
		});
	}

	function userBlock(text: string, f: Fmt): Block | null {
		const stripped = stripSkillBlocks(text.trim(), f).trim();
		return stripped ? { kind: "user", text: stripped } : null;
	}

	function assistantBlock(msg: any): Block | null {
		const parts = (msg.content || [])
			.filter((c: any) => c.type === "text")
			.map((c: any) => (c.text as string).trim())
			.filter((t: string) => t.length > 0);
		return parts.length > 0 ? { kind: "assistant", text: parts.join("\n\n") } : null;
	}

	// --- Event handlers ---

	pi.on("message_end", async (event, _ctx) => {
		if (!logFile) return;
		const msg = event.message;
		if (!msg || !("role" in msg)) return;

		if (msg.role === "user") {
			const block = userBlock(messageText(msg.content), fmt);
			if (block) await withLock(() => appendBlock(block));
			return;
		}

		if (msg.role === "assistant") {
			const block = assistantBlock(msg);
			if (block) await withLock(() => appendBlock(block));
			return;
		}
		// toolResult messages are handled by the tool_result event (for QA tools).
	});

	// Neither ask-tool shuffles its options, so the tool_call args are already
	// the true display order — safe to write the question live, before the user
	// answers.
	pi.on("tool_call", async (event, _ctx) => {
		if (!logFile) return;
		const toolName = (event as any).toolName;
		if (!isAskTool(toolName)) return;
		const items = extractQuestions((event as any).input);
		if (items.length === 0) return;
		const block: Block = { kind: "question", label: "Question", items };
		await withLock(() => appendBlock(block));
	});

	// quiz DOES shuffle its options inside execute(), so the tool_call args are
	// the pre-shuffle author order — NOT what the user is shown. quiz emits an
	// onUpdate() with the true (post-shuffle) order before it blocks on the
	// user's answer; wait for that instead so the logged order always matches
	// what's on screen. Guard against duplicate writes if multiple updates fire
	// for the same call.
	const loggedQuizQuestion = new Set<string>();
	pi.on("tool_execution_update", async (event, _ctx) => {
		if (!logFile) return;
		const toolName = (event as any).toolName;
		if (toolName !== "quiz") return;
		const toolCallId = (event as any).toolCallId;
		if (loggedQuizQuestion.has(toolCallId)) return;
		const shuffled = (event as any).partialResult?.details?.options as
			| Array<{ index: number; label: string }>
			| undefined;
		if (!shuffled || shuffled.length === 0) return;
		loggedQuizQuestion.add(toolCallId);
		const input = (event as any).args || {};
		const block: Block = {
			kind: "question",
			label: "Quiz",
			items: [
				{
					question: String(input.question ?? "").trim(),
					context: typeof input.details === "string" && input.details.trim() ? input.details.trim() : undefined,
					options: shuffled.map((o) => ({ label: o.label })),
				},
			],
		};
		await withLock(() => appendBlock(block));
	});

	pi.on("tool_result", async (event, _ctx) => {
		if (!logFile) return;
		const toolName = (event as any).toolName;
		if (!isQaTool(toolName)) return;
		const details = (event as any).details;
		const block: Block =
			toolName === "quiz" ? { kind: "quizAnswer", details } : { kind: "askAnswer", details };
		await withLock(() => appendBlock(block));
	});

	// --- Commands ---

	// An empty note gets a header so it opens readable and shows pictures without
	// a keypress. Org only, and only while the file is still empty — never over
	// content the user already has. This can't live in backfill: a freshly
	// linked file has nothing to backfill yet, and the header would then be
	// missing for the whole session.
	function ensurePreamble(file: string, f: Fmt): void {
		if (f !== "org") return;
		let existing = "";
		try {
			existing = fs.readFileSync(file, "utf-8");
		} catch {
			return;
		}
		if (existing.trim().length > 0) return;
		const title = path.basename(file, path.extname(file));
		try {
			fs.writeFileSync(
				file,
				`#+title: ${title}\n#+startup: inlineimages\n#+options: toc:nil\n\n`,
				"utf-8",
			);
		} catch {
			// ignore
		}
	}

	pi.registerCommand("md-log", {
		description: "Mirror the session to a .md/.org file (backfills history)",
		handler: async (args, ctx: any) => {
			const raw = args.trim();
			if (!raw) {
				ctx.ui.notify("Usage: /md-log [--create] <filepath>", "warning");
				return;
			}
			if (typeof ctx.isIdle === "function" && !ctx.isIdle()) {
				ctx.ui.notify("Wait for the agent to finish before linking.", "warning");
				return;
			}

			const create = /(^|\s)(--create|-c)(?=\s|$)/.test(raw);
			const filepath = raw.replace(/(^|\s)(--create|-c)(?=\s|$)/g, " ").trim();
			if (!filepath) {
				ctx.ui.notify("Usage: /md-log [--create] <filepath>", "warning");
				return;
			}

			const expanded = expandHome(filepath);
			const resolved = path.isAbsolute(expanded) ? expanded : path.resolve(ctx.cwd, expanded);

			// By default the file must already exist — /md-log links into an
			// existing note and never scatters new ones around, which keeps a
			// typo'd path from creating a stray file. `--create` is the explicit
			// opt-in (parent directory must already exist, for the same reason).
			if (!fs.existsSync(resolved)) {
				if (!create) {
					ctx.ui.notify(
						`File does not exist: ${resolved}\n(/md-log --create to make it)`,
						"error",
					);
					return;
				}
				try {
					fs.writeFileSync(resolved, "", { flag: "wx" });
				} catch (err: any) {
					ctx.ui.notify(`Could not create: ${resolved} (${err?.message ?? err})`, "error");
					return;
				}
			}
			if (!fs.statSync(resolved).isFile()) {
				ctx.ui.notify(`Not a file: ${resolved}`, "error");
				return;
			}

			logFile = resolved;
			sessionCwd = ctx.cwd ?? sessionCwd;
			fmt = formatFor(resolved);
			imageCache.clear();
			ensurePreamble(resolved, fmt);
			pi.appendEntry("md-log", { file: resolved });

			// Backfill the active branch.
			const { count, appended } = backfill(ctx);

			const theme = ctx.ui.theme;
			ctx.ui.setStatus(
				"md-log",
				theme.fg("accent", "🗒 ") + theme.fg("dim", path.basename(resolved)),
			);
			ctx.ui.notify(
				`Linked (${fmt}): ${resolved}\n${count} entries backfilled` +
					(appended ? " (appended to the note's existing content)" : ""),
				"success",
			);
		},
	});

	pi.registerCommand("md-unlog", {
		description: "Stop mirroring the session to a markdown/org file",
		handler: async (_args, ctx) => {
			if (!logFile) {
				ctx.ui.notify("No file linked", "warning");
				return;
			}
			const name = path.basename(logFile);
			logFile = null;
			pi.appendEntry("md-log", { file: null });
			ctx.ui.setStatus("md-log", undefined);
			ctx.ui.notify(`Unlinked: ${name}`, "info");
		},
	});

	// --- Backfill ---

	function backfill(ctx: any): { count: number; appended: boolean } {
		if (!logFile) return { count: 0, appended: false };
		const file = logFile;
		const entries: any[] = ctx.sessionManager.getEntries();
		if (entries.length === 0) return { count: 0, appended: false };

		const byId = new Map<string, any>();
		for (const e of entries) if (e.id) byId.set(e.id, e);

		// Active leaf = last entry that has an id (skip the session header).
		let leaf: any = null;
		for (let i = entries.length - 1; i >= 0; i--) {
			if (entries[i].id) {
				leaf = entries[i];
				break;
			}
		}
		if (!leaf) return { count: 0, appended: false };

		// Walk parent chain to root.
		const chain: any[] = [];
		let cur: any = leaf;
		const seen = new Set<string>();
		while (cur && cur.id && !seen.has(cur.id)) {
			seen.add(cur.id);
			chain.push(cur);
			cur = cur.parentId ? byId.get(cur.parentId) : null;
		}
		chain.reverse();

		// Track tool-call args from assistant messages so we can pair with results.
		const toolCallArgs = new Map<string, { name: string; args: any }>();

		const blocks: Block[] = [];
		let count = 0;
		for (const entry of chain) {
			if (entry.type !== "message") continue;
			const msg = entry.message;
			if (!msg || !("role" in msg)) continue;
			count++;

			if (msg.role === "user") {
				const block = userBlock(messageText(msg.content), fmt);
				if (block) blocks.push(block);
				continue;
			}

			if (msg.role === "assistant") {
				// Index tool calls for later pairing.
				for (const c of msg.content || []) {
					if (c.type === "toolCall" && isQaTool(c.name)) {
						toolCallArgs.set(c.id, { name: c.name, args: c.arguments });
					}
				}
				const block = assistantBlock(msg);
				if (block) blocks.push(block);
				continue;
			}

			if (msg.role === "toolResult") {
				if (!isQaTool(msg.toolName)) continue;
				const tc = toolCallArgs.get(msg.toolCallId);
				// Question block. For quiz, use the persisted result's `details.options`
				// — the TRUE post-shuffle display order the user actually saw — rather
				// than the original tool-call args, which are the pre-shuffle author
				// order and can mismatch what's on screen. ask_user_question never
				// shuffles, so its tool-call args are already the true order.
				if (tc) {
					const a = tc.args || {};
					if (tc.name === "quiz") {
						const shuffled = msg.details?.options as
							| Array<{ index: number; label: string }>
							| undefined;
						const options =
							shuffled && shuffled.length > 0
								? shuffled.map((o) => ({ label: o.label }))
								: normalizeOptions(a.options);
						blocks.push({
							kind: "question",
							label: "Quiz",
							items: [
								{
									question: String(a.question ?? "").trim(),
									context:
										typeof a.details === "string" && a.details.trim()
											? a.details.trim()
											: undefined,
									options,
								},
							],
						});
					} else {
						const items = extractQuestions(a);
						if (items.length > 0) blocks.push({ kind: "question", label: "Question", items });
					}
				}
				blocks.push(
					msg.toolName === "quiz"
						? { kind: "quizAnswer", details: msg.details }
						: { kind: "askAnswer", details: msg.details },
				);
				continue;
			}
		}

		if (blocks.length === 0) return { count, appended: false };

		const rendered =
			blocks
				.map((b) => renderBlock(b, fmt))
				.filter((t) => t.trim().length > 0)
				.join("\n\n") + "\n";

		// Never clobber what is already in the note. An empty file is ours to
		// seed (an org file gets a title so it doesn't open on a bare headline);
		// a file with content keeps it and the session is appended below.
		let existing = "";
		try {
			existing = fs.readFileSync(file, "utf-8");
		} catch {
			existing = "";
		}
		let payload: string;
		const appended = existing.trim().length > 0;
		if (!appended) {
			// `inlineimages` shows the visualize skill's pictures the moment the file
			// opens. LaTeX preview is deliberately NOT in STARTUP: each formula costs
			// a latex+dvipng round trip, so it stays on demand (C-c C-x C-l).
			const preamble =
				fmt === "org"
					? `#+title: ${path.basename(file, path.extname(file))}\n#+startup: inlineimages\n#+options: toc:nil\n\n`
					: "";
			payload = preamble + rendered;
		} else {
			const gap = existing.endsWith("\n\n") ? "" : existing.endsWith("\n") ? "\n" : "\n\n";
			payload = existing + gap + rendered;
		}

		try {
			fs.writeFileSync(file, payload, "utf-8");
		} catch {
			// ignore
		}
		return { count, appended };
	}
}
