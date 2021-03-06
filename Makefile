.PHONY: format tags clean run

export PF_USER_CUSTOM = ../../boardforth.c
export LDADD          = -L/usr/local/lib -lSDL2

TAGS_OPTS = --declarations -o TAGS

build: boardforth

boardforth: boardforth.c
	$(MAKE) -C pforth/build/unix pfdicdat
	mv pforth/build/unix/pforth.dic .
	$(MAKE) -C pforth/build/unix clean
	cp pforth.dic pforth/build/unix/
	$(MAKE) -C pforth/build/unix pfdicapp EXTRA_CCOPTS="-DPF_NO_MAIN"
	mv pforth/build/unix/pforth ./boardforth

tags:
	find . -type f -iname "*.[ch]" | etags $(TAGS_OPTS) -

format: boardforth.c
	clang-format -i boardforth.c

clean: 
	$(MAKE) -C pforth/build/unix clean
	rm pforth.dic boardforth

run: boardforth
	./boardforth
