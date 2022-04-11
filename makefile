prefix ?= /usr/local
bin = $(prefix)/bin

mcal:
	swiftc main.swift -o mcal2json

install: mcal
	install -d "$(bin)"
	install mcal2json "$(bin)"

uninstall:
	rm -rf "$(bin)/mcal2json"

clean:
	rm -rf mcal

.PHONY: mcal install uninstall clean
