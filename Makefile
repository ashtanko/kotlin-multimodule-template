.PHONY: default check lint format spotless detekt diktat test report treport lines md all kover bump-gradle

# Static-analysis tasks. Each fans out to every module (template.kotlin-library convention plugin),
# with every diktat and detekt rule enabled over main and test sources. --continue reports every
# failing tool/module in one pass instead of stopping at the first.
LINT_TASKS := spotlessCheck detekt diktatCheck

check:
	./gradlew spotlessApply $(LINT_TASKS) --continue --profile --daemon

# Verify-only twin of `check` (no auto-format) — what CI runs.
lint:
	./gradlew $(LINT_TASKS) --continue

format:
	./gradlew spotlessApply

default:
	make check && make md

md:
	./gradlew detektMergeMd && truncate -s0 README.md && cat config/main.md >> README.md && cat build/reports/detekt/detekt.md >> README.md && cat config/license.md >> README.md

all:
	make check && ./gradlew build && make md

test:
	./gradlew test

report:
	./gradlew jacocoTestReport

treport:
	make test && make report

lines:
	find . -name '*.kt' | xargs wc -l

kover:
	./gradlew koverHtmlReport

spotless:
	./gradlew spotlessCheck --continue

diktat:
	./gradlew diktatCheck --continue

detekt:
	./gradlew detekt --continue

bump-gradle:
	chmod +x gradlew && ./gradlew wrapper --gradle-version 9.5

.DEFAULT_GOAL := default

