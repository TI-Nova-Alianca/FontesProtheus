// Programa...: BolAuto
// Autor......: Robert Koch
// Data.......: 11/11/2010
// Cliente....: Alianca
// Descricao..: Impressao automatica de boletos, para ser chamada apos a geracao de NF
//              ou apos a transmissao de notas para a SEFAZ, por exemplo.
//              Criado com base no _SPEDNFE de 15/12/2009.
//
// #TipoDePrograma    #Processamento
// #Descricao         #Impressao automatica de boletos
// #PalavasChave      #boletos #geracao_NF #SEFAZ 
// #TabelasPrincipais #SF2 #SF3 #SE1 #SC5 
// #Modulos 		  #FAT
//
// Historico de alteracoes:
// 19/01/2016 - SICREDI - alterar para que busque a subconta 1 - nova
// 23/06/2017 - Catia   - ao buscar o banco/agencia/conta esta não bloqueado
// 26/09/2018 - Andre   - Bloquear geração de boletos para NF não autorizadas ( F3_CODRSEF = '100' )
// 07/05/2019 - Catia   - tratamento para buscar a subconta 1 tambem para o banco do brasil
// 10/05/2019 - Catia   - alterado a forma de buscar a subconta, filial 09 nao estava imprimindo boletos
// 14/05/2019 - Catia   - na caixa tem que ser usada a conta 003 - teste para fazer fixo por aqui
// 01/07/2020 - Claudia - Incluidas as filiais para subconta de banco do brasil. GLPI: 8103
//
// --------------------------------------------------------------------------
user function BolAuto (_sSerie, _sNotaIni, _sNotaFim)
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _sNFIni     := iif (_sNotaIni == NIL, "", _sNotaIni)
	local _sNFFim     := iif (_sNotaFim == NIL, "", _sNotaFim)
	local _aColunas   := {}
	local _aBoletos2  := {}
	local _nBoleto    := 0
	local _sAliasQ2   := ""
	local _aRetQry    := {}
	private _aBoletos := {}

	// Verifica boletos pendentes de impressao.
	if empty (_sNFIni) .or. empty (_sNFFim)
		_sQuery := ""
		_sQuery += " select F2_SERIE, min (F2_DOC) MenorNF, max (F2_DOC) MaiorNF"
		_sQuery += "   from " + RetSQLName ("SF2") + " SF2 "
		_sQuery += " 		INNER JOIN " + RetSQLName ("SF3") + " AS SF3 "
		_sQuery += "		ON (SF3.D_E_L_E_T_ = ''"
		_sQuery += "			AND SF3.F3_FILIAL  = SF2.F2_FILIAL"
		_sQuery += "	        AND SF3.F3_SERIE   = SF2.F2_SERIE"
		_sQuery += "			AND SF3.F3_NFISCAL = SF2.F2_DOC"
		_sQuery += "			AND SF3.F3_CODRSEF = '100'"
		_sQuery += "			AND SF3.F3_CHVNFE  = SF2.F2_CHVNFE)"
		_sQuery += "  where SF2.D_E_L_E_T_ != '*'"
		_sQuery += "    and F2_FILIAL      = '" + xfilial ("SF2") + "'"
		_sQuery += "    and F2_SERIE       = '" + _sSerie + "'"
		_sQuery += "    and F2_BANCO       = '   '"
		_sQuery += "    and F2_EMISSAO     = '" + dtos (dDataBase) + "'"  // Sugere apenas as notas do dia.
		_sQuery += "    and F2_CHVNFE      != ''"  // Compo gravado no momento de impressao do DANFe
		_sQuery += "  Group by F2_SERIE"
		_sQuery += "  Order by F2_SERIE"
		_aRetQry = aclone (U_Qry2Array (_sQuery))
		if len (_aRetQry) > 0
			_sNFIni = _aRetQry [1, 1]
			_sNFFim = _aRetQry [1, 2]
		endif
	endif
		
	if !empty (_sNFIni) .and. !empty (_sNFFim)

		// Verifica se alguma das notas tem boleto a imprimir. Usa clausula 'distinct' por que
		// o programa de impressao de boletos entende que todas as parcelas de cada titulo
		// deverao ser impressas.
		_sQuery := ""
		_sQuery += " select distinct E1_PREFIXO, E1_NUM, A6_COD, A6_AGENCIA, A6_NUMCON"
		_sQuery += "   from " + RetSQLName ("SE1") + " SE1, "
		_sQuery +=              RetSQLName ("SC5") + " SC5, "
		_sQuery +=              RetSQLName ("SA6") + " SA6, "
		_sQuery +=              RetSQLName ("SF3") + " SF3  "
		_sQuery += "  where SE1.D_E_L_E_T_ != '*'"
		_sQuery += "    and SC5.D_E_L_E_T_ != '*'"
		_sQuery += "    and SA6.D_E_L_E_T_ != '*'"
		_sQuery += "	and	SF3.D_E_L_E_T_ != '*'"
		_sQuery += "    and C5_NUM         = E1_PEDIDO"
		_sQuery += "    and C5_BANCO       in " + FormatIn (GetMv ("VA_BCOBOL"), "/")  // Ainda nao tenho rotina de impressao para todos os bancos.
		_sQuery += "    and A6_COD         = C5_BANCO"
		_sQuery += "    and E1_FILIAL      = '" + xfilial ("SE1") + "'"
		_sQuery += "    and C5_FILIAL      = '" + xfilial ("SC5") + "'"
		_sQuery += "    and A6_FILIAL      = '" + xfilial ("SA6") + "'"
		_sQuery += "	and F3_FILIAL      = E1_FILIAL"
		_sQuery += "    and A6_BLOCKED     = '2'"
		_sQuery += "    and E1_PREFIXO     = '" + _sSerie + "'"
		_sQuery += "	and F3_SERIE       = E1_PREFIXO"
		_sQuery += "    and E1_NUM         between '" + _sNFIni + "' and '" + _sNFFim + "'"
		_sQuery += "    and F3_NFISCAL     = E1_NUM"
		_sQuery += "    and F3_CODRSEF     = '100'"
     	_sQuery += "    and E1_BOLIMP      = ''"
		_sQuery += "    and E1_NUMBCO      = ''"
		_sQuery += " ORDER BY E1_NUM"
		
		_sAliasQ2 = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ2, .f., .t.)
		do while ! (_sAliasQ2) -> (eof ())
			
			do case 
			   case (_sAliasQ2) -> A6_COD = '748' // força subconta 1
			    	_wsubconta = '1'
			   case (_sAliasQ2) -> A6_COD = '001' .and. (cfilant = '01' .or. cfilant = '03' .or. cfilant = '07' .or. cfilant = '09' .or. cfilant = '16')  ///força subconta 1 convenio NOVO a partir de 05/2019 
			   		_wsubconta = '1'
			   case (_sAliasQ2) -> A6_COD = '104' .and. cfilant = '01' 
			   		_wsubconta = '003'		   	
			   OTHERWISE		
			   		_wsubconta = '0' // outros bancos usa subconta zero
			endcase
			
			see -> (dbsetorder (1))	
			if see -> (dbseek (xfilial ("SEE") + (_sAliasQ2) -> A6_COD + (_sAliasQ2) -> A6_AGENCIA + (_sAliasQ2) -> A6_NUMCON, .T.))
				aadd (_aBoletos, {.T., (_sAliasQ2) -> e1_prefixo, (_sAliasQ2) -> e1_num, see -> ee_codigo, see -> ee_agencia, see -> ee_conta, _wsubconta, 'BolAuto'})
			endif
			(_sAliasQ2) -> (dbskip ())
		enddo
		(_sAliasQ2) -> (dbclosearea ())
		dbselectarea ("SF2")
	endif

	if len (_aBoletos) > 0
		_aColunas = {}
		aadd (_aColunas, {2, "Serie",  45, "@!"})
		aadd (_aColunas, {3, "Numero", 65, "@!"})
		aadd (_aColunas, {4, "Banco",  45, "@!"})
		
		// Markbrowse para o usuario selecionar os boletos
		U_MBArray (@_aBoletos, "Selecione boletos a imprimir", _aColunas, 1, 600, 400)
		
		// Monta array apenas com os boletos a imprimir
		_aBoletos2 = {}
		for _nBoleto = 1 to len (_aBoletos)
			if _aBoletos [_nBoleto, 1]
				aadd (_aBoletos2, {_aBoletos [_nBoleto, 2], ;
				_aBoletos [_nBoleto, 3], ;
				_aBoletos [_nBoleto, 4], ;
				_aBoletos [_nBoleto, 5], ;
				_aBoletos [_nBoleto, 6], ;
				_aBoletos [_nBoleto, 7], ;
				_aBoletos [_nBoleto, 8]})
			endif
		next
		if len (_aBoletos2) > 0
			processa ({|| U_ML_BOLLSR (_aBoletos2)})
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return
