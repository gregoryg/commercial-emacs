;;; sami.el --- Quail package for inputting Sámi  -*-coding: utf-8; lexical-binding: t -*-

;; Copyright (C) 2019-2022 Free Software Foundation, Inc.

;; Author: Wojciech S. Gac <wojciech.s.gac@gmail.com>
;; Keywords: i18n, multilingual, input method, Sámi

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

;; This file implements the following input methods for the Sámi
;; language
;; - norwegian-sami-prefix
;; - bergsland-hasselbrink-sami-prefix
;; - southern-sami-prefix
;; - ume-sami-prefix
;; - northern-sami-prefix
;; - inari-sami-prefix
;; - skolt-sami-prefix
;; - kildin-sami-prefix

;;; Code:

(require 'quail)

(quail-define-package
 "norwegian-sami-prefix" "Sámi" "/NSoS" nil
 "Norwegian Southern Sámi input method

Alphabet (parenthesized letters are used in foreign names):
А а	B b	(C c)	D d	E e	F f	G g	H h
I i	(Ï ï)	J j	K k	L l	M m	N n	O o
P p	(Q q)	R r	S s	T t	U u	V v	(W w)
(X x)	Y y	(Z z)	Æ æ	Ø ø	Å å
"
 nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ("А" ?А)
 ("а" ?а)
 ("B" ?B)
 ("b" ?b)
 ("C" ?C)
 ("c" ?c)
 ("D" ?D)
 ("d" ?d)
 ("E" ?E)
 ("e" ?e)
 ("F" ?F)
 ("f" ?f)
 ("G" ?G)
 ("g" ?g)
 ("H" ?H)
 ("h" ?h)
 ("I" ?I)
 ("i" ?i)
 (":I" ?Ï)
 (":i" ?ï)
 ("J" ?J)
 ("j" ?j)
 ("K" ?K)
 ("k" ?k)
 ("L" ?L)
 ("l" ?l)
 ("M" ?M)
 ("m" ?m)
 ("N" ?N)
 ("n" ?n)
 ("O" ?O)
 ("o" ?o)
 ("P" ?P)
 ("p" ?p)
 ("Q" ?Q)
 ("q" ?q)
 ("R" ?R)
 ("r" ?r)
 ("S" ?S)
 ("s" ?s)
 ("T" ?T)
 ("t" ?t)
 ("U" ?U)
 ("u" ?u)
 ("V" ?V)
 ("v" ?v)
 ("W" ?W)
 ("w" ?w)
 ("X" ?X)
 ("x" ?x)
 ("Y" ?Y)
 ("y" ?y)
 ("Z" ?Z)
 ("z" ?z)
 ("AE" ?Æ)
 ("ae" ?æ)
 ("/O" ?Ø)
 ("/o" ?ø)
 ("/A" ?Å)
 ("/a" ?å))

(quail-define-package
 "bergsland-hasselbrink-sami-prefix" "Sámi" "/BHS" nil
 "Bergsland-Hasselbrink Southern Sámi input method

Alphabet:
А а	Â â	Á á	B b	C c	Č č	D d	Đ đ
E e	F f	G g	H h	I i	Î î	J j	K k
L l	M m	N n	Ŋ ŋ	O o	P p	R r	S s
Š š	T t	U u	V v	Y y	Z z	Ž ž	Ä ä
Æ æ	Ö ö	Å å	'
"
 nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ("А" ?А)
 ("а" ?а)
 ("^A" ?Â)
 ("^a" ?â)
 ("'A" ?Á)
 ("'a" ?á)
 ("B" ?B)
 ("b" ?b)
 ("C" ?C)
 ("c" ?c)
 ("^C" ?Č)
 ("^c" ?č)
 ("D" ?D)
 ("d" ?d)
 ("-D" ?Đ)
 ("-d" ?đ)
 ("E" ?E)
 ("e" ?e)
 ("F" ?F)
 ("f" ?f)
 ("G" ?G)
 ("g" ?g)
 ("H" ?H)
 ("h" ?h)
 ("I" ?I)
 ("i" ?i)
 ("^I" ?Î)
 ("^i" ?î)
 ("J" ?J)
 ("j" ?j)
 ("K" ?K)
 ("k" ?k)
 ("L" ?L)
 ("l" ?l)
 ("M" ?M)
 ("m" ?m)
 ("N" ?N)
 ("n" ?n)
 ("/N" ?Ŋ)
 ("/n" ?ŋ)
 ("O" ?O)
 ("o" ?o)
 ("P" ?P)
 ("p" ?p)
 ("R" ?R)
 ("r" ?r)
 ("S" ?S)
 ("s" ?s)
 ("^S" ?Š)
 ("^s" ?š)
 ("T" ?T)
 ("t" ?t)
 ("U" ?U)
 ("u" ?u)
 ("V" ?V)
 ("v" ?v)
 ("Y" ?Y)
 ("y" ?y)
 ("Z" ?Z)
 ("z" ?z)
 ("^Z" ?Ž)
 ("^z" ?ž)
 (":A" ?Ä)
 (":a" ?ä)
 ("AE" ?Æ)
 ("ae" ?æ)
 (":O" ?Ö)
 (":o" ?ö)
 ("/A" ?Å)
 ("/a" ?å))

(quail-define-package
 "southern-sami-prefix" "Sámi" "/SoS" nil
 "Contemporary Southern Sámi input method

Alphabet (parenthesized letters are used in foreign names):
А а	B b	(C c)	D d	E e	F f	G g	H h
I i	(Ï ï)	J j	K k	L l	M m	N n	O o
P p	(Q q)	R r	S s	T t	U u	V v	(W w)
(X x)	Y y	(Z z)	Ä ä	Ö ö	Å å
"
 nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ("А" ?А)
 ("а" ?а)
 ("B" ?B)
 ("b" ?b)
 ("C" ?C)
 ("c" ?c)
 ("D" ?D)
 ("d" ?d)
 ("E" ?E)
 ("e" ?e)
 ("F" ?F)
 ("f" ?f)
 ("G" ?G)
 ("g" ?g)
 ("H" ?H)
 ("h" ?h)
 ("I" ?I)
 ("i" ?i)
 (":I" ?Ï)
 (":i" ?ï)
 ("J" ?J)
 ("j" ?j)
 ("K" ?K)
 ("k" ?k)
 ("L" ?L)
 ("l" ?l)
 ("M" ?M)
 ("m" ?m)
 ("N" ?N)
 ("n" ?n)
 ("O" ?O)
 ("o" ?o)
 ("P" ?P)
 ("p" ?p)
 ("Q" ?Q)
 ("q" ?q)
 ("R" ?R)
 ("r" ?r)
 ("S" ?S)
 ("s" ?s)
 ("T" ?T)
 ("t" ?t)
 ("U" ?U)
 ("u" ?u)
 ("V" ?V)
 ("v" ?v)
 ("W" ?W)
 ("w" ?w)
 ("X" ?X)
 ("x" ?x)
 ("Y" ?Y)
 ("y" ?y)
 ("Z" ?Z)
 ("z" ?z)
 (":A" ?Ä)
 (":a" ?ä)
 (":O" ?Ö)
 (":o" ?ö)
 ("/A" ?Å)
 ("/a" ?å))

(quail-define-package
 "ume-sami-prefix" "Sámi" "/UmS" nil
 "Ume Sámi input method

Alphabet:
А а	Á á	B b	D d	Đ đ	E e	F f	G g
H h	I i	Ï ï	J j	K k	L l	M m	N n
Ŋ ŋ	O o	P p	R r	S s	T t	Ŧ ŧ	U u
Ü ü	V v	Y y	Å å	Ä ä	Ö ö
"
 nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ("А" ?А)
 ("а" ?а)
 ("'A" ?Á)
 ("'a" ?á)
 ("B" ?B)
 ("b" ?b)
 ("D" ?D)
 ("d" ?d)
 ("-D" ?Đ)
 ("-d" ?đ)
 ("E" ?E)
 ("e" ?e)
 ("F" ?F)
 ("f" ?f)
 ("G" ?G)
 ("g" ?g)
 ("H" ?H)
 ("h" ?h)
 ("I" ?I)
 ("i" ?i)
 (":I" ?Ï)
 (":i" ?ï)
 ("J" ?J)
 ("j" ?j)
 ("K" ?K)
 ("k" ?k)
 ("L" ?L)
 ("l" ?l)
 ("M" ?M)
 ("m" ?m)
 ("N" ?N)
 ("n" ?n)
 ("/N" ?Ŋ)
 ("/n" ?ŋ)
 ("O" ?O)
 ("o" ?o)
 ("P" ?P)
 ("p" ?p)
 ("R" ?R)
 ("r" ?r)
 ("S" ?S)
 ("s" ?s)
 ("T" ?T)
 ("t" ?t)
 ("-T" ?Ŧ)
 ("-t" ?ŧ)
 ("U" ?U)
 ("u" ?u)
 (":U" ?Ü)
 (":u" ?ü)
 ("V" ?V)
 ("v" ?v)
 ("Y" ?Y)
 ("y" ?y)
 ("/A" ?Å)
 ("/a" ?å)
 (":A" ?Ä)
 (":a" ?ä)
 (":O" ?Ö)
 (":o" ?ö)
 )

(quail-define-package
 "northern-sami-prefix" "Sámi" "/NoS" nil
 "Northern Sámi input method

Alphabet:
А а	Á á	B b	C c	Č č	D d	Đ đ	E e
F f	G g	H h	I i	J j	K k	L l	M m
N n	Ŋ ŋ	O o	P p	R r	S s	Š š	T t
Ŧ ŧ	U u	V v	Z z	Ž ž
"
 nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ("А" ?А)
 ("а" ?а)
 ("'A" ?Á)
 ("'a" ?á)
 ("B" ?B)
 ("b" ?b)
 ("C" ?C)
 ("c" ?c)
 ("^C" ?Č)
 ("^c" ?č)
 ("D" ?D)
 ("d" ?d)
 ("-D" ?Đ)
 ("-d" ?đ)
 ("E" ?E)
 ("e" ?e)
 ("F" ?F)
 ("f" ?f)
 ("G" ?G)
 ("g" ?g)
 ("H" ?H)
 ("h" ?h)
 ("I" ?I)
 ("i" ?i)
 ("J" ?J)
 ("j" ?j)
 ("K" ?K)
 ("k" ?k)
 ("L" ?L)
 ("l" ?l)
 ("M" ?M)
 ("m" ?m)
 ("N" ?N)
 ("n" ?n)
 ("/N" ?Ŋ)
 ("/n" ?ŋ)
 ("O" ?O)
 ("o" ?o)
 ("P" ?P)
 ("p" ?p)
 ("R" ?R)
 ("r" ?r)
 ("S" ?S)
 ("s" ?s)
 ("^S" ?Š)
 ("^s" ?š)
 ("T" ?T)
 ("t" ?t)
 ("-T" ?Ŧ)
 ("-t" ?ŧ)
 ("U" ?U)
 ("u" ?u)
 ("V" ?V)
 ("v" ?v)
 ("Z" ?Z)
 ("z" ?z)
 ("^Z" ?Ž)
 ("^z" ?ž)
 )

(quail-define-package
 "inari-sami-prefix" "Sámi" "/InS" nil
 "Inari Sámi input method

Alphabet (parenthesized letters are used in foreign names only):
А а	Â â	B b	C c	Č č	D d	Đ đ	E e
F f	G g	H h	I i	J j	K k	L l	M m
N n	O o	P p	(Q q)	R r	S s	Š š	T t
U u	V v	(W w)	(X x)	Y y	Z z	Ž ž	Ä ä
Á á	Å å	Ö ö
"
 nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ("А" ?А)
 ("а" ?а)
 ("^A" ?Â)
 ("^a" ?â)
 ("B" ?B)
 ("b" ?b)
 ("C" ?C)
 ("c" ?c)
 ("^C" ?Č)
 ("^c" ?č)
 ("D" ?D)
 ("d" ?d)
 ("-D" ?Đ)
 ("-d" ?đ)
 ("E" ?E)
 ("e" ?e)
 ("F" ?F)
 ("f" ?f)
 ("G" ?G)
 ("g" ?g)
 ("H" ?H)
 ("h" ?h)
 ("I" ?I)
 ("i" ?i)
 ("J" ?J)
 ("j" ?j)
 ("K" ?K)
 ("k" ?k)
 ("L" ?L)
 ("l" ?l)
 ("M" ?M)
 ("m" ?m)
 ("N" ?N)
 ("n" ?n)
 ("O" ?O)
 ("o" ?o)
 ("P" ?P)
 ("p" ?p)
 ("Q" ?Q)
 ("q" ?q)
 ("R" ?R)
 ("r" ?r)
 ("S" ?S)
 ("s" ?s)
 ("^S" ?Š)
 ("^s" ?š)
 ("T" ?T)
 ("t" ?t)
 ("U" ?U)
 ("u" ?u)
 ("V" ?V)
 ("v" ?v)
 ("W" ?W)
 ("w" ?w)
 ("X" ?X)
 ("x" ?x)
 ("Y" ?Y)
 ("y" ?y)
 ("Z" ?Z)
 ("z" ?z)
 ("^Z" ?Ž)
 ("^z" ?ž)
 (":A" ?Ä)
 (":a" ?ä)
 ("'A" ?Á)
 ("'a" ?á)
 ("/A" ?Å)
 ("/a" ?å)
 (":O" ?Ö)
 (":o" ?ö))

(quail-define-package
 "skolt-sami-prefix" "Sámi" "/SkS" nil
 "Skolt Sámi input method

Alphabet (parenthesized letters are used in foreign names only):
А а	Â â	B b	C c	Č č	Ʒ ʒ	Ǯ ǯ	D d
Đ đ	E e	F f	G g	Ǧ ǧ	Ǥ ǥ	H h	I i
J j	K k	Ǩ ǩ	L l	M m	N n	Ŋ ŋ	O o
Õ õ	P p	(Q q)	R r	S s	Š š	T t	U u
V v	(W w)	(X x)	(Y y)	Z z	Ž ž	Å å	Ä ä
(Ö ö)	ʹ
"
 nil t nil nil nil nil nil nil nil nil t)

(quail-define-rules
 ("A" ?А)
 ("a" ?а)
 ("^A" ?Â)
 ("^a" ?â)
 ("B" ?B)
 ("b" ?b)
 ("C" ?C)
 ("c" ?c)
 ("^C" ?Č)
 ("^c" ?č)
 ("/X" ?Ʒ)
 ("/x" ?ʒ)
 ("^X" ?Ǯ)
 ("^x" ?ǯ)
 ("D" ?D)
 ("d" ?d)
 ("-D" ?Đ)
 ("-d" ?đ)
 ("E" ?E)
 ("e" ?e)
 ("F" ?F)
 ("f" ?f)
 ("G" ?G)
 ("g" ?g)
 ("^G" ?Ǧ)
 ("^g" ?ǧ)
 ("-G" ?Ǥ)
 ("-g" ?ǥ)
 ("H" ?H)
 ("h" ?h)
 ("I" ?I)
 ("i" ?i)
 ("J" ?J)
 ("j" ?j)
 ("K" ?K)
 ("k" ?k)
 ("^K" ?Ǩ)
 ("^k" ?ǩ)
 ("L" ?L)
 ("l" ?l)
 ("M" ?M)
 ("m" ?m)
 ("N" ?N)
 ("n" ?n)
 ("/N" ?Ŋ)
 ("/n" ?ŋ)
 ("O" ?O)
 ("o" ?o)
 ("~O" ?Õ)
 ("~o" ?õ)
 ("P" ?P)
 ("p" ?p)
 ("Q" ?Q)
 ("q" ?q)
 ("R" ?R)
 ("r" ?r)
 ("S" ?S)
 ("s" ?s)
 ("^S" ?Š)
 ("^s" ?š)
 ("T" ?T)
 ("t" ?t)
 ("U" ?U)
 ("u" ?u)
 ("V" ?V)
 ("v" ?v)
 ("W" ?W)
 ("w" ?w)
 ("X" ?X)
 ("x" ?x)
 ("Y" ?Y)
 ("y" ?y)
 ("Z" ?Z)
 ("z" ?z)
 ("^Z" ?Ž)
 ("^z" ?ž)
 ("/A" ?Å)
 ("/a" ?å)
 (":A" ?Ä)
 (":a" ?ä)
 (":O" ?Ö)
 (":o" ?ö))

(quail-define-package
 "kildin-sami-prefix" "Sámi" "/KiS" nil
 "Kildin Sámi input method

Alphabet (parenthesized letters are used in foreign names only):
А а	А̄ а̄	Ӓ ӓ	Б б	В в	Г г	Д д	Е е	Е̄ е̄
Ё ё	Ё̄ ё̄	Ж ж	З з	Һ һ	(')	И и	Ӣ ӣ	Й й
Ј ј	(Ҋ ҋ)	К к	Л л	Ӆ ӆ	М м	Ӎ ӎ	Н н	Ӊ ӊ
Ӈ ӈ	О о	О̄ о̄	П п	Р р	Ҏ ҏ	С с	Т т	У у
Ӯ ӯ	Ф ф	Х х	Ц ц	Ч ч	Ш ш	Щ щ	Ъ ъ	Ы ы
Ь ь	Ҍ ҍ	Э э	Э̄ э̄	Ӭ ӭ	Ю ю	Ю̄ ю̄	Я я	Я̄ я̄
")

(quail-define-rules
 ("1" ?1)
 ("2" ?2)
 ("3" ?3)
 ("4" ?4)
 ("5" ?5)
 ("6" ?6)
 ("7" ?7)
 ("8" ?8)
 ("9" ?9)
 ("0" ?0)
 ("-" ?-)
 ("=" ?ч)
 ("`" ?ю)
 ("-`" ["ю̄"])
 ("q" ?я)
 ("-q" ["я̄"])
 ("w" ?в)
 ("e" ?е)
 ("-e" ["е̄"])
 ("-@" ["ё̄"])
 ("r" ?р)
 ("-r" ?ҏ)
 ("t" ?т)
 ("y" ?ы)
 ("u" ?у)
 ("-u" ?ӯ)
 ("i" ?и)
 ("o" ?о)
 ("-o" ["о̄"])
 ("p" ?п)
 ("[" ?ш)
 ("]" ?щ)
 ("a" ?а)
 ("-a" ["а̄"])
 (":a" ?ӓ)
 ("s" ?с)
 ("d" ?д)
 ("f" ?ф)
 ("g" ?г)
 ("h" ?х)
 ("/h" ?һ)
 ("j" ?й)
 ("-j" ["ӣ"])
 ("'j" ?ҋ)
 ("/j" ?ј)
 ("k" ?к)
 ("l" ?л)
 ("'l" ?ӆ)
 (";" ?\;)
 ("'" ?')
 ("\\" ?э)
 ("-\\" ["э̄"])
 (":\\" ?ӭ)
 ("z" ?з)
 ("x" ?ь)
 ("-x" ?ҍ)
 ("c" ?ц)
 ("v" ?ж)
 ("b" ?б)
 ("n" ?н)
 ("'n" ?ӊ)
 (",n" ?ӈ)
 ("m" ?м)
 ("'m" ?ӎ)
 ("," ?,)
 ("." ?.)
 ("/" ?/)

 ("!" ?!)
 ("@" ?ё)
 ("#" ?ъ)
 ("$" ?Ё)
 ("%" ?%)
 ("^" ?^)
 ("&" ?&)
 ("*" ?*)
 ("(" ?\()
 (")" ?\))
 ("_" ?_)
 ("+" ?Ч)
 ("~" ?Ю)
 ("-~" ["Ю̄"])
 ("Q" ?Я)
 ("-Q" ["Я̄"])
 ("W" ?В)
 ("E" ?Е)
 ("-E" ["Е̄"])
 ("-$" ["Ё̄"])
 ("R" ?Р)
 ("-R" ?Ҏ)
 ("T" ?Т)
 ("Y" ?Ы)
 ("U" ?У)
 ("-U" ["Ӯ"])
 ("I" ?И)
 ("O" ?О)
 ("-O" ["О̄"])
 ("P" ?П)
 ("{" ?Ш)
 ("}" ?Щ)
 ("A" ?А)
 ("-A" ["А̄"])
 (":A" ?Ӓ)
 ("S" ?С)
 ("D" ?Д)
 ("F" ?Ф)
 ("G" ?Г)
 ("H" ?Х)
 ("/H" ?Һ)
 ("J" ?Й)
 ("-J" ["Ӣ"])
 ("'J" ?Ҋ)
 ("/J" ?Ј)
 ("K" ?К)
 ("L" ?Л)
 ("'L" ?Ӆ)
 (":" ?:)
 ("\"" ?\")
 ("|" ?Э)
 ("-|" ["Э̄"])
 (":|" ?Ӭ)
 ("Z" ?З)
 ("X" ?Ь)
 ("-X" ?Ҍ)
 ("C" ?Ц)
 ("V" ?Ж)
 ("B" ?Б)
 ("N" ?Н)
 ("'N" ?Ӊ)
 (",N" ?Ӈ)
 ("M" ?М)
 ("'M" ?Ӎ)
 ("<" ?<)
 (">" ?>)
 ("?" ??))

;;; sami.el ends here
