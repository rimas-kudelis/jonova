SOURCES=$(shell python3 scripts/read-configs.py --sources )
FAMILY=$(shell python3 scripts/read-configs.py --family )
DRAWBOT_SCRIPTS=$(shell ls documentation/*.py)
DRAWBOT_OUTPUT=$(shell ls documentation/*.py | sed 's/\.py/.png/g')

help:
	@echo "###"
	@echo "# Build targets for $(FAMILY)"
	@echo "###"
	@echo
	@echo "  make build:  Builds the fonts and places them in the fonts/ directory"
	@echo "  make test:   Tests the fonts with fontbakery"
	@echo "  make proof:  Creates HTML proof documents in the proof/ directory"
	@echo "  make images: Creates PNG specimen images in the documentation/ directory"
	@echo

build: build.stamp

venv: venv/touchfile

venv-test: venv-test/touchfile

fontvalidator:
	curl -L https://github.com/HinTak/Font-Validator/releases/download/FontVal-2.1.6/FontVal-2.1.6-ubuntu-18.04-x64.tgz -o- | tar -xzO FontVal-2.1.6-ubuntu-18.04-x64/FontValidator-ubuntu-18.04-x64 > fontvalidator
	chmod +x fontvalidator

customize: venv
	. venv/bin/activate; python3 scripts/customize.py

build.stamp: venv sources/config-Jonova.yaml sources/config-JonovaCondensed.yaml sources/features.fea $(SOURCES)
	rm -rf fonts
	(for config in sources/config*.yaml; do . venv/bin/activate; gftools builder $$config; done)  && touch build.stamp

venv/touchfile: requirements.txt
	test -d venv || python3 -m venv venv
	. venv/bin/activate; pip install -Ur requirements.txt
	touch venv/touchfile

venv-test/touchfile: requirements-test.txt
	test -d venv-test || python3 -m venv venv-test
	. venv-test/bin/activate; pip install -Ur requirements-test.txt
	touch venv-test/touchfile

test: test-jonova test-jonova-condensed

test-jonova: venv-test build.stamp
	TOCHECK=$$(find fonts/variable -type f -name "Jonova-*" 2>/dev/null); if [ -z "$$TOCHECK" ]; then TOCHECK=$$(find fonts/ttf -type f -name "Jonova-*" 2>/dev/null); fi; . venv-test/bin/activate; mkdir -p out/badges/Jonova out/fontbakery/Jonova; fontbakery check-googlefonts --exclude-checkid com.google.fonts/check/vendor_id -l WARN --full-lists--succinct --badges out/badges/Jonova --html out/fontbakery/Jonova/fontbakery-report.html --ghmarkdown out/fontbakery/Jonova/fontbakery-report.md $$TOCHECK || echo '::warning file=sources/config-Jonova.yaml,title=Fontbakery failures::The fontbakery QA check reported errors in Jonova. Please check the generated report.'

test-jonova-condensed: venv-test build.stamp
	TOCHECK=$$(find fonts/variable -type f -name "JonovaCondensed-*" 2>/dev/null); if [ -z "$$TOCHECK" ]; then TOCHECK=$$(find fonts/ttf -type f -name "JonovaCondensed-*" 2>/dev/null); fi; . venv-test/bin/activate; mkdir -p out/badges/JonovaCondensed out/fontbakery/JonovaCondensed; fontbakery check-googlefonts --exclude-checkid com.google.fonts/check/vendor_id -l WARN --full-lists --succinct --badges out/badges/JonovaCondensed --html out/fontbakery/JonovaCondensed/fontbakery-report.html --ghmarkdown out/fontbakery/JonovaCondensed/fontbakery-report.md $$TOCHECK || echo '::warning file=sources/config-JonovaCondensed.yaml,title=Fontbakery failures::The fontbakery QA check reported errors in Jonova Condensed. Please check the generated report.'
	sed -i 's^"label": "^"label": "Cond: ^g' out/badges/JonovaCondensed/*.json

fv-test: fv-test-jonova fv-test-jonova-condensed
	cd out/fontvalidator; echo "" > index.html; for FILE in $$(find . -type f); do echo "<p><a href='$$FILE'>$$(basename $$FILE)</a></p>" >> index.html; done

fv-test-jonova: fontvalidator build.stamp
	TOCHECK=$$(find fonts/variable -type f -name "Jonova-*" -exec echo "-file {}" \; 2>/dev/null); if [ -z "$$TOCHECK" ]; then echo $$(find fonts/ttf -type f -name "Jonova-*" -exec echo "-file {}" \; 2>/dev/null); TOCHECK=$$(find fonts/ttf -type f -exec echo "-file {}" \; 2>/dev/null); fi; mkdir -p out/fontvalidator; ./fontvalidator -all-tables -report-dir out/fontvalidator $$TOCHECK || echo '::warning file=sources/config-Jonova.yaml,title=FontValidator failures::The FontValidator QA check reported errors in Jonova. Please check the generated reports.'; cd out/fontvalidator; echo "" > index.html; for FILE in $$(find . -type f); do echo "<p><a href='$$FILE'>$$(basename $$FILE)</a></p>" >> index.html; done

fv-test-jonova-condensed: fontvalidator build.stamp
	TOCHECK=$$(find fonts/variable -type f -name "JonovaCondensed-*" -exec echo "-file {}" \; 2>/dev/null); if [ -z "$$TOCHECK" ]; then echo $$(find fonts/ttf -type f -name "JonovaCondensed-*" -exec echo "-file {}" \; 2>/dev/null); TOCHECK=$$(find fonts/ttf -type f -exec echo "-file {}" \; 2>/dev/null); fi; mkdir -p out/fontvalidator; ./fontvalidator -all-tables -report-dir out/fontvalidator $$TOCHECK || echo '::warning file=sources/config-JonovaCondensed.yaml,title=FontValidator failures::The FontValidator QA check reported errors in Jonova Condensed. Please check the generated reports.'; cd out/fontvalidator; echo "" > index.html; for FILE in $$(find . -type f); do echo "<p><a href='$$FILE'>$$(basename $$FILE)</a></p>" >> index.html; done

proof: proof-jonova proof-jonova-condensed

proof-jonova: venv build.stamp
	TOCHECK=$$(find fonts/variable -type f -name "Jonova-*" 2>/dev/null); if [ -z "$$TOCHECK" ]; then TOCHECK=$$(find fonts/ttf -type f -name "Jonova-*" 2>/dev/null); fi ; . venv/bin/activate; mkdir -p out/proof/Jonova; diffenator2 proof $$TOCHECK -o out/proof/Jonova

proof-jonova-condensed: venv build.stamp
	TOCHECK=$$(find fonts/variable -type f -name "JonovaCondensed-*" 2>/dev/null); if [ -z "$$TOCHECK" ]; then TOCHECK=$$(find fonts/ttf -type f -name "JonovaCondensed-*" 2>/dev/null); fi ; . venv/bin/activate; mkdir -p out/proof/JonovaCondensed; diffenator2 proof $$TOCHECK -o out/proof/JonovaCondensed

# The following four targets are likely temporary. They're meant to diffenate the font
# produced from current status of the main branch against Fotonija's last release.
# In future, this could probably be reworked to diff a PR against current parent branch.
diff: diff-jonova diff-jonova-condensed

diff-jonova: venv build.stamp jonova-2.032
	TOCHECK=$$(find fonts/variable -type f -name "Jonova-*" 2>/dev/null); \
	if [ -z "$$TOCHECK" ]; then TOCHECK=$$(find fonts/ttf -type f -name "Jonova-*" 2>/dev/null); fi; \
	. venv/bin/activate; \
	mkdir -p out/proof/Jonova; \
	diffenator2 diff --imgs --debug-gifs --fonts-before jonova-2.032/Jonova/*.ttf --fonts-after $$TOCHECK --out out/proof/Jonova

diff-jonova-condensed: venv build.stamp
	TOCHECK=$$(find fonts/variable -type f -name "JonovaCondensed-*" 2>/dev/null); \
	if [ -z "$$TOCHECK" ]; then TOCHECK=$$(find fonts/ttf -type f -name "JonovaCondensed-*" 2>/dev/null); fi; \
	. venv/bin/activate; \
	mkdir -p out/proof/JonovaCondensed; \
	diffenator2 diff --imgs --debug-gifs --fonts-before jonova-2.032/JonovaCondensed/*.ttf --fonts-after $$TOCHECK --out out/proof/JonovaCondensed

jonova-2.032:
	curl -L https://github.com/rimas-kudelis/jonova/archive/refs/tags/v2.032.tar.gz -o- | tar -xz
	mv "jonova-2.032/Jonova Condensed" jonova-2.032/JonovaCondensed

images: venv $(DRAWBOT_OUTPUT)

%.png: %.py build.stamp
	. venv/bin/activate; python3 $< --output $@

clean:
	rm -rf venv
	find . -name "*.pyc" -delete

update-project-template:
	npx update-template https://github.com/googlefonts/googlefonts-project-template/

update: venv venv-test
	venv/bin/pip install --upgrade pip-tools
	# See https://pip-tools.readthedocs.io/en/latest/#a-note-on-resolvers for
	# the `--resolver` flag below.
	venv/bin/pip-compile --upgrade --verbose --resolver=backtracking requirements.in
	venv/bin/pip-sync requirements.txt

	venv-test/bin/pip install --upgrade pip-tools
	venv-test/bin/pip-compile --upgrade --verbose --resolver=backtracking requirements-test.in
	venv-test/bin/pip-sync requirements-test.txt

	git commit -m "Update requirements" requirements.txt requirements-test.txt
	git push
