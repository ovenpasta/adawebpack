EXAMPLE_DIRS = \
	basic \
	basic_c \
	image \
	ttf

.PHONY: all clean $(EXAMPLE_DIRS)

all:
	for d in $(EXAMPLE_DIRS); do $(MAKE) -C $$d; done

$(EXAMPLE_DIRS):
	$(MAKE) -C $@

clean:
	for d in $(EXAMPLE_DIRS); do $(MAKE) -C $$d clean; done
