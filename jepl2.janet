(var prompt "jepl> ")
(def NEWLINE 10)

(defn for-any?
    "returns true if predicate `pred` is true for any element in `collection`"
    [collection pred]
    (reduce (fn [a b] (or a (pred b))) false collection))

(defn rgb [r g b]
    @{ :red r :green g :blue b
       :enable (fn [self] (file/write stdout (string "\x1b[38;2;" r ";" g ";" b "m")))
       :close (fn [self] (file/write stdout "\x1b[0m") (flush))})

(defn initialize-repl []
    (print "Welcome to JEPL, an alternative Janet REPL!")
    (eval '(var ans nil)))

(defn ?docs [query]
    (with [output-color (rgb 130 220 110)]
        (:enable output-color)
        (doc* (symbol query))))

(defn needs-parens? [expr]
    (and
        (not (for-any? [":" "@" "\"" "'" "(" ")"] |(string/has-prefix? $ expr)))
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

(defmacro quit-repl []
    '(do (print) (error :exit)))

(defn main [args]
    (initialize-repl)
    (try
        (forever
            (var input (getline prompt))
            (if (empty? input)
                (quit-repl) # EOF
                (set input (string/trim input)))
            (cond
                (empty? input) ()
                (= input "exit") (quit-repl)
                (string/has-prefix? "#" input) ()
                (for-any? ["(??" ")??" " ??"] |(string/has-suffix? $ input))
                    (?docs (first (string/split " " (->
                        input
                        (string/slice 0 -4)
                        (string/triml " ()'")))))

                # default:
                (print (string/format "%M" (my-eval input)))))
        ([err]
            (if (not (= :exit err))
                (print err)))))
