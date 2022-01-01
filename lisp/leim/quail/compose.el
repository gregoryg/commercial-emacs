;;; compose.el --- Quail package for Multi_key character composition -*-coding: utf-8; lexical-binding: t -*-

;; Copyright (C) 2020-2022 Free Software Foundation, Inc.

;; Author: Juri Linkov <juri@linkov.net>
;; Keywords: multilingual, input method, i18n

;; This file is NOT part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This input method supports the same key sequences as defined by the
;; standard X Multi_key: https://en.wikipedia.org/wiki/Compose_key

;; You can enable this input method transiently with `C-u C-x \ compose RET'.
;; Then typing `C-x \' will enable this input method temporarily, and
;; after typing a key sequence it will be disabled.  So typing
;; e.g. `C-x \ E =' will insert the Euro sign character, and disable
;; this input method automatically afterwards.

;;; Code:

(require 'quail)

(quail-define-package
 "compose" "UTF-8" "+" t
 "Compose-like input method with the same key sequences as X Multi_key.
Examples:
 E = -> €   1 2 -> ½   ^ 3 -> ³"
 '(("\t" . quail-completion))
 t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ("''" ?´)
 ("-^" ?¯)
 ("^-" ?¯)
 ("__" ?¯)
 ("_^" ?¯)
 (" (" ?˘)
 ("( " ?˘)
 ("\"\"" ?¨)
 (" <" ?ˇ)
 ("< " ?ˇ)
 ("-- " ?­)
 ("++" ?#)
 ("' " ?\')
 (" '" ?\')
 ("AT" ?@)
 ("((" ?\[)
 ("//" ["\\\\"])
 ("/<" ["\\\\"])
 ("</" ["\\\\"])
 ("))" ?\])
 ("^ " ?^)
 (" ^" ?^)
 ("> " ?^)
 (" >" ?^)
 ("` " ?`)
 (" `" ?`)
 (", " ?¸)
 (" ," ?¸)
 (",," ?¸)
 ("(-" ?\{)
 ("-(" ?\{)
 ("/^" ?|)
 ("^/" ?|)
 ("VL" ?|)
 ("LV" ?|)
 ("vl" ?|)
 ("lv" ?|)
 (")-" ?\})
 ("-)" ?\})
 ("~ " ?~)
 (" ~" ?~)
 ("- " ?~)
 (" -" ?~)
 ("  " ? )
 (" ." ? )
 ("oc" ?©)
 ("oC" ?©)
 ("Oc" ?©)
 ("OC" ?©)
 ("Co" ?©)
 ("CO" ?©)
 ("or" ?®)
 ("oR" ?®)
 ("Or" ?®)
 ("OR" ?®)
 ("Ro" ?®)
 ("RO" ?®)
 (".>" ?›)
 (".<" ?‹)
 (".." ?…)
 (".-" ?·)
 (".^" ?·)
 ("^." ?·)
 (".=" ?•)
 ("!^" ?¦)
 ("!!" ?¡)
 ("p!" ?¶)
 ("P!" ?¶)
 ("+-" ?±)
 ("-+" ?±)
 ("??" ?¿)
 ("ss" ?ß)
 ("SS" ?ẞ)
 ("oe" ?œ)
 ("OE" ?Œ)
 ("ae" ?æ)
 ("AE" ?Æ)
 ("ff" ?ﬀ)
 ("fi" ?ﬁ)
 ("fl" ?ﬂ)
 ("Fi" ?ﬃ)
 ("Fl" ?ﬄ)
 ("IJ" ?Ĳ)
 ("Ij" ?Ĳ)
 ("ij" ?ĳ)
 ("oo" ?°)
 ("*0" ?°)
 ("0*" ?°)
 ("<<" ?«)
 (">>" ?»)
 ("<'" ?‘)
 ("'<" ?‘)
 (">'" ?’)
 ("'>" ?’)
 (",'" ?‚)
 ("'," ?‚)
 ("<\"" ?“)
 ("\"<" ?“)
 (">\"" ?”)
 ("\">" ?”)
 (",\"" ?„)
 ("\"," ?„)
 ("%o" ?‰)
 ("CE" ?₠)
 ("C/" ?₡)
 ("/C" ?₡)
 ("Cr" ?₢)
 ("Fr" ?₣)
 ("L=" ?₤)
 ("=L" ?₤)
 ("m/" ?₥)
 ("/m" ?₥)
 ("N=" ?₦)
 ("=N" ?₦)
 ("Pt" ?₧)
 ("Rs" ?₨)
 ("W=" ?₩)
 ("=W" ?₩)
 ("d=" ?₫)
 ("=d" ?₫)
 ("C=" ?€)
 ("=C" ?€)
 ("c=" ?€)
 ("=c" ?€)
 ("E=" ?€)
 ("=E" ?€)
 ("e=" ?€)
 ("=e" ?€)
 ("С=" ?€)
 ("=С" ?€)
 ("Е=" ?€)
 ("=Е" ?€)
 ("P=" ?₽)
 ("p=" ?₽)
 ("=P" ?₽)
 ("=p" ?₽)
 ("З=" ?₽)
 ("з=" ?₽)
 ("=З" ?₽)
 ("=з" ?₽)
 ("R=" ?₹)
 ("=R" ?₹)
 ("r=" ?₹)
 ("=r" ?₹)
 ("C|" ?¢)
 ("|C" ?¢)
 ("c|" ?¢)
 ("|c" ?¢)
 ("c/" ?¢)
 ("/c" ?¢)
 ("L-" ?£)
 ("-L" ?£)
 ("l-" ?£)
 ("-l" ?£)
 ("Y=" ?¥)
 ("=Y" ?¥)
 ("y=" ?¥)
 ("=y" ?¥)
 ("Y-" ?¥)
 ("-Y" ?¥)
 ("y-" ?¥)
 ("-y" ?¥)
 ("fs" ?ſ)
 ("fS" ?ſ)
 ("--." ?–)
 ("---" ?—)
 ("#q" ?♩)
 ("#e" ?♪)
 ("#E" ?♫)
 ("#S" ?♬)
 ("#b" ?♭)
 ("#f" ?♮)
 ("##" ?♯)
 ("so" ?§)
 ("os" ?§)
 ("SO" ?§)
 ("OS" ?§)
 ("s!" ?§)
 ("S!" ?§)
 ("па" ?§)
 ("ox" ?¤)
 ("xo" ?¤)
 ("oX" ?¤)
 ("Xo" ?¤)
 ("OX" ?¤)
 ("XO" ?¤)
 ("Ox" ?¤)
 ("xO" ?¤)
 ("PP" ?¶)
 ("No" ?№)
 ("NO" ?№)
 ("Но" ?№)
 ("НО" ?№)
 ("?!" ?⸘)
 ("!?" ?‽)
 ("CCCP" ?☭)
 ("OA" ?Ⓐ)
 ("<3" ?♥)
 (":)" ?☺)
 (":(" ?☹)
 ("\\o/" ?🙌)
 ("poo" ?💩)
 ("FU" ?🖕)
 ("LLAP" ?🖖)
 ("ᄀᄀ" ?ᄁ)
 ("ᄃᄃ" ?ᄄ)
 ("ᄇᄇ" ?ᄈ)
 ("ᄉᄉ" ?ᄊ)
 ("ᄌᄌ" ?ᄍ)
 ("ᄂᄀ" ?ᄓ)
 ("ᄂᄂ" ?ᄔ)
 ("ᄂᄃ" ?ᄕ)
 ("ᄂᄇ" ?ᄖ)
 ("ᄃᄀ" ?ᄗ)
 ("ᄅᄂ" ?ᄘ)
 ("ᄅᄅ" ?ᄙ)
 ("ᄅᄒ" ?ᄚ)
 ("ᄅᄋ" ?ᄛ)
 ("ᄆᄇ" ?ᄜ)
 ("ᄆᄋ" ?ᄝ)
 ("ᄇᄀ" ?ᄞ)
 ("ᄇᄂ" ?ᄟ)
 ("ᄇᄃ" ?ᄠ)
 ("ᄇᄉ" ?ᄡ)
 ("ᄇᄌ" ?ᄧ)
 ("ᄇᄎ" ?ᄨ)
 ("ᄇᄐ" ?ᄩ)
 ("ᄇᄑ" ?ᄪ)
 ("ᄇᄋ" ?ᄫ)
 ("ᄉᄀ" ?ᄭ)
 ("ᄉᄂ" ?ᄮ)
 ("ᄉᄃ" ?ᄯ)
 ("ᄉᄅ" ?ᄰ)
 ("ᄉᄆ" ?ᄱ)
 ("ᄉᄇ" ?ᄲ)
 ("ᄉᄋ" ?ᄵ)
 ("ᄉᄌ" ?ᄶ)
 ("ᄉᄎ" ?ᄷ)
 ("ᄉᄏ" ?ᄸ)
 ("ᄉᄐ" ?ᄹ)
 ("ᄉᄑ" ?ᄺ)
 ("ᄉᄒ" ?ᄻ)
 ("ᄼᄼ" ?ᄽ)
 ("ᄾᄾ" ?ᄿ)
 ("ᄋᄀ" ?ᅁ)
 ("ᄋᄃ" ?ᅂ)
 ("ᄋᄆ" ?ᅃ)
 ("ᄋᄇ" ?ᅄ)
 ("ᄋᄉ" ?ᅅ)
 ("ᄋᅀ" ?ᅆ)
 ("ᄋᄋ" ?ᅇ)
 ("ᄋᄌ" ?ᅈ)
 ("ᄋᄎ" ?ᅉ)
 ("ᄋᄐ" ?ᅊ)
 ("ᄋᄑ" ?ᅋ)
 ("ᄌᄋ" ?ᅍ)
 ("ᅎᅎ" ?ᅏ)
 ("ᅐᅐ" ?ᅑ)
 ("ᄎᄏ" ?ᅒ)
 ("ᄎᄒ" ?ᅓ)
 ("ᄑᄇ" ?ᅖ)
 ("ᄑᄋ" ?ᅗ)
 ("ᄒᄒ" ?ᅘ)
 ("ᅡᅵ" ?ᅢ)
 ("ᅣᅵ" ?ᅤ)
 ("ᅥᅵ" ?ᅦ)
 ("ᅧᅵ" ?ᅨ)
 ("ᅩᅡ" ?ᅪ)
 ("ᅩᅵ" ?ᅬ)
 ("ᅮᅥ" ?ᅯ)
 ("ᅮᅵ" ?ᅱ)
 ("ᅳᅵ" ?ᅴ)
 ("ᅡᅩ" ?ᅶ)
 ("ᅡᅮ" ?ᅷ)
 ("ᅣᅩ" ?ᅸ)
 ("ᅣᅭ" ?ᅹ)
 ("ᅥᅩ" ?ᅺ)
 ("ᅥᅮ" ?ᅻ)
 ("ᅥᅳ" ?ᅼ)
 ("ᅧᅩ" ?ᅽ)
 ("ᅧᅮ" ?ᅾ)
 ("ᅩᅥ" ?ᅿ)
 ("ᅩᅦ" ?ᆀ)
 ("ᅩᅨ" ?ᆁ)
 ("ᅩᅩ" ?ᆂ)
 ("ᅩᅮ" ?ᆃ)
 ("ᅭᅣ" ?ᆄ)
 ("ᅭᅤ" ?ᆅ)
 ("ᅭᅧ" ?ᆆ)
 ("ᅭᅩ" ?ᆇ)
 ("ᅭᅵ" ?ᆈ)
 ("ᅮᅡ" ?ᆉ)
 ("ᅮᅢ" ?ᆊ)
 ("ᅮᅨ" ?ᆌ)
 ("ᅮᅮ" ?ᆍ)
 ("ᅲᅡ" ?ᆎ)
 ("ᅲᅥ" ?ᆏ)
 ("ᅲᅦ" ?ᆐ)
 ("ᅲᅧ" ?ᆑ)
 ("ᅲᅨ" ?ᆒ)
 ("ᅲᅮ" ?ᆓ)
 ("ᅲᅵ" ?ᆔ)
 ("ᅳᅮ" ?ᆕ)
 ("ᅳᅳ" ?ᆖ)
 ("ᅴᅮ" ?ᆗ)
 ("ᅵᅡ" ?ᆘ)
 ("ᅵᅣ" ?ᆙ)
 ("ᅵᅩ" ?ᆚ)
 ("ᅵᅮ" ?ᆛ)
 ("ᅵᅳ" ?ᆜ)
 ("ᅵᆞ" ?ᆝ)
 ("ᆞᅥ" ?ᆟ)
 ("ᆞᅮ" ?ᆠ)
 ("ᆞᅵ" ?ᆡ)
 ("ᆞᆞ" ?ᆢ)
 ("ᆨᆨ" ?ᆩ)
 ("ᆨᆺ" ?ᆪ)
 ("ᆫᆽ" ?ᆬ)
 ("ᆫᇂ" ?ᆭ)
 ("ᆯᆨ" ?ᆰ)
 ("ᆯᆷ" ?ᆱ)
 ("ᆯᆸ" ?ᆲ)
 ("ᆯᆺ" ?ᆳ)
 ("ᆯᇀ" ?ᆴ)
 ("ᆯᇁ" ?ᆵ)
 ("ᆯᇂ" ?ᆶ)
 ("ᆸᆺ" ?ᆹ)
 ("ᆺᆺ" ?ᆻ)
 ("ᆨᆯ" ?ᇃ)
 ("ᆫᆨ" ?ᇅ)
 ("ᆫᆮ" ?ᇆ)
 ("ᆫᆺ" ?ᇇ)
 ("ᆫᇫ" ?ᇈ)
 ("ᆫᇀ" ?ᇉ)
 ("ᆮᆨ" ?ᇊ)
 ("ᆮᆯ" ?ᇋ)
 ("ᆯᆫ" ?ᇍ)
 ("ᆯᆮ" ?ᇎ)
 ("ᆯᆯ" ?ᇐ)
 ("ᆯᇫ" ?ᇗ)
 ("ᆯᆿ" ?ᇘ)
 ("ᆯᇹ" ?ᇙ)
 ("ᆷᆨ" ?ᇚ)
 ("ᆷᆯ" ?ᇛ)
 ("ᆷᆸ" ?ᇜ)
 ("ᆷᆺ" ?ᇝ)
 ("ᆷᇫ" ?ᇟ)
 ("ᆷᆾ" ?ᇠ)
 ("ᆷᇂ" ?ᇡ)
 ("ᆷᆼ" ?ᇢ)
 ("ᆸᆯ" ?ᇣ)
 ("ᆸᇁ" ?ᇤ)
 ("ᆸᇂ" ?ᇥ)
 ("ᆸᆼ" ?ᇦ)
 ("ᆺᆨ" ?ᇧ)
 ("ᆺᆮ" ?ᇨ)
 ("ᆺᆯ" ?ᇩ)
 ("ᆺᆸ" ?ᇪ)
 ("ᆼᆨ" ?ᇬ)
 ("ᆼᆼ" ?ᇮ)
 ("ᆼᆿ" ?ᇯ)
 ("ᇰᆺ" ?ᇱ)
 ("ᇰᇫ" ?ᇲ)
 ("ᇁᆸ" ?ᇳ)
 ("ᇁᆼ" ?ᇴ)
 ("ᇂᆫ" ?ᇵ)
 ("ᇂᆯ" ?ᇶ)
 ("ᇂᆷ" ?ᇷ)
 ("ᇂᆸ" ?ᇸ)
 ("ᄡᄀ" ?ᄢ)
 ("ᄡᄃ" ?ᄣ)
 ("ᄡᄇ" ?ᄤ)
 ("ᄡᄉ" ?ᄥ)
 ("ᄡᄌ" ?ᄦ)
 ("ᄈᄋ" ?ᄬ)
 ("ᄲᄀ" ?ᄳ)
 ("ᄊᄉ" ?ᄴ)
 ("ᅪᅵ" ?ᅫ)
 ("ᅯᅵ" ?ᅰ)
 ("ᅯᅳ" ?ᆋ)
 ("ᆪᆨ" ?ᇄ)
 ("ᆰᆺ" ?ᇌ)
 ("ᇎᇂ" ?ᇏ)
 ("ᆱᆨ" ?ᇑ)
 ("ᆱᆺ" ?ᇒ)
 ("ᆲᆺ" ?ᇓ)
 ("ᆲᇂ" ?ᇔ)
 ("ᆲᆼ" ?ᇕ)
 ("ᆳᆺ" ?ᇖ)
 ("ᇝᆺ" ?ᇞ)
 ("ᇬᆨ" ?ᇭ)
 ("ᄇᄭ" ?ᄢ)
 ("ᄇᄯ" ?ᄣ)
 ("ᄇᄲ" ?ᄤ)
 ("ᄇᄊ" ?ᄥ)
 ("ᄇᄶ" ?ᄦ)
 ("ᄇᄫ" ?ᄬ)
 ("ᄉᄞ" ?ᄳ)
 ("ᄉᄊ" ?ᄴ)
 ("ᅩᅢ" ?ᅫ)
 ("ᅮᅦ" ?ᅰ)
 ("ᅮᅼ" ?ᆋ)
 ("ᆨᇧ" ?ᇄ)
 ("ᆯᆪ" ?ᇌ)
 ("ᆯᇚ" ?ᇑ)
 ("ᆯᇝ" ?ᇒ)
 ("ᆯᆹ" ?ᇓ)
 ("ᆯᇥ" ?ᇔ)
 ("ᆯᇦ" ?ᇕ)
 ("ᆯᆻ" ?ᇖ)
 ("ᆷᆻ" ?ᇞ)
 ("ᆼᆩ" ?ᇭ)
 (",-" ?¬)
 ("-," ?¬)
 ("^_a" ?ª)
 ("^_a" ?ª)
 ("^2" ?²)
 ("2^" ?²)
 ("^3" ?³)
 ("3^" ?³)
 ("mu" ?µ)
 ("/u" ?µ)
 ("u/" ?µ)
 ("^1" ?¹)
 ("1^" ?¹)
 ("^_o" ?º)
 ("^_o" ?º)
 ("14" ?¼)
 ("12" ?½)
 ("34" ?¾)
 ("`A" ?À)
 ("A`" ?À)
 ("´A" ?Á)
 ("A´" ?Á)
 ("'A" ?Á)
 ("A'" ?Á)
 ("^A" ?Â)
 ("A^" ?Â)
 (">A" ?Â)
 ("A>" ?Â)
 ("~A" ?Ã)
 ("A~" ?Ã)
 ("\"A" ?Ä)
 ("A\"" ?Ä)
 ("¨A" ?Ä)
 ("A¨" ?Ä)
 ("oA" ?Å)
 ("*A" ?Å)
 ("A*" ?Å)
 ("AA" ?Å)
 (",C" ?Ç)
 ("C," ?Ç)
 ("¸C" ?Ç)
 ("`E" ?È)
 ("E`" ?È)
 ("´E" ?É)
 ("E´" ?É)
 ("'E" ?É)
 ("E'" ?É)
 ("^E" ?Ê)
 ("E^" ?Ê)
 (">E" ?Ê)
 ("E>" ?Ê)
 ("\"E" ?Ë)
 ("E\"" ?Ë)
 ("¨E" ?Ë)
 ("E¨" ?Ë)
 ("`I" ?Ì)
 ("I`" ?Ì)
 ("´I" ?Í)
 ("I´" ?Í)
 ("'I" ?Í)
 ("I'" ?Í)
 ("^I" ?Î)
 ("I^" ?Î)
 (">I" ?Î)
 ("I>" ?Î)
 ("\"I" ?Ï)
 ("I\"" ?Ï)
 ("¨I" ?Ï)
 ("I¨" ?Ï)
 ("'J" ["J́"])
 ("J'" ["J́"])
 ("´J" ["J́"])
 ("J´" ["J́"])
 ("DH" ?Ð)
 ("~N" ?Ñ)
 ("N~" ?Ñ)
 ("`O" ?Ò)
 ("O`" ?Ò)
 ("´O" ?Ó)
 ("O´" ?Ó)
 ("'O" ?Ó)
 ("O'" ?Ó)
 ("^O" ?Ô)
 ("O^" ?Ô)
 (">O" ?Ô)
 ("O>" ?Ô)
 ("~O" ?Õ)
 ("O~" ?Õ)
 ("\"O" ?Ö)
 ("O\"" ?Ö)
 ("¨O" ?Ö)
 ("O¨" ?Ö)
 ("xx" ?×)
 ("/O" ?Ø)
 ("O/" ?Ø)
 ("`U" ?Ù)
 ("U`" ?Ù)
 ("´U" ?Ú)
 ("U´" ?Ú)
 ("'U" ?Ú)
 ("U'" ?Ú)
 ("^U" ?Û)
 ("U^" ?Û)
 (">U" ?Û)
 ("U>" ?Û)
 ("\"U" ?Ü)
 ("U\"" ?Ü)
 ("¨U" ?Ü)
 ("U¨" ?Ü)
 ("´Y" ?Ý)
 ("Y´" ?Ý)
 ("'Y" ?Ý)
 ("Y'" ?Ý)
 ("TH" ?Þ)
 ("`a" ?à)
 ("a`" ?à)
 ("´a" ?á)
 ("a´" ?á)
 ("'a" ?á)
 ("a'" ?á)
 ("^a" ?â)
 ("a^" ?â)
 (">a" ?â)
 ("a>" ?â)
 ("~a" ?ã)
 ("a~" ?ã)
 ("\"a" ?ä)
 ("a\"" ?ä)
 ("¨a" ?ä)
 ("a¨" ?ä)
 ("oa" ?å)
 ("*a" ?å)
 ("a*" ?å)
 ("aa" ?å)
 (",c" ?ç)
 ("c," ?ç)
 ("¸c" ?ç)
 ("`e" ?è)
 ("e`" ?è)
 ("´e" ?é)
 ("e´" ?é)
 ("'e" ?é)
 ("e'" ?é)
 ("^e" ?ê)
 ("e^" ?ê)
 (">e" ?ê)
 ("e>" ?ê)
 ("\"e" ?ë)
 ("e\"" ?ë)
 ("¨e" ?ë)
 ("e¨" ?ë)
 ("`i" ?ì)
 ("i`" ?ì)
 ("´i" ?í)
 ("i´" ?í)
 ("'i" ?í)
 ("i'" ?í)
 ("^i" ?î)
 ("i^" ?î)
 (">i" ?î)
 ("i>" ?î)
 ("\"i" ?ï)
 ("i\"" ?ï)
 ("¨i" ?ï)
 ("i¨" ?ï)
 ("'j" ["j́"])
 ("j'" ["j́"])
 ("´j" ["j́"])
 ("j´" ["j́"])
 ("dh" ?ð)
 ("~n" ?ñ)
 ("n~" ?ñ)
 ("`o" ?ò)
 ("o`" ?ò)
 ("´o" ?ó)
 ("o´" ?ó)
 ("'o" ?ó)
 ("o'" ?ó)
 ("^o" ?ô)
 ("o^" ?ô)
 (">o" ?ô)
 ("o>" ?ô)
 ("~o" ?õ)
 ("o~" ?õ)
 ("o¨" ?ö)
 ("¨o" ?ö)
 ("\"o" ?ö)
 ("o\"" ?ö)
 (":-" ?÷)
 ("-:" ?÷)
 ("/o" ?ø)
 ("o/" ?ø)
 ("`u" ?ù)
 ("u`" ?ù)
 ("´u" ?ú)
 ("u´" ?ú)
 ("'u" ?ú)
 ("u'" ?ú)
 ("^u" ?û)
 ("u^" ?û)
 (">u" ?û)
 ("u>" ?û)
 ("\"u" ?ü)
 ("u\"" ?ü)
 ("¨u" ?ü)
 ("u¨" ?ü)
 ("´y" ?ý)
 ("y´" ?ý)
 ("'y" ?ý)
 ("y'" ?ý)
 ("th" ?þ)
 ("\"y" ?ÿ)
 ("y\"" ?ÿ)
 ("¨y" ?ÿ)
 ("y¨" ?ÿ)
 ("¯A" ?Ā)
 ("_A" ?Ā)
 ("A_" ?Ā)
 ("-A" ?Ā)
 ("A-" ?Ā)
 ("¯a" ?ā)
 ("_a" ?ā)
 ("a_" ?ā)
 ("-a" ?ā)
 ("a-" ?ā)
 ("UA" ?Ă)
 ("uA" ?Ă)
 ("bA" ?Ă)
 ("A(" ?Ă)
 ("Ua" ?ă)
 ("ua" ?ă)
 ("ba" ?ă)
 ("a(" ?ă)
 (";A" ?Ą)
 ("A;" ?Ą)
 (",A" ?Ą)
 ("A," ?Ą)
 (";a" ?ą)
 ("a;" ?ą)
 (",a" ?ą)
 ("a," ?ą)
 ("´C" ?Ć)
 ("'C" ?Ć)
 ("C'" ?Ć)
 ("´c" ?ć)
 ("'c" ?ć)
 ("c'" ?ć)
 ("^C" ?Ĉ)
 ("^c" ?ĉ)
 (".C" ?Ċ)
 ("C." ?Ċ)
 (".c" ?ċ)
 ("c." ?ċ)
 ("cC" ?Č)
 ("<C" ?Č)
 ("C<" ?Č)
 ("cc" ?č)
 ("<c" ?č)
 ("c<" ?č)
 ("cD" ?Ď)
 ("<D" ?Ď)
 ("D<" ?Ď)
 ("cd" ?ď)
 ("<d" ?ď)
 ("d<" ?ď)
 ("-D" ?Đ)
 ("D-" ?Đ)
 ("/D" ?Đ)
 ("-d" ?đ)
 ("d-" ?đ)
 ("/d" ?đ)
 ("¯E" ?Ē)
 ("_E" ?Ē)
 ("E_" ?Ē)
 ("-E" ?Ē)
 ("E-" ?Ē)
 ("¯e" ?ē)
 ("_e" ?ē)
 ("e_" ?ē)
 ("-e" ?ē)
 ("e-" ?ē)
 ("UE" ?Ĕ)
 ("bE" ?Ĕ)
 ("Ue" ?ĕ)
 ("be" ?ĕ)
 (".E" ?Ė)
 ("E." ?Ė)
 (".e" ?ė)
 ("e." ?ė)
 (";E" ?Ę)
 ("E;" ?Ę)
 (",E" ?Ę)
 ("E," ?Ę)
 (";e" ?ę)
 ("e;" ?ę)
 (",e" ?ę)
 ("e," ?ę)
 ("cE" ?Ě)
 ("<E" ?Ě)
 ("E<" ?Ě)
 ("ce" ?ě)
 ("<e" ?ě)
 ("e<" ?ě)
 ("^G" ?Ĝ)
 ("^g" ?ĝ)
 ("UG" ?Ğ)
 ("GU" ?Ğ)
 ("bG" ?Ğ)
 ("˘G" ?Ğ)
 ("G˘" ?Ğ)
 ("G(" ?Ğ)
 ("Ug" ?ğ)
 ("gU" ?ğ)
 ("bg" ?ğ)
 ("˘g" ?ğ)
 ("g˘" ?ğ)
 ("g(" ?ğ)
 (".G" ?Ġ)
 ("G." ?Ġ)
 (".g" ?ġ)
 ("g." ?ġ)
 (",G" ?Ģ)
 ("G," ?Ģ)
 ("¸G" ?Ģ)
 (",g" ?ģ)
 ("g," ?ģ)
 ("¸g" ?ģ)
 ("^H" ?Ĥ)
 ("^h" ?ĥ)
 ("/H" ?Ħ)
 ("/h" ?ħ)
 ("~I" ?Ĩ)
 ("I~" ?Ĩ)
 ("~i" ?ĩ)
 ("i~" ?ĩ)
 ("¯I" ?Ī)
 ("_I" ?Ī)
 ("I_" ?Ī)
 ("-I" ?Ī)
 ("I-" ?Ī)
 ("¯i" ?ī)
 ("_i" ?ī)
 ("i_" ?ī)
 ("-i" ?ī)
 ("i-" ?ī)
 ("UI" ?Ĭ)
 ("bI" ?Ĭ)
 ("Ui" ?ĭ)
 ("bi" ?ĭ)
 (";I" ?Į)
 ("I;" ?Į)
 (",I" ?Į)
 ("I," ?Į)
 (";i" ?į)
 ("i;" ?į)
 (",i" ?į)
 ("i," ?į)
 (".I" ?İ)
 ("I." ?İ)
 ("i." ?ı)
 (".i" ?ı)
 ("^J" ?Ĵ)
 ("^j" ?ĵ)
 (",K" ?Ķ)
 ("K," ?Ķ)
 ("¸K" ?Ķ)
 (",k" ?ķ)
 ("k," ?ķ)
 ("¸k" ?ķ)
 ("kk" ?ĸ)
 ("´L" ?Ĺ)
 ("'L" ?Ĺ)
 ("L'" ?Ĺ)
 ("´l" ?ĺ)
 ("'l" ?ĺ)
 ("l'" ?ĺ)
 (",L" ?Ļ)
 ("L," ?Ļ)
 ("¸L" ?Ļ)
 (",l" ?ļ)
 ("l," ?ļ)
 ("¸l" ?ļ)
 ("cL" ?Ľ)
 ("<L" ?Ľ)
 ("L<" ?Ľ)
 ("cl" ?ľ)
 ("<l" ?ľ)
 ("l<" ?ľ)
 ("/L" ?Ł)
 ("L/" ?Ł)
 ("/l" ?ł)
 ("l/" ?ł)
 ("´N" ?Ń)
 ("'N" ?Ń)
 ("N'" ?Ń)
 ("´n" ?ń)
 ("'n" ?ń)
 ("n'" ?ń)
 (",N" ?Ņ)
 ("N," ?Ņ)
 ("¸N" ?Ņ)
 (",n" ?ņ)
 ("n," ?ņ)
 ("¸n" ?ņ)
 ("cN" ?Ň)
 ("<N" ?Ň)
 ("N<" ?Ň)
 ("cn" ?ň)
 ("<n" ?ň)
 ("n<" ?ň)
 ("NG" ?Ŋ)
 ("ng" ?ŋ)
 ("¯O" ?Ō)
 ("_O" ?Ō)
 ("O_" ?Ō)
 ("-O" ?Ō)
 ("O-" ?Ō)
 ("¯o" ?ō)
 ("_o" ?ō)
 ("o_" ?ō)
 ("-o" ?ō)
 ("o-" ?ō)
 ("UO" ?Ŏ)
 ("bO" ?Ŏ)
 ("Uo" ?ŏ)
 ("bo" ?ŏ)
 ("=O" ?Ő)
 ("=o" ?ő)
 ("´R" ?Ŕ)
 ("'R" ?Ŕ)
 ("R'" ?Ŕ)
 ("´r" ?ŕ)
 ("'r" ?ŕ)
 ("r'" ?ŕ)
 (",R" ?Ŗ)
 ("R," ?Ŗ)
 ("¸R" ?Ŗ)
 (",r" ?ŗ)
 ("r," ?ŗ)
 ("¸r" ?ŗ)
 ("cR" ?Ř)
 ("<R" ?Ř)
 ("R<" ?Ř)
 ("cr" ?ř)
 ("<r" ?ř)
 ("r<" ?ř)
 ("´S" ?Ś)
 ("'S" ?Ś)
 ("S'" ?Ś)
 ("´s" ?ś)
 ("'s" ?ś)
 ("s'" ?ś)
 ("^S" ?Ŝ)
 ("^s" ?ŝ)
 (",S" ?Ş)
 ("S," ?Ş)
 ("¸S" ?Ş)
 (",s" ?ş)
 ("s," ?ş)
 ("¸s" ?ş)
 ("s¸" ?ş)
 ("cS" ?Š)
 ("<S" ?Š)
 ("S<" ?Š)
 ("cs" ?š)
 ("<s" ?š)
 ("s<" ?š)
 (",T" ?Ţ)
 ("T," ?Ţ)
 ("¸T" ?Ţ)
 (",t" ?ţ)
 ("t," ?ţ)
 ("¸t" ?ţ)
 ("cT" ?Ť)
 ("<T" ?Ť)
 ("T<" ?Ť)
 ("ct" ?ť)
 ("<t" ?ť)
 ("t<" ?ť)
 ("/T" ?Ŧ)
 ("T/" ?Ŧ)
 ("T-" ?Ŧ)
 ("/t" ?ŧ)
 ("t/" ?ŧ)
 ("t-" ?ŧ)
 ("~U" ?Ũ)
 ("U~" ?Ũ)
 ("~u" ?ũ)
 ("u~" ?ũ)
 ("¯U" ?Ū)
 ("_U" ?Ū)
 ("U_" ?Ū)
 ("-U" ?Ū)
 ("U-" ?Ū)
 ("¯u" ?ū)
 ("_u" ?ū)
 ("u_" ?ū)
 ("-u" ?ū)
 ("u-" ?ū)
 ("UU" ?Ŭ)
 ("uU" ?Ŭ)
 ("bU" ?Ŭ)
 ("Uu" ?ŭ)
 ("uu" ?ŭ)
 ("bu" ?ŭ)
 ("oU" ?Ů)
 ("*U" ?Ů)
 ("U*" ?Ů)
 ("ou" ?ů)
 ("*u" ?ů)
 ("u*" ?ů)
 ("=U" ?Ű)
 ("=u" ?ű)
 (";U" ?Ų)
 ("U;" ?Ų)
 (",U" ?Ų)
 ("U," ?Ų)
 (";u" ?ų)
 ("u;" ?ų)
 (",u" ?ų)
 ("u," ?ų)
 ("^W" ?Ŵ)
 ("W^" ?Ŵ)
 ("^w" ?ŵ)
 ("w^" ?ŵ)
 ("^Y" ?Ŷ)
 ("Y^" ?Ŷ)
 ("^y" ?ŷ)
 ("y^" ?ŷ)
 ("\"Y" ?Ÿ)
 ("Y\"" ?Ÿ)
 ("¨Y" ?Ÿ)
 ("Y¨" ?Ÿ)
 ("´Z" ?Ź)
 ("'Z" ?Ź)
 ("Z'" ?Ź)
 ("´z" ?ź)
 ("'z" ?ź)
 ("z'" ?ź)
 (".Z" ?Ż)
 ("Z." ?Ż)
 (".z" ?ż)
 ("z." ?ż)
 ("cZ" ?Ž)
 ("vZ" ?Ž)
 ("<Z" ?Ž)
 ("Z<" ?Ž)
 ("cz" ?ž)
 ("vz" ?ž)
 ("<z" ?ž)
 ("z<" ?ž)
 ("/b" ?ƀ)
 ("/I" ?Ɨ)
 ("+O" ?Ơ)
 ("+o" ?ơ)
 ("+U" ?Ư)
 ("+u" ?ư)
 ("/Z" ?Ƶ)
 ("/z" ?ƶ)
 ("cA" ?Ǎ)
 ("ca" ?ǎ)
 ("cI" ?Ǐ)
 ("ci" ?ǐ)
 ("cO" ?Ǒ)
 ("co" ?ǒ)
 ("cU" ?Ǔ)
 ("cu" ?ǔ)
 ("¯Ü" ?Ǖ)
 ("_Ü" ?Ǖ)
 ("¯\"U" ?Ǖ)
 ("_\"U" ?Ǖ)
 ("¯ü" ?ǖ)
 ("_ü" ?ǖ)
 ("¯\"u" ?ǖ)
 ("_\"u" ?ǖ)
 ("´Ü" ?Ǘ)
 ("'Ü" ?Ǘ)
 ("´\"U" ?Ǘ)
 ("'\"U" ?Ǘ)
 ("´ü" ?ǘ)
 ("'ü" ?ǘ)
 ("´\"u" ?ǘ)
 ("'\"u" ?ǘ)
 ("cÜ" ?Ǚ)
 ("c\"U" ?Ǚ)
 ("cü" ?ǚ)
 ("c\"u" ?ǚ)
 ("`Ü" ?Ǜ)
 ("`\"U" ?Ǜ)
 ("`ü" ?ǜ)
 ("`\"u" ?ǜ)
 ("¯Ä" ?Ǟ)
 ("_Ä" ?Ǟ)
 ("¯\"A" ?Ǟ)
 ("_\"A" ?Ǟ)
 ("¯ä" ?ǟ)
 ("_ä" ?ǟ)
 ("¯\"a" ?ǟ)
 ("_\"a" ?ǟ)
 ("¯Ȧ" ?Ǡ)
 ("_Ȧ" ?Ǡ)
 ("¯.A" ?Ǡ)
 ("_.A" ?Ǡ)
 ("¯ȧ" ?ǡ)
 ("_ȧ" ?ǡ)
 ("¯.a" ?ǡ)
 ("_.a" ?ǡ)
 ("¯Æ" ?Ǣ)
 ("_Æ" ?Ǣ)
 ("¯æ" ?ǣ)
 ("_æ" ?ǣ)
 ("/G" ?Ǥ)
 ("/g" ?ǥ)
 ("cG" ?Ǧ)
 ("cg" ?ǧ)
 ("cK" ?Ǩ)
 ("ck" ?ǩ)
 (";O" ?Ǫ)
 ("O;" ?Ǫ)
 (",O" ?Ǫ)
 ("O," ?Ǫ)
 (";o" ?ǫ)
 ("o;" ?ǫ)
 (",o" ?ǫ)
 ("o," ?ǫ)
 ("¯Ǫ" ?Ǭ)
 ("_Ǫ" ?Ǭ)
 ("¯;O" ?Ǭ)
 ("_;O" ?Ǭ)
 ("¯ǫ" ?ǭ)
 ("_ǫ" ?ǭ)
 ("¯;o" ?ǭ)
 ("_;o" ?ǭ)
 ("cƷ" ?Ǯ)
 ("cʒ" ?ǯ)
 ("cj" ?ǰ)
 ("´G" ?Ǵ)
 ("'G" ?Ǵ)
 ("´g" ?ǵ)
 ("'g" ?ǵ)
 ("`N" ?Ǹ)
 ("`n" ?ǹ)
 ("´Å" ?Ǻ)
 ("'Å" ?Ǻ)
 ("*'A" ?Ǻ)
 ("´å" ?ǻ)
 ("'å" ?ǻ)
 ("*'a" ?ǻ)
 ("´Æ" ?Ǽ)
 ("'Æ" ?Ǽ)
 ("´æ" ?ǽ)
 ("'æ" ?ǽ)
 ("´Ø" ?Ǿ)
 ("'Ø" ?Ǿ)
 ("´/O" ?Ǿ)
 ("'/O" ?Ǿ)
 ("´ø" ?ǿ)
 ("'ø" ?ǿ)
 ("´/o" ?ǿ)
 ("'/o" ?ǿ)
 ("cH" ?Ȟ)
 ("ch" ?ȟ)
 (".A" ?Ȧ)
 (".a" ?ȧ)
 ("¸E" ?Ȩ)
 ("¸e" ?ȩ)
 ("¯Ö" ?Ȫ)
 ("_Ö" ?Ȫ)
 ("¯\"O" ?Ȫ)
 ("_\"O" ?Ȫ)
 ("¯ö" ?ȫ)
 ("_ö" ?ȫ)
 ("¯\"o" ?ȫ)
 ("_\"o" ?ȫ)
 ("¯Õ" ?Ȭ)
 ("_Õ" ?Ȭ)
 ("¯~O" ?Ȭ)
 ("_~O" ?Ȭ)
 ("¯õ" ?ȭ)
 ("_õ" ?ȭ)
 ("¯~o" ?ȭ)
 ("_~o" ?ȭ)
 (".O" ?Ȯ)
 (".o" ?ȯ)
 ("¯Ȯ" ?Ȱ)
 ("_Ȯ" ?Ȱ)
 ("¯.O" ?Ȱ)
 ("_.O" ?Ȱ)
 ("¯ȯ" ?ȱ)
 ("_ȯ" ?ȱ)
 ("¯.o" ?ȱ)
 ("_.o" ?ȱ)
 ("¯Y" ?Ȳ)
 ("_Y" ?Ȳ)
 ("¯y" ?ȳ)
 ("_y" ?ȳ)
 ("ee" ?ə)
 ("/i" ?ɨ)
 ("/ʔ" ?ʡ)
 ("^_h" ?ʰ)
 ("^_h" ?ʰ)
 ("^_ɦ" ?ʱ)
 ("^_ɦ" ?ʱ)
 ("^_j" ?ʲ)
 ("^_j" ?ʲ)
 ("^_r" ?ʳ)
 ("^_r" ?ʳ)
 ("^_ɹ" ?ʴ)
 ("^_ɹ" ?ʴ)
 ("^_ɻ" ?ʵ)
 ("^_ɻ" ?ʵ)
 ("^_ʁ" ?ʶ)
 ("^_ʁ" ?ʶ)
 ("^_w" ?ʷ)
 ("^_w" ?ʷ)
 ("^_y" ?ʸ)
 ("^_y" ?ʸ)
 ("^_ɣ" ?ˠ)
 ("^_ɣ" ?ˠ)
 ("^_l" ?ˡ)
 ("^_l" ?ˡ)
 ("^_s" ?ˢ)
 ("^_s" ?ˢ)
 ("^_x" ?ˣ)
 ("^_x" ?ˣ)
 ("^_ʕ" ?ˤ)
 ("^_ʕ" ?ˤ)
 ("\"´" ?̈́)
 ("\"'" ?̈́)
 ("¨´" ?΅)
 ("¨'" ?΅)
 ("'\" " ?΅)
 ("´Α" ?Ά)
 ("'Α" ?Ά)
 ("Α'" ?Ά)
 ("´Ε" ?Έ)
 ("'Ε" ?Έ)
 ("Ε'" ?Έ)
 ("´Η" ?Ή)
 ("'Η" ?Ή)
 ("Η'" ?Ή)
 ("´Ι" ?Ί)
 ("'Ι" ?Ί)
 ("Ι'" ?Ί)
 ("´Ο" ?Ό)
 ("'Ο" ?Ό)
 ("Ο'" ?Ό)
 ("´Υ" ?Ύ)
 ("'Υ" ?Ύ)
 ("Υ'" ?Ύ)
 ("´Ω" ?Ώ)
 ("'Ω" ?Ώ)
 ("Ω'" ?Ώ)
 ("´ϊ" ?ΐ)
 ("'ϊ" ?ΐ)
 ("´\"ι" ?ΐ)
 ("'\"ι" ?ΐ)
 ("\"Ι" ?Ϊ)
 ("Ι\"" ?Ϊ)
 ("\"Υ" ?Ϋ)
 ("Υ\"" ?Ϋ)
 ("´α" ?ά)
 ("'α" ?ά)
 ("α'" ?ά)
 ("´ε" ?έ)
 ("'ε" ?έ)
 ("ε'" ?έ)
 ("´η" ?ή)
 ("'η" ?ή)
 ("η'" ?ή)
 ("´ι" ?ί)
 ("'ι" ?ί)
 ("´ϋ" ?ΰ)
 ("'ϋ" ?ΰ)
 ("´\"υ" ?ΰ)
 ("'\"υ" ?ΰ)
 ("\"ι" ?ϊ)
 ("ι\"" ?ϊ)
 ("\"υ" ?ϋ)
 ("υ\"" ?ϋ)
 ("´ο" ?ό)
 ("'ο" ?ό)
 ("ο'" ?ό)
 ("´υ" ?ύ)
 ("'υ" ?ύ)
 ("υ'" ?ύ)
 ("´ω" ?ώ)
 ("'ω" ?ώ)
 ("ω'" ?ώ)
 ("\"ϒ" ?ϔ)
 ("`Е" ?Ѐ)
 ("\"Е" ?Ё)
 ("´Г" ?Ѓ)
 ("'Г" ?Ѓ)
 ("\"І" ?Ї)
 ("´К" ?Ќ)
 ("'К" ?Ќ)
 ("`И" ?Ѝ)
 ("UУ" ?Ў)
 ("bУ" ?Ў)
 ("UИ" ?Й)
 ("bИ" ?Й)
 ("Uи" ?й)
 ("bи" ?й)
 ("`е" ?ѐ)
 ("\"е" ?ё)
 ("´г" ?ѓ)
 ("'г" ?ѓ)
 ("\"і" ?ї)
 ("´к" ?ќ)
 ("'к" ?ќ)
 ("`и" ?ѝ)
 ("Uу" ?ў)
 ("bу" ?ў)
 ("/Г" ?Ғ)
 ("/г" ?ғ)
 ("/К" ?Ҟ)
 ("/к" ?ҟ)
 ("/Ү" ?Ұ)
 ("/ү" ?ұ)
 ("UЖ" ?Ӂ)
 ("bЖ" ?Ӂ)
 ("Uж" ?ӂ)
 ("bж" ?ӂ)
 ("UА" ?Ӑ)
 ("bА" ?Ӑ)
 ("Uа" ?ӑ)
 ("bа" ?ӑ)
 ("\"А" ?Ӓ)
 ("\"а" ?ӓ)
 ("UЕ" ?Ӗ)
 ("bЕ" ?Ӗ)
 ("Uе" ?ӗ)
 ("bе" ?ӗ)
 ("\"Ә" ?Ӛ)
 ("\"ә" ?ӛ)
 ("\"Ж" ?Ӝ)
 ("\"ж" ?ӝ)
 ("\"З" ?Ӟ)
 ("\"з" ?ӟ)
 ("¯И" ?Ӣ)
 ("_И" ?Ӣ)
 ("¯и" ?ӣ)
 ("_и" ?ӣ)
 ("\"И" ?Ӥ)
 ("\"и" ?ӥ)
 ("\"О" ?Ӧ)
 ("\"о" ?ӧ)
 ("\"Ө" ?Ӫ)
 ("\"ө" ?ӫ)
 ("\"Э" ?Ӭ)
 ("\"э" ?ӭ)
 ("¯У" ?Ӯ)
 ("_У" ?Ӯ)
 ("¯у" ?ӯ)
 ("_у" ?ӯ)
 ("\"У" ?Ӱ)
 ("\"у" ?ӱ)
 ("=У" ?Ӳ)
 ("=у" ?ӳ)
 ("\"Ч" ?Ӵ)
 ("\"ч" ?ӵ)
 ("\"Ы" ?Ӹ)
 ("\"ы" ?ӹ)
 ("ٓا" ?آ)
 ("ٔا" ?أ)
 ("ٔو" ?ؤ)
 ("ٕا" ?إ)
 ("ٔي" ?ئ)
 ("ٔە" ?ۀ)
 ("ٔہ" ?ۂ)
 ("ٔے" ?ۓ)
 ("़न" ?ऩ)
 ("़र" ?ऱ)
 ("़ळ" ?ऴ)
 ("़क" ?क़)
 ("़ख" ?ख़)
 ("़ग" ?ग़)
 ("़ज" ?ज़)
 ("़ड" ?ड़)
 ("़ढ" ?ढ़)
 ("़फ" ?फ़)
 ("़य" ?य़)
 ("ো" ?ো)
 ("ৌ" ?ৌ)
 ("়ড" ?ড়)
 ("়ঢ" ?ঢ়)
 ("়য" ?য়)
 ("਼ਲ" ?ਲ਼)
 ("਼ਸ" ?ਸ਼)
 ("਼ਖ" ?ਖ਼)
 ("਼ਗ" ?ਗ਼)
 ("਼ਜ" ?ਜ਼)
 ("਼ਫ" ?ਫ਼)
 ("ୈ" ?ୈ)
 ("ୋ" ?ୋ)
 ("ୌ" ?ୌ)
 ("଼ଡ" ?ଡ଼)
 ("଼ଢ" ?ଢ଼)
 ("ௗஒ" ?ஔ)
 ("ொ" ?ொ)
 ("ோ" ?ோ)
 ("ௌ" ?ௌ)
 ("ై" ?ై)
 ("ೀ" ?ೀ)
 ("ೇ" ?ೇ)
 ("ೈ" ?ೈ)
 ("ೊ" ?ೊ)
 ("ೋ" ?ೋ)
 ("ൊ" ?ൊ)
 ("ോ" ?ോ)
 ("ൌ" ?ൌ)
 ("ේ" ?ේ)
 ("ො" ?ො)
 ("ෝ" ?ෝ)
 ("ෞ" ?ෞ)
 ("ྷག" ?གྷ)
 ("ྷཌ" ?ཌྷ)
 ("ྷད" ?དྷ)
 ("ྷབ" ?བྷ)
 ("ྷཛ" ?ཛྷ)
 ("ྵཀ" ?ཀྵ)
 ("ཱི" ?ཱི)
 ("ཱུ" ?ཱུ)
 ("ྲྀ" ?ྲྀ)
 ("ླྀ" ?ླྀ)
 ("ཱྀ" ?ཱྀ)
 ("ྒྷ" ?ྒྷ)
 ("ྜྷ" ?ྜྷ)
 ("ྡྷ" ?ྡྷ)
 ("ྦྷ" ?ྦྷ)
 ("ྫྷ" ?ྫྷ)
 ("ྐྵ" ?ྐྵ)
 ("ီဥ" ?ဦ)
 (".B" ?Ḃ)
 ("B." ?Ḃ)
 (".b" ?ḃ)
 ("b." ?ḃ)
 ("!B" ?Ḅ)
 ("!b" ?ḅ)
 ("´Ç" ?Ḉ)
 ("'Ç" ?Ḉ)
 ("´,C" ?Ḉ)
 ("´¸C" ?Ḉ)
 ("'¸C" ?Ḉ)
 ("´ç" ?ḉ)
 ("'ç" ?ḉ)
 ("´,c" ?ḉ)
 ("´¸c" ?ḉ)
 ("'¸c" ?ḉ)
 (".D" ?Ḋ)
 ("D." ?Ḋ)
 (".d" ?ḋ)
 ("d." ?ḋ)
 ("!D" ?Ḍ)
 ("!d" ?ḍ)
 (",D" ?Ḑ)
 ("D," ?Ḑ)
 ("¸D" ?Ḑ)
 (",d" ?ḑ)
 ("d," ?ḑ)
 ("¸d" ?ḑ)
 ("`Ē" ?Ḕ)
 ("`¯E" ?Ḕ)
 ("`_E" ?Ḕ)
 ("`ē" ?ḕ)
 ("`¯e" ?ḕ)
 ("`_e" ?ḕ)
 ("´Ē" ?Ḗ)
 ("'Ē" ?Ḗ)
 ("´¯E" ?Ḗ)
 ("´_E" ?Ḗ)
 ("'¯E" ?Ḗ)
 ("'_E" ?Ḗ)
 ("´ē" ?ḗ)
 ("'ē" ?ḗ)
 ("´¯e" ?ḗ)
 ("´_e" ?ḗ)
 ("'¯e" ?ḗ)
 ("'_e" ?ḗ)
 ("UȨ" ?Ḝ)
 ("bȨ" ?Ḝ)
 ("U ,E" ?Ḝ)
 ("U¸E" ?Ḝ)
 ("b,E" ?Ḝ)
 ("b¸E" ?Ḝ)
 ("Uȩ" ?ḝ)
 ("bȩ" ?ḝ)
 ("U ,e" ?ḝ)
 ("U¸e" ?ḝ)
 ("b,e" ?ḝ)
 ("b¸e" ?ḝ)
 (".F" ?Ḟ)
 ("F." ?Ḟ)
 (".f" ?ḟ)
 ("f." ?ḟ)
 ("¯G" ?Ḡ)
 ("_G" ?Ḡ)
 ("¯g" ?ḡ)
 ("_g" ?ḡ)
 (".H" ?Ḣ)
 (".h" ?ḣ)
 ("!H" ?Ḥ)
 ("!h" ?ḥ)
 ("\"H" ?Ḧ)
 ("\"h" ?ḧ)
 (",H" ?Ḩ)
 ("H," ?Ḩ)
 ("¸H" ?Ḩ)
 (",h" ?ḩ)
 ("h," ?ḩ)
 ("¸h" ?ḩ)
 ("´Ï" ?Ḯ)
 ("'Ï" ?Ḯ)
 ("´\"I" ?Ḯ)
 ("'\"I" ?Ḯ)
 ("´ï" ?ḯ)
 ("'ï" ?ḯ)
 ("´\"i" ?ḯ)
 ("'\"i" ?ḯ)
 ("´K" ?Ḱ)
 ("'K" ?Ḱ)
 ("´k" ?ḱ)
 ("'k" ?ḱ)
 ("!K" ?Ḳ)
 ("!k" ?ḳ)
 ("!L" ?Ḷ)
 ("!l" ?ḷ)
 ("¯Ḷ" ?Ḹ)
 ("_Ḷ" ?Ḹ)
 ("¯!L" ?Ḹ)
 ("_!L" ?Ḹ)
 ("¯ḷ" ?ḹ)
 ("_ḷ" ?ḹ)
 ("¯!l" ?ḹ)
 ("_!l" ?ḹ)
 ("´M" ?Ḿ)
 ("'M" ?Ḿ)
 ("´m" ?ḿ)
 ("'m" ?ḿ)
 (".M" ?Ṁ)
 ("M." ?Ṁ)
 (".m" ?ṁ)
 ("m." ?ṁ)
 ("!M" ?Ṃ)
 ("!m" ?ṃ)
 (".N" ?Ṅ)
 (".n" ?ṅ)
 ("!N" ?Ṇ)
 ("!n" ?ṇ)
 ("´Õ" ?Ṍ)
 ("'Õ" ?Ṍ)
 ("´~O" ?Ṍ)
 ("'~O" ?Ṍ)
 ("´õ" ?ṍ)
 ("'õ" ?ṍ)
 ("´~o" ?ṍ)
 ("'~o" ?ṍ)
 ("\"Õ" ?Ṏ)
 ("\"~O" ?Ṏ)
 ("\"õ" ?ṏ)
 ("\"~o" ?ṏ)
 ("`Ō" ?Ṑ)
 ("`¯O" ?Ṑ)
 ("`_O" ?Ṑ)
 ("`ō" ?ṑ)
 ("`¯o" ?ṑ)
 ("`_o" ?ṑ)
 ("´Ō" ?Ṓ)
 ("'Ō" ?Ṓ)
 ("´¯O" ?Ṓ)
 ("´_O" ?Ṓ)
 ("'¯O" ?Ṓ)
 ("'_O" ?Ṓ)
 ("´ō" ?ṓ)
 ("'ō" ?ṓ)
 ("´¯o" ?ṓ)
 ("´_o" ?ṓ)
 ("'¯o" ?ṓ)
 ("'_o" ?ṓ)
 ("´P" ?Ṕ)
 ("'P" ?Ṕ)
 ("´p" ?ṕ)
 ("'p" ?ṕ)
 (".P" ?Ṗ)
 ("P." ?Ṗ)
 (".p" ?ṗ)
 ("p." ?ṗ)
 (".R" ?Ṙ)
 (".r" ?ṙ)
 ("!R" ?Ṛ)
 ("!r" ?ṛ)
 ("¯Ṛ" ?Ṝ)
 ("_Ṛ" ?Ṝ)
 ("¯!R" ?Ṝ)
 ("_!R" ?Ṝ)
 ("¯ṛ" ?ṝ)
 ("_ṛ" ?ṝ)
 ("¯!r" ?ṝ)
 ("_!r" ?ṝ)
 (".S" ?Ṡ)
 ("S." ?Ṡ)
 (".s" ?ṡ)
 ("s." ?ṡ)
 ("!S" ?Ṣ)
 ("!s" ?ṣ)
 (".Ś" ?Ṥ)
 (".´S" ?Ṥ)
 (".'S" ?Ṥ)
 (".ś" ?ṥ)
 (".´s" ?ṥ)
 (".'s" ?ṥ)
 (".Š" ?Ṧ)
 (".š" ?ṧ)
 (".Ṣ" ?Ṩ)
 (".!S" ?Ṩ)
 (".ṣ" ?ṩ)
 (".!s" ?ṩ)
 (".T" ?Ṫ)
 ("T." ?Ṫ)
 (".t" ?ṫ)
 ("t." ?ṫ)
 ("!T" ?Ṭ)
 ("!t" ?ṭ)
 ("´Ũ" ?Ṹ)
 ("'Ũ" ?Ṹ)
 ("´~U" ?Ṹ)
 ("'~U" ?Ṹ)
 ("´ũ" ?ṹ)
 ("'ũ" ?ṹ)
 ("´~u" ?ṹ)
 ("'~u" ?ṹ)
 ("\"Ū" ?Ṻ)
 ("\"¯U" ?Ṻ)
 ("\"_U" ?Ṻ)
 ("\"ū" ?ṻ)
 ("\"¯u" ?ṻ)
 ("\"_u" ?ṻ)
 ("~V" ?Ṽ)
 ("~v" ?ṽ)
 ("!V" ?Ṿ)
 ("!v" ?ṿ)
 ("`W" ?Ẁ)
 ("`w" ?ẁ)
 ("´W" ?Ẃ)
 ("'W" ?Ẃ)
 ("´w" ?ẃ)
 ("'w" ?ẃ)
 ("\"W" ?Ẅ)
 ("\"w" ?ẅ)
 (".W" ?Ẇ)
 (".w" ?ẇ)
 ("!W" ?Ẉ)
 ("!w" ?ẉ)
 (".X" ?Ẋ)
 (".x" ?ẋ)
 ("\"X" ?Ẍ)
 ("\"x" ?ẍ)
 (".Y" ?Ẏ)
 (".y" ?ẏ)
 ("^Z" ?Ẑ)
 ("^z" ?ẑ)
 ("!Z" ?Ẓ)
 ("!z" ?ẓ)
 ("\"t" ?ẗ)
 ("ow" ?ẘ)
 ("oy" ?ẙ)
 (".ſ" ?ẛ)
 ("!A" ?Ạ)
 ("!a" ?ạ)
 ("?A" ?Ả)
 ("?a" ?ả)
 ("´Â" ?Ấ)
 ("'Â" ?Ấ)
 ("´^A" ?Ấ)
 ("'^A" ?Ấ)
 ("´â" ?ấ)
 ("'â" ?ấ)
 ("´^a" ?ấ)
 ("'^a" ?ấ)
 ("`Â" ?Ầ)
 ("`^A" ?Ầ)
 ("`â" ?ầ)
 ("`^a" ?ầ)
 ("?Â" ?Ẩ)
 ("?^A" ?Ẩ)
 ("?â" ?ẩ)
 ("?^a" ?ẩ)
 ("~Â" ?Ẫ)
 ("~^A" ?Ẫ)
 ("~â" ?ẫ)
 ("~^a" ?ẫ)
 ("^Ạ" ?Ậ)
 ("^!A" ?Ậ)
 ("^ạ" ?ậ)
 ("^!a" ?ậ)
 ("´Ă" ?Ắ)
 ("'Ă" ?Ắ)
 ("´bA" ?Ắ)
 ("'bA" ?Ắ)
 ("´ă" ?ắ)
 ("'ă" ?ắ)
 ("´ba" ?ắ)
 ("'ba" ?ắ)
 ("`Ă" ?Ằ)
 ("`bA" ?Ằ)
 ("`ă" ?ằ)
 ("`ba" ?ằ)
 ("?Ă" ?Ẳ)
 ("?bA" ?Ẳ)
 ("?ă" ?ẳ)
 ("?ba" ?ẳ)
 ("~Ă" ?Ẵ)
 ("~bA" ?Ẵ)
 ("~ă" ?ẵ)
 ("~ba" ?ẵ)
 ("UẠ" ?Ặ)
 ("bẠ" ?Ặ)
 ("U!A" ?Ặ)
 ("b!A" ?Ặ)
 ("Uạ" ?ặ)
 ("bạ" ?ặ)
 ("U!a" ?ặ)
 ("b!a" ?ặ)
 ("!E" ?Ẹ)
 ("!e" ?ẹ)
 ("?E" ?Ẻ)
 ("?e" ?ẻ)
 ("~E" ?Ẽ)
 ("~e" ?ẽ)
 ("´Ê" ?Ế)
 ("'Ê" ?Ế)
 ("´^E" ?Ế)
 ("'^E" ?Ế)
 ("´ê" ?ế)
 ("'ê" ?ế)
 ("´^e" ?ế)
 ("'^e" ?ế)
 ("`Ê" ?Ề)
 ("`^E" ?Ề)
 ("`ê" ?ề)
 ("`^e" ?ề)
 ("?Ê" ?Ể)
 ("?^E" ?Ể)
 ("?ê" ?ể)
 ("?^e" ?ể)
 ("~Ê" ?Ễ)
 ("~^E" ?Ễ)
 ("~ê" ?ễ)
 ("~^e" ?ễ)
 ("^Ẹ" ?Ệ)
 ("^!E" ?Ệ)
 ("^ẹ" ?ệ)
 ("^!e" ?ệ)
 ("?I" ?Ỉ)
 ("?i" ?ỉ)
 ("!I" ?Ị)
 ("!i" ?ị)
 ("!O" ?Ọ)
 ("!o" ?ọ)
 ("?O" ?Ỏ)
 ("?o" ?ỏ)
 ("´Ô" ?Ố)
 ("'Ô" ?Ố)
 ("´^O" ?Ố)
 ("'^O" ?Ố)
 ("´ô" ?ố)
 ("'ô" ?ố)
 ("´^o" ?ố)
 ("'^o" ?ố)
 ("`Ô" ?Ồ)
 ("`^O" ?Ồ)
 ("`ô" ?ồ)
 ("`^o" ?ồ)
 ("?Ô" ?Ổ)
 ("?^O" ?Ổ)
 ("?ô" ?ổ)
 ("?^o" ?ổ)
 ("~Ô" ?Ỗ)
 ("~^O" ?Ỗ)
 ("~ô" ?ỗ)
 ("~^o" ?ỗ)
 ("^Ọ" ?Ộ)
 ("^!O" ?Ộ)
 ("^ọ" ?ộ)
 ("^!o" ?ộ)
 ("´Ơ" ?Ớ)
 ("'Ơ" ?Ớ)
 ("´+O" ?Ớ)
 ("'+O" ?Ớ)
 ("´ơ" ?ớ)
 ("'ơ" ?ớ)
 ("´+o" ?ớ)
 ("'+o" ?ớ)
 ("`Ơ" ?Ờ)
 ("`+O" ?Ờ)
 ("`ơ" ?ờ)
 ("`+o" ?ờ)
 ("?Ơ" ?Ở)
 ("?+O" ?Ở)
 ("?ơ" ?ở)
 ("?+o" ?ở)
 ("~Ơ" ?Ỡ)
 ("~+O" ?Ỡ)
 ("~ơ" ?ỡ)
 ("~+o" ?ỡ)
 ("!Ơ" ?Ợ)
 ("!+O" ?Ợ)
 ("!ơ" ?ợ)
 ("!+o" ?ợ)
 ("!U" ?Ụ)
 ("!u" ?ụ)
 ("?U" ?Ủ)
 ("?u" ?ủ)
 ("´Ư" ?Ứ)
 ("'Ư" ?Ứ)
 ("´+U" ?Ứ)
 ("'+U" ?Ứ)
 ("´ư" ?ứ)
 ("'ư" ?ứ)
 ("´+u" ?ứ)
 ("'+u" ?ứ)
 ("`Ư" ?Ừ)
 ("`+U" ?Ừ)
 ("`ư" ?ừ)
 ("`+u" ?ừ)
 ("?Ư" ?Ử)
 ("?+U" ?Ử)
 ("?ư" ?ử)
 ("?+u" ?ử)
 ("~Ư" ?Ữ)
 ("~+U" ?Ữ)
 ("~ư" ?ữ)
 ("~+u" ?ữ)
 ("!Ư" ?Ự)
 ("!+U" ?Ự)
 ("!ư" ?ự)
 ("!+u" ?ự)
 ("`Y" ?Ỳ)
 ("`y" ?ỳ)
 ("!Y" ?Ỵ)
 ("!y" ?ỵ)
 ("?Y" ?Ỷ)
 ("?y" ?ỷ)
 ("~Y" ?Ỹ)
 ("~y" ?ỹ)
 (")α" ?ἀ)
 ("(α" ?ἁ)
 ("`ἀ" ?ἂ)
 ("`)α" ?ἂ)
 ("`ἁ" ?ἃ)
 ("`(α" ?ἃ)
 ("´ἀ" ?ἄ)
 ("'ἀ" ?ἄ)
 ("´)α" ?ἄ)
 ("')α" ?ἄ)
 ("´ἁ" ?ἅ)
 ("'ἁ" ?ἅ)
 ("´(α" ?ἅ)
 ("'(α" ?ἅ)
 ("~ἀ" ?ἆ)
 ("~)α" ?ἆ)
 ("~ἁ" ?ἇ)
 ("~(α" ?ἇ)
 (")Α" ?Ἀ)
 ("(Α" ?Ἁ)
 ("`Ἀ" ?Ἂ)
 ("`)Α" ?Ἂ)
 ("`Ἁ" ?Ἃ)
 ("`(Α" ?Ἃ)
 ("´Ἀ" ?Ἄ)
 ("'Ἀ" ?Ἄ)
 ("´)Α" ?Ἄ)
 ("')Α" ?Ἄ)
 ("´Ἁ" ?Ἅ)
 ("'Ἁ" ?Ἅ)
 ("´(Α" ?Ἅ)
 ("'(Α" ?Ἅ)
 ("~Ἀ" ?Ἆ)
 ("~)Α" ?Ἆ)
 ("~Ἁ" ?Ἇ)
 ("~(Α" ?Ἇ)
 (")ε" ?ἐ)
 ("(ε" ?ἑ)
 ("`ἐ" ?ἒ)
 ("`)ε" ?ἒ)
 ("`ἑ" ?ἓ)
 ("`(ε" ?ἓ)
 ("´ἐ" ?ἔ)
 ("'ἐ" ?ἔ)
 ("´)ε" ?ἔ)
 ("')ε" ?ἔ)
 ("´ἑ" ?ἕ)
 ("'ἑ" ?ἕ)
 ("´(ε" ?ἕ)
 ("'(ε" ?ἕ)
 (")Ε" ?Ἐ)
 ("(Ε" ?Ἑ)
 ("`Ἐ" ?Ἒ)
 ("`)Ε" ?Ἒ)
 ("`Ἑ" ?Ἓ)
 ("`(Ε" ?Ἓ)
 ("´Ἐ" ?Ἔ)
 ("'Ἐ" ?Ἔ)
 ("´)Ε" ?Ἔ)
 ("')Ε" ?Ἔ)
 ("´Ἑ" ?Ἕ)
 ("'Ἑ" ?Ἕ)
 ("´(Ε" ?Ἕ)
 ("'(Ε" ?Ἕ)
 (")η" ?ἠ)
 ("(η" ?ἡ)
 ("`ἠ" ?ἢ)
 ("`)η" ?ἢ)
 ("`ἡ" ?ἣ)
 ("`(η" ?ἣ)
 ("´ἠ" ?ἤ)
 ("'ἠ" ?ἤ)
 ("´)η" ?ἤ)
 ("')η" ?ἤ)
 ("´ἡ" ?ἥ)
 ("'ἡ" ?ἥ)
 ("´(η" ?ἥ)
 ("'(η" ?ἥ)
 ("~ἠ" ?ἦ)
 ("~)η" ?ἦ)
 ("~ἡ" ?ἧ)
 ("~(η" ?ἧ)
 (")Η" ?Ἠ)
 ("(Η" ?Ἡ)
 ("`Ἠ" ?Ἢ)
 ("`)Η" ?Ἢ)
 ("`Ἡ" ?Ἣ)
 ("`(Η" ?Ἣ)
 ("´Ἠ" ?Ἤ)
 ("'Ἠ" ?Ἤ)
 ("´)Η" ?Ἤ)
 ("')Η" ?Ἤ)
 ("´Ἡ" ?Ἥ)
 ("'Ἡ" ?Ἥ)
 ("´(Η" ?Ἥ)
 ("'(Η" ?Ἥ)
 ("~Ἠ" ?Ἦ)
 ("~)Η" ?Ἦ)
 ("~Ἡ" ?Ἧ)
 ("~(Η" ?Ἧ)
 (")ι" ?ἰ)
 ("(ι" ?ἱ)
 ("`ἰ" ?ἲ)
 ("`)ι" ?ἲ)
 ("`ἱ" ?ἳ)
 ("`(ι" ?ἳ)
 ("´ἰ" ?ἴ)
 ("'ἰ" ?ἴ)
 ("´)ι" ?ἴ)
 ("')ι" ?ἴ)
 ("´ἱ" ?ἵ)
 ("'ἱ" ?ἵ)
 ("´(ι" ?ἵ)
 ("'(ι" ?ἵ)
 ("~ἰ" ?ἶ)
 ("~)ι" ?ἶ)
 ("~ἱ" ?ἷ)
 ("~(ι" ?ἷ)
 (")Ι" ?Ἰ)
 ("(Ι" ?Ἱ)
 ("`Ἰ" ?Ἲ)
 ("`)Ι" ?Ἲ)
 ("`Ἱ" ?Ἳ)
 ("`(Ι" ?Ἳ)
 ("´Ἰ" ?Ἴ)
 ("'Ἰ" ?Ἴ)
 ("´)Ι" ?Ἴ)
 ("')Ι" ?Ἴ)
 ("´Ἱ" ?Ἵ)
 ("'Ἱ" ?Ἵ)
 ("´(Ι" ?Ἵ)
 ("'(Ι" ?Ἵ)
 ("~Ἰ" ?Ἶ)
 ("~)Ι" ?Ἶ)
 ("~Ἱ" ?Ἷ)
 ("~(Ι" ?Ἷ)
 (")ο" ?ὀ)
 ("(ο" ?ὁ)
 ("`ὀ" ?ὂ)
 ("`)ο" ?ὂ)
 ("`ὁ" ?ὃ)
 ("`(ο" ?ὃ)
 ("´ὀ" ?ὄ)
 ("'ὀ" ?ὄ)
 ("´)ο" ?ὄ)
 ("')ο" ?ὄ)
 ("´ὁ" ?ὅ)
 ("'ὁ" ?ὅ)
 ("´(ο" ?ὅ)
 ("'(ο" ?ὅ)
 (")Ο" ?Ὀ)
 ("(Ο" ?Ὁ)
 ("`Ὀ" ?Ὂ)
 ("`)Ο" ?Ὂ)
 ("`Ὁ" ?Ὃ)
 ("`(Ο" ?Ὃ)
 ("´Ὀ" ?Ὄ)
 ("'Ὀ" ?Ὄ)
 ("´)Ο" ?Ὄ)
 ("')Ο" ?Ὄ)
 ("´Ὁ" ?Ὅ)
 ("'Ὁ" ?Ὅ)
 ("´(Ο" ?Ὅ)
 ("'(Ο" ?Ὅ)
 (")υ" ?ὐ)
 ("(υ" ?ὑ)
 ("`ὐ" ?ὒ)
 ("`)υ" ?ὒ)
 ("`ὑ" ?ὓ)
 ("`(υ" ?ὓ)
 ("´ὐ" ?ὔ)
 ("'ὐ" ?ὔ)
 ("´)υ" ?ὔ)
 ("')υ" ?ὔ)
 ("´ὑ" ?ὕ)
 ("'ὑ" ?ὕ)
 ("´(υ" ?ὕ)
 ("'(υ" ?ὕ)
 ("~ὐ" ?ὖ)
 ("~)υ" ?ὖ)
 ("~ὑ" ?ὗ)
 ("~(υ" ?ὗ)
 ("(Υ" ?Ὑ)
 ("`Ὑ" ?Ὓ)
 ("`(Υ" ?Ὓ)
 ("´Ὑ" ?Ὕ)
 ("'Ὑ" ?Ὕ)
 ("´(Υ" ?Ὕ)
 ("'(Υ" ?Ὕ)
 ("~Ὑ" ?Ὗ)
 ("~(Υ" ?Ὗ)
 (")ω" ?ὠ)
 ("(ω" ?ὡ)
 ("`ὠ" ?ὢ)
 ("`)ω" ?ὢ)
 ("`ὡ" ?ὣ)
 ("`(ω" ?ὣ)
 ("´ὠ" ?ὤ)
 ("'ὠ" ?ὤ)
 ("´)ω" ?ὤ)
 ("')ω" ?ὤ)
 ("´ὡ" ?ὥ)
 ("'ὡ" ?ὥ)
 ("´(ω" ?ὥ)
 ("'(ω" ?ὥ)
 ("~ὠ" ?ὦ)
 ("~)ω" ?ὦ)
 ("~ὡ" ?ὧ)
 ("~(ω" ?ὧ)
 (")Ω" ?Ὠ)
 ("(Ω" ?Ὡ)
 ("`Ὠ" ?Ὢ)
 ("`)Ω" ?Ὢ)
 ("`Ὡ" ?Ὣ)
 ("`(Ω" ?Ὣ)
 ("´Ὠ" ?Ὤ)
 ("'Ὠ" ?Ὤ)
 ("´)Ω" ?Ὤ)
 ("')Ω" ?Ὤ)
 ("´Ὡ" ?Ὥ)
 ("'Ὡ" ?Ὥ)
 ("´(Ω" ?Ὥ)
 ("'(Ω" ?Ὥ)
 ("~Ὠ" ?Ὦ)
 ("~)Ω" ?Ὦ)
 ("~Ὡ" ?Ὧ)
 ("~(Ω" ?Ὧ)
 ("`α" ?ὰ)
 ("`ε" ?ὲ)
 ("`η" ?ὴ)
 ("`ι" ?ὶ)
 ("`ο" ?ὸ)
 ("`υ" ?ὺ)
 ("`ω" ?ὼ)
 ("ιἀ" ?ᾀ)
 ("ι)α" ?ᾀ)
 ("ιἁ" ?ᾁ)
 ("ι(α" ?ᾁ)
 ("ιἂ" ?ᾂ)
 ("ι`ἀ" ?ᾂ)
 ("ι`)α" ?ᾂ)
 ("ιἃ" ?ᾃ)
 ("ι`ἁ" ?ᾃ)
 ("ι`(α" ?ᾃ)
 ("ιἄ" ?ᾄ)
 ("ι´ἀ" ?ᾄ)
 ("ι'ἀ" ?ᾄ)
 ("ι´)α" ?ᾄ)
 ("ι')α" ?ᾄ)
 ("ιἅ" ?ᾅ)
 ("ι´ἁ" ?ᾅ)
 ("ι'ἁ" ?ᾅ)
 ("ι´(α" ?ᾅ)
 ("ι'(α" ?ᾅ)
 ("ιἆ" ?ᾆ)
 ("ι~ἀ" ?ᾆ)
 ("ι~)α" ?ᾆ)
 ("ιἇ" ?ᾇ)
 ("ι~ἁ" ?ᾇ)
 ("ι~(α" ?ᾇ)
 ("ιἈ" ?ᾈ)
 ("ι)Α" ?ᾈ)
 ("ιἉ" ?ᾉ)
 ("ι(Α" ?ᾉ)
 ("ιἊ" ?ᾊ)
 ("ι`Ἀ" ?ᾊ)
 ("ι`)Α" ?ᾊ)
 ("ιἋ" ?ᾋ)
 ("ι`Ἁ" ?ᾋ)
 ("ι`(Α" ?ᾋ)
 ("ιἌ" ?ᾌ)
 ("ι´Ἀ" ?ᾌ)
 ("ι'Ἀ" ?ᾌ)
 ("ι´)Α" ?ᾌ)
 ("ι')Α" ?ᾌ)
 ("ιἍ" ?ᾍ)
 ("ι´Ἁ" ?ᾍ)
 ("ι'Ἁ" ?ᾍ)
 ("ι´(Α" ?ᾍ)
 ("ι'(Α" ?ᾍ)
 ("ιἎ" ?ᾎ)
 ("ι~Ἀ" ?ᾎ)
 ("ι~)Α" ?ᾎ)
 ("ιἏ" ?ᾏ)
 ("ι~Ἁ" ?ᾏ)
 ("ι~(Α" ?ᾏ)
 ("ιἠ" ?ᾐ)
 ("ι)η" ?ᾐ)
 ("ιἡ" ?ᾑ)
 ("ι(η" ?ᾑ)
 ("ιἢ" ?ᾒ)
 ("ι`ἠ" ?ᾒ)
 ("ι`)η" ?ᾒ)
 ("ιἣ" ?ᾓ)
 ("ι`ἡ" ?ᾓ)
 ("ι`(η" ?ᾓ)
 ("ιἤ" ?ᾔ)
 ("ι´ἠ" ?ᾔ)
 ("ι'ἠ" ?ᾔ)
 ("ι´)η" ?ᾔ)
 ("ι')η" ?ᾔ)
 ("ιἥ" ?ᾕ)
 ("ι´ἡ" ?ᾕ)
 ("ι'ἡ" ?ᾕ)
 ("ι´(η" ?ᾕ)
 ("ι'(η" ?ᾕ)
 ("ιἦ" ?ᾖ)
 ("ι~ἠ" ?ᾖ)
 ("ι~)η" ?ᾖ)
 ("ιἧ" ?ᾗ)
 ("ι~ἡ" ?ᾗ)
 ("ι~(η" ?ᾗ)
 ("ιἨ" ?ᾘ)
 ("ι)Η" ?ᾘ)
 ("ιἩ" ?ᾙ)
 ("ι(Η" ?ᾙ)
 ("ιἪ" ?ᾚ)
 ("ι`Ἠ" ?ᾚ)
 ("ι`)Η" ?ᾚ)
 ("ιἫ" ?ᾛ)
 ("ι`Ἡ" ?ᾛ)
 ("ι`(Η" ?ᾛ)
 ("ιἬ" ?ᾜ)
 ("ι´Ἠ" ?ᾜ)
 ("ι'Ἠ" ?ᾜ)
 ("ι´)Η" ?ᾜ)
 ("ι')Η" ?ᾜ)
 ("ιἭ" ?ᾝ)
 ("ι´Ἡ" ?ᾝ)
 ("ι'Ἡ" ?ᾝ)
 ("ι´(Η" ?ᾝ)
 ("ι'(Η" ?ᾝ)
 ("ιἮ" ?ᾞ)
 ("ι~Ἠ" ?ᾞ)
 ("ι~)Η" ?ᾞ)
 ("ιἯ" ?ᾟ)
 ("ι~Ἡ" ?ᾟ)
 ("ι~(Η" ?ᾟ)
 ("ιὠ" ?ᾠ)
 ("ι)ω" ?ᾠ)
 ("ιὡ" ?ᾡ)
 ("ι(ω" ?ᾡ)
 ("ιὢ" ?ᾢ)
 ("ι`ὠ" ?ᾢ)
 ("ι`)ω" ?ᾢ)
 ("ιὣ" ?ᾣ)
 ("ι`ὡ" ?ᾣ)
 ("ι`(ω" ?ᾣ)
 ("ιὤ" ?ᾤ)
 ("ι´ὠ" ?ᾤ)
 ("ι'ὠ" ?ᾤ)
 ("ι´)ω" ?ᾤ)
 ("ι')ω" ?ᾤ)
 ("ιὥ" ?ᾥ)
 ("ι´ὡ" ?ᾥ)
 ("ι'ὡ" ?ᾥ)
 ("ι´(ω" ?ᾥ)
 ("ι'(ω" ?ᾥ)
 ("ιὦ" ?ᾦ)
 ("ι~ὠ" ?ᾦ)
 ("ι~)ω" ?ᾦ)
 ("ιὧ" ?ᾧ)
 ("ι~ὡ" ?ᾧ)
 ("ι~(ω" ?ᾧ)
 ("ιὨ" ?ᾨ)
 ("ι)Ω" ?ᾨ)
 ("ιὩ" ?ᾩ)
 ("ι(Ω" ?ᾩ)
 ("ιὪ" ?ᾪ)
 ("ι`Ὠ" ?ᾪ)
 ("ι`)Ω" ?ᾪ)
 ("ιὫ" ?ᾫ)
 ("ι`Ὡ" ?ᾫ)
 ("ι`(Ω" ?ᾫ)
 ("ιὬ" ?ᾬ)
 ("ι´Ὠ" ?ᾬ)
 ("ι'Ὠ" ?ᾬ)
 ("ι´)Ω" ?ᾬ)
 ("ι')Ω" ?ᾬ)
 ("ιὭ" ?ᾭ)
 ("ι´Ὡ" ?ᾭ)
 ("ι'Ὡ" ?ᾭ)
 ("ι´(Ω" ?ᾭ)
 ("ι'(Ω" ?ᾭ)
 ("ιὮ" ?ᾮ)
 ("ι~Ὠ" ?ᾮ)
 ("ι~)Ω" ?ᾮ)
 ("ιὯ" ?ᾯ)
 ("ι~Ὡ" ?ᾯ)
 ("ι~(Ω" ?ᾯ)
 ("Uα" ?ᾰ)
 ("bα" ?ᾰ)
 ("¯α" ?ᾱ)
 ("_α" ?ᾱ)
 ("ιὰ" ?ᾲ)
 ("ι`α" ?ᾲ)
 ("ια" ?ᾳ)
 ("ιά" ?ᾴ)
 ("ι´α" ?ᾴ)
 ("ι'α" ?ᾴ)
 ("~α" ?ᾶ)
 ("ιᾶ" ?ᾷ)
 ("ι~α" ?ᾷ)
 ("UΑ" ?Ᾰ)
 ("bΑ" ?Ᾰ)
 ("¯Α" ?Ᾱ)
 ("_Α" ?Ᾱ)
 ("`Α" ?Ὰ)
 ("ιΑ" ?ᾼ)
 ("¨~" ?῁)
 ("ιὴ" ?ῂ)
 ("ι`η" ?ῂ)
 ("ιη" ?ῃ)
 ("ιή" ?ῄ)
 ("ι´η" ?ῄ)
 ("ι'η" ?ῄ)
 ("~η" ?ῆ)
 ("ιῆ" ?ῇ)
 ("ι~η" ?ῇ)
 ("`Ε" ?Ὲ)
 ("`Η" ?Ὴ)
 ("ιΗ" ?ῌ)
 ("᾿`" ?῍)
 ("᾿´" ?῎)
 ("᾿'" ?῎)
 ("᾿~" ?῏)
 ("Uι" ?ῐ)
 ("bι" ?ῐ)
 ("¯ι" ?ῑ)
 ("_ι" ?ῑ)
 ("`ϊ" ?ῒ)
 ("`\"ι" ?ῒ)
 ("~ι" ?ῖ)
 ("~ϊ" ?ῗ)
 ("~\"ι" ?ῗ)
 ("UΙ" ?Ῐ)
 ("bΙ" ?Ῐ)
 ("¯Ι" ?Ῑ)
 ("_Ι" ?Ῑ)
 ("`Ι" ?Ὶ)
 ("῾`" ?῝)
 ("῾´" ?῞)
 ("῾'" ?῞)
 ("῾~" ?῟)
 ("Uυ" ?ῠ)
 ("bυ" ?ῠ)
 ("¯υ" ?ῡ)
 ("_υ" ?ῡ)
 ("`ϋ" ?ῢ)
 ("`\"υ" ?ῢ)
 (")ρ" ?ῤ)
 ("(ρ" ?ῥ)
 ("~υ" ?ῦ)
 ("~ϋ" ?ῧ)
 ("~\"υ" ?ῧ)
 ("UΥ" ?Ῠ)
 ("bΥ" ?Ῠ)
 ("¯Υ" ?Ῡ)
 ("_Υ" ?Ῡ)
 ("`Υ" ?Ὺ)
 ("(Ρ" ?Ῥ)
 ("¨`" ?῭)
 ("ιὼ" ?ῲ)
 ("ι`ω" ?ῲ)
 ("ιω" ?ῳ)
 ("ιώ" ?ῴ)
 ("ι´ω" ?ῴ)
 ("ι'ω" ?ῴ)
 ("~ω" ?ῶ)
 ("ιῶ" ?ῷ)
 ("ι~ω" ?ῷ)
 ("`Ο" ?Ὸ)
 ("`Ω" ?Ὼ)
 ("ιΩ" ?ῼ)
 ("^0" ?⁰)
 ("^_i" ?ⁱ)
 ("^_i" ?ⁱ)
 ("^4" ?⁴)
 ("^5" ?⁵)
 ("^6" ?⁶)
 ("^7" ?⁷)
 ("^8" ?⁸)
 ("^9" ?⁹)
 ("^+" ?⁺)
 ("^−" ?⁻)
 ("^=" ?⁼)
 ("^(" ?⁽)
 ("^)" ?⁾)
 ("^_n" ?ⁿ)
 ("^_n" ?ⁿ)
 ("_0" ?₀)
 ("_0" ?₀)
 ("_1" ?₁)
 ("_1" ?₁)
 ("_2" ?₂)
 ("_2" ?₂)
 ("_3" ?₃)
 ("_3" ?₃)
 ("_4" ?₄)
 ("_4" ?₄)
 ("_5" ?₅)
 ("_5" ?₅)
 ("_6" ?₆)
 ("_6" ?₆)
 ("_7" ?₇)
 ("_7" ?₇)
 ("_8" ?₈)
 ("_8" ?₈)
 ("_9" ?₉)
 ("_9" ?₉)
 ("_+" ?₊)
 ("_+" ?₊)
 ("_−" ?₋)
 ("_−" ?₋)
 ("_=" ?₌)
 ("_=" ?₌)
 ("_(" ?₍)
 ("_(" ?₍)
 ("_)" ?₎)
 ("_)" ?₎)
 ("SM" ?℠)
 ("sM" ?℠)
 ("Sm" ?℠)
 ("sm" ?℠)
 ("TM" ?™)
 ("tM" ?™)
 ("Tm" ?™)
 ("tm" ?™)
 ("17" ?⅐)
 ("19" ?⅑)
 ("110" ?⅒)
 ("13" ?⅓)
 ("23" ?⅔)
 ("15" ?⅕)
 ("25" ?⅖)
 ("35" ?⅗)
 ("45" ?⅘)
 ("16" ?⅙)
 ("56" ?⅚)
 ("18" ?⅛)
 ("38" ?⅜)
 ("58" ?⅝)
 ("78" ?⅞)
 ("03" ?↉)
 ("/←" ?↚)
 ("/→" ?↛)
 ("/↔" ?↮)
 ("<-" ?←)
 ("->" ?→)
 ("=>" ?⇒)
 ("∄" ?∄)
 ("{}" ?∅)
 ("∉" ?∉)
 ("∌" ?∌)
 ("∤" ?∤)
 ("∦" ?∦)
 ("≁" ?≁)
 ("≄" ?≄)
 ("≁" ?≇)
 ("≉" ?≉)
 ("/=" ?≠)
 ("=/" ?≠)
 ("≠" ?≠)
 ("≢" ?≢)
 ("<=" ?≤)
 (">=" ?≥)
 ("≭" ?≭)
 ("≮" ?≮)
 ("≮" ?≮)
 ("≯" ?≯)
 ("≯" ?≯)
 ("≰" ?≰)
 ("≱" ?≱)
 ("≴" ?≴)
 ("≵" ?≵)
 ("≸" ?≸)
 ("≹" ?≹)
 ("⊀" ?⊀)
 ("⊁" ?⊁)
 ("⊄" ?⊄)
 ("⊄" ?⊄)
 ("⊅" ?⊅)
 ("⊅" ?⊅)
 ("⊈" ?⊈)
 ("⊉" ?⊉)
 ("⊬" ?⊬)
 ("⊭" ?⊭)
 ("⊮" ?⊮)
 ("⊯" ?⊯)
 ("⋠" ?⋠)
 ("⋡" ?⋡)
 ("⋢" ?⋢)
 ("⋣" ?⋣)
 ("⋪" ?⋪)
 ("⋫" ?⋫)
 ("⋬" ?⋬)
 ("⋭" ?⋭)
 ("di" ?⌀)
 ("(1)" ?①)
 ("(2)" ?②)
 ("(3)" ?③)
 ("(4)" ?④)
 ("(5)" ?⑤)
 ("(6)" ?⑥)
 ("(7)" ?⑦)
 ("(8)" ?⑧)
 ("(9)" ?⑨)
 ("(10)" ?⑩)
 ("(11)" ?⑪)
 ("(12)" ?⑫)
 ("(13)" ?⑬)
 ("(14)" ?⑭)
 ("(15)" ?⑮)
 ("(16)" ?⑯)
 ("(17)" ?⑰)
 ("(18)" ?⑱)
 ("(19)" ?⑲)
 ("(20)" ?⑳)
 ("(A)" ?Ⓐ)
 ("(B)" ?Ⓑ)
 ("(C)" ?Ⓒ)
 ("(D)" ?Ⓓ)
 ("(E)" ?Ⓔ)
 ("(F)" ?Ⓕ)
 ("(G)" ?Ⓖ)
 ("(H)" ?Ⓗ)
 ("(I)" ?Ⓘ)
 ("(J)" ?Ⓙ)
 ("(K)" ?Ⓚ)
 ("(L)" ?Ⓛ)
 ("(M)" ?Ⓜ)
 ("(N)" ?Ⓝ)
 ("(O)" ?Ⓞ)
 ("(P)" ?Ⓟ)
 ("(Q)" ?Ⓠ)
 ("(R)" ?Ⓡ)
 ("(S)" ?Ⓢ)
 ("(T)" ?Ⓣ)
 ("(U)" ?Ⓤ)
 ("(V)" ?Ⓥ)
 ("(W)" ?Ⓦ)
 ("(X)" ?Ⓧ)
 ("(Y)" ?Ⓨ)
 ("(Z)" ?Ⓩ)
 ("(a)" ?ⓐ)
 ("(b)" ?ⓑ)
 ("(c)" ?ⓒ)
 ("(d)" ?ⓓ)
 ("(e)" ?ⓔ)
 ("(f)" ?ⓕ)
 ("(g)" ?ⓖ)
 ("(h)" ?ⓗ)
 ("(i)" ?ⓘ)
 ("(j)" ?ⓙ)
 ("(k)" ?ⓚ)
 ("(l)" ?ⓛ)
 ("(m)" ?ⓜ)
 ("(n)" ?ⓝ)
 ("(o)" ?ⓞ)
 ("(p)" ?ⓟ)
 ("(q)" ?ⓠ)
 ("(r)" ?ⓡ)
 ("(s)" ?ⓢ)
 ("(t)" ?ⓣ)
 ("(u)" ?ⓤ)
 ("(v)" ?ⓥ)
 ("(w)" ?ⓦ)
 ("(x)" ?ⓧ)
 ("(y)" ?ⓨ)
 ("(z)" ?ⓩ)
 ("(0)" ?⓪)
 ("⫝̸" ?⫝̸)
 ("^一" ?㆒)
 ("^二" ?㆓)
 ("^三" ?㆔)
 ("^四" ?㆕)
 ("^上" ?㆖)
 ("^中" ?㆗)
 ("^下" ?㆘)
 ("^甲" ?㆙)
 ("^乙" ?㆚)
 ("^丙" ?㆛)
 ("^丁" ?㆜)
 ("^天" ?㆝)
 ("^地" ?㆞)
 ("^人" ?㆟)
 ("(21)" ?㉑)
 ("(22)" ?㉒)
 ("(23)" ?㉓)
 ("(24)" ?㉔)
 ("(25)" ?㉕)
 ("(26)" ?㉖)
 ("(27)" ?㉗)
 ("(28)" ?㉘)
 ("(29)" ?㉙)
 ("(30)" ?㉚)
 ("(31)" ?㉛)
 ("(32)" ?㉜)
 ("(33)" ?㉝)
 ("(34)" ?㉞)
 ("(35)" ?㉟)
 ("(ᄀ)" ?㉠)
 ("(ᄂ)" ?㉡)
 ("(ᄃ)" ?㉢)
 ("(ᄅ)" ?㉣)
 ("(ᄆ)" ?㉤)
 ("(ᄇ)" ?㉥)
 ("(ᄉ)" ?㉦)
 ("(ᄋ)" ?㉧)
 ("(ᄌ)" ?㉨)
 ("(ᄎ)" ?㉩)
 ("(ᄏ)" ?㉪)
 ("(ᄐ)" ?㉫)
 ("(ᄑ)" ?㉬)
 ("(ᄒ)" ?㉭)
 ("(가)" ?㉮)
 ("(나)" ?㉯)
 ("(다)" ?㉰)
 ("(라)" ?㉱)
 ("(마)" ?㉲)
 ("(바)" ?㉳)
 ("(사)" ?㉴)
 ("(아)" ?㉵)
 ("(자)" ?㉶)
 ("(차)" ?㉷)
 ("(카)" ?㉸)
 ("(타)" ?㉹)
 ("(파)" ?㉺)
 ("(하)" ?㉻)
 ("(一)" ?㊀)
 ("(二)" ?㊁)
 ("(三)" ?㊂)
 ("(四)" ?㊃)
 ("(五)" ?㊄)
 ("(六)" ?㊅)
 ("(七)" ?㊆)
 ("(八)" ?㊇)
 ("(九)" ?㊈)
 ("(十)" ?㊉)
 ("(月)" ?㊊)
 ("(火)" ?㊋)
 ("(水)" ?㊌)
 ("(木)" ?㊍)
 ("(金)" ?㊎)
 ("(土)" ?㊏)
 ("(日)" ?㊐)
 ("(株)" ?㊑)
 ("(有)" ?㊒)
 ("(社)" ?㊓)
 ("(名)" ?㊔)
 ("(特)" ?㊕)
 ("(財)" ?㊖)
 ("(祝)" ?㊗)
 ("(労)" ?㊘)
 ("(秘)" ?㊙)
 ("(男)" ?㊚)
 ("(女)" ?㊛)
 ("(適)" ?㊜)
 ("(優)" ?㊝)
 ("(印)" ?㊞)
 ("(注)" ?㊟)
 ("(項)" ?㊠)
 ("(休)" ?㊡)
 ("(写)" ?㊢)
 ("(正)" ?㊣)
 ("(上)" ?㊤)
 ("(中)" ?㊥)
 ("(下)" ?㊦)
 ("(左)" ?㊧)
 ("(右)" ?㊨)
 ("(医)" ?㊩)
 ("(宗)" ?㊪)
 ("(学)" ?㊫)
 ("(監)" ?㊬)
 ("(企)" ?㊭)
 ("(資)" ?㊮)
 ("(協)" ?㊯)
 ("(夜)" ?㊰)
 ("(36)" ?㊱)
 ("(37)" ?㊲)
 ("(38)" ?㊳)
 ("(39)" ?㊴)
 ("(40)" ?㊵)
 ("(41)" ?㊶)
 ("(42)" ?㊷)
 ("(43)" ?㊸)
 ("(44)" ?㊹)
 ("(45)" ?㊺)
 ("(46)" ?㊻)
 ("(47)" ?㊼)
 ("(48)" ?㊽)
 ("(49)" ?㊾)
 ("(50)" ?㊿)
 ("(ア)" ?㋐)
 ("(イ)" ?㋑)
 ("(ウ)" ?㋒)
 ("(エ)" ?㋓)
 ("(オ)" ?㋔)
 ("(カ)" ?㋕)
 ("(キ)" ?㋖)
 ("(ク)" ?㋗)
 ("(ケ)" ?㋘)
 ("(コ)" ?㋙)
 ("(サ)" ?㋚)
 ("(シ)" ?㋛)
 ("(ス)" ?㋜)
 ("(セ)" ?㋝)
 ("(ソ)" ?㋞)
 ("(タ)" ?㋟)
 ("(チ)" ?㋠)
 ("(ツ)" ?㋡)
 ("(テ)" ?㋢)
 ("(ト)" ?㋣)
 ("(ナ)" ?㋤)
 ("(ニ)" ?㋥)
 ("(ヌ)" ?㋦)
 ("(ネ)" ?㋧)
 ("(ノ)" ?㋨)
 ("(ハ)" ?㋩)
 ("(ヒ)" ?㋪)
 ("(フ)" ?㋫)
 ("(ヘ)" ?㋬)
 ("(ホ)" ?㋭)
 ("(マ)" ?㋮)
 ("(ミ)" ?㋯)
 ("(ム)" ?㋰)
 ("(メ)" ?㋱)
 ("(モ)" ?㋲)
 ("(ヤ)" ?㋳)
 ("(ユ)" ?㋴)
 ("(ヨ)" ?㋵)
 ("(ラ)" ?㋶)
 ("(リ)" ?㋷)
 ("(ル)" ?㋸)
 ("(レ)" ?㋹)
 ("(ロ)" ?㋺)
 ("(ワ)" ?㋻)
 ("(ヰ)" ?㋼)
 ("(ヱ)" ?㋽)
 ("(ヲ)" ?㋾)
 ("ִי" ?יִ)
 ("ַײ" ?ײַ)
 ("ׁש" ?שׁ)
 ("ׂש" ?שׂ)
 ("ׁשּ" ?שּׁ)
 ("ּׁש" ?שּׁ)
 ("ׂשּ" ?שּׂ)
 ("ּׂש" ?שּׂ)
 ("ַא" ?אַ)
 ("ָא" ?אָ)
 ("ּא" ?אּ)
 ("ּב" ?בּ)
 ("ּג" ?גּ)
 ("ּד" ?דּ)
 ("ּה" ?הּ)
 ("ּו" ?וּ)
 ("ּז" ?זּ)
 ("ּט" ?טּ)
 ("ּי" ?יּ)
 ("ּך" ?ךּ)
 ("ּכ" ?כּ)
 ("ּל" ?לּ)
 ("ּמ" ?מּ)
 ("ּנ" ?נּ)
 ("ּס" ?סּ)
 ("ּף" ?ףּ)
 ("ּפ" ?פּ)
 ("ּצ" ?צּ)
 ("ּק" ?קּ)
 ("ּר" ?רּ)
 ("ּש" ?שּ)
 ("ּת" ?תּ)
 ("ֹו" ?וֹ)
 ("ֿב" ?בֿ)
 ("ֿכ" ?כֿ)
 ("ֿפ" ?פֿ)
 ("𝅗𝅥" ?𝅗𝅥)
 ("𝅘𝅥" ?𝅘𝅥)
 ("𝅘𝅥𝅮" ?𝅘𝅥𝅮)
 ("𝅘𝅥𝅯" ?𝅘𝅥𝅯)
 ("𝅘𝅥𝅰" ?𝅘𝅥𝅰)
 ("𝅘𝅥𝅱" ?𝅘𝅥𝅱)
 ("𝅘𝅥𝅲" ?𝅘𝅥𝅲)
 ("𝆹𝅥" ?𝆹𝅥)
 ("𝆺𝅥" ?𝆺𝅥)
 ("𝆹𝅥𝅮" ?𝆹𝅥𝅮)
 ("𝆺𝅥𝅮" ?𝆺𝅥𝅮)
 ("𝆹𝅥𝅯" ?𝆹𝅥𝅯)
 ("𝆺𝅥𝅯" ?𝆺𝅥𝅯)
 (";S" ?Ș)
 ("S;" ?Ș)
 (";s" ?ș)
 ("s;" ?ș)
 (";T" ?Ț)
 ("T;" ?Ț)
 (";t" ?ț)
 ("t;" ?ț)
 ("``а" ["а̏"])
 ("`а" ["а̀"])
 ("´а" ["а́"])
 ("'а" ["а́"])
 ("¯а" ["а̄"])
 ("_а" ["а̄"])
 ("^а" ["а̂"])
 ("``А" ["А̏"])
 ("`А" ["А̀"])
 ("´А" ["А́"])
 ("'А" ["А́"])
 ("¯А" ["А̄"])
 ("_А" ["А̄"])
 ("^А" ["А̂"])
 ("``е" ["е̏"])
 ("´е" ["е́"])
 ("'е" ["е́"])
 ("¯е" ["е̄"])
 ("_е" ["е̄"])
 ("^е" ["е̂"])
 ("``Е" ["Е̏"])
 ("´Е" ["Е́"])
 ("'Е" ["Е́"])
 ("¯Е" ["Е̄"])
 ("_Е" ["Е̄"])
 ("^Е" ["Е̂"])
 ("``и" ["и̏"])
 ("´и" ["и́"])
 ("'и" ["и́"])
 ("^и" ["и̂"])
 ("``И" ["И̏"])
 ("´И" ["И́"])
 ("'И" ["И́"])
 ("^И" ["И̂"])
 ("``о" ["о̏"])
 ("`о" ["о̀"])
 ("´о" ["о́"])
 ("'о" ["о́"])
 ("¯о" ["о̄"])
 ("_о" ["о̄"])
 ("^о" ["о̂"])
 ("``О" ["О̏"])
 ("`О" ["О̀"])
 ("´О" ["О́"])
 ("'О" ["О́"])
 ("¯О" ["О̄"])
 ("_О" ["О̄"])
 ("^О" ["О̂"])
 ("``у" ["у̏"])
 ("`у" ["у̀"])
 ("´у" ["у́"])
 ("'у" ["у́"])
 ("^у" ["у̂"])
 ("``У" ["У̏"])
 ("`У" ["У̀"])
 ("´У" ["У́"])
 ("'У" ["У́"])
 ("^У" ["У̂"])
 ("``р" ["р̏"])
 ("`р" ["р̀"])
 ("´р" ["р́"])
 ("'р" ["р́"])
 ("¯р" ["р̄"])
 ("_р" ["р̄"])
 ("^р" ["р̂"])
 ("``Р" ["Р̏"])
 ("`Р" ["Р̀"])
 ("´Р" ["Р́"])
 ("'Р" ["Р́"])
 ("¯Р" ["Р̄"])
 ("_Р" ["Р̄"])
 ("^Р" ["Р̂"])
 ("v/" ?√)
 ("/v" ?√)
 ("88" ?∞)
 ("=_" ?≡)
 ("_≠" ?≢)
 ("≠_" ?≢)
 ("<_" ?≤)
 ("_<" ?≤)
 (">_" ?≥)
 ("_>" ?≥)
 ("_⊂" ?⊆)
 ("⊂_" ?⊆)
 ("_⊃" ?⊇)
 ("⊃_" ?⊇)
 ("○-" ?⊖)
 ("-○" ?⊖)
 ("○." ?⊙)
 (".○" ?⊙)
 ("<>" ?⋄)
 ("><" ?⋄)
 ("∧∨" ?⋄)
 ("∨∧" ?⋄)
 (":." ?∴)
 (".:" ?∵)
 ("⊥⊤" ?⌶)
 ("⊤⊥" ?⌶)
 ("[]" ?⌷)
 ("][" ?⌷)
 ("⎕=" ?⌸)
 ("=⎕" ?⌸)
 ("⎕÷" ?⌹)
 ("÷⎕" ?⌹)
 ("⎕⋄" ?⌺)
 ("⋄⎕" ?⌺)
 ("⎕∘" ?⌻)
 ("∘⎕" ?⌻)
 ("⎕○" ?⌼)
 ("○⎕" ?⌼)
 ("○|" ?⌽)
 ("|○" ?⌽)
 ("○∘" ?⌾)
 ("∘○" ?⌾)
 ("/-" ?⌿)
 ("-/" ?⌿)
 ("\\-" ?⍀)
 ("-\\" ?⍀)
 ("/⎕" ?⍁)
 ("⎕/" ?⍁)
 ("\\⎕" ?⍂)
 ("⎕\\" ?⍂)
 ("<⎕" ?⍃)
 ("⎕<" ?⍃)
 (">⎕" ?⍄)
 ("⎕>" ?⍄)
 ("←|" ?⍅)
 ("|←" ?⍅)
 ("→|" ?⍆)
 ("|→" ?⍆)
 ("←⎕" ?⍇)
 ("⎕←" ?⍇)
 ("→⎕" ?⍈)
 ("⎕→" ?⍈)
 ("○\\" ?⍉)
 ("\\○" ?⍉)
 ("_⊥" ?⍊)
 ("⊥_" ?⍊)
 ("∆|" ?⍋)
 ("|∆" ?⍋)
 ("∨⎕" ?⍌)
 ("⎕∨" ?⍌)
 ("∆⎕" ?⍍)
 ("⎕∆" ?⍍)
 ("∘⊥" ?⍎)
 ("⊥∘" ?⍎)
 ("↑-" ?⍏)
 ("-↑" ?⍏)
 ("↑⎕" ?⍐)
 ("⎕↑" ?⍐)
 ("¯⊤" ?⍑)
 ("⊤¯" ?⍑)
 ("∇|" ?⍒)
 ("|∇" ?⍒)
 ("∧⎕" ?⍓)
 ("⎕∧" ?⍓)
 ("∇⎕" ?⍔)
 ("⎕∇" ?⍔)
 ("∘⊤" ?⍕)
 ("⊤∘" ?⍕)
 ("↓-" ?⍖)
 ("-↓" ?⍖)
 ("↓⎕" ?⍗)
 ("⎕↓" ?⍗)
 ("_'" ?⍘)
 ("∆_" ?⍙)
 ("_∆" ?⍙)
 ("⋄_" ?⍚)
 ("_⋄" ?⍚)
 ("∘_" ?⍛)
 ("_∘" ?⍛)
 ("○_" ?⍜)
 ("_○" ?⍜)
 ("∘∩" ?⍝)
 ("∩∘" ?⍝)
 ("⎕'" ?⍞)
 ("'⎕" ?⍞)
 ("○*" ?⍟)
 ("*○" ?⍟)
 (":⎕" ?⍠)
 ("⎕:" ?⍠)
 ("¨⊤" ?⍡)
 ("⊤¨" ?⍡)
 ("¨∇" ?⍢)
 ("∇¨" ?⍢)
 ("*¨" ?⍣)
 ("¨*" ?⍣)
 ("∘¨" ?⍤)
 ("¨∘" ?⍤)
 ("○¨" ?⍥)
 ("¨○" ?⍥)
 ("∪|" ?⍦)
 ("|∪" ?⍦)
 ("⊂|" ?⍧)
 ("|⊂" ?⍧)
 ("~¨" ?⍨)
 ("¨>" ?⍩)
 (">¨" ?⍩)
 ("∇~" ?⍫)
 ("~∇" ?⍫)
 ("0~" ?⍬)
 ("~0" ?⍬)
 ("|~" ?⍭)
 ("~|" ?⍭)
 (";_" ?⍮)
 ("≠⎕" ?⍯)
 ("⎕≠" ?⍯)
 ("?⎕" ?⍰)
 ("⎕?" ?⍰)
 ("∨~" ?⍱)
 ("~∨" ?⍱)
 ("∧~" ?⍲)
 ("~∧" ?⍲)
 ("⍺_" ?⍶)
 ("_⍺" ?⍶)
 ("∊_" ?⍷)
 ("_∊" ?⍷)
 ("⍳_" ?⍸)
 ("_⍳" ?⍸)
 ("⍵_" ?⍹)
 ("_⍵" ?⍹)
 )

;; Quail package `iso-transl' is based on `C-x 8' key sequences.
;; This input method supports the same key sequences as defined
;; by the `C-x 8' keymap in iso-transl.el.

(quail-define-package
 "iso-transl" "UTF-8" "X8" t
 "Use the same key sequences as in `C-x 8' keymap defined in iso-transl.el.
Examples:
 * E -> €   1 / 2 -> ½   ^ 3 -> ³"
 '(("\t" . quail-completion))
 t nil nil nil nil nil nil nil nil t)

(eval-when-compile
  (require 'iso-transl)
  (defmacro iso-transl--define-rules ()
    `(quail-define-rules
      ,@(mapcar (lambda (rule)
                  (let ((from (car rule))
                        (to (cdr rule)))
                    (list from (if (stringp to)
                                   (vector to)
                                 to))))
                iso-transl-char-map))))

(iso-transl--define-rules)

(provide 'compose)
;;; compose.el ends here
