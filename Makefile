SHELL     	:= /bin/bash
HELIX_ROOT	:= $(HOME)/git/helix
CARGO_BIN 	:= $(HOME)/.cargo/bin
NIGHTLY_EXE := $(HOME)/.cargo/bin/hx_nightly

.PHONY: build_helix run_helix set_nightly

build_helix:
	@echo "Available flavours:"; \
	ls -d $(HELIX_ROOT)/*/ | xargs -n1 basename; \
	read -p "Subfolder to compile: " flavour; \
	cd $(HELIX_ROOT)/$$flavour/helix && \
	cargo install --profile opt --config 'build.rustflags="-C target-cpu=native"' --path helix-term --locked && \
	mv $(CARGO_BIN)/hx $(CARGO_BIN)/hx_$$flavour

set_nightly:
	@echo "Available executables:"; \
	ls $(CARGO_BIN) | grep '^hx_'; \
	read -p "Executable to become nightly: " exe; \
	ln -sf $(CARGO_BIN)/$$exe $(NIGHTLY_EXE)

run_helix:
	@echo "Available executables:"; \
	ls $(CARGO_BIN) | grep '^hx_'; \
	read -p "Executable to run: " exe; \
	flavour=$${exe#hx_}; \
	export HELIX_RUNTIME=$(HELIX_ROOT)/$$flavour/helix/runtime; \
	$(CARGO_BIN)/$$exe -w $(HOME)/git/rsvr
