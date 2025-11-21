.PHONY: help pub-dry-run pub-publish

help:
	@echo "Targets:"
	@echo "  pub-dry-run   Run dart pub publish --dry-run"
	@echo "  pub-publish   Publish the package (non-interactive, uses --force)"

pub-dry-run:
	dart pub publish --dry-run

pub-publish:
	dart pub publish --force
