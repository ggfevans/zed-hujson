; Strings
(string) @string
(escape_sequence) @string.escape

; Numbers
(number) @number

; Booleans and null
(true) @constant.builtin
(false) @constant.builtin
(null) @constant.builtin

; Object keys. @property is a fallback for themes that don't define
; @property.json_key (Zed resolves capture lists right-to-left).
(pair
  key: (string) @property.json_key @property)

; Punctuation
"{" @punctuation.bracket
"}" @punctuation.bracket
"[" @punctuation.bracket
"]" @punctuation.bracket
":" @punctuation.delimiter
"," @punctuation.delimiter

; Comments
(comment) @comment
