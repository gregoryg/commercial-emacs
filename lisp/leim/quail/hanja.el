;;; hanja.el --- Quail-package for Korean Hanja (KSC5601)  -*-coding: utf-8; lexical-binding: t -*-

;; Copyright (C) 1997, 2001-2023 Free Software Foundation, Inc.
;; Copyright (C) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
;;   2006, 2007, 2008, 2009, 2010, 2011
;;   National Institute of Advanced Industrial Science and Technology (AIST)
;;   Registration Number H14PRO021

;; Keywords: multilingual, input method, Korean, Hanja

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

;; This file defines korean-hanja keyboards:
;; - hanja input method with hangul keyboard type 2

;;; Code:

(require 'quail)
(require 'korea-util)

(quail-define-package
 "korean-hanja" "Korean" "漢2" t
 "2벌식KSC漢字: 該當하는 漢字의 韻을 한글2벌式으로 呼出하여 選擇"
		      nil nil nil nil nil nil t)

(quail-define-rules
 ("rk"	"伽佳假價加可呵哥嘉嫁家暇架枷柯歌珂痂稼苛茄街袈訶賈跏軻迦駕")
 ("rkr"	"刻却各恪慤殼珏脚覺角閣")
 ("rks"	"侃刊墾奸姦干幹懇揀杆柬桿澗癎看磵稈竿簡肝艮艱諫間")
 ("rkf"	"乫喝曷渴碣竭葛褐蝎鞨")
 ("rka"	"勘坎堪嵌感憾戡敢柑橄減甘疳監瞰紺邯鑑鑒龕")
 ("rkq"	"匣岬甲胛鉀閘")
 ("rkd"	"剛堈姜岡崗康强彊慷江畺疆糠絳綱羌腔舡薑襁講鋼降鱇")
 ("ro"	"介价個凱塏愷愾慨改槪漑疥皆盖箇芥蓋豈鎧開")
 ("ror"	"喀客")
 ("rod"	"坑更粳羹")
 ("rir"	"醵")
 ("rj"	"倨去居巨拒据據擧渠炬祛距踞車遽鉅鋸")
 ("rjs"	"乾件健巾建愆楗腱虔蹇鍵騫")
 ("rjf"	"乞傑杰桀")
 ("rja"	"儉劍劒檢瞼鈐黔")
 ("rjq"	"劫怯迲")
 ("rp"	"偈憩揭")
 ("rur"	"擊格檄激膈覡隔")
 ("rus"	"堅牽犬甄絹繭肩見譴遣鵑")
 ("ruf"	"抉決潔結缺訣")
 ("rua"	"兼慊箝謙鉗鎌")
 ("rud"	"京俓倞傾儆勁勍卿坰境庚徑慶憬擎敬景暻更梗涇炅烱璟璥瓊痙硬磬竟競絅經耕耿脛莖警輕逕鏡頃頸驚鯨")
 ("rP"	"係啓堺契季屆悸戒桂械棨溪界癸磎稽系繫繼計誡谿階鷄")
 ("rh"	"古叩告呱固姑孤尻庫拷攷故敲暠枯槁沽痼皐睾稿羔考股膏苦苽菰藁蠱袴誥賈辜錮雇顧高鼓")
 ("rhr"	"哭斛曲梏穀谷鵠")
 ("rhs"	"困坤崑昆梱棍滾琨袞鯤")
 ("rhf"	"汨滑骨")
 ("rhd"	"供公共功孔工恐恭拱控攻珙空蚣貢鞏")
 ("rhw"	"串")
 ("rhk"	"寡戈果瓜科菓誇課跨過鍋顆")
 ("rhkr"	"廓槨藿郭")
 ("rhks"	"串冠官寬慣棺款灌琯瓘管罐菅觀貫關館")
 ("rhkf"	"刮恝括适")
 ("rhkd"	"侊光匡壙廣曠洸炚狂珖筐胱鑛")
 ("rho"	"卦掛罫")
 ("rhl"	"乖傀塊壞怪愧拐槐魁")
 ("rhld"	"宏紘肱轟")
 ("ry"	"交僑咬喬嬌嶠巧攪敎校橋狡皎矯絞翹膠蕎蛟較轎郊餃驕鮫")
 ("rn"	"丘久九仇俱具勾區口句咎嘔坵垢寇嶇廐懼拘救枸柩構歐毆毬求溝灸狗玖球瞿矩究絿耉臼舅舊苟衢謳購軀逑邱鉤銶駒驅鳩鷗龜")
 ("rnr"	"國局菊鞠鞫麴")
 ("rns"	"君窘群裙軍郡")
 ("rnf"	"堀屈掘窟")
 ("rnd"	"宮弓穹窮芎躬")
 ("rnjs"	"倦券勸卷圈拳捲權淃眷")
 ("rnjf"	"厥獗蕨蹶闕")
 ("rnp"	"机櫃潰詭軌饋")
 ("rnl"	"句晷歸貴鬼龜")
 ("rb"	"叫圭奎揆槻珪硅窺竅糾葵規赳逵閨")
 ("rbs"	"勻均畇筠菌鈞龜")
 ("rbf"	"橘")
 ("rmr"	"克剋劇戟棘極隙")
 ("rms"	"僅劤勤懃斤根槿瑾筋芹菫覲謹近饉")
 ("rmf"	"契")
 ("rma"	"今妗擒昑檎琴禁禽芩衾衿襟金錦")
 ("rmq"	"伋及急扱汲級給")
 ("rmd"	"亘兢矜肯")
 ("rl"	"企伎其冀嗜器圻基埼夔奇妓寄岐崎己幾忌技旗旣朞期杞棋棄機欺氣汽沂淇玘琦琪璂璣畸畿碁磯祁祇祈祺箕紀綺羈耆耭肌記譏豈起錡錤飢饑騎騏驥麒")
 ("rls"	"緊")
 ("rlf"	"佶吉拮桔")
 ("rla"	"金")
 ("Rlr"	"喫")
 ("sk"	"儺喇奈娜懦懶拏拿癩羅蘿螺裸邏那")
 ("skr"	"樂洛烙珞落諾酪駱")
 ("sks"	"亂卵暖欄煖爛蘭難鸞")
 ("skf"	"捏捺")
 ("ska"	"南嵐枏楠湳濫男藍襤")
 ("skq"	"拉納臘蠟衲")
 ("skd"	"囊娘廊朗浪狼郎")
 ("so"	"乃來內奈柰耐")
 ("sod"	"冷")
 ("su"	"女")
 ("sus"	"年撚秊")
 ("sua"	"念恬拈捻")
 ("sud"	"寧寗")
 ("sh"	"努勞奴弩怒擄櫓爐瑙盧老蘆虜路露駑魯鷺")
 ("shr"	"碌祿綠菉錄鹿")
 ("shs"	"論")
 ("shd"	"壟弄濃籠聾膿農")
 ("shl"	"惱牢磊腦賂雷")
 ("sy"	"尿")
 ("sn"	"壘屢樓淚漏累縷陋")
 ("sns"	"嫩")
 ("snf"	"訥")
 ("sb"	"杻紐")
 ("smr"	"勒肋")
 ("sma"	"凜")
 ("smd"	"凌稜綾能菱陵")
 ("sl"	"尼泥")
 ("slr"	"匿溺")
 ("ek"	"多茶")
 ("eks"	"丹亶但單團壇彖斷旦檀段湍短端簞緞蛋袒鄲鍛")
 ("ekf"	"撻澾獺疸達")
 ("eka"	"啖坍憺擔曇淡湛潭澹痰聃膽蕁覃談譚錟")
 ("ekq"	"沓畓答踏遝")
 ("ekd"	"唐堂塘幢戇撞棠當糖螳黨")
 ("eo"	"代垈坮大對岱帶待戴擡玳臺袋貸隊黛")
 ("eor"	"宅")
 ("ejr"	"德悳")
 ("eh"	"倒刀到圖堵塗導屠島嶋度徒悼挑掉搗桃棹櫂淘渡滔濤燾盜睹禱稻萄覩賭跳蹈逃途道都鍍陶韜")
 ("ehr"	"毒瀆牘犢獨督禿篤纛讀")
 ("ehs"	"墩惇敦旽暾沌焞燉豚頓")
 ("ehf"	"乭突")
 ("ehd"	"仝冬凍動同憧東桐棟洞潼疼瞳童胴董銅")
 ("en"	"兜斗杜枓痘竇荳讀豆逗頭")
 ("ens"	"屯臀芚遁遯鈍")
 ("emr"	"得")
 ("emd"	"嶝橙燈登等藤謄鄧騰")
 ("fk"	"喇懶拏癩羅蘿螺裸邏")
 ("fkr"	"樂洛烙珞絡落諾酪駱")
 ("fks"	"丹亂卵欄欒瀾爛蘭鸞")
 ("fkf"	"剌辣")
 ("fka"	"嵐擥攬欖濫籃纜藍襤覽")
 ("fkq"	"拉臘蠟")
 ("fkd"	"廊朗浪狼琅瑯螂郞")
 ("fo"	"來崍徠萊")
 ("fod"	"冷")
 ("fir"	"掠略")
 ("fid"	"亮倆兩凉梁樑粮粱糧良諒輛量")
 ("fu"	"侶儷勵呂廬慮戾旅櫚濾礪藜蠣閭驢驪麗黎")
 ("fur"	"力曆歷瀝礫轢靂")
 ("fus"	"憐戀攣漣煉璉練聯蓮輦連鍊")
 ("fuf"	"冽列劣洌烈裂")
 ("fua"	"廉斂殮濂簾")
 ("fuq"	"獵")
 ("fud"	"令伶囹寧岺嶺怜玲笭羚翎聆逞鈴零靈領齡")
 ("fP"	"例澧禮醴隷")
 ("fh"	"勞怒撈擄櫓潞瀘爐盧老蘆虜路輅露魯鷺鹵")
 ("fhr"	"碌祿綠菉錄鹿麓")
 ("fhs"	"論")
 ("fhd"	"壟弄朧瀧瓏籠聾")
 ("fhl"	"儡瀨牢磊賂賚賴雷")
 ("fy"	"了僚寮廖料燎療瞭聊蓼遼鬧")
 ("fyd"	"龍")
 ("fn"	"壘婁屢樓淚漏瘻累縷蔞褸鏤陋")
 ("fb"	"劉旒柳榴流溜瀏琉瑠留瘤硫謬類")
 ("fbr"	"六戮陸")
 ("fbs"	"侖倫崙淪綸輪")
 ("fbf"	"律慄栗率")
 ("fbd"	"隆")
 ("fmr"	"勒肋")
 ("fma"	"凜")
 ("fmd"	"凌楞稜綾菱陵")
 ("fl"	"俚利厘吏唎履悧李梨浬犁狸理璃異痢籬罹羸莉裏裡里釐離鯉")
 ("fls"	"吝潾燐璘藺躪隣鱗麟")
 ("fla"	"林淋琳臨霖")
 ("flq"	"砬立笠粒")
 ("ak"	"摩瑪痲碼磨馬魔麻")
 ("akr"	"寞幕漠膜莫邈")
 ("aks"	"万卍娩巒彎慢挽晩曼滿漫灣瞞萬蔓蠻輓饅鰻")
 ("akf"	"唜抹末沫茉襪靺")
 ("akd"	"亡妄忘忙望網罔芒茫莽輞邙")
 ("ao"	"埋妹媒寐昧枚梅每煤罵買賣邁魅")
 ("aor"	"脈貊陌驀麥")
 ("aod"	"孟氓猛盲盟萌")
 ("aur"	"冪覓")
 ("aus"	"免冕勉棉沔眄眠綿緬面麵")
 ("auf"	"滅蔑")
 ("aud"	"冥名命明暝椧溟皿瞑茗蓂螟酩銘鳴")
 ("aP"	"袂")
 ("ah"	"侮冒募姆帽慕摸摹暮某模母毛牟牡瑁眸矛耗芼茅謀謨貌")
 ("ahr"	"木沐牧目睦穆鶩")
 ("ahf"	"歿沒")
 ("ahd"	"夢朦蒙")
 ("ay"	"卯墓妙廟描昴杳渺猫竗苗錨")
 ("an"	"務巫憮懋戊拇撫无楙武毋無珷畝繆舞茂蕪誣貿霧鵡")
 ("anr"	"墨默")
 ("ans"	"們刎吻問文汶紊紋聞蚊門雯")
 ("anf"	"勿沕物")
 ("al"	"味媚尾嵋彌微未梶楣渼湄眉米美薇謎迷靡黴")
 ("als"	"岷悶愍憫敏旻旼民泯玟珉緡閔")
 ("alf"	"密蜜謐")
 ("qkr"	"剝博拍搏撲朴樸泊珀璞箔粕縛膊舶薄迫雹駁")
 ("qks"	"伴半反叛拌搬攀斑槃泮潘班畔瘢盤盼磐磻礬絆般蟠返頒飯")
 ("qkf"	"勃拔撥渤潑發跋醱鉢髮魃")
 ("qkd"	"倣傍坊妨尨幇彷房放方旁昉枋榜滂磅紡肪膀舫芳蒡蚌訪謗邦防龐")
 ("qo"	"倍俳北培徘拜排杯湃焙盃背胚裴裵褙賠輩配陪")
 ("qor"	"伯佰帛柏栢白百魄")
 ("qjs"	"幡樊煩燔番磻繁蕃藩飜")
 ("qjf"	"伐筏罰閥")
 ("qja"	"凡帆梵氾汎泛犯範范")
 ("qjq"	"法琺")
 ("qur"	"僻劈壁擘檗璧癖碧蘗闢霹")
 ("qus"	"便卞弁變辨辯邊")
 ("quf"	"別瞥鱉鼈")
 ("qud"	"丙倂兵屛幷昞昺柄棅炳甁病秉竝輧餠騈")
 ("qh"	"保堡報寶普步洑湺潽珤甫菩補褓譜輔")
 ("qhr"	"伏僕匐卜宓復服福腹茯蔔複覆輹輻馥鰒")
 ("qhs"	"本")
 ("qhf"	"乶")
 ("qhd"	"俸奉封峯峰捧棒烽熢琫縫蓬蜂逢鋒鳳")
 ("qn"	"不付俯傅剖副否咐埠夫婦孚孵富府復扶敷斧浮溥父符簿缶腐腑膚艀芙莩訃負賦賻赴趺部釜阜附駙鳧")
 ("qnr"	"北")
 ("qns"	"分吩噴墳奔奮忿憤扮昐汾焚盆粉糞紛芬賁雰")
 ("qnf"	"不佛弗彿拂")
 ("qnd"	"崩朋棚硼繃鵬")
 ("ql"	"丕備匕匪卑妃婢庇悲憊扉批斐枇榧比毖毗毘沸泌琵痺砒碑秕秘粃緋翡肥脾臂菲蜚裨誹譬費鄙非飛鼻")
 ("qls"	"嚬嬪彬斌檳殯浜濱瀕牝玭貧賓頻")
 ("qld"	"憑氷聘騁")
 ("tk"	"乍事些仕伺似使俟僿史司唆嗣四士奢娑寫寺射巳師徙思捨斜斯柶査梭死沙泗渣瀉獅砂社祀祠私篩紗絲肆舍莎蓑蛇裟詐詞謝賜赦辭邪飼駟麝")
 ("tkr"	"削數朔索")
 ("tks"	"傘刪山散汕珊産疝算蒜酸霰")
 ("tkf"	"乷撒殺煞薩")
 ("tka"	"三參杉森渗芟蔘衫")
 ("tkq"	"揷澁鈒颯")
 ("tkd"	"上傷像償商喪嘗孀尙峠常床庠廂想桑橡湘爽牀狀相祥箱翔裳觴詳象賞霜")
 ("to"	"塞璽賽")
 ("tor"	"嗇塞穡索色")
 ("tod"	"牲生甥省笙")
 ("tj"	"墅壻嶼序庶徐恕抒捿敍暑曙書栖棲犀瑞筮絮緖署胥舒薯西誓逝鋤黍鼠")
 ("tjr"	"夕奭席惜昔晳析汐淅潟石碩蓆釋錫")
 ("tjs"	"仙僊先善嬋宣扇敾旋渲煽琁瑄璇璿癬禪線繕羨腺膳船蘚蟬詵跣選銑鐥饍鮮")
 ("tjf"	"卨屑楔泄洩渫舌薛褻設說雪齧")
 ("tja"	"剡暹殲纖蟾贍閃陝")
 ("tjq"	"攝涉燮葉")
 ("tjd"	"城姓宬性惺成星晟猩珹盛省筬聖聲腥誠醒")
 ("tp"	"世勢歲洗稅笹細說貰")
 ("th"	"召嘯塑宵小少巢所掃搔昭梳沼消溯瀟炤燒甦疏疎瘙笑篠簫素紹蔬蕭蘇訴逍遡邵銷韶騷")
 ("thr"	"俗屬束涑粟續謖贖速")
 ("ths"	"孫巽損蓀遜飡")
 ("thf"	"率")
 ("thd"	"宋悚松淞訟誦送頌")
 ("tho"	"刷殺灑碎鎖")
 ("thl"	"衰釗")
 ("tn"	"修受嗽囚垂壽嫂守岫峀帥愁戍手授搜收數樹殊水洙漱燧狩獸琇璲瘦睡秀穗竪粹綏綬繡羞脩茱蒐蓚藪袖誰讐輸遂邃酬銖銹隋隧隨雖需須首髓鬚")
 ("tnr"	"叔塾夙孰宿淑潚熟琡璹肅菽")
 ("tns"	"巡徇循恂旬栒楯橓殉洵淳珣盾瞬筍純脣舜荀蓴蕣詢諄醇錞順馴")
 ("tnf"	"戌術述鉥")
 ("tnd"	"崇崧嵩")
 ("tmf"	"瑟膝蝨")
 ("tmq"	"濕拾習褶襲")
 ("tmd"	"丞乘僧勝升承昇繩蠅陞")
 ("tl"	"侍匙嘶始媤尸屎屍市弑恃施是時枾柴猜矢示翅蒔蓍視試詩諡豕豺")
 ("tlr"	"埴寔式息拭植殖湜熄篒蝕識軾食飾")
 ("tls"	"伸侁信呻娠宸愼新晨燼申神紳腎臣莘薪藎蜃訊身辛辰迅")
 ("tlf"	"失室實悉")
 ("tla"	"審尋心沁沈深瀋甚芯諶")
 ("tlq"	"什十拾")
 ("Tkd"	"雙")
 ("Tl"	"氏")
 ("dk"	"亞俄兒啞娥峨我牙芽莪蛾衙訝阿雅餓鴉鵝")
 ("dkr"	"堊岳嶽幄惡愕握樂渥鄂鍔顎鰐齷")
 ("dks"	"安岸按晏案眼雁鞍顔鮟")
 ("dkf"	"斡謁軋閼")
 ("dka"	"唵岩巖庵暗癌菴闇")
 ("dkq"	"壓押狎鴨")
 ("dkd"	"仰央怏昻殃秧鴦")
 ("do"	"厓哀埃崖愛曖涯碍艾隘靄")
 ("dor"	"厄扼掖液縊腋額")
 ("dod"	"櫻罌鶯鸚")
 ("di"	"也倻冶夜惹揶椰爺耶若野")
 ("dir"	"弱掠略約若葯蒻藥躍")
 ("did"	"亮佯兩凉壤孃恙揚攘敭暘梁楊樣洋瀁煬痒瘍禳穰糧羊良襄諒讓釀陽量養")
 ("dj"	"圄御於漁瘀禦語馭魚齬")
 ("djr"	"億憶抑檍臆")
 ("djs"	"偃堰彦焉言諺")
 ("djf"	"孼蘖")
 ("dja"	"俺儼嚴奄掩淹")
 ("djq"	"嶪業")
 ("dps"	"円")
 ("du"	"予余勵呂女如廬旅歟汝濾璵礖礪與艅茹輿轝閭餘驪麗黎")
 ("dur"	"亦力域役易曆歷疫繹譯轢逆驛")
 ("dus"	"嚥堧姸娟宴年延憐戀捐挻撚椽沇沿涎涓淵演漣烟然煙煉燃燕璉硏硯秊筵緣練縯聯衍軟輦蓮連鉛鍊鳶")
 ("duf"	"列劣咽悅涅烈熱裂說閱")
 ("dua"	"厭廉念捻染殮炎焰琰艶苒簾閻髥鹽")
 ("duq"	"曄獵燁葉")
 ("dud"	"令囹塋寧嶺嶸影怜映暎楹榮永泳渶潁濚瀛瀯煐營獰玲瑛瑩瓔盈穎纓羚聆英詠迎鈴鍈零霙靈領")
 ("dP"	"乂倪例刈叡曳汭濊猊睿穢芮藝蘂禮裔詣譽豫醴銳隸霓預")
 ("dh"	"五伍俉傲午吾吳嗚塢墺奧娛寤悟惡懊敖旿晤梧汚澳烏熬獒筽蜈誤鰲鼇")
 ("dhr"	"屋沃獄玉鈺")
 ("dhs"	"溫瑥瘟穩縕蘊")
 ("dhf"	"兀")
 ("dhd"	"壅擁瓮甕癰翁邕雍饔")
 ("dhk"	"渦瓦窩窪臥蛙蝸訛")
 ("dhks"	"婉完宛梡椀浣玩琓琬碗緩翫脘腕莞豌阮頑")
 ("dhkf"	"曰")
 ("dhkd"	"往旺枉汪王")
 ("dho"	"倭娃歪矮")
 ("dhl"	"外嵬巍猥畏")
 ("dy"	"了僚僥凹堯夭妖姚寥寮尿嶢拗搖撓擾料曜樂橈燎燿瑤療窈窯繇繞耀腰蓼蟯要謠遙遼邀饒")
 ("dyr"	"慾欲浴縟褥辱")
 ("dyd"	"俑傭冗勇埇墉容庸慂榕涌湧溶熔瑢用甬聳茸蓉踊鎔鏞龍")
 ("dn"	"于佑偶優又友右宇寓尤愚憂旴牛玗瑀盂祐禑禹紆羽芋藕虞迂遇郵釪隅雨雩")
 ("dnr"	"勖彧旭昱栯煜稶郁頊")
 ("dns"	"云暈橒殞澐熉耘芸蕓運隕雲韻")
 ("dnf"	"蔚鬱亐")
 ("dnd"	"熊雄")
 ("dnjs"	"元原員圓園垣媛嫄寃怨愿援沅洹湲源爰猿瑗苑袁轅遠阮院願鴛")
 ("dnjf"	"月越鉞")
 ("dnl"	"位偉僞危圍委威尉慰暐渭爲瑋緯胃萎葦蔿蝟衛褘謂違韋魏")
 ("db"	"乳侑儒兪劉唯喩孺宥幼幽庾悠惟愈愉揄攸有杻柔柚柳楡楢油洧流游溜濡猶猷琉瑜由留癒硫紐維臾萸裕誘諛諭踰蹂遊逾遺酉釉鍮類")
 ("dbr"	"六堉戮毓肉育陸")
 ("dbs"	"倫允奫尹崙淪潤玧胤贇輪鈗閏")
 ("dbf"	"律慄栗率聿")
 ("dbd"	"戎瀜絨融隆")
 ("dms"	"垠恩慇殷誾銀隱")
 ("dmf"	"乙")
 ("dma"	"吟淫蔭陰音飮")
 ("dmq"	"揖泣邑")
 ("dmd"	"凝應膺鷹")
 ("dml"	"依倚儀宜意懿擬椅毅疑矣義艤薏蟻衣誼議醫")
 ("dl"	"二以伊利吏夷姨履已弛彛怡易李梨泥爾珥理異痍痢移罹而耳肄苡荑裏裡貽貳邇里離飴餌")
 ("dlr"	"匿溺瀷益翊翌翼謚")
 ("dls"	"人仁刃印吝咽因姻寅引忍湮燐璘絪茵藺蚓認隣靭靷鱗麟")
 ("dlf"	"一佚佾壹日溢逸鎰馹")
 ("dla"	"任壬妊姙恁林淋稔臨荏賃")
 ("dlq"	"入卄立笠粒")
 ("dld"	"仍剩孕芿")
 ("wk"	"仔刺咨姉姿子字孜恣慈滋炙煮玆瓷疵磁紫者自茨蔗藉諮資雌")
 ("wkr"	"作勺嚼斫昨灼炸爵綽芍酌雀鵲")
 ("wks"	"孱棧殘潺盞")
 ("wka"	"岑暫潛箴簪蠶")
 ("wkq"	"雜")
 ("wkd"	"丈仗匠場墻壯奬將帳庄張掌暲杖樟檣欌漿牆狀獐璋章粧腸臟臧莊葬蔣薔藏裝贓醬長障")
 ("wo"	"再哉在宰才材栽梓渽滓災縡裁財載齋齎")
 ("wod"	"爭箏諍錚")
 ("wj"	"佇低儲咀姐底抵杵楮樗沮渚狙猪疽箸紵苧菹著藷詛貯躇這邸雎齟")
 ("wjr"	"勣吊嫡寂摘敵滴狄炙的積笛籍績翟荻謫賊赤跡蹟迪迹適鏑")
 ("wjs"	"佃佺傳全典前剪塡塼奠專展廛悛戰栓殿氈澱煎琠田甸畑癲筌箋箭篆纏詮輾轉鈿銓錢鐫電顚顫餞")
 ("wjf"	"切截折浙癤竊節絶")
 ("wja"	"占岾店漸点粘霑鮎點")
 ("wjq"	"接摺蝶")
 ("wjd"	"丁井亭停偵呈姃定幀庭廷征情挺政整旌晶晸柾楨檉正汀淀淨渟湞瀞炡玎珽町睛碇禎程穽精綎艇訂諪貞鄭酊釘鉦鋌錠霆靖靜頂鼎")
 ("wp"	"制劑啼堤帝弟悌提梯濟祭第臍薺製諸蹄醍除際霽題齊")
 ("wh"	"俎兆凋助嘲弔彫措操早晁曺曹朝條棗槽漕潮照燥爪璪眺祖祚租稠窕粗糟組繰肇藻蚤詔調趙躁造遭釣阻雕鳥")
 ("whr"	"族簇足鏃")
 ("whs"	"存尊")
 ("whf"	"卒拙猝")
 ("whd"	"倧宗從悰慫棕淙琮種終綜縱腫踪踵鍾鐘")
 ("whk"	"佐坐左座挫")
 ("whl"	"罪")
 ("wn"	"主住侏做姝胄呪周嗾奏宙州廚晝朱柱株注洲湊澍炷珠疇籌紂紬綢舟蛛註誅走躊輳週酎酒鑄駐")
 ("wnr"	"竹粥")
 ("wns"	"俊儁准埈寯峻晙樽浚準濬焌畯竣蠢逡遵雋駿")
 ("wnf"	"茁")
 ("wnd"	"中仲衆重")
 ("wmr"	"卽")
 ("wmf"	"櫛")
 ("wmq"	"楫汁葺")
 ("wmd"	"增憎曾拯烝甑症繒蒸證贈")
 ("wl"	"之只咫地址志持指摯支旨智枝枳止池沚漬知砥祉祗紙肢脂至芝芷蜘誌識贄趾遲")
 ("wlr"	"直稙稷織職")
 ("wls"	"唇嗔塵振搢晉晋桭榛殄津溱珍瑨璡畛疹盡眞瞋秦縉縝臻蔯袗診賑軫辰進鎭陣陳震")
 ("wlf"	"侄叱姪嫉帙桎瓆疾秩窒膣蛭質跌迭")
 ("wla"	"斟朕")
 ("wlq"	"什執潗緝輯鏶集")
 ("wld"	"徵懲澄")
 ("ck"	"且侘借叉嗟嵯差次此磋箚茶蹉車遮")
 ("ckr"	"捉搾着窄錯鑿齪")
 ("cks"	"撰澯燦璨瓚竄簒纂粲纘讚贊鑽餐饌")
 ("ckf"	"刹察擦札紮")
 ("cka"	"僭參塹慘慙懺斬站讒讖")
 ("ckd"	"倉倡創唱娼廠彰愴敞昌昶暢槍滄漲猖瘡窓脹艙菖蒼")
 ("co"	"債埰寀寨彩採砦綵菜蔡采釵")
 ("cor"	"冊柵策責")
 ("cj"	"凄妻悽處")
 ("cjr"	"倜刺剔尺慽戚拓擲斥滌瘠脊蹠陟隻")
 ("cjs"	"仟千喘天川擅泉淺玔穿舛薦賤踐遷釧闡阡韆")
 ("cjf"	"凸哲喆徹撤澈綴輟轍鐵")
 ("cja"	"僉尖沾添甛瞻簽籤詹諂")
 ("cjq"	"堞妾帖捷牒疊睫諜貼輒")
 ("cjd"	"廳晴淸聽菁請靑鯖")
 ("cp"	"切剃替涕滯締諦逮遞體")
 ("ch"	"初剿哨憔抄招梢椒楚樵炒焦硝礁礎秒稍肖艸苕草蕉貂超酢醋醮")
 ("chr"	"促囑燭矗蜀觸")
 ("chs"	"寸忖村邨")
 ("chd"	"叢塚寵悤憁摠總聰蔥銃")
 ("chkf"	"撮")
 ("chl"	"催崔最")
 ("cn"	"墜抽推椎楸樞湫皺秋芻萩諏趨追鄒酋醜錐錘鎚雛騶鰍")
 ("cnr"	"丑畜祝竺筑築縮蓄蹙蹴軸逐")
 ("cns"	"春椿瑃")
 ("cnf"	"出朮黜")
 ("cnd"	"充忠沖蟲衝衷")
 ("cnp"	"悴膵萃贅")
 ("cnl"	"取吹嘴娶就炊翠聚脆臭趣醉驟鷲")
 ("cmr"	"側仄厠惻測")
 ("cmd"	"層")
 ("cl"	"侈値嗤峙幟恥梔治淄熾痔痴癡稚穉緇緻置致蚩輜雉馳齒")
 ("clr"	"則勅飭")
 ("cls"	"親")
 ("clf"	"七柒漆")
 ("cla"	"侵寢枕沈浸琛砧針鍼")
 ("clq"	"蟄")
 ("cld"	"秤稱")
 ("zho"	"快")
 ("xk"	"他咤唾墮妥惰打拖朶楕舵陀馱駝")
 ("xkr"	"倬卓啄坼度托拓擢晫柝濁濯琢琸託鐸")
 ("xks"	"呑嘆坦彈憚歎灘炭綻誕")
 ("xkf"	"奪脫")
 ("xka"	"探眈耽貪")
 ("xkq"	"塔搭榻")
 ("xkd"	"宕帑湯糖蕩")
 ("xo"	"兌台太怠態殆汰泰笞胎苔跆邰颱")
 ("xor"	"宅擇澤")
 ("xod"	"撑")
 ("xj"	"攄")
 ("xh"	"兎吐土討")
 ("xhd"	"慟桶洞痛筒統通")
 ("xhl"	"堆槌腿褪退頹")
 ("xn"	"偸套妬投透鬪")
 ("xmr"	"慝特")
 ("xma"	"闖")
 ("vk"	"坡婆巴把播擺杷波派爬琶破罷芭跛頗")
 ("vks"	"判坂板版瓣販辦鈑阪")
 ("vkf"	"八叭捌")
 ("vo"	"佩唄悖敗沛浿牌狽稗覇貝")
 ("vod"	"彭澎烹膨")
 ("vir"	"愎")
 ("vus"	"便偏扁片篇編翩遍鞭騙")
 ("vua"	"貶")
 ("vud"	"坪平枰萍評")
 ("vP"	"吠嬖幣廢弊斃肺蔽閉陛")
 ("vh"	"佈包匍匏咆哺圃布怖抛抱捕暴泡浦疱砲胞脯苞葡蒲袍褒逋鋪飽鮑")
 ("vhr"	"幅暴曝瀑爆輻")
 ("vy"	"俵剽彪慓杓標漂瓢票表豹飇飄驃")
 ("vna"	"品稟")
 ("vnd"	"楓諷豊風馮")
 ("vl"	"彼披疲皮被避陂")
 ("vlf"	"匹弼必泌珌畢疋筆苾馝")
 ("vlq"	"乏逼")
 ("gk"	"下何厦夏廈昰河瑕荷蝦賀遐霞鰕")
 ("gkr"	"壑學虐謔鶴")
 ("gks"	"寒恨悍旱汗漢澣瀚罕翰閑閒限韓")
 ("gkf"	"割轄")
 ("gka"	"函含咸啣喊檻涵緘艦銜陷鹹")
 ("gkq"	"合哈盒蛤閤闔陜")
 ("gkd"	"亢伉姮嫦巷恒抗杭桁沆港缸肛航行降項")
 ("go"	"亥偕咳垓奚孩害懈楷海瀣蟹解該諧邂駭骸")
 ("gor"	"劾核")
 ("god"	"倖幸杏荇行")
 ("gid"	"享向嚮珦鄕響餉饗香")
 ("gj"	"噓墟虛許")
 ("gjs"	"憲櫶獻軒")
 ("gjf"	"歇")
 ("gja"	"險驗")
 ("gur"	"奕爀赫革")
 ("gus"	"俔峴弦懸晛泫炫玄玹現眩睍絃絢縣舷衒見賢鉉顯")
 ("guf"	"孑穴血頁")
 ("gua"	"嫌")
 ("guq"	"俠協夾峽挾浹狹脅脇莢鋏頰")
 ("gud"	"亨兄刑型形泂滎瀅灐炯熒珩瑩荊螢衡逈邢鎣馨")
 ("gP"	"兮彗惠慧暳蕙蹊醯鞋")
 ("gh"	"乎互呼壕壺好岵弧戶扈昊晧毫浩淏湖滸澔濠濩灝狐琥瑚瓠皓祜糊縞胡芦葫蒿虎號蝴護豪鎬頀顥")
 ("ghr"	"惑或酷")
 ("ghs"	"婚昏混渾琿魂")
 ("ghf"	"忽惚笏")
 ("ghd"	"哄弘汞泓洪烘紅虹訌鴻")
 ("ghk"	"化和嬅樺火畵禍禾花華話譁貨靴")
 ("ghkr"	"廓擴攫確碻穫")
 ("ghks"	"丸喚奐宦幻患換歡晥桓渙煥環紈還驩鰥")
 ("ghkf"	"活滑猾豁闊")
 ("ghkd"	"凰幌徨恍惶愰慌晃晄榥況湟滉潢煌璜皇篁簧荒蝗遑隍黃")
 ("ghl"	"匯回廻徊恢悔懷晦會檜淮澮灰獪繪膾茴蛔誨賄")
 ("ghlr"	"劃獲")
 ("ghld"	"宖橫鐄")
 ("gy"	"哮嚆孝效斅曉梟涍淆爻肴酵驍")
 ("gn"	"侯候厚后吼喉嗅帿後朽煦珝逅")
 ("gns"	"勛勳塤壎焄熏燻薰訓暈")
 ("gnd"	"薨")
 ("gnjs"	"喧暄煊萱")
 ("gnp"	"卉喙毁")
 ("gnl"	"彙徽揮暉煇諱輝麾")
 ("gb"	"休携烋畦虧")
 ("gbf"	"恤譎鷸")
 ("gbd"	"兇凶匈洶胸")
 ("gmr"	"黑")
 ("gms"	"昕欣炘痕")
 ("gmf"	"吃屹紇訖")
 ("gma"	"欠欽歆")
 ("gmq"	"吸恰洽翕")
 ("gmd"	"興")
 ("gml"	"僖凞喜噫囍姬嬉希憙憘戱晞曦熙熹熺犧禧稀羲")
 ("glf"	"詰"))

;;; hanja.el ends here
