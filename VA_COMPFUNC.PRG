//  Programa...: VA_COMPFUN
//  Autor......: Catia Cardoso
//  Data.......: 20/01/2016
//  Descricao..: gera arquivo de desconto de compras de funcionarios - integracao folha - TXT
//  Historico de alteracoes:
//
//  24/10/2016 - Alterada Query de L1_EMISSAO para L1_EMISNF - por conta de cupom com data de orçamento diferente da data de emissao da NF
//  27/03/2018 - Alteração para que se parte do cupom foi paga com vale que gere so a diferença em desconto em folha
//  25/10/2018 - Alterado Relatorio para que considere a reimplantação das lojas - cond 997 e forma de pagamento

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function VA_COMPFUNC()
	local i	:= 0
	cPerg   := "VA_COMPFUNC"
	
    _ValidPerg()
    if Pergunte(cPerg,.T.)
    	
    	if mv_par01 > mv_par02
    		u_help ("Erro com o parametro de datas. Verifique!")
    		return
    	endif
    	
    	if dtos(mv_par01) = '20181026'
    		if dtos(mv_par02) = '20181125'
    			u_help ("Intervalo de datas, compreende data de reimplantacao das lojas. Necessário listar 2 relatorios. Reimplantacao em 01/11/2018")
    			return
    		endif
    	endif
    
		_sSQL := " "
		_sSQL += " SELECT SL1.L1_VACGC"
		if mv_par06 = 2
			_sSQL += "      , SUM(SL4.L4_VALOR)*100"
		else
			_sSQL += "      , SUM(SL1.L1_VLRTOT - SL1.L1_VALES)*100"
	    endif
	    _sSQL += "   FROM SL1010 AS SL1" 
	    if mv_par06 = 2
	       	_sSQL += " 		INNER JOIN SL4010 AS SL4"
			_sSQL += " 			ON (SL4.D_E_L_E_T_ = ''"
			_sSQL += " 				AND SL4.L4_FILIAL  = SL1.L1_FILIAL"
			_sSQL += " 				AND SL4.L4_NUM     = SL1.L1_NUM"
			_sSQL += " 				AND SL4.L4_FORMA   = 'CO'"
			_sSQL += " 				AND SL4.L4_ADMINIS LIKE '%900%' )"
		endif	
		_sSQL += "  	INNER JOIN SF2010 AS SF2"
	 	_sSQL += "			ON (SF2.D_E_L_E_T_ = ''"
	 	_sSQL += "				AND SF2.F2_FILIAL  = L1_FILIAL"
	 	_sSQL += "				AND SF2.F2_DOC     = L1_DOC"
	 	_sSQL += "				AND SF2.F2_SERIE   = L1_SERIE"
	 	_sSQL += "				AND SF2.F2_EMISSAO = L1_EMISNF)"
	 	_sSQL += "  	INNER JOIN ZAD010 AS ZAD"
	 	_sSQL += "			ON (ZAD.D_E_L_E_T_     = ''"
	 	_sSQL += "				AND ZAD.ZAD_CPF    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	 	if mv_par05 = 1
			_sSQL += "				AND ZAD.ZAD_SITUA IN ('1','2')"  // -- busca so os ativos e afastados	 		
	 	endif
	 	_sSQL += "				AND ZAD.ZAD_CPF    =  L1_CGCCLI)"
		_sSQL += " WHERE SL1.D_E_L_E_T_  =''"
	 	_sSQL += "   AND SL1.L1_EMISNF  BETWEEN '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "'"
	   	_sSQL += "   AND SL1.L1_DOC     !=''"
	   	if mv_par06 = 1
	   		_sSQL += "   AND SL1.L1_CONDPG   = '997'"
	   	endif	
	    _sSQL += " GROUP BY SL1.L1_VACGC "
	    _sSQL += " ORDER BY SL1.L1_VACGC"  

	    _aDados := U_Qry2Array(_sSQL)
		if len(_aDados) > 0
			_wlinha = ''
			_sArq = "C:\TEMP\COMPRAS_LOJAS.TXT"
			_nHdl = fcreate(_sArq, 0)
			for i=1 to len(_aDados)
				_wlinha := alltrim(_aDados [i,1]) + strzero(_aDados [i,2],12)
				fwrite (_nHdl, _wlinha + chr (13) + chr (10))
			next
			fclose (_nHdl)
		endif
	endif						
return	

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Inicial         ?", "D", 8, 0,  "",  "   ", {},                         ""})
    aadd (_aRegsPerg, {02, "Data Final           ?", "D", 8, 0,  "",  "   ", {},                         ""})
    aadd (_aRegsPerg, {03, "Funcionario          ?", "C",11, 0,  "",  "ZAD", {},                         "Funcioanrio Inicial"})
	aadd (_aRegsPerg, {04, "Funcionario          ?", "C",11, 0,  "",  "ZAD", {},                         "Funcionario Final"})
	aadd (_aRegsPerg, {05, "Considera demitidos  ?", "N", 1, 0,  "",  "   ", {"Nao", "Sim"}, ""})
	aadd (_aRegsPerg, {06, "Reimplantação Lojas  ?", "N", 1, 0,  "",  "   ", {"Antes", "Depois"}, ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return