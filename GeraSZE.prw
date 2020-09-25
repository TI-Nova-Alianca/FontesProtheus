// Programa...: GeraSZE
// Autor......: Robert Koch
// Data.......: 07/12/2019
// Descricao..: Gera carga safra (SZE/SZF). Criado para ser chamado por outras rotinas.
//
// Historico de alteracoes:
// 05/02/2020 - Robert - Verifica se o associado tem alguma restricao na view VA_VAGENDA_SAFRA
// 26/02/2020 - Robert - Campo ze_senhade passa a ser do tipo caracter.
//

#include "VA_INCLU.prw"

// --------------------------------------------------------------------------
user function GeraSZE (_oAssoc,_sSafra,_sBalanca,_sSerieNF,_sNumNF,_sChvNfPe,_sPlacaVei,_sTombador,_sObs,_aItensCar, _lAmostra, _sSenhaOrd)
	local _sCargaGer := ''
	local _nItemCar  := 0
//	local _nItemVit  := 0
	local _nLock     := 0
	local _sIdImpr   := ''
	local _oSQL      := NIL
	local _aRetQry   := {}

	u_logIni ()
//	u_log ('param:', _oAssoc,_sSafra,_sBalanca,_sSerieNF,_sNumNF,_sChvNfPe,_sPlacaVei,_sTombador,_sObs,_aItensCar, _lAmostra, _sSenhaOrd)

	// Esta programa foi criado para ser chamado via web service, que jah deve
	// deixar a variavel _sErros criada, mas, para garantir...
	if type ("_sErros") != 'C'
		private _sErros := ""
	endif

	// Apenas uma sessao por vez.
	_nLock = U_semaforo (procname () + cEmpAnt + cFilAnt, .F.)
	if _nLock == 0
		_sErros += "Bloqueio de semaforo. Verifique se existe outra sessao gerando carga e tente novamente."
	endif


	// Define qual a impressora a usar para imprimir os tickets
	if empty (_sErros)
		do case
		case _sBalanca == 'LB'
			_sIdImpr = '07'  // LAB SAFRA MATRIZ
// Ainda nao consegui imprimir fora da rede da matriz --> 		case _sBalanca == 'JC'
// Ainda nao consegui imprimir fora da rede da matriz --> 			_sIdImpr = '08'
// Ainda nao consegui imprimir fora da rede da matriz --> 		case _sBalanca == 'LV'
// Ainda nao consegui imprimir fora da rede da matriz --> 			_sIdImpr = '09'
		otherwise
			_sIdImpr = ''
			u_log ("Impressora de ticket nao definida para a balanca '" + _sBalanca + "'. Nao vou solicitar impressao.")
		endcase
	endif

	if empty (_sErros)

		// Algumas variaveis que devem estar prontas para as validacoes dos programas originais.
		private _lLeitBar  := .F.
		private _lBalEletr := .F.
		private _sPortaBal := ''
		private _sModelBal := 0
		private _nMultBal  := 10
		private _nPesoEmb  := 20
		private _lImpTick  := ! empty (_sIdImpr)
		private _sPortTick := iif (! empty (_sIdImpr), U_RetZX5 ('49', _sIdImpr, 'ZX5_49CAM'), '')
		private _lLeBrix   := .T.
		private _nQViasTk1 := 1
		private _nQViasTk2 := 2
		private _lTickPeso := .F.
		private _lIntPort  := .F.
		private agets      := {}  // Alimentada pelas rotinas do sistema e necessaria para validacoes de campos obrigatorios.
		private aTela      := {}  // Alimentada pelas rotinas do sistema e necessaria para validacoes de campos obrigatorios.
		private _ZESAFRA   := _sSafra
		private _ZELOCAL   := _sBalanca
		private _ZECOOP    := "000021"
		private _ZELOJCOOP := "01"
		private _ZENOMCOOP := "Alianca"
		private _ZEASSOC   := _oAssoc:Codigo
		private _ZELOJASSO := _oAssoc:Loja
		private _ZENOMASSO := _oAssoc:Nome
		private _ZECPFTERC := ''
		private _ZENOMTERC := ''
		private _ZEPATRIAR := ''
		private _ZESNFPROD := _sSerieNF
		private _ZENFPROD  := _sNumNF
		private _ZFQTEMBAL    := 1
		private _ZFEMBALAG    := 'GRANEL'
		private inclui        := .T.
		private altera        := .F.
		RegToMemory ("SZE", inclui, inclui)  // Cria variaveis M->... para simular uma enchoice
		private m->ZE_PLACA   := _sPlacaVei
		private m->ZE_locdesc := _sTombador
		private m->ZE_amostra := IIF (_lAmostra, 'S', 'N')
		private m->ze_senhade := _sSenhaOrd
		private N             := 1
		private _aCadVitic    := {}  // Variavel usada pelos outros programas.
		private lMSErroAuto   := .F.  // Para mostrar erros das rotinas padrao.
		private lMSHelpAuto   := .F.  // Para mostrar erros das rotinas padrao.
		private _zx509fina    := U_RetZX5 ("09", _sSafra + _sBalanca, 'ZX5_09FINA')
		private _zx509orga    := U_RetZX5 ("09", _sSafra + _sBalanca, 'ZX5_09ORGA')
	endif
	//u_log ('Porta para impressao de ticket:', _sPortTick)

	// Verifica se o associado tem alguma restricao
	if empty (_sErros)
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT TOP 1 RESTRICAO"
		_oSQL:_sQuery +=  " FROM VA_VAGENDA_SAFRA"
		_oSQL:_sQuery += " WHERE ASSOCIADO    = '" + _oAssoc:Codigo + "'"
		_oSQL:_sQuery +=   " AND LOJA_ASSOC   = '" + _oAssoc:Loja   + "'"
		_oSQL:_sQuery +=   " AND RESTRICAO   != ''"
		u_log (_oSQL:_squery)
		_sRestri = _oSQL:RetQry ()
		if ! empty (_sRestri)
			_sErros += "Associado com restricoes: " + _sRestri
		endif
	endif

	// Gera array com os cadastros viticolas vinculados ao associado. Deve ser mantido, aqui, o mesmo formato gerado pela classe ClsAssoc.
	if empty (_sErros)
		_aCadVitic := aclone (_oAssoc:CadVitic ())
		if len (_aCadVitic) == 0
			_sErros += "Nao ha nenhuma variedade de uva ligada ao associado."
		endif
/*
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT CAD_VITIC, GRPFAM, DESCR_GRPFAM, PRODUTO, DESCRICAO, TIPO_ORGANICO, RECADAST_VITIC, FINA_COMUM,"
		_oSQL:_sQuery +=       " A2_MUN AS DESCR_MUN, AMOSTRA, RECEB_FISICO_VITIC, SIST_CONDUCAO"
		_oSQL:_sQuery +=  " FROM VA_VAGENDA_SAFRA"
		_oSQL:_sQuery +=  "," + RetSQLName ("SA2") + " SA2"
		_oSQL:_sQuery += " WHERE V.ASSOCIADO    = '" + ::Codigo + "'"
		_oSQL:_sQuery +=   " AND V.LOJA_ASSOC   = '" + ::Loja   + "'"
		_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=   " AND SA2.A2_COD     = V.ASSOCIADO"
		_oSQL:_sQuery +=   " AND SA2.A2_LOJA    = V.LOJA_ASSOC"
		_oSQL:_sQuery += " ORDER BY CAD_VITIC, GRPFAM, PRODUTO"
		u_log (_oSQL:_squery)
	
		// Poderia simplesmente pegar o retorno da query, mas usando os includes facilito
		// futuras pesquisas em fontes para saber onde estes dados sao usados.
		_aRetQry = _oSQL:Qry2Array ()
		_aCadVitic = {}
		for _nLinha = 1 to len (_aRetQry)
			aadd (_aCadVitic, array (.CadVitQtColunas))
			_aRet [_nLinha, .CadVitCodigo]      = _aRetQry [_nLinha, 1]
			_aRet [_nLinha, .CadVitCodGrpFam]   = _aRetQry [_nLinha, 2]
			_aRet [_nLinha, .CadVitNomeGrpFam]  = _aRetQry [_nLinha, 3]
			_aRet [_nLinha, .CadVitProduto]     = _aRetQry [_nLinha, 4]
			_aRet [_nLinha, .CadVitDescPro]     = _aRetQry [_nLinha, 5]
			_aRet [_nLinha, .CadVitOrganico]    = _aRetQry [_nLinha, 6]
			_aRet [_nLinha, .CadVitSafrVit]     = _aRetQry [_nLinha, 7]
			_aRet [_nLinha, .CadVitVarUva]      = _aRetQry [_nLinha, 8]
			_aRet [_nLinha, .CadVitDescMun]     = _aRetQry [_nLinha, 9]
			_aRet [_nLinha, .CadVitAmostra]     = _aRetQry [_nLinha, 10]
			_aRet [_nLinha, .CadVitRecebFisico] = stod (_aRetQry [_nLinha, 11])
			_aRet [_nLinha, .CadVitSistCond]    = _aRetQry [_nLinha, 12]
		next
*/
	endif
//	u_log ('_aCadVitic ficou assim:', _aCadVitic)

	// Cria aHeader e aCols para poder usar as validacoes do VA_RUS2.PRW
	if empty (_sErros)  // Variavel private do web service
		sb1 -> (dbsetorder (1))
		private aHeader := aclone (U_GeraHead ("SZF", .F., {}, {}, .F.))
		private aCols := {}
		for _nItemCar = 1 to len (_aItensCar)
			if ! sb1 -> (dbseek (xfilial ("SB1") + _aItensCar [_nItemCar, 2], .F.))
				_sErros += "Variedade '" + _aItensCar [_nItemCar, 2] + "' nado encontrada no cadastro de itens."
			else
				// Verifica em qual das linhas da array de cadastros viticolas encontra-se esta variedade.
				//u_log ('procurando variedade', sb1 -> b1_cod, 'nos cad. viticolas abaixo:')
				//u_log (_aCadVitic)
				_nItemVit = ascan (_aCadVitic, {|_aVal| _aVal [.CadVitProduto] == sb1 -> b1_cod})
				if _nItemVit == 0
					_sErros += "Variedade " + SB1 -> B1_COD + " nao vinculada ao cadastro viticola " + _aItensCar [_nItemCar, 1]
					exit
				endif
				//u_log ('encontrei itemvit:', _nItemVit)

				aadd (aCols, aclone (U_LinVazia (aHeader)))
				N = len (aCols)
				GDFieldPut ("ZF_ITEM",    strzero (_nItemCar, 2))
				GDFieldPut ("ZF_CADVITI", _aItensCar [_nItemCar, 1])
				GDFieldPut ("ZF_ITEMVIT", _nItemVit)
				GDFieldPut ("ZF_PRODUTO", sb1 -> b1_cod)
				GDFieldPut ("ZF_DESCRI",  sb1 -> b1_desc)
				GDFieldPut ("ZF_CONDUC",  _aCadVitic [_nItemVit, .CadVitSistCond])
				GDFieldPut ("ZF_EMBALAG", iif (_aItensCar [_nItemCar, 3] == 'G', 'GRANEL', iif (_aItensCar [_nItemCar, 3] == 'C', 'CAIXAS', _aItensCar [_nItemCar, 3])))
				GDFieldPut ("ZF_QTEMBAL", 1)
				GDFieldPut ("ZF_HRRECEB", left (time (), 5))
				GDFieldPut ("ZF_IDZA8",   _aItensCar [_nItemCar, 1])  // Por enquanto ainda eh igual ao cadastro viticola
				GDFieldPut ("ZF_OBS",     _sObs)

				//u_log ('Vou chamar validacao de linha com o seguinte conteudo:')
				//u_logACols ()

				// Executa a validacao de linha
				if ! U_VA_RUS2L ()
					_sErros += 'Erro na validacao do item ' + cvaltochar (_nItemCar)
					exit
				endif
			endif
		next
	//	u_log (aHeader)
	//	u_log (aCols)
	//	u_logACols ()
	endif

	// Validacoes do programa original.
	if empty (_sErros)  // Variavel private do web service
		if U_VA_RUS2T ()
			//u_log ('Tudo ok')
			//_sCargaGer = CriaVar ("ZE_CARGA")
			//u_log ('Tentando gravar carga')
			
			// Deixa criara variavel para retorno
			private _RetGrvZZE := ""
			
			 // Gravacao pelo programa original.
			if U_VA_RUS2G ()
				_sCargaGer = _RetGrvZZE
			else
				_sCargaGer = ''
			endif
		endif
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	u_logFim ()
return _sCargaGer
