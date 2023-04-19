* 2.面板回归
* 2.0 数据预处理
keep if NetAsset > 0 // 剔除净资产为负数
drop if Nnind == "66"
drop if Nnind == "67"
drop if Nnind == "68"
drop if Nnind == "69" //剔除金融行业
gen EW = 1 if date > 10
replace EW = 0 if EW == .
sum EW
tab EW 
* 2.1 情绪地区反转效应
set matsize 1752
xi:xtreg Dretwd emotion RiskPremium1 SMB1 HML1,fe 
est store st_ols
xi:xtgls Dretwd emotion RiskPremium1 SMB1 HML1 
est store st_gls
xi:xtreg Dretwd emotion RiskPremium1 SMB1 HML1 i.EW ,fe
est store ew_ols
xi:xtgls Dretwd emotion RiskPremium1 SMB1 HML1 i.EW 
est store ew_gls
xtreg Dretwd emotion RiskPremium1 SMB1 HML1 i.EW i.Regplc,fe
est store Re_ols
xtgls Dretwd emotion RiskPremium1 SMB1 HML1 i.EW i.Regplc
est store Re_gls
esttab st_ols st_gls ew_ols ew_gls Re_ols Re_gls using 情绪地区反转.csv, replace b(%9.3f) star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ar2 obslast scalars(F)
* 2.2 特征效应
preserve
egen mis = rowmiss(_all)
drop if mis
winsor2 NetAsset PE PB ISR Year CMV, replace cuts(1 99) trim
gen emo_PE = emotion * PE //生成交互项
gen emo_PB = emotion * PB
gen emo_CMV = emotion * CMV 
gen emo_EY = emotion * Year 
gen emo_ISR = emotion * ISR 
gen emo_NA = emotion * NetAsset 
destring Nnind,replace
xtreg  Dretwd emotion emo_PE emo_PB emo_CMV emo_EY emo_ISR emo_NA RiskPremium1 SMB1 HML1,fe
est store trait_fixed
xtgls Dretwd emotion emo_PE emo_PB emo_CMV emo_EY emo_ISR emo_NA RiskPremium1 SMB1 HML1
est store trait_gls
esttab trait_fixed trait_gls using 特征.csv, replace star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ar2 obslast scalars(F) 
replace Nnind = 0 if Nnind == 90 
xi:xtreg  Dretwd emotion c.emotion#i.Nnind RiskPremium1 SMB1 HML1,fe
est store ind_fixed
xi:xtgls Dretwd emotion c.emotion#i.Nnind RiskPremium1 SMB1 HML1
est store ind_gls
esttab ind_fixed ind_gls using 行业.csv, replace b(%9.3f) star( * 0.10 ** 0.05 *** 0.01 ) nogaps compress ar2 obslast scalars(F)  
restore
* 2.3 工具变量稳健性检验
// ssc install xtivreg2 安装包
tsset icode date 
gen New_forward = F.NewConfirmed 
xtreg Dretwd emotion RiskPremium1 SMB1 HML1,fe
est store m
xtivreg2 Dretwd RiskPremium1 SMB1 HML1 (emotion = New_forward),fe
est store m1
xi:xtivreg2 Dretwd RiskPremium1 SMB1 HML1 i.EW (emotion = New_forward),fe
est store m2
xi:xtivreg2 Dretwd RiskPremium1 SMB1 HML1 i.EW i.Regplc (emotion = New_forward),fe
est store m3
outreg2 [m m1 m2 m3] using xi_2sls.doc,replace tstat addtext(Company FE, YES ) //输出回归结果
