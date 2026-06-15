; Shadows helix's runtime queries/comment/highlights.scm (the config runtime
; dir has the highest priority). Upstream captures tag names as
; @hint/@info/@warning/@error — the same theme keys that color LSP
; diagnostics — so a theme cannot restyle comment tags without also
; repainting diagnostics. Capture every tag as @comment.todo instead;
; themes.nix styles that one key. The groups mirror upstream's severity
; split so a per-severity re-split later is a capture rename, not a rewrite.

(tag
 (name) @ui.text
 (user)? @constant)

; Upstream hint level tags
((tag (name) @comment.todo)
 (#any-of? @comment.todo "HINT" "MARK" "PASSED" "STUB" "MOCK" "TIP"))

("text" @comment.todo
 (#any-of? @comment.todo "HINT" "MARK" "PASSED" "STUB" "MOCK" "TIP"))

; Upstream info level tags
((tag (name) @comment.todo)
 (#any-of? @comment.todo "INFO" "NOTE" "TODO" "TO-DO" "PERF" "OPTIMIZE" "PERFORMANCE" "QUESTION" "ASK" "REVIEW" "PR" "CR"))

("text" @comment.todo
 (#any-of? @comment.todo "INFO" "NOTE" "TODO" "TO-DO" "PERF" "OPTIMIZE" "PERFORMANCE" "QUESTION" "ASK" "REVIEW" "PR" "CR"))

; Upstream warning level tags
((tag (name) @comment.todo)
 (#any-of? @comment.todo "HACK" "WARN" "WARNING" "TEST" "TEMP"))

("text" @comment.todo
 (#any-of? @comment.todo "HACK" "WARN" "WARNING" "TEST" "TEMP"))

; Upstream error level tags
((tag (name) @comment.todo)
 (#any-of? @comment.todo "BUG" "FIXME" "ISSUE" "XXX" "FIX" "SAFETY" "FIXIT" "FAILED" "DEBUG" "INVARIANT" "COMPLIANCE" "PANIC" "SECURITY"))

("text" @comment.todo
 (#any-of? @comment.todo "BUG" "FIXME" "ISSUE" "XXX" "FIX" "SAFETY" "FIXIT" "FAILED" "DEBUG" "INVARIANT" "COMPLIANCE" "PANIC" "SECURITY"))

; Issue number (#123)
("text" @constant.numeric
 (#match? @constant.numeric "^#[0-9]+$"))

; User mention (@user)
("text" @tag
 (#match? @tag "^[@][a-zA-Z0-9_-]+$"))

(uri) @markup.link.url
