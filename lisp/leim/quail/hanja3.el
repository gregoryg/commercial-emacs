;;; hanja3.el --- Quail-package for Korean Hanja (KSC5601)  -*-coding: utf-8; lexical-binding: t -*-

;; Copyright (C) 1997, 1999, 2001-2022 Free Software Foundation, Inc.

;; Author: Koaunghi Un <koaunghi.un@zdv.uni-tuebingen.de>
;; Keywords: mule, quail, multilingual, input method, Korean, Hanja

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

;; This file defines korean-hanja3 keyboards:
;; - hanja input method with hangul keyboard type 3

;;; Code:

(require 'quail)

(quail-define-package
 "korean-hanja3" "Korean" "漢3" t
 "3벌식KSC漢字: 該當하는 漢字의 韻을 한글3벌式으로 呼出하여 選擇"
                      nil nil nil nil nil nil t)

(quail-define-rules
 ("kf" "伽佳假價加可呵哥嘉嫁家暇架枷柯歌珂痂稼苛茄街袈訶賈跏軻迦駕")
 ("kfx" "刻却各恪慤殼珏脚覺角閣")
 ("kfs" "侃刊墾奸姦干幹懇揀杆柬桿澗癎看磵稈竿簡肝艮艱諫間")
 ("kfw" "乫喝曷渴碣竭葛褐蝎鞨")
 ("kfz" "勘坎堪嵌感憾戡敢柑橄減甘疳監瞰紺邯鑑鑒龕")
 ("kf3" "匣岬甲胛鉀閘")
 ("kfa" "剛堈姜岡崗康强彊慷江畺疆糠絳綱羌腔舡薑襁講鋼降鱇")
 ("kr" "介价個凱塏愷愾慨改槪漑疥皆盖箇芥蓋豈鎧開")
 ("krx" "喀客")
 ("kra" "坑更粳羹")
 ("k6x" "醵")
 ("kt" "倨去居巨拒据據擧渠炬祛距踞車遽鉅鋸")
 ("kts" "乾件健巾建愆楗腱虔蹇鍵騫")
 ("ktw" "乞傑杰桀")
 ("ktz" "儉劍劒檢瞼鈐黔")
 ("kt3" "劫怯迲")
 ("kc" "偈憩揭")
 ("kex" "擊格檄激膈覡隔")
 ("kes" "堅牽犬甄絹繭肩見譴遣鵑")
 ("kew" "抉決潔結缺訣")
 ("kez" "兼慊箝謙鉗鎌")
 ("kea" "京俓倞傾儆勁勍卿坰境庚徑慶憬擎敬景暻更梗涇炅烱璟璥瓊痙硬磬竟競絅經耕耿脛莖警輕逕鏡頃頸驚鯨")
 ("k7" "係啓堺契季屆悸戒桂械棨溪界癸磎稽系繫繼計誡谿階鷄")
 ("kv" "古叩告呱固姑孤尻庫拷攷故敲暠枯槁沽痼皐睾稿羔考股膏苦苽菰藁蠱袴誥賈辜錮雇顧高鼓")
 ("kvx" "哭斛曲梏穀谷鵠")
 ("kvs" "困坤崑昆梱棍滾琨袞鯤")
 ("kvw" "汨滑骨")
 ("kva" "供公共功孔工恐恭拱控攻珙空蚣貢鞏")
 ("kv!" "串")
 ("k/" "古叩告呱固姑孤尻庫拷攷故敲暠枯槁沽痼皐睾稿羔考股膏苦苽菰藁蠱袴誥賈辜錮雇顧高鼓")
 ("k/x" "哭斛曲梏穀谷鵠")
 ("k/s" "困坤崑昆梱棍滾琨袞鯤")
 ("k/w" "汨滑骨")
 ("k/a" "供公共功孔工恐恭拱控攻珙空蚣貢鞏")
 ("k/!" "串")
 ("k/f" "寡戈果瓜科菓誇課跨過鍋顆")
 ("k/fx" "廓槨藿郭")
 ("k/fs" "串冠官寬慣棺款灌琯瓘管罐菅觀貫關館")
 ("k/fw" "刮恝括适")
 ("k/fa" "侊光匡壙廣曠洸炚狂珖筐胱鑛")
 ("k/r" "卦掛罫")
 ("k/d" "乖傀塊壞怪愧拐槐魁")
 ("k/da" "宏紘肱轟")
 ("k4" "交僑咬喬嬌嶠巧攪敎校橋狡皎矯絞翹膠蕎蛟較轎郊餃驕鮫")
 ("kb" "丘久九仇俱具勾區口句咎嘔坵垢寇嶇廐懼拘救枸柩構歐毆毬求溝灸狗玖球瞿矩究絿耉臼舅舊苟衢謳購軀逑邱鉤銶駒驅鳩鷗龜")
 ("kbx" "國局菊鞠鞫麴")
 ("kbs" "君窘群裙軍郡")
 ("kbw" "堀屈掘窟")
 ("kba" "宮弓穹窮芎躬")
 ("k9" "丘久九仇俱具勾區口句咎嘔坵垢寇嶇廐懼拘救枸柩構歐毆毬求溝灸狗玖球瞿矩究絿耉臼舅舊苟衢謳購軀逑邱鉤銶駒驅鳩鷗龜")
 ("k9x" "國局菊鞠鞫麴")
 ("k9s" "君窘群裙軍郡")
 ("k9w" "堀屈掘窟")
 ("k9a" "宮弓穹窮芎躬")
 ("k9ts" "倦券勸卷圈拳捲權淃眷")
 ("k9tw" "厥獗蕨蹶闕")
 ("k9c" "机櫃潰詭軌饋")
 ("k9d" "句晷歸貴鬼龜")
 ("k5" "叫圭奎揆槻珪硅窺竅糾葵規赳逵閨")
 ("k5s" "勻均畇筠菌鈞龜")
 ("k5w" "橘")
 ("kgx" "克剋劇戟棘極隙")
 ("kgs" "僅劤勤懃斤根槿瑾筋芹菫覲謹近饉")
 ("kgw" "契")
 ("kgz" "今妗擒昑檎琴禁禽芩衾衿襟金錦")
 ("kg3" "伋及急扱汲級給")
 ("kga" "亘兢矜肯")
 ("kd" "企伎其冀嗜器圻基埼夔奇妓寄岐崎己幾忌技旗旣朞期杞棋棄機欺氣汽沂淇玘琦琪璂璣畸畿碁磯祁祇祈祺箕紀綺羈耆耭肌記譏豈起錡錤飢饑騎騏驥麒")
 ("kds" "緊")
 ("kdw" "佶吉拮桔")
 ("kdz" "金")
 ("kkdx" "喫")
 ("hf" "儺喇奈娜懦懶拏拿癩羅蘿螺裸邏那")
 ("hfx" "樂洛烙珞落諾酪駱")
 ("hfs" "亂卵暖欄煖爛蘭難鸞")
 ("hfw" "捏捺")
 ("hfz" "南嵐枏楠湳濫男藍襤")
 ("hf3" "拉納臘蠟衲")
 ("hfa" "囊娘廊朗浪狼郎")
 ("hr" "乃來內奈柰耐")
 ("hra" "冷")
 ("he" "女")
 ("hes" "年撚秊")
 ("hez" "念恬拈捻")
 ("hea" "寧寗")
 ("hv" "努勞奴弩怒擄櫓爐瑙盧老蘆虜路露駑魯鷺")
 ("hvx" "碌祿綠菉錄鹿")
 ("hvs" "論")
 ("hva" "壟弄濃籠聾膿農")
 ("h/" "努勞奴弩怒擄櫓爐瑙盧老蘆虜路露駑魯鷺")
 ("h/x" "碌祿綠菉錄鹿")
 ("h/s" "論")
 ("h/a" "壟弄濃籠聾膿農")
 ("h/d" "惱牢磊腦賂雷")
 ("h4" "尿")
 ("hb" "壘屢樓淚漏累縷陋")
 ("hbs" "嫩")
 ("hbw" "訥")
 ("h9" "壘屢樓淚漏累縷陋")
 ("h9s" "嫩")
 ("h9w" "訥")
 ("h5" "杻紐")
 ("hgx" "勒肋")
 ("hgz" "凜")
 ("hga" "凌稜綾能菱陵")
 ("hd" "尼泥")
 ("hdx" "匿溺")
 ("uf" "多茶")
 ("ufs" "丹亶但單團壇彖斷旦檀段湍短端簞緞蛋袒鄲鍛")
 ("ufw" "撻澾獺疸達")
 ("ufz" "啖坍憺擔曇淡湛潭澹痰聃膽蕁覃談譚錟")
 ("uf3" "沓畓答踏遝")
 ("ufa" "唐堂塘幢戇撞棠當糖螳黨")
 ("ur" "代垈坮大對岱帶待戴擡玳臺袋貸隊黛")
 ("urx" "宅")
 ("utx" "德悳")
 ("uv" "倒刀到圖堵塗導屠島嶋度徒悼挑掉搗桃棹櫂淘渡滔濤燾盜睹禱稻萄覩賭跳蹈逃途道都鍍陶韜")
 ("uvx" "毒瀆牘犢獨督禿篤纛讀")
 ("uvs" "墩惇敦旽暾沌焞燉豚頓")
 ("uvw" "乭突")
 ("uva" "仝冬凍動同憧東桐棟洞潼疼瞳童胴董銅")
 ("u/" "倒刀到圖堵塗導屠島嶋度徒悼挑掉搗桃棹櫂淘渡滔濤燾盜睹禱稻萄覩賭跳蹈逃途道都鍍陶韜")
 ("u/x" "毒瀆牘犢獨督禿篤纛讀")
 ("u/s" "墩惇敦旽暾沌焞燉豚頓")
 ("u/w" "乭突")
 ("u/a" "仝冬凍動同憧東桐棟洞潼疼瞳童胴董銅")
 ("ub" "兜斗杜枓痘竇荳讀豆逗頭")
 ("ubs" "屯臀芚遁遯鈍")
 ("u9" "兜斗杜枓痘竇荳讀豆逗頭")
 ("u9s" "屯臀芚遁遯鈍")
 ("ugx" "得")
 ("uga" "嶝橙燈登等藤謄鄧騰")
 ("yf" "喇懶拏癩羅蘿螺裸邏")
 ("yfx" "樂洛烙珞絡落諾酪駱")
 ("yfs" "丹亂卵欄欒瀾爛蘭鸞")
 ("yfw" "剌辣")
 ("yfz" "嵐擥攬欖濫籃纜藍襤覽")
 ("yf3" "拉臘蠟")
 ("yfa" "廊朗浪狼琅瑯螂郞")
 ("yr" "來崍徠萊")
 ("yra" "冷")
 ("y6x" "掠略")
 ("y6a" "亮倆兩凉梁樑粮粱糧良諒輛量")
 ("ye" "侶儷勵呂廬慮戾旅櫚濾礪藜蠣閭驢驪麗黎")
 ("yex" "力曆歷瀝礫轢靂")
 ("yes" "憐戀攣漣煉璉練聯蓮輦連鍊")
 ("yew" "冽列劣洌烈裂")
 ("yez" "廉斂殮濂簾")
 ("ye3" "獵")
 ("yea" "令伶囹寧岺嶺怜玲笭羚翎聆逞鈴零靈領齡")
 ("y7" "例澧禮醴隷")
 ("yv" "勞怒撈擄櫓潞瀘爐盧老蘆虜路輅露魯鷺鹵")
 ("yvx" "碌祿綠菉錄鹿麓")
 ("yvs" "論")
 ("yva" "壟弄朧瀧瓏籠聾")
 ("y/" "勞怒撈擄櫓潞瀘爐盧老蘆虜路輅露魯鷺鹵")
 ("y/x" "碌祿綠菉錄鹿麓")
 ("y/s" "論")
 ("y/a" "壟弄朧瀧瓏籠聾")
 ("y/d" "儡瀨牢磊賂賚賴雷")
 ("y4" "了僚寮廖料燎療瞭聊蓼遼鬧")
 ("y4a" "龍")
 ("yb" "壘婁屢樓淚漏瘻累縷蔞褸鏤陋")
 ("y9" "壘婁屢樓淚漏瘻累縷蔞褸鏤陋")
 ("y5" "劉旒柳榴流溜瀏琉瑠留瘤硫謬類")
 ("y5x" "六戮陸")
 ("y5s" "侖倫崙淪綸輪")
 ("y5w" "律慄栗率")
 ("y5a" "隆")
 ("ygx" "勒肋")
 ("ygz" "凜")
 ("yga" "凌楞稜綾菱陵")
 ("yd" "俚利厘吏唎履悧李梨浬犁狸理璃異痢籬罹羸莉裏裡里釐離鯉")
 ("yds" "吝潾燐璘藺躪隣鱗麟")
 ("ydz" "林淋琳臨霖")
 ("yd3" "砬立笠粒")
 ("if" "摩瑪痲碼磨馬魔麻")
 ("ifx" "寞幕漠膜莫邈")
 ("ifs" "万卍娩巒彎慢挽晩曼滿漫灣瞞萬蔓蠻輓饅鰻")
 ("ifw" "唜抹末沫茉襪靺")
 ("ifa" "亡妄忘忙望網罔芒茫莽輞邙")
 ("ir" "埋妹媒寐昧枚梅每煤罵買賣邁魅")
 ("irx" "脈貊陌驀麥")
 ("ira" "孟氓猛盲盟萌")
 ("iex" "冪覓")
 ("ies" "免冕勉棉沔眄眠綿緬面麵")
 ("iew" "滅蔑")
 ("iea" "冥名命明暝椧溟皿瞑茗蓂螟酩銘鳴")
 ("i7" "袂")
 ("iv" "侮冒募姆帽慕摸摹暮某模母毛牟牡瑁眸矛耗芼茅謀謨貌")
 ("ivx" "木沐牧目睦穆鶩")
 ("ivw" "歿沒")
 ("iva" "夢朦蒙")
 ("i/" "侮冒募姆帽慕摸摹暮某模母毛牟牡瑁眸矛耗芼茅謀謨貌")
 ("i/x" "木沐牧目睦穆鶩")
 ("i/w" "歿沒")
 ("i/a" "夢朦蒙")
 ("i4" "卯墓妙廟描昴杳渺猫竗苗錨")
 ("ib" "務巫憮懋戊拇撫无楙武毋無珷畝繆舞茂蕪誣貿霧鵡")
 ("ibx" "墨默")
 ("ibs" "們刎吻問文汶紊紋聞蚊門雯")
 ("ibw" "勿沕物")
 ("i9" "務巫憮懋戊拇撫无楙武毋無珷畝繆舞茂蕪誣貿霧鵡")
 ("i9x" "墨默")
 ("i9s" "們刎吻問文汶紊紋聞蚊門雯")
 ("i9w" "勿沕物")
 ("id" "味媚尾嵋彌微未梶楣渼湄眉米美薇謎迷靡黴")
 ("ids" "岷悶愍憫敏旻旼民泯玟珉緡閔")
 ("idw" "密蜜謐")
 (";fx" "剝博拍搏撲朴樸泊珀璞箔粕縛膊舶薄迫雹駁")
 (";fs" "伴半反叛拌搬攀斑槃泮潘班畔瘢盤盼磐磻礬絆般蟠返頒飯")
 (";fw" "勃拔撥渤潑發跋醱鉢髮魃")
 (";fa" "倣傍坊妨尨幇彷房放方旁昉枋榜滂磅紡肪膀舫芳蒡蚌訪謗邦防龐")
 (";r" "倍俳北培徘拜排杯湃焙盃背胚裴裵褙賠輩配陪")
 (";rx" "伯佰帛柏栢白百魄")
 (";ts" "幡樊煩燔番磻繁蕃藩飜")
 (";tw" "伐筏罰閥")
 (";tz" "凡帆梵氾汎泛犯範范")
 (";t3" "法琺")
 (";ex" "僻劈壁擘檗璧癖碧蘗闢霹")
 (";es" "便卞弁變辨辯邊")
 (";ew" "別瞥鱉鼈")
 (";ea" "丙倂兵屛幷昞昺柄棅炳甁病秉竝輧餠騈")
 (";v" "保堡報寶普步洑湺潽珤甫菩補褓譜輔")
 (";vx" "伏僕匐卜宓復服福腹茯蔔複覆輹輻馥鰒")
 (";vs" "本")
 (";vw" "乶")
 (";va" "俸奉封峯峰捧棒烽熢琫縫蓬蜂逢鋒鳳")
 (";/" "保堡報寶普步洑湺潽珤甫菩補褓譜輔")
 (";/x" "伏僕匐卜宓復服福腹茯蔔複覆輹輻馥鰒")
 (";/s" "本")
 (";/w" "乶")
 (";/a" "俸奉封峯峰捧棒烽熢琫縫蓬蜂逢鋒鳳")
 (";b" "不付俯傅剖副否咐埠夫婦孚孵富府復扶敷斧浮溥父符簿缶腐腑膚艀芙莩訃負賦賻赴趺部釜阜附駙鳧")
 (";bx" "北")
 (";bs" "分吩噴墳奔奮忿憤扮昐汾焚盆粉糞紛芬賁雰")
 (";bw" "不佛弗彿拂")
 (";ba" "崩朋棚硼繃鵬")
 (";9" "不付俯傅剖副否咐埠夫婦孚孵富府復扶敷斧浮溥父符簿缶腐腑膚艀芙莩訃負賦賻赴趺部釜阜附駙鳧")
 (";9x" "北")
 (";9s" "分吩噴墳奔奮忿憤扮昐汾焚盆粉糞紛芬賁雰")
 (";9w" "不佛弗彿拂")
 (";9a" "崩朋棚硼繃鵬")
 (";d" "丕備匕匪卑妃婢庇悲憊扉批斐枇榧比毖毗毘沸泌琵痺砒碑秕秘粃緋翡肥脾臂菲蜚裨誹譬費鄙非飛鼻")
 (";ds" "嚬嬪彬斌檳殯浜濱瀕牝玭貧賓頻")
 (";da" "憑氷聘騁")
 ("nf" "乍事些仕伺似使俟僿史司唆嗣四士奢娑寫寺射巳師徙思捨斜斯柶査梭死沙泗渣瀉獅砂社祀祠私篩紗絲肆舍莎蓑蛇裟詐詞謝賜赦辭邪飼駟麝")
 ("nfx" "削數朔索")
 ("nfs" "傘刪山散汕珊産疝算蒜酸霰")
 ("nfw" "乷撒殺煞薩")
 ("nfz" "三參杉森渗芟蔘衫")
 ("nf3" "揷澁鈒颯")
 ("nfa" "上傷像償商喪嘗孀尙峠常床庠廂想桑橡湘爽牀狀相祥箱翔裳觴詳象賞霜")
 ("nr" "塞璽賽")
 ("nrx" "嗇塞穡索色")
 ("nra" "牲生甥省笙")
 ("nt" "墅壻嶼序庶徐恕抒捿敍暑曙書栖棲犀瑞筮絮緖署胥舒薯西誓逝鋤黍鼠")
 ("ntx" "夕奭席惜昔晳析汐淅潟石碩蓆釋錫")
 ("nts" "仙僊先善嬋宣扇敾旋渲煽琁瑄璇璿癬禪線繕羨腺膳船蘚蟬詵跣選銑鐥饍鮮")
 ("ntw" "卨屑楔泄洩渫舌薛褻設說雪齧")
 ("ntz" "剡暹殲纖蟾贍閃陝")
 ("nt3" "攝涉燮葉")
 ("nta" "城姓宬性惺成星晟猩珹盛省筬聖聲腥誠醒")
 ("nc" "世勢歲洗稅笹細說貰")
 ("nv" "召嘯塑宵小少巢所掃搔昭梳沼消溯瀟炤燒甦疏疎瘙笑篠簫素紹蔬蕭蘇訴逍遡邵銷韶騷")
 ("nvx" "俗屬束涑粟續謖贖速")
 ("nvs" "孫巽損蓀遜飡")
 ("nvw" "率")
 ("nva" "宋悚松淞訟誦送頌")
 ("n/" "召嘯塑宵小少巢所掃搔昭梳沼消溯瀟炤燒甦疏疎瘙笑篠簫素紹蔬蕭蘇訴逍遡邵銷韶騷")
 ("n/x" "俗屬束涑粟續謖贖速")
 ("n/s" "孫巽損蓀遜飡")
 ("n/w" "率")
 ("n/a" "宋悚松淞訟誦送頌")
 ("n/r" "刷殺灑碎鎖")
 ("n/d" "衰釗")
 ("nb" "修受嗽囚垂壽嫂守岫峀帥愁戍手授搜收數樹殊水洙漱燧狩獸琇璲瘦睡秀穗竪粹綏綬繡羞脩茱蒐蓚藪袖誰讐輸遂邃酬銖銹隋隧隨雖需須首髓鬚")
 ("nbx" "叔塾夙孰宿淑潚熟琡璹肅菽")
 ("nbs" "巡徇循恂旬栒楯橓殉洵淳珣盾瞬筍純脣舜荀蓴蕣詢諄醇錞順馴")
 ("nbw" "戌術述鉥")
 ("nba" "崇崧嵩")
 ("n9" "修受嗽囚垂壽嫂守岫峀帥愁戍手授搜收數樹殊水洙漱燧狩獸琇璲瘦睡秀穗竪粹綏綬繡羞脩茱蒐蓚藪袖誰讐輸遂邃酬銖銹隋隧隨雖需須首髓鬚")
 ("n9x" "叔塾夙孰宿淑潚熟琡璹肅菽")
 ("n9s" "巡徇循恂旬栒楯橓殉洵淳珣盾瞬筍純脣舜荀蓴蕣詢諄醇錞順馴")
 ("n9w" "戌術述鉥")
 ("n9a" "崇崧嵩")
 ("ngw" "瑟膝蝨")
 ("ng3" "濕拾習褶襲")
 ("nga" "丞乘僧勝升承昇繩蠅陞")
 ("nd" "侍匙嘶始媤尸屎屍市弑恃施是時枾柴猜矢示翅蒔蓍視試詩諡豕豺")
 ("ndx" "埴寔式息拭植殖湜熄篒蝕識軾食飾")
 ("nds" "伸侁信呻娠宸愼新晨燼申神紳腎臣莘薪藎蜃訊身辛辰迅")
 ("ndw" "失室實悉")
 ("ndz" "審尋心沁沈深瀋甚芯諶")
 ("nd3" "什十拾")
 ("nnfa" "雙")
 ("nnd" "氏")
 ("jf" "亞俄兒啞娥峨我牙芽莪蛾衙訝阿雅餓鴉鵝")
 ("jfx" "堊岳嶽幄惡愕握樂渥鄂鍔顎鰐齷")
 ("jfs" "安岸按晏案眼雁鞍顔鮟")
 ("jfw" "斡謁軋閼")
 ("jfz" "唵岩巖庵暗癌菴闇")
 ("jf3" "壓押狎鴨")
 ("jfa" "仰央怏昻殃秧鴦")
 ("jr" "厓哀埃崖愛曖涯碍艾隘靄")
 ("jrx" "厄扼掖液縊腋額")
 ("jra" "櫻罌鶯鸚")
 ("j6" "也倻冶夜惹揶椰爺耶若野")
 ("j6x" "弱掠略約若葯蒻藥躍")
 ("j6a" "亮佯兩凉壤孃恙揚攘敭暘梁楊樣洋瀁煬痒瘍禳穰糧羊良襄諒讓釀陽量養")
 ("jt" "圄御於漁瘀禦語馭魚齬")
 ("jtx" "億憶抑檍臆")
 ("jts" "偃堰彦焉言諺")
 ("jtw" "孼蘖")
 ("jtz" "俺儼嚴奄掩淹")
 ("jt3" "嶪業")
 ("jcs" "円")
 ("je" "予余勵呂女如廬旅歟汝濾璵礖礪與艅茹輿轝閭餘驪麗黎")
 ("jex" "亦力域役易曆歷疫繹譯轢逆驛")
 ("jes" "嚥堧姸娟宴年延憐戀捐挻撚椽沇沿涎涓淵演漣烟然煙煉燃燕璉硏硯秊筵緣練縯聯衍軟輦蓮連鉛鍊鳶")
 ("jew" "列劣咽悅涅烈熱裂說閱")
 ("jez" "厭廉念捻染殮炎焰琰艶苒簾閻髥鹽")
 ("je3" "曄獵燁葉")
 ("jea" "令囹塋寧嶺嶸影怜映暎楹榮永泳渶潁濚瀛瀯煐營獰玲瑛瑩瓔盈穎纓羚聆英詠迎鈴鍈零霙靈領")
 ("j7" "乂倪例刈叡曳汭濊猊睿穢芮藝蘂禮裔詣譽豫醴銳隸霓預")
 ("jv" "五伍俉傲午吾吳嗚塢墺奧娛寤悟惡懊敖旿晤梧汚澳烏熬獒筽蜈誤鰲鼇")
 ("jvx" "屋沃獄玉鈺")
 ("jvs" "溫瑥瘟穩縕蘊")
 ("jvw" "兀")
 ("jva" "壅擁瓮甕癰翁邕雍饔")
 ("j/" "五伍俉傲午吾吳嗚塢墺奧娛寤悟惡懊敖旿晤梧汚澳烏熬獒筽蜈誤鰲鼇")
 ("j/x" "屋沃獄玉鈺")
 ("j/s" "溫瑥瘟穩縕蘊")
 ("j/w" "兀")
 ("j/a" "壅擁瓮甕癰翁邕雍饔")
 ("j/f" "渦瓦窩窪臥蛙蝸訛")
 ("j/fs" "婉完宛梡椀浣玩琓琬碗緩翫脘腕莞豌阮頑")
 ("j/fw" "曰")
 ("j/fa" "往旺枉汪王")
 ("j/r" "倭娃歪矮")
 ("j/d" "外嵬巍猥畏")
 ("j4" "了僚僥凹堯夭妖姚寥寮尿嶢拗搖撓擾料曜樂橈燎燿瑤療窈窯繇繞耀腰蓼蟯要謠遙遼邀饒")
 ("j4x" "慾欲浴縟褥辱")
 ("j4a" "俑傭冗勇埇墉容庸慂榕涌湧溶熔瑢用甬聳茸蓉踊鎔鏞龍")
 ("jb" "于佑偶優又友右宇寓尤愚憂旴牛玗瑀盂祐禑禹紆羽芋藕虞迂遇郵釪隅雨雩")
 ("jbx" "勖彧旭昱栯煜稶郁頊")
 ("jbs" "云暈橒殞澐熉耘芸蕓運隕雲韻")
 ("jbw" "蔚鬱亐")
 ("jba" "熊雄")
 ("j9" "于佑偶優又友右宇寓尤愚憂旴牛玗瑀盂祐禑禹紆羽芋藕虞迂遇郵釪隅雨雩")
 ("j9x" "勖彧旭昱栯煜稶郁頊")
 ("j9s" "云暈橒殞澐熉耘芸蕓運隕雲韻")
 ("j9w" "蔚鬱亐")
 ("j9a" "熊雄")
 ("j9ts" "元原員圓園垣媛嫄寃怨愿援沅洹湲源爰猿瑗苑袁轅遠阮院願鴛")
 ("j9tw" "月越鉞")
 ("j9d" "位偉僞危圍委威尉慰暐渭爲瑋緯胃萎葦蔿蝟衛褘謂違韋魏")
 ("j5" "乳侑儒兪劉唯喩孺宥幼幽庾悠惟愈愉揄攸有杻柔柚柳楡楢油洧流游溜濡猶猷琉瑜由留癒硫紐維臾萸裕誘諛諭踰蹂遊逾遺酉釉鍮類")
 ("j5x" "六堉戮毓肉育陸")
 ("j5s" "倫允奫尹崙淪潤玧胤贇輪鈗閏")
 ("j5w" "律慄栗率聿")
 ("j5a" "戎瀜絨融隆")
 ("jgs" "垠恩慇殷誾銀隱")
 ("jgw" "乙")
 ("jgz" "吟淫蔭陰音飮")
 ("jg3" "揖泣邑")
 ("jga" "凝應膺鷹")
 ("j8" "依倚儀宜意懿擬椅毅疑矣義艤薏蟻衣誼議醫")
 ("jd" "二以伊利吏夷姨履已弛彛怡易李梨泥爾珥理異痍痢移罹而耳肄苡荑裏裡貽貳邇里離飴餌")
 ("jdx" "匿溺瀷益翊翌翼謚")
 ("jds" "人仁刃印吝咽因姻寅引忍湮燐璘絪茵藺蚓認隣靭靷鱗麟")
 ("jdw" "一佚佾壹日溢逸鎰馹")
 ("jdz" "任壬妊姙恁林淋稔臨荏賃")
 ("jd3" "入卄立笠粒")
 ("jda" "仍剩孕芿")
 ("lf" "仔刺咨姉姿子字孜恣慈滋炙煮玆瓷疵磁紫者自茨蔗藉諮資雌")
 ("lfx" "作勺嚼斫昨灼炸爵綽芍酌雀鵲")
 ("lfs" "孱棧殘潺盞")
 ("lfz" "岑暫潛箴簪蠶")
 ("lf3" "雜")
 ("lfa" "丈仗匠場墻壯奬將帳庄張掌暲杖樟檣欌漿牆狀獐璋章粧腸臟臧莊葬蔣薔藏裝贓醬長障")
 ("lr" "再哉在宰才材栽梓渽滓災縡裁財載齋齎")
 ("lra" "爭箏諍錚")
 ("lt" "佇低儲咀姐底抵杵楮樗沮渚狙猪疽箸紵苧菹著藷詛貯躇這邸雎齟")
 ("ltx" "勣吊嫡寂摘敵滴狄炙的積笛籍績翟荻謫賊赤跡蹟迪迹適鏑")
 ("lts" "佃佺傳全典前剪塡塼奠專展廛悛戰栓殿氈澱煎琠田甸畑癲筌箋箭篆纏詮輾轉鈿銓錢鐫電顚顫餞")
 ("ltw" "切截折浙癤竊節絶")
 ("ltz" "占岾店漸点粘霑鮎點")
 ("lt3" "接摺蝶")
 ("lta" "丁井亭停偵呈姃定幀庭廷征情挺政整旌晶晸柾楨檉正汀淀淨渟湞瀞炡玎珽町睛碇禎程穽精綎艇訂諪貞鄭酊釘鉦鋌錠霆靖靜頂鼎")
 ("lc" "制劑啼堤帝弟悌提梯濟祭第臍薺製諸蹄醍除際霽題齊")
 ("lv" "俎兆凋助嘲弔彫措操早晁曺曹朝條棗槽漕潮照燥爪璪眺祖祚租稠窕粗糟組繰肇藻蚤詔調趙躁造遭釣阻雕鳥")
 ("lvx" "族簇足鏃")
 ("lvs" "存尊")
 ("lvw" "卒拙猝")
 ("lva" "倧宗從悰慫棕淙琮種終綜縱腫踪踵鍾鐘")
 ("l/" "俎兆凋助嘲弔彫措操早晁曺曹朝條棗槽漕潮照燥爪璪眺祖祚租稠窕粗糟組繰肇藻蚤詔調趙躁造遭釣阻雕鳥")
 ("l/x" "族簇足鏃")
 ("l/s" "存尊")
 ("l/w" "卒拙猝")
 ("l/a" "倧宗從悰慫棕淙琮種終綜縱腫踪踵鍾鐘")
 ("l/f" "佐坐左座挫")
 ("l/d" "罪")
 ("lb" "主住侏做姝胄呪周嗾奏宙州廚晝朱柱株注洲湊澍炷珠疇籌紂紬綢舟蛛註誅走躊輳週酎酒鑄駐")
 ("lbx" "竹粥")
 ("lbs" "俊儁准埈寯峻晙樽浚準濬焌畯竣蠢逡遵雋駿")
 ("lbw" "茁")
 ("lba" "中仲衆重")
 ("l9" "主住侏做姝胄呪周嗾奏宙州廚晝朱柱株注洲湊澍炷珠疇籌紂紬綢舟蛛註誅走躊輳週酎酒鑄駐")
 ("l9x" "竹粥")
 ("l9s" "俊儁准埈寯峻晙樽浚準濬焌畯竣蠢逡遵雋駿")
 ("l9w" "茁")
 ("l9a" "中仲衆重")
 ("lgx" "卽")
 ("lgw" "櫛")
 ("lg3" "楫汁葺")
 ("lga" "增憎曾拯烝甑症繒蒸證贈")
 ("ld" "之只咫地址志持指摯支旨智枝枳止池沚漬知砥祉祗紙肢脂至芝芷蜘誌識贄趾遲")
 ("ldx" "直稙稷織職")
 ("lds" "唇嗔塵振搢晉晋桭榛殄津溱珍瑨璡畛疹盡眞瞋秦縉縝臻蔯袗診賑軫辰進鎭陣陳震")
 ("ldw" "侄叱姪嫉帙桎瓆疾秩窒膣蛭質跌迭")
 ("ldz" "斟朕")
 ("ld3" "什執潗緝輯鏶集")
 ("lda" "徵懲澄")
 ("of" "且侘借叉嗟嵯差次此磋箚茶蹉車遮")
 ("ofx" "捉搾着窄錯鑿齪")
 ("ofs" "撰澯燦璨瓚竄簒纂粲纘讚贊鑽餐饌")
 ("ofw" "刹察擦札紮")
 ("ofz" "僭參塹慘慙懺斬站讒讖")
 ("ofa" "倉倡創唱娼廠彰愴敞昌昶暢槍滄漲猖瘡窓脹艙菖蒼")
 ("or" "債埰寀寨彩採砦綵菜蔡采釵")
 ("orx" "冊柵策責")
 ("ot" "凄妻悽處")
 ("otx" "倜刺剔尺慽戚拓擲斥滌瘠脊蹠陟隻")
 ("ots" "仟千喘天川擅泉淺玔穿舛薦賤踐遷釧闡阡韆")
 ("otw" "凸哲喆徹撤澈綴輟轍鐵")
 ("otz" "僉尖沾添甛瞻簽籤詹諂")
 ("ot3" "堞妾帖捷牒疊睫諜貼輒")
 ("ota" "廳晴淸聽菁請靑鯖")
 ("oc" "切剃替涕滯締諦逮遞體")
 ("ov" "初剿哨憔抄招梢椒楚樵炒焦硝礁礎秒稍肖艸苕草蕉貂超酢醋醮")
 ("ovx" "促囑燭矗蜀觸")
 ("ovs" "寸忖村邨")
 ("ova" "叢塚寵悤憁摠總聰蔥銃")
 ("o/" "初剿哨憔抄招梢椒楚樵炒焦硝礁礎秒稍肖艸苕草蕉貂超酢醋醮")
 ("o/x" "促囑燭矗蜀觸")
 ("o/s" "寸忖村邨")
 ("o/a" "叢塚寵悤憁摠總聰蔥銃")
 ("o/fw" "撮")
 ("o/d" "催崔最")
 ("ob" "墜抽推椎楸樞湫皺秋芻萩諏趨追鄒酋醜錐錘鎚雛騶鰍")
 ("obx" "丑畜祝竺筑築縮蓄蹙蹴軸逐")
 ("obs" "春椿瑃")
 ("obw" "出朮黜")
 ("oba" "充忠沖蟲衝衷")
 ("o9" "墜抽推椎楸樞湫皺秋芻萩諏趨追鄒酋醜錐錘鎚雛騶鰍")
 ("o9x" "丑畜祝竺筑築縮蓄蹙蹴軸逐")
 ("o9s" "春椿瑃")
 ("o9w" "出朮黜")
 ("o9a" "充忠沖蟲衝衷")
 ("o9c" "悴膵萃贅")
 ("o9d" "取吹嘴娶就炊翠聚脆臭趣醉驟鷲")
 ("ogx" "側仄厠惻測")
 ("oga" "層")
 ("od" "侈値嗤峙幟恥梔治淄熾痔痴癡稚穉緇緻置致蚩輜雉馳齒")
 ("odx" "則勅飭")
 ("ods" "親")
 ("odw" "七柒漆")
 ("odz" "侵寢枕沈浸琛砧針鍼")
 ("od3" "蟄")
 ("oda" "秤稱")
 ("0/r" "快")
 ("'f" "他咤唾墮妥惰打拖朶楕舵陀馱駝")
 ("'fx" "倬卓啄坼度托拓擢晫柝濁濯琢琸託鐸")
 ("'fs" "呑嘆坦彈憚歎灘炭綻誕")
 ("'fw" "奪脫")
 ("'fz" "探眈耽貪")
 ("'f3" "塔搭榻")
 ("'fa" "宕帑湯糖蕩")
 ("'r" "兌台太怠態殆汰泰笞胎苔跆邰颱")
 ("'rx" "宅擇澤")
 ("'ra" "撑")
 ("'t" "攄")
 ("'v" "兎吐土討")
 ("'va" "慟桶洞痛筒統通")
 ("'/" "兎吐土討")
 ("'/a" "慟桶洞痛筒統通")
 ("'/d" "堆槌腿褪退頹")
 ("'b" "偸套妬投透鬪")
 ("'9" "偸套妬投透鬪")
 ("'gx" "慝特")
 ("'gz" "闖")
 ("pf" "坡婆巴把播擺杷波派爬琶破罷芭跛頗")
 ("pfs" "判坂板版瓣販辦鈑阪")
 ("pfw" "八叭捌")
 ("pr" "佩唄悖敗沛浿牌狽稗覇貝")
 ("pra" "彭澎烹膨")
 ("p6x" "愎")
 ("pes" "便偏扁片篇編翩遍鞭騙")
 ("pez" "貶")
 ("pea" "坪平枰萍評")
 ("p7" "吠嬖幣廢弊斃肺蔽閉陛")
 ("pv" "佈包匍匏咆哺圃布怖抛抱捕暴泡浦疱砲胞脯苞葡蒲袍褒逋鋪飽鮑")
 ("pvx" "幅暴曝瀑爆輻")
 ("p/" "佈包匍匏咆哺圃布怖抛抱捕暴泡浦疱砲胞脯苞葡蒲袍褒逋鋪飽鮑")
 ("p/x" "幅暴曝瀑爆輻")
 ("p4" "俵剽彪慓杓標漂瓢票表豹飇飄驃")
 ("pbz" "品稟")
 ("pba" "楓諷豊風馮")
 ("p9z" "品稟")
 ("p9a" "楓諷豊風馮")
 ("pd" "彼披疲皮被避陂")
 ("pdw" "匹弼必泌珌畢疋筆苾馝")
 ("pd3" "乏逼")
 ("mf" "下何厦夏廈昰河瑕荷蝦賀遐霞鰕")
 ("mfx" "壑學虐謔鶴")
 ("mfs" "寒恨悍旱汗漢澣瀚罕翰閑閒限韓")
 ("mfw" "割轄")
 ("mfz" "函含咸啣喊檻涵緘艦銜陷鹹")
 ("mf3" "合哈盒蛤閤闔陜")
 ("mfa" "亢伉姮嫦巷恒抗杭桁沆港缸肛航行降項")
 ("mr" "亥偕咳垓奚孩害懈楷海瀣蟹解該諧邂駭骸")
 ("mrx" "劾核")
 ("mra" "倖幸杏荇行")
 ("m6a" "享向嚮珦鄕響餉饗香")
 ("mt" "噓墟虛許")
 ("mts" "憲櫶獻軒")
 ("mtw" "歇")
 ("mtz" "險驗")
 ("mex" "奕爀赫革")
 ("mes" "俔峴弦懸晛泫炫玄玹現眩睍絃絢縣舷衒見賢鉉顯")
 ("mew" "孑穴血頁")
 ("mez" "嫌")
 ("me3" "俠協夾峽挾浹狹脅脇莢鋏頰")
 ("mea" "亨兄刑型形泂滎瀅灐炯熒珩瑩荊螢衡逈邢鎣馨")
 ("m7" "兮彗惠慧暳蕙蹊醯鞋")
 ("mv" "乎互呼壕壺好岵弧戶扈昊晧毫浩淏湖滸澔濠濩灝狐琥瑚瓠皓祜糊縞胡芦葫蒿虎號蝴護豪鎬頀顥")
 ("mvx" "惑或酷")
 ("mvs" "婚昏混渾琿魂")
 ("mvw" "忽惚笏")
 ("mva" "哄弘汞泓洪烘紅虹訌鴻")
 ("m/" "乎互呼壕壺好岵弧戶扈昊晧毫浩淏湖滸澔濠濩灝狐琥瑚瓠皓祜糊縞胡芦葫蒿虎號蝴護豪鎬頀顥")
 ("m/x" "惑或酷")
 ("m/s" "婚昏混渾琿魂")
 ("m/w" "忽惚笏")
 ("m/a" "哄弘汞泓洪烘紅虹訌鴻")
 ("m/f" "化和嬅樺火畵禍禾花華話譁貨靴")
 ("m/fx" "廓擴攫確碻穫")
 ("m/fs" "丸喚奐宦幻患換歡晥桓渙煥環紈還驩鰥")
 ("m/fw" "活滑猾豁闊")
 ("m/fa" "凰幌徨恍惶愰慌晃晄榥況湟滉潢煌璜皇篁簧荒蝗遑隍黃")
 ("m/d" "匯回廻徊恢悔懷晦會檜淮澮灰獪繪膾茴蛔誨賄")
 ("m/dx" "劃獲")
 ("m/da" "宖橫鐄")
 ("m4" "哮嚆孝效斅曉梟涍淆爻肴酵驍")
 ("mb" "侯候厚后吼喉嗅帿後朽煦珝逅")
 ("mbs" "勛勳塤壎焄熏燻薰訓暈")
 ("mba" "薨")
 ("m9" "侯候厚后吼喉嗅帿後朽煦珝逅")
 ("m9s" "勛勳塤壎焄熏燻薰訓暈")
 ("m9a" "薨")
 ("m9ts" "喧暄煊萱")
 ("m9c" "卉喙毁")
 ("m9d" "彙徽揮暉煇諱輝麾")
 ("m5" "休携烋畦虧")
 ("m5w" "恤譎鷸")
 ("m5a" "兇凶匈洶胸")
 ("mgx" "黑")
 ("mgs" "昕欣炘痕")
 ("mgw" "吃屹紇訖")
 ("mgz" "欠欽歆")
 ("mg3" "吸恰洽翕")
 ("mga" "興")
 ("m8" "僖凞喜噫囍姬嬉希憙憘戱晞曦熙熹熺犧禧稀羲")
 ("mdw" "詰"))

;;; hanja3.el ends here
