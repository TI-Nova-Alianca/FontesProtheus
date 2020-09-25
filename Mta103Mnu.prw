// Programa:  Mta103Mnu
// Autor:     Robert Koch
// Data:      18/09/2013
// Descricao: P.E. antes de montar MBrowse na tela de NF de entrada.
//
// Historico de alteracoes:
//
// 23/08/2017 -  Catia   - Botao para liberar NF de importação
// 11/10/2019 -  Cláudia - Botao para gerar etiqueta de NF entrada"
// --------------------------------------------------------------------------
user function Mta103Mnu ()
	local _aRotAdic := {}
	aadd (_aRotAdic, {"Eventos Alianca" 	, "U_VA_SZNC  ('NFENTRADA', sf1 -> f1_doc, sf1 -> f1_serie, sf1 -> f1_fornece, sf1 -> f1_loja)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Eventos NF-e"    	, "U_EvtNFe   ('E', sf1 -> f1_doc, sf1 -> f1_serie, sf1 -> f1_fornece, sf1 -> f1_loja)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Dados adicionais"	, "U_NFDAdicC ('E', sf1 -> f1_doc, sf1 -> f1_serie, sf1 -> f1_fornece, sf1 -> f1_loja)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"NF Import.FLAG"  	, "U_NFImpFlag( sf1 -> f1_doc, sf1 -> f1_serie, sf1 -> f1_fornece, sf1 -> f1_loja)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Gera Etq NF entrada"	, "U_EtqPllGN ()", 0, 6, 0, NIL})
	aadd (aRotina, {"Especificos"           , _aRotAdic, 0, 6, 0, NIL})
return

// --- seta flag da nota de importacao permtindo que seja excluida a nota
user function NFImpFlag ( _wdoc, _wserie, _wfornece, _wloja)

	_sSQL := ""
	_sSQL += " UPDATE SD1010"
   	_sSQL += "    SET D1_TIPO_NF = ''"  
 	_sSQL += "  WHERE D1_FILIAL  = '" + xfilial('SD1') + "'"
   	_sSQL += "    AND D1_DOC     = '" + _wdoc + "'"
   	_sSQL += "    AND D1_SERIE   = '" + _wserie + "'"
   	_sSQL += "    AND D1_FORNECE = '" + _wfornece + "'"
   	_sSQL += "    AND D1_LOJA    = '" + _wloja + "'"
   	_sSQL += "    AND D_E_L_E_T_ = ''"
   	
   	if TCSQLExec (_sSQL) < 0
       U_AvisaTI ("Erro - Nao foi possivel alterar FLAG na NF de importação (NF/SERIE/CLIENTE): " + _wdoc + '/' + _wserie + '/' + _wfornece)
    endif   
	    	
return