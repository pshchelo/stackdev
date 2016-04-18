.PHONY: default all deps build final iso clean clean_cache clean_build clean_final clean_iso

default: deps build final

all: deps build final iso

deps:
	./install-deps.sh

build:
	./build.sh

final:
	./final.sh

iso:
	./build-iso.sh

clean: clean_cache clean_build clean_final clean_iso

clean_cache:
	rm -f build_files/corepure64.gz
	rm -f build_files/vmlinuz64

clean_build:
	sudo -v
	sudo rm -rf build
	rm -f build_files/*.tcz
	rm -f build_files/*.tcz.*

clean_final:
	sudo -v
	sudo rm -rf final
	rm -f irsible*.vmlinuz
	rm -f irsible*.gz

clean_iso:
	rm -rf newiso
	rm -f build_files/syslinux-4.06.tar.gz
	rm -rf build_files/syslinux-4.06
	rm -f irsible.iso

umount_build:
	sudo -v
	sudo umount build/proc
	sudo umount build/tmp/tcloop/*

umount_final:
	sudo -v
	sudo umount final/proc
	sudo umount final/tmp/tcloop/*
