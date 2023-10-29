# change-inner

An attempt at providing vim's `ci` and `ca` for Emacs.
Originally [here](https://github.com/magnars/change-inner.el),
this forks contains breaking changes and is unlikely to land upstream—hence, a separate repository.

Instead of
[expand-region](https://github.com/magnars/expand-region.el),
this fork requires
[puni](https://github.com/AmaiKinono/puni)
to work.

A usage example, from the upstream repository:

    function test() {
      return "semantic| kill";
    }

with `|` indicating the point.

 * `change-inner "` would kill the contents of the string, resulting in

       function test() {
         return "|";
       }

 * `change-inner-outer "` would kill the entire string:

       function test() {
         return |;
       }

 * `change-inner {` would kill the return-statement:

       function test() {|}

 * `change-inner-outer {` would kill the entire block:

       function test() |

## Installation

The easiest way to install this is using `package-vc.el`:

``` emacs-lisp
(package-vc-install "https://github.com/slotThe/change-inner")
```

Good keybindings for `change-inner` and `change-inner-outer` could be `M-i` and `M-o`:

``` emacs-lisp
(global-set-key (kbd "M-i") 'change-inner)
(global-set-key (kbd "M-o") 'change-inner-outer)
```

Optionally you can also use
[vc-use-package](https://github.com/slotThe/vc-use-package):

``` emacs-lisp
(use-package change-inner
  :vc (:fetcher github :repo slotThe/change-inner)
  :bind (("M-i" . change-inner)
         ("M-o" . change-inner-outer)))
```
