.PHONY: run
run: completions
	rlwrap -f completions --always-readline janet jepl2.janet

clean:
	rm completions

completions:
	janet -e "(each b (all-bindings) (print b))" > completions
