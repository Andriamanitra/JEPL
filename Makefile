.PHONY: run
run: completions.txt
	rlwrap -f completions.txt --always-readline janet jepl2.janet

clean:
	rm completions.txt

completions:
	janet -e "(each b (all-bindings) (print b))" > completions
