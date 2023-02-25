
(c) Chris Pinnock 2022-2023
MIT license

The directory is designed to live at tezos/scripts/dpkg.

The following patch to the top level Makefile includes a dpkg
target:

```
diff --git a/Makefile b/Makefile
index 00613735b4..24d355061e 100644
--- a/Makefile
+++ b/Makefile
@@ -374,6 +374,10 @@ fmt-ocaml:
 fmt-python:
        @$(MAKE) -C tests_python fmt

+.PHONY: dpkg
+dpkg:  all
+       @./scripts/dpkg/make_dpkg.sh
+
 .PHONY: build-deps
 build-deps:
        @./scripts/install_build_deps.sh
@@ -471,8 +475,12 @@ uninstall:
 coverage-clean:
        @-rm -Rf ${COVERAGE_OUTPUT}/*.coverage ${COVERAGE_REPORT}

+.PHONY: dpkg-clean
+dpkg-clean:
+       @-rm -rf _dpkgstage *.deb
+
 .PHONY: clean
-clean: coverage-clean clean-old-names
+clean: coverage-clean clean-old-names dpkg-clean
        @-dune clean
        @-rm -f ${OCTEZ_BIN} ${UNRELEASED_OCTEZ_BIN}
        @-${MAKE} -C docs clean
```
