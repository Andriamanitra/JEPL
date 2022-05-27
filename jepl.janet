(var prompt "jepl> ")
(var repl-history @[])
(var history-index 0)
(var cursor 0)
(var completions @[])
(var completion-index nil)

(defn rgb [r g b]
    @{ :red r :green g :blue b
       :enable (fn [self] (file/write stdout (string "\x1b[38;2;" r ";" g ";" b "m")))
       :close (fn [self] (file/write stdout "\x1b[0m"))})

(defn addstr [row col text]
    (file/write stdout
        (string "\x1b7\x1b[" row ";" col "f" text "\x1b8")))

(defn write-history [new-entry]
    (if (and (not (empty? new-entry)) (not= new-entry (last repl-history)))
        (do
            (array/push repl-history new-entry)
            (set history-index (length repl-history)))))

(defn prev-history []
    (if (< 0 history-index)
        (do
            (-- history-index)
            (get repl-history history-index ""))))

(defn next-history []
    (if (< history-index (length repl-history)) (do
        (++ history-index)
        (get repl-history history-index ""))))

(defn initialize-repl []
    (print "Welcome to JEPL, an alternative Janet REPL!")
    (eval '(var ans nil)))

(defn ?docs [query]
    (with [output-color (rgb 130 220 110)]
        (:enable output-color)
        (doc* (symbol query))))

(defn colored [text r g b]
    (string "\x1b[38;2;" r ";" g ";" b "m" text "\x1b[0m"))

(defn needs-parens? [expr]
    (and
        (not (string/has-prefix? ":" expr))
        (not (string/has-prefix? "@" expr))
        (not (string/has-prefix? "\"" expr))
        (not (string/has-prefix? "'" expr))
        (not (string/has-prefix? "(" expr)) #)
        (string/find " " expr)))

(defn my-eval [input]
    (def to-eval
        (if (needs-parens? input)
            (string "(" input ")")
            input))
    (try
        (do
            (def result (eval-string (string "(var ans " to-eval ")")))
            result)
        ([err]
            (with [output-color (rgb 240 0 0)]
                (:enable output-color)
                (print err))
            (eval '(var ans nil)))))

(defn is-line? [buf]
    (= 10 (last buf)))

(defn is-space? [ascii-code] (= 32 ascii-code))

(defn is-alphabetic? [ascii-value]
    (or
        (< 64 ascii-value 91)
        (< 96 ascii-value 123)))

(defn is-printable? [ascii-value]
    (or
        (= 10 ascii-value)
        (< 31 ascii-value 127)
        (< 127 ascii-value)))

(defn full-seq? [buf]
    (cond
        (empty? buf) false
        (not= 0x1b (first buf)) true
        (is-alphabetic? (last buf)) true
        (= 0x7e (last buf)) true
        false))

(defn at-last-element? [cursor]
    (= cursor (length (dyn :buf))))

(defn at-word-border? [cursor]
    (def non-word-chars " \t\n()")
    (cond
        (= 0 cursor) true
        (at-last-element? cursor) true
        (is-space? (get (dyn :buf) cursor)) true
        false))

(defmacro quit-repl []
    '(do (print) (error :exit)))

(defn to-byte-string [buf]
    (string ;(map |(string/format "\\x%02x" $) buf)))

(defn erase-char []
    (def buf (dyn :buf))
    (if-not (empty? buf)
        (do
            (buffer/blit buf buf (dec cursor) cursor)
            (buffer/popn buf 1)
            (-- cursor)
            (def num-chars-after (- (length buf) cursor))
            (file/write stdout
                # overwrite whatever was there before
                "\x08" (buffer/slice buf cursor) " \x08"
                # move back to cursor
                (string/repeat "\x08" num-chars-after)))))

(defn erase-word []
    (def buf (dyn :buf))
    (while (is-space? (get buf (dec cursor)))
        (erase-char))
    (while (and (pos? cursor) (not (is-space? (last buf))))
        (erase-char)))

(defn move-cursor-right []
    (if-not (at-last-element? cursor)
        (do
            (file/write stdout "\e[C")
            (++ cursor))))

(defn move-cursor-left []
    (if (pos? cursor)
        (do
            (file/write stdout "\x08")
            (-- cursor))))

(defn move-cursor-to-beginning []
    (while (pos? cursor)
        (move-cursor-left)))

(defn move-cursor-to-end []
    (while (not (at-last-element? cursor))
        (move-cursor-right)))

(defn replace-buffer [new-buf]
    (def buf (dyn :buf))
    (move-cursor-to-end)
    (while (not (empty? buf))
        (buffer/popn buf 1)
        (file/write stdout "\x08 \x08"))
    (buffer/clear buf)
    (buffer/push buf new-buf)
    (set cursor (length buf))
    (file/write stdout buf))

(defn write-char [ch]
    (def buf (dyn :buf))
    (set completion-index nil)
    (file/write stdout ch)
    (if-not (at-last-element? cursor)
        (buffer/blit buf buf (+ 1 cursor) cursor))
    (buffer/blit buf ch cursor)
    (++ cursor)
    (def chars-after (buffer/slice buf cursor))
    (file/write stdout chars-after)
    (file/write stdout (string/repeat "\x08" (length chars-after))))


(defn find-completions [query]
    (filter |(string/has-prefix? query $) (map string (all-bindings))))

(defn update-completions []
    (set completions (find-completions (dyn :buf)))
    (set completion-index -1))

(defn prev-completion []
    (-- completion-index)
    (if (neg? completion-index)
        (set completion-index (dec (length completions))))
    (get completions completion-index))

(defn next-completion []
    (++ completion-index)
    (if (= completion-index (length completions)) (set completion-index 0))
    (get completions completion-index))

(defn handle-unknown-escape-seq [tmp-buf]
    (def text
        (string
            ">  Received unknown escape sequence: "
            (to-byte-string tmp-buf)
            "                      "))
    (with [output-color (rgb 240 0 0)]
        (:enable output-color)
        (addstr 1 1 text)))

(defn handle-escape-seq [tmp-buf]
    (match (string tmp-buf)
        "\x04" (quit-repl) # EOF (ctrl+d)
        "\x11" (quit-repl) # ctrl-q
        "\x01" (move-cursor-to-beginning) # ctrl-a
        "\x05" (move-cursor-to-end) # ctrl-e
        "\x08" (erase-word) # ctrl-backspace
        "\x17" (erase-word) # ctrl-w
        "\x7f" (erase-char) # backspace
        "\x09" # tab
            (do
                (if (nil? completion-index) (update-completions))
                (if-not (empty? completions) (replace-buffer (next-completion))))
        "\x1b\x5b\x5a" # shift-tab
            (do
                (if (nil? completion-index) (update-completions))
                (if-not (empty? completions) (replace-buffer (prev-completion))))
        "\e\x5b\x33\x7e" # delete key
            (if (not (at-last-element? cursor))
                (do (move-cursor-right) (erase-char)))
        "\e[A" # arrow up
            (if-let [entry (prev-history)]
                (replace-buffer entry))
        "\e[B" # arrow down
            (if-let [entry (next-history)]
                (replace-buffer entry))
        "\e[C" # arrow right
            (move-cursor-right)
        "\e[D" # arrow left
            (move-cursor-left)
        "\e\x5b\x48" # home
            (move-cursor-to-beginning)
        "\e\x5b\x46" # end
            (move-cursor-to-end)
        "\e\x5b\x31\x3b\x35\x44" # ctrl-left
            (do
                (move-cursor-left)
                (while (not (at-word-border? cursor))
                    (move-cursor-left)))
        "\x1b\x5b\x31\x3b\x35\x43" # ctrl-right
            (do
                (move-cursor-right)
                (while (not (at-word-border? cursor))
                    (move-cursor-right)))
        (handle-unknown-escape-seq tmp-buf)))

(defn get-input []
    (file/write stdout prompt)
    (def NEWLINE 10)
    (with-dyns [:buf @""]
        (forever
            (def tmp-buf @"")
            (while (not (full-seq? tmp-buf))
                (def byte (file/read stdin 1))
                (if (nil? byte) (quit-repl))
                (buffer/push tmp-buf byte))
            (if (= NEWLINE (first tmp-buf)) (break))
            (if (is-printable? (first tmp-buf))
                (write-char tmp-buf)
                (handle-escape-seq tmp-buf)))
        (def input (string/trim (string (dyn :buf))))
        (write-history input)
        (print)
        (set cursor 0)
        input))


(defn for-any?
    "returns true if predicate `pred` is true for any element in `collection`"
    [collection pred]
    (reduce (fn [a b] (or a (pred b))) false collection))

(defn main [args]
    (initialize-repl)
    (try
        (forever
            (def input (get-input))
            (cond
                (empty? input) ()
                (string/has-prefix? "#" input) ()
                (for-any? ["(??" ")??" " ??"] |(string/has-suffix? $ input))
                    (?docs (first (string/split " " (->
                        input
                        (string/slice 0 -4)
                        (string/triml " ()'")))))
                (= input "exit") (quit-repl)

                # default:
                (print (string/format "%M" (my-eval input)))))
        ([err]
            (if (not (= :exit err))
                (print err)))))
