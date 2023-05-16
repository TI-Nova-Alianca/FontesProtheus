
// Programa...: MT103FIM
// Autor......: Maurício C. Dani - TOTVS RS
// Data.......: 15/05/2018
// Descricao..: P.E. - Operação após gravação da NFE
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. - Operação após gravação da NFE
// #PalavasChave      #ponto_de_entrada #gravacao_NFE 
// #TabelasPrincipais #ZZX #SF1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 24/02/2021 - Claudia - Ajustes conforme GLPI: 9481
// 25/08/2021 - Robert  - Nova versao de ciencia e manifesto da TRS (GLPI 10822)
// 30/08/2021 - Robert  - Passa a fazer manifesto somente se o usuario confirmou a tela.
// 23/11/2021 - Claudia - Gerar manifesto apenas para SPED. GLPI: 11183
// 14/12/2021 - Robert  - Nao grava o campo FT_ITEM quando executa MATA103 via rotina automatica (GLPI 11360)
// 09/01/2022 - Robert  - Contranotas de safra estavam chamando tela do manifesto.
// 15/05/2023 - Robert - Alterados alguns logs de INFO para DEBUG e vice-versa.
//

// ------------------------------------------------------------------------------------
User Function MT103FIM()
	local _aAreaAnt := U_ML_SRArea ()
	Local _lConf    := PARAMIXB[2]==1

	// Ajusta tabela SFT quando necessario.
	if alltrim (cEspecie) == 'CTE' .and. _lConf  // Usuario confirmou a tela
		U_Log2 ('debug', '[' + procname () + ']Vou ajustar sft')
		_AjSFT ()
	endif

	if cFormul != 'S'  // Contranotas de safra estavam chamando tela do manifesto
		if alltrim (cEspecie) == 'SPED' .and. _lConf  // Usuario confirmou a tela
			//Realiza ciência
			U_FBTRS101({SF1->F1_CHVNFE}, 4, '')
			//Abre tela do manifesto
			U_FBTRS102(.T.)
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
Return


// ------------------------------------------------------------------------------------
static function _AjSFT ()
	local _oSQL      := NIL

	// Rotina automatica nao grava o FT_ITEM = D1_ITEM
	// Problema parece bem antigo, cfe. comentario no ZZX.PRW: "erro no produto - porem o suporte nao reproduziu e por isso nao vai corrigir"
	// Testado na release33 (14/12/2021) e permanece com problema.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "UPDATE " + RetSQLName ("SFT")
	_oSQL:_sQuery +=   " SET FT_ITEM = '0001'"
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND FT_FILIAL  = '" + xfilial ("SFT")   + "'"
	_oSQL:_sQuery +=   " AND FT_TIPOMOV = 'E'"
	_oSQL:_sQuery +=   " AND FT_NFISCAL = '" + sf1 -> f1_doc     + "'"
	_oSQL:_sQuery +=   " AND FT_SERIE   = '" + sf1 -> f1_serie   + "'"
	_oSQL:_sQuery +=   " AND FT_CLIEFOR = '" + sf1 -> f1_fornece + "'"
	_oSQL:_sQuery +=   " AND FT_LOJA    = '" + sf1 -> f1_loja    + "'"
	_oSQL:_sQuery +=   " AND FT_ESPECIE = '" + sf1 -> f1_especie + "'"
	_oSQL:_sQuery +=   " AND FT_ITEM    = ''"
	_oSQL:Log ()
	_oSQL:Exec ()
return
