(require 'psc-ide)

(defconst psc-ide-test-example-imports "
module Main where

import Prelude hiding (compose)

import Control.Monad.Aff (Aff(), runAff, later')
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Exception (throwException)
import Halogen hiding (get, set) as H

import Halogen.Util (appendToBody, onLoad)
import 		Halogen.HTML.Indexed 		as 	Hd
import Halogen.HTML.Properties.Indexed (key, href) as P
import Halogen.HTML.Events.Indexed as P

")

(defun psc-ide-test-example-with-buffer (f)
  (with-temp-buffer
    (insert psc-ide-test-example-imports)
    (goto-char 0)
    (funcall f)))

(defun psc-ide-test-parse-example-imports ()
  (psc-ide-test-example-with-buffer
    (lambda () (psc-ide-parse-imports-in-buffer))))

;; Module  import parsing tests

(ert-deftest test-get-import-matches-in-buffer-should-return-all-imports ()
  (with-temp-buffer
    (insert psc-ide-test-example-imports)
    (goto-char 0)
    (let ((matches (psc-ide-parse-imports-in-buffer)))
      (should (= 10 (length matches))))))

(defun test-import (import name as)
    (string-match psc-ide-import-regex import)
    (let* ((import (psc-ide-extract-import-from-match-data import)))
      (should (equal (assoc 'module import) (cons 'module name)))
      (should (equal (assoc 'qualifier import) (cons 'qualifier as)))))

(ert-deftest test-get-import-from-match-data-full ()
  (test-import "import Mod.SubMod (foo, bar) as El"
               "Mod.SubMod"
               "El"))

(ert-deftest test-match-import-single-module ()
  (test-import "import Foo" "Foo" nil))

(ert-deftest test-match-import-with-qualifier ()
  (test-import "import Foo as F" "Foo" "F"))

(ert-deftest test-match-import-with-single-expose ()
  (test-import "import Foo (test)" "Foo" nil))

(ert-deftest test-match-import-with-multiple-exposings-tight ()
  (test-import "import Foo (test1,test2)" "Foo" nil))

(ert-deftest test-match-import-with-multiple-exposings-loose ()
  (test-import "import Foo ( test1 , test2 )" "Foo" nil))

(ert-deftest test-match-import-with-qualifier+multiple-exposings-tight ()
  (test-import "import Foo (test1,test2) as F" "Foo" "F"))

(ert-deftest test-match-import-with-qualifier+multiple-exposings-loose ()
  (test-import
   "import Foo ( test1 , test2 ) as F"
   "Foo"
   "F"))

(ert-deftest test-all-imported-modules ()
  (let ((imports (psc-ide-test-example-with-buffer
                   (lambda () (psc-ide-all-imported-modules)))))
    (should (equal (length imports) 10))))

(ert-deftest test-moduels-for-qualifier ()
  (let ((imports (psc-ide-test-example-with-buffer
                   (lambda () (psc-ide-modules-for-qualifier "P")))))
    (should (equal (length imports) 2))))

(ert-deftest test-get-completion-settings ()
  (psc-ide-test-example-with-buffer
    (lambda ()
      (let* ((command (json-read-from-string (psc-ide-build-completion-command "P.a" nil)))
             (params (cdr (assoc 'params command)))
             (filters (append (cdr (assoc 'filters params)) nil))
             (search (-some (lambda (filter)
                               (when (equal "prefix" (cdr (assoc 'filter filter)))
                                 (cdr (assoc 'search (cdr (assoc 'params filter)))))) filters))
             (modules (-some (lambda (filter)
                               (when (equal "modules" (cdr (assoc 'filter filter)))
                                 (cdr (assoc 'modules (cdr (assoc 'params filter)))))) filters)))
        (should (equal search "a"))
        (should (equal (length modules) 2))))))
