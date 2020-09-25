// Programa...: MT094FIL
// Autor......: Andre Alves
// Data.......: 10/09/2019
// Descricao..: P.E. Utilizado para filtrar os registros da mBrowse dos pedidos de compra.
//
// Historico de alteracoes:
//
// 05/11/2019 - Andre  - Alterado para considerar primeiro o Centro de custo.
// 08/11/2019 - Andre  - Alterado forma de pesquisa para pedidos pendentes. Adicionado pela query.
// 23/01/2020 - Robert - Acrescentado novo username do Jocemar.
// 02/04/2020 - Robert - Novo username de Fernando Matana.
//

// --------------------------------------------------------------------------
USER FUNCTION MT094FIL() 
	LOCAL cRet  := ""

	//Regra para ADMINISTRATIVO
	if alltrim(upper(cusername)) $ 'RITA.CORREA/RODRIGO.COLLEONI'
		
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += " SELECT STRING_AGG(RTRIM(CR_NUM),'/') "
		_oSQL:_sQuery += "		FROM " + RetSQLName ("SCR") + " SCR "
		_oSQL:_sQuery += "		WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "		AND CR_FILIAL = '" + xfilial ("SCR") + "'"
		_oSQL:_sQuery += "		AND CR_USER = '" + __cUserID + "' " 
		_oSQL:_sQuery += "		AND (substring(CR_CC,3,4) IN ('2009','2010','2011','3001','3002') OR (CR_CC = '' AND CR_TIPOPRO IN ('AI','EP','GG','II','MA','MB','ME','MP','MT','PA','PI','PP','PS','VC','VA','VD','BN','UC'))) "
		_oSQL:_sQuery += "		AND CR_USERLIB = '' "
		_sAliasQ = _oSQL:RetQry ()
		
		cRet := " ALLTRIM(CR_NUM) $ '" + ALLTRIM(_sAliasQ) + "' "
	endif

	//Regra para COMERCIAL
//	if alltrim(upper(cusername)) $ 'CESAR.CHINATO/FERNANDO'
	if alltrim(upper(cusername)) $ 'CESAR.CHINATO/FERNANDO.MATANA'

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += " SELECT STRING_AGG(RTRIM(CR_NUM),'/') "
		_oSQL:_sQuery += "		FROM " + RetSQLName ("SCR") + " SCR "
		_oSQL:_sQuery += "		WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "		AND CR_FILIAL = '" + xfilial ("SCR") + "'"
		_oSQL:_sQuery += "		AND CR_USER = '" + __cUserID + "' " 
		_oSQL:_sQuery += "		AND (substring(CR_CC,3,4) IN ('4001','4002','4003','4004','4005','4006','4007','4008','4009','4010','4011','4012','4013','4014') OR (CR_CC = '' AND CR_TIPOPRO IN ('MR'))) "
		_oSQL:_sQuery += "		AND CR_USERLIB = '' "
		_sAliasQ = _oSQL:RetQry ()
		
		cRet := " ALLTRIM(CR_NUM) $ '" + ALLTRIM(_sAliasQ) + "' "
	endif

	//Regra para INDUSTRIAL
	if alltrim(upper(cusername)) $ 'JOCEMAR/JOCEMAR.DALCORNO'

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += " SELECT STRING_AGG(RTRIM(CR_NUM),'/') "
		_oSQL:_sQuery += "		FROM " + RetSQLName ("SCR") + " SCR "
		_oSQL:_sQuery += "		WHERE D_E_L_E_T_ = '' "
//		_oSQL:_sQuery += "		AND CR_FILIAL = '" + xfilial ("SCR") + "'"
		_oSQL:_sQuery += "		AND CR_USER = '" + __cUserID + "' " 
		_oSQL:_sQuery += "		AND (substring(CR_CC,3,4) IN ('1101','1102','1201','1202','1301','1302','1303','1304','1401','1402','1403','1404','1405','1406','1410','1901','2001','2002','2003','2004','2005','2006','2007','2008','2012','2013','2014','2015','2016','2017','2018','2019','2020','2021','2022','2023','2024','2027','2999') OR (CR_CC= '' AND CR_TIPOPRO IN ('MM','AP','CL','GF','IA','MO','RE'))) "
		_oSQL:_sQuery += "		AND CR_USERLIB = '' "
		_sAliasQ = _oSQL:RetQry ()
		
		cRet := " ALLTRIM(CR_NUM) $ '" + ALLTRIM(_sAliasQ) + "' "
	endif

	//SEM FILTROS
//	if alltrim(upper(cusername)) $ 'ALEXANDRE/ROBERT.KOCH/ADMINISTRADOR'
	if alltrim(upper(cusername)) $ 'ALEXANDRE.NUNES/ROBERT.KOCH/ADMINISTRADOR'
		cRet :=  NIL
	endif

	/*
	if alltrim(upper(cusername)) $ 'RITA.CORREA/RODRIGO.COLLEONI/ADMINISTRADOR'
		if ! empty (CR_CC)
			cRet := " (substring(CR_CC,3,4) $ '2009/2010/2011/3001/3002/4004') "
		else 
			cRet := " CR_TIPOPRO $ 'AI/EP/GG/II/MA/MB/ME/MP/MT/PA/PI/PP/PS/VC/VA/VD/BN/UC' "
		endif
	endif

	//Regra para COMERCIAL
	if alltrim(upper(cusername)) $ 'CESAR.CHINATO/FERNANDO'
		if ! empty (CR_CC)
			cRet := " (substring(CR_CC,3,4) $ '4001/4002/4003/4005/4006/4007/4008/4009/4010/4011/4012/4013/4014') "
		else
			cRet := " CR_TIPOPRO = 'MR' "
		endif
	endif

	//Regra para INDUSTRIAL
	if alltrim(upper(cusername)) $ 'JOCEMAR'
		if ! empty (CR_CC)
			cRet := " (substring(CR_CC,3,4) $ '1101/1102/1201/1202/1301/1302/1303/1304/1401/1402/1403/1404/1405/1406/1901/2001/2002/2003/2004/2005/2006/2007/2008/2012/2013/2014/2015/2016/2017/2018/2019/2020/2021/2022/2023/2027/2999') "
		else
			cRet := " CR_TIPOPRO $ 'MM/AP/CL/GF/IA/MO/RE' "
			endif
	endif

	*/

RETURN (cRet) 
