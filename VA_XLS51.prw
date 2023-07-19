// Programa...: VA_XLS51
// Autor......: Cláudia Lionço
// Data.......: 24/08/2020
// Descricao..: Exporta planiha com rateios CC auxiliares para produtivos
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta planiha com rateios CC auxiliares para produtivos
// #PalavasChave      #rateios #rateios_CC 
// #TabelasPrincipais #CT2 #CTT 
// #Modulos 		  #CTB 
//
// Historico de alteracoes:
// 20230719 - Claudia - Ajuste do relatório para leitura da view 
//                      VA_VRATEIOS_CC_AUX_PARA_PRODUTIVOS. GLPI: 13935
// 
// --------------------------------------------------------------------------
User Function VA_XLS51()
	Private cPerg   := "VAXLS51"
	
	_ValidPerg()

	If Pergunte (cPerg, .T.)
		If !empty(mv_par01) .and. !empty(mv_par02)
			Processa( { |lEnd| _Gera() } )
		Else
			u_help("Deve-se preencher os parametros de ano inicial e final!")
		EndIf
	Endif
Return
//	
// --------------------------------------------------------------------------
// Geração da planilha
Static Function _Gera()
	local _oSQL := NIL

	procregua (4)
	incproc ()
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 		* "
	_oSQL:_sQuery += " FROM VA_VRATEIOS_CC_AUX_PARA_PRODUTIVOS "
	_oSQL:_sQuery += " WHERE YEAR(DT_MOVTO) BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "

	_oSQL:Log ()
	_oSQL:Qry2XLS (.F., .F., .T.)	

Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT        TIPO TAM DEC VALID F3     Opcoes          	    Help
	aadd (_aRegsPerg, {01, "Ano Inicial ", "C", 4,  0,  "",   "   ", {},                   	""})
	aadd (_aRegsPerg, {02, "Ano Final   ", "C", 4,  0,  "",   "   ", {},                   	""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return

