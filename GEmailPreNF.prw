// Programa.:  BatPreEnt
// Autor....:  Catia Cardoso       
// Data.....:  01/10/2014     
// Descricao:  Gera Email de Pré-Notas Bloqueadas  
//
// Historico de alteracoes:
// 28/11/2016 - Robert - Envia e-mail para compras@... e nao mais para o grupo 017.
// 23/11/2017 - Robert - Criada opcao de visualizar em tela
// 01/03/2018 - Catia  - tratamento para mostrar como divergencia a data de entrega x data de digitação
// --------------------------------------------------------------------------
user function GEmailPreNF (_sFornece, _sLoja, _sNF, _sSerie, _lSoTela)
    local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _sCRLF := chr (13) + chr (10)
	local _oSQL     := NIL
	local _sMsg     := ""
	//local _sDest    := ""
	local _aCols    := {}
	local _aRetQry  := {}
	
	_lSoTela = iif (_lSoTela == NIL, .F., _lSoTela)

   _aCols = {}
   aadd (_aCols, {'Produto'       ,    'left' ,  ''})
   aadd (_aCols, {'Descricao'     ,    'left' ,  ''})
   aadd (_aCols, {'Quant.OC'      ,    'left' ,  ''})
   aadd (_aCols, {'Quant.NF'      ,    'left' ,  ''})
   aadd (_aCols, {'%Diverg.Qtd'   ,    'left' ,  ''})
   aadd (_aCols, {'Valor OC'      ,    'left' ,  ''})
   aadd (_aCols, {'Valor NF'      ,    'left' ,  ''})
   aadd (_aCols, {'%Diverg.Valor' ,    'left' ,  ''})
   aadd (_aCols, {'Dt.Entr OC'    ,    'left' ,  ''})
   aadd (_aCols, {'Dt.Entr NF'    ,    'left' ,  ''})
   
    
   // Verifica OC x Pre-NF e lista itens com divergencia na QUANTIDADE ou PREÇO
   _oSQL := ClsSQL():New ()
   _oSQL:_sQuery := ""
   _oSQL:_sQuery += "SELECT SD1.D1_COD"
   _oSQL:_sQuery += "     , SC7.C7_DESCRI"
   _oSQL:_sQuery += "     , SC7.C7_QUANT"
   _oSQL:_sQuery += "     , SD1.D1_QUANT"
   _oSQL:_sQuery += "     , ROUND ( (SD1.D1_QUANT*100 / SC7.C7_QUANT)-100, 2) AS DIF_QUANT"
   _oSQL:_sQuery += "     , SC7.C7_PRECO"
   _oSQL:_sQuery += "     , SD1.D1_VUNIT"
   _oSQL:_sQuery += "     , ROUND ( (SD1.D1_VUNIT*100 / SC7.C7_PRECO)-100, 2) AS DIF_PRECO"
   _oSQL:_sQuery += "     , dbo.VA_DTOC(SC7.C7_DATPRF)"
   _oSQL:_sQuery += "     , dbo.VA_DTOC(SD1.D1_DTDIGIT)"
   _oSQL:_sQuery += "  FROM SF1010 AS SF1"
   _oSQL:_sQuery += " INNER JOIN SD1010 AS SD1"
   _oSQL:_sQuery += "     ON (SD1.D_E_L_E_T_ = ''"
   _oSQL:_sQuery += "         AND SD1.D1_FORNECE = SF1.F1_FORNECE" 
   _oSQL:_sQuery += "         AND SD1.D1_LOJA    = SF1.F1_LOJA"
   _oSQL:_sQuery += "         AND SD1.D1_DOC     = SF1.F1_DOC"
   _oSQL:_sQuery += "         AND SD1.D1_SERIE   = SF1.F1_SERIE)" 
   _oSQL:_sQuery += " INNER JOIN SC7010 AS SC7"
   _oSQL:_sQuery += "     ON (SC7.D_E_L_E_T_ = ''"
   _oSQL:_sQuery += "         AND SC7.C7_PRODUTO = SD1.D1_COD"
   _oSQL:_sQuery += "         AND SC7.C7_FORNECE = SF1.F1_FORNECE"
   _oSQL:_sQuery += "         AND SC7.C7_LOJA    = SF1.F1_LOJA"
   _oSQL:_sQuery += "         AND SC7.C7_NUM     = SD1.D1_PEDIDO"
   _oSQL:_sQuery += "         AND SC7.C7_ITEM    = SD1.D1_ITEMPC)" 
   _oSQL:_sQuery += " WHERE SF1.D_E_L_E_T_    = ''"
   _oSQL:_sQuery += "   AND SF1.F1_DOC        = '" + _sNF + "'"
   _oSQL:_sQuery += "   AND SF1.F1_SERIE      = '" + _sSerie + "'"
   _oSQL:_sQuery += "   AND SF1.F1_FORNECE    = '" + _sFornece + "'"
   _oSQL:_sQuery += "   AND SF1.F1_LOJA       = '" + _sLoja + "'"
   _oSQL:_sQuery += "   AND (SD1.D1_QUANT < > SC7.C7_QUANT OR SD1.D1_VUNIT < > SC7.C7_PRECO OR SC7.C7_DATPRF < > SD1.D1_DTDIGIT)"
   _oSQL:_sQuery += " ORDER BY F1_DOC, D1_PEDIDO, D1_COD, D1_ITEMPC"
//	u_log (_oSQL:_sQuery)
	_aRetQry := aclone (_oSQL:Qry2Array (.T., .F.))
	if len (_aRetQry) > 0
	     // se a pre-nota estiver bloqueada, manda email solicitando tomada de decisao.
         _xfornece = fbuscacpo("SA2", 1 ,xFilial("SA2") +  sf1->f1_fornece + sf1->f1_loja, "A2_NOME")
         _sMsg = "Doc. de Entrada com DIVERGENCIA de Preço/Quantidade/Data Entrega - Necessita Tomada de Decisão"
         _sMsg += _sCRLF
         _sMsg += _sCRLF
         _sMsg += "Documento  : " + sf1 -> f1_doc
         _sMsg += _sCRLF
         _sMsg += "Série      : " + sf1 -> f1_serie
         _sMsg += _sCRLF
         _sMsg += "Fornecedor : " + sf1 -> f1_fornece + '/' + sf1 -> f1_loja + '/' + sa2 -> a2_nome
         _sMsg += _sCRLF
         _sMsg += _sCRLF
         _sMsg += _oSQL:Qry2HTM ("Itens OC x Doc Entrada", _aCols, "", .F.)
//         u_log (_sMsg)
         if _lSoTela
         	u_ShowHTM (_sMsg, 'I')
         else
         	U_ZZUNU ({'080'}, "Doc. de Entrada com DIVERGENCIA de Preço/Quantidade/Data Entrega - Necessita Tomada de Decisão", _sMsg, .F., cEmpAnt, cFilAnt, "")
         endif
	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return .T.
