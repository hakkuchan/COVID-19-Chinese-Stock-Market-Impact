* 变量设置
label var date "距离事件日1月20日按交易日编号"
bysort date : egen Mcmv=sum(CMV)
label variable Mcmv "总体市场所有股票某日流通市值加总"
bysort date : egen Memo=sum(emotion*CMV)
label variable Memo "所有股票某日情绪加权流通市值"
bysort date : gen sent_mkt = Memo/Mcmv
label variable sent_mkt  "市场情绪"
xtset icode  date 
by icode : gen event_window_0 = 1 if date > -1 & date < 10 // 10天
by icode : gen event_window_1 = 1 if date > 9 & date < 46 // 36天
by icode : gen estimate_window= 1 if date < -19 & date > -122 // 100天
* 描述性统计：个股回报率；个股日情绪
sum Dretwd emotion if date > -1 & date < 10
sum Dretwd emotion if date > 9 & date < 46
sum Dretwd emotion if date < -19 & date > -122
* 描述性统计：市场回报率
preserve
duplicates drop Cdretwdos,force
sum Cdretwdos if date > -1 & date < 10
sum Cdretwdos if date > 9 & date < 46
sum Cdretwdos if date < -19 & date > -122
restore
* 计算正常预期回报(事件窗）
reg Dretwd RiskPremium1 SMB1 HML1 if estimate_window == 1
gen rit1 = 1.06014*RiskPremium1+.8110656*SMB1-.0908234*HML1+.0002415 if event_window_0 == 1 //计算预期正常回报率，回归系数随着上一步reg结果改变
gen ar1 = Dretwd - rit1
by icode: egen car1 =sum(ar1)
preserve
winsor2 car1, replace cuts(1 99) trim 
duplicates drop icode,force
destring Nnind,replace
ttest car1=0
ttest car1=0 if Nnind == 27 
ttest car1=0 if Nnind != 27 // 测试非医药行业的平均CAR
asdoc by Nnind: ttest car1=0, rowappend // 测试每个行业的平均CAR并输出doc
ttest car1=0 if Regplc != 0
gen medic=1 if Nnind == 27 
lab var medic "医药行业"
gen hubei=1 if Regplc != 0
lab var hubei "企业位于湖北"
replace medic=0 if medic ==. 
ttable2 car1,by(medic)
replace hubei =0 if hubei  ==. 
ttable2 car1,by(hubei)
restore
* 计算正常预期回报（疫情前）
gen rit2 = 1.06014*RiskPremium1+.8110656*SMB1-.0908234*HML1+.0002415 if estimate_window== 1
gen ar2 = Dretwd - rit2
sort icode
by icode: egen car2 =sum(ar2)
preserve
winsor2 car2, replace cuts(1 99) trim
duplicates drop icode,force
destring Nnind,replace
gen medic=1 if Nnind == 27
lab var medic "医药行业"
replace medic=0 if medic ==.
ttable2 car2,by(medic)
restore
* 计算正常预期回报（事后窗）
gen rit3 = 1.06014*RiskPremium1+.8110656*SMB1-.0908234*HML1+.0002415 if event_window_1 == 1 
gen ar3 = Dretwd - rit3
sort icode
by icode: egen car3 =sum(ar3)
preserve
winsor2 car3, replace cuts(1 99) trim
duplicates drop icode,force
ttest car3=0
destring Nnind,replace
ttest car3=0 if Nnind == 27
ttest car3=0 if Regplc != 0 
gen medic=1 if Nnind == 27
lab var medic "医药行业"
gen hubei=1 if Regplc != 0
lab var hubei "企业位于湖北"
replace medic=0 if medic ==.
ttable2 car3,by(medic)
replace hubei =0 if hubei  ==. 
ttable2 car3,by(hubei)
restore
