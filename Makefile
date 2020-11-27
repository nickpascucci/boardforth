.PHONY: format tags clean run


# This must be relative to the pForth build directory.
export PF_USER_CUSTOM = ../../boardforth.c
# export PF_NO_MAIN     = 1
export LDADD          = -L/usr/local/lib -lSDL2


TAGS_OPTS = --declarations -o TAGS

build: boardforth.c
	$(MAKE) -C pforth/build/unix
	mv pforth/build/unix/pforth ./boardforth
	mv pforth/build/unix/pforth.dic .

tags:
	find . -type f -iname "*.[ch]" | etags $(TAGS_OPTS) -

format: boardforth.c
	clang-format -i boardforth.c

clean: 
	rm -rf build

run: build
	./boardforth
