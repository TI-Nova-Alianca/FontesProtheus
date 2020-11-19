// Programa...: SF1140I
// Autor......: Robert Koch
// Data.......: 13/08/2014
// Descricao..: P.E. apos a inclusao de pre-nota de entrada.
//
// Historico de alteracoes:
// 30/09/2014 - incluida opcao para mandar email - se pre-nota estiver bloqueada
// 03/03/2016 - alteracao para que nao solicite se deseja imprimir romaneio quando eh conhecimento de frete
// 27/03/2018 - estava funcao _AtuZZX ('') nao encontrada
// 23/11/2018 - tirado teste do bat de transferencias de filiais
// 17/12/2018 - Incluida impressão de romaneio de entrada
// --------------------------------------------------------------------------------------------------------
user function SF1140I ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	//local _xRet      := " "
	
//   //  se a pre-nota estiver bloqueada, manda email solicitando tomada de decisao.
 //   _xRet = fbuscacpo("SF1", 1 ,xFilial("SF1") + sf1->f1_doc +  sf1->f1_serie + sf1->f1_fornece + sf1->f1_loja, "F1_STATUS")
  //  if _xRet ="B" .OR. _xRet="C"
   //     U_GEmailPreNF (sf1 -> f1_fornece, sf1 -> f1_loja, sf1 -> f1_doc, sf1 -> f1_serie)
    //endif
   
	// Imprime romaneio de entrada
	if sf1 -> f1_especie !='CTR' .and. sf1 -> f1_especie !='CTE'
	 if ! isincallstack ('U_ZZXG') 
	    if cEmpAnt + cFilAnt == '0101' .and.  U_MsgYesNo ("Deseja imprimir o romaneio de entrada?")
	    	U_RomEntr (sf1 -> f1_fornece, sf1 -> f1_loja, sf1 -> f1_doc, sf1 -> f1_serie)
		endif    	  	
	 endif
	endif
	
	// grava usuario que esta incluindo o documento de entrada
    RecLock("SF1",.F.)
    	SF1 -> F1_VAUSER  = alltrim(cUserName)
    	SF1 -> F1_VADTINC = date ()
    	SF1 -> F1_VAHRINC = time ()
    MsUnLock()
	
	// Atualiza status na tabela ZZX (XML de NF de entrada).
	_AtuZZX ('')

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return

// --------------------------------------------------------------------------
// Atualiza status na tabela ZZX  --- essa rotina é usada pelo SF1140I
static function _AtuZZX (_zzxstatus)
	local _oSQL      := NIL
	if sf1->f1_especie = 'SPED' .or.  sf1->f1_especie = 'CTE' // Doc.Lançado
		if ! empty (sf1 -> f1_chvnfe) 
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " UPDATE " + RetSQLName ("ZZX")
			_oSQL:_sQuery +=    " SET ZZX_STATUS = '1' "
			_oSQL:_sQuery +=    "   , ZZX_CSTAT  = '" + dtoc(F1_VADTINC) + ' - ' + F1_VAHRINC + ' - ' + F1_VAUSER + "'" 
			_oSQL:_sQuery +=  " WHERE ZZX_CHAVE  = '" + sf1 -> f1_chvnfe + "'"
			_oSQL:_sQuery +=    " AND D_E_L_E_T_ = ''"
			_oSQL:Exec ()
		else  // 2=Pre-NF gerada
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " UPDATE " + RetSQLName ("ZZX")
			_oSQL:_sQuery += "    SET ZZX_STATUS = '2'"
			_oSQL:_sQuery += "      , ZZX_CSTAT  = '" + dtoc(F1_VADTINC) + ' - ' + F1_VAHRINC + ' - ' + F1_VAUSER + "'"
			_oSQL:_sQuery += "  WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery += "    AND F1_DOC     = '" + sf1 -> f1_doc + "'" 
	    	_oSQL:_sQuery += "    AND F1_FORNECE = '" + sf1 -> f1_fornece + "'"
	    endif
	 endif
return
