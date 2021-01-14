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
user function GeraSZE (_oAssoc,_sSafra,_sBalanca,_sSerieNF,_sNumNF,_sChvNfPe,_sPlacaVei,_sTombador,_sObs,_aItensCar, _lAmostra, _sSenhaOrd, _sIdImpr)
	local _sCargaGer := ''
	local _nItemCar  := 0
	local _nLock     := 0
	local _oSQL      := NIL
	local _aEspum := {}
	u_log2 ('info', 'Iniciando ' + procname ())

	// Este programa foi criado para ser chamado via web service, que jah deve
	// deixar a variavel _sErros criada, mas, para garantir...
	if type ("_sErros") != 'C'
		private _sErros := ""
	endif

	// Apenas uma sessao por vez.
	_nLock = U_semaforo (procname () + cEmpAnt + cFilAnt, .F.)
	if _nLock == 0
		_sErros += "Bloqueio de semaforo. Verifique se existe outra sessao gerando carga e tente novamente."
	endif

	if empty (_sErros)

		// Algumas variaveis que devem estar prontas para as validacoes dos programas originais.
		private _lLeitBar  := .F.
		private _lBalEletr := .F.
		private _sPortaBal := ''
		private _sModelBal := 0
		private _nMultBal  := 10
		private _nPesoEmb  := 20
		private _lImpTick  := .F.
		private _sPortTick := ''
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


	// Se nao informada uma impressora especifica, mantem a impressora default desta filial.
	if ! empty (_sIdImpr)
		_sPortTick = U_RetZX5 ('49', _sIdImpr, 'ZX5_49CAM')
	else
		do case
		case _sBalanca == 'LB'
			_sIdImpr = '14' //'07'  // LAB SAFRA MATRIZ
		// Ainda nao consegui imprimir fora da rede da matriz --> 		case _sBalanca == 'JC'
		// Ainda nao consegui imprimir fora da rede da matriz --> 			_sIdImpr = '08'
		// Ainda nao consegui imprimir fora da rede da matriz --> 		case _sBalanca == 'LV'
		// Ainda nao consegui imprimir fora da rede da matriz --> 			_sIdImpr = '09'
		otherwise
			_sIdImpr = ''
			u_log ("Impressora de ticket nao definida para a balanca '" + _sBalanca + "'. Nao vou solicitar impressao.")
		endcase
	endif
	u_log2 ('debug', '_sIdImpr:' + _sIdImpr)
	u_log2 ('debug', '_sPortTick:' + _sPortTick)
	if ! empty (_sPortTick)
		_lImpTick = .T.
	endif


	// Verifica se o associado tem alguma restricao
	if empty (_sErros)
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT GX0001_ASSOCIADO_RESTRICAO as restricao"
		_oSQL:_sQuery +=  " FROM GX0001_AGENDA_SAFRA"
		_oSQL:_sQuery += " WHERE GX0001_ASSOCIADO_CODIGO = '" + _oAssoc:Codigo + "'"
		_oSQL:_sQuery +=   " AND GX0001_ASSOCIADO_LOJA   = '" + _oAssoc:Loja   + "'"
		_oSQL:_sQuery +=   " AND GX0001_ASSOCIADO_RESTRICAO != ''"
		_oSQL:Log ()
		_sRestri = _oSQL:RetQry ()
		if ! empty (_sRestri)
			_sErros += "Associado com restricoes: " + _sRestri
		endif
	endif

	// Gera array com os cadastros viticolas vinculados ao associado. Deve ser mantido, aqui, o mesmo formato gerado pela classe ClsAssoc.
	if empty (_sErros)
		_aCadVitic = aclone (U_VA_RusCV (_oAssoc:Codigo, _oAssoc:Loja))
		if len (_aCadVitic) == 0
			_sErros += "Nao ha nenhuma variedade de uva ligada ao associado."
		endif
	endif
	//u_log2 ('info', '_aCadVitic ficou assim:')
	u_log2 ('info', _aCadVitic)

	// Cria aHeader e aCols para poder usar as validacoes do VA_RUS2.PRW
	if empty (_sErros)  // Variavel private do web service
		sb1 -> (dbsetorder (1))
		private aHeader := aclone (U_GeraHead ("SZF", .F., {}, {}, .F.))
		private aCols := {}
		u_log2 ('debug', '_aItensCar:')
		u_log2 ('debug', _aItensCar)
		for _nItemCar = 1 to len (_aItensCar)

			// Verifica em qual das linhas da array de cadastros viticolas encontra-se esta variedade.
			u_log2 ('debug', 'Pesquisando ' + _aItensCar [_nItemCar, 2])
			_nItemVit = ascan (_aCadVitic, {|_aVal| alltrim (_aVal [.CadVitProduto]) == alltrim (_aItensCar [_nItemCar, 2])})
			if _nItemVit == 0
				_sErros += "Variedade " + alltrim (_aItensCar [_nItemCar, 2]) + " nao vinculada com a propriedade rural " + _aItensCar [_nItemCar, 1] + ' / SIVIBE ' + _aItensCar [_nItemCar, 5]
				exit
			endif

			if ! sb1 -> (dbseek (xfilial ("SB1") + _aItensCar [_nItemCar, 2], .F.))
				_sErros += "Variedade '" + _aItensCar [_nItemCar, 2] + "' nao encontrada no cadastro de itens."
				exit
			endif

			// Se foi informado que eh uva para espumante, preciso converter do codigo base (uva para vinho) para o codigo 'para espumante'
			if _aItensCar [_nItemCar, 6] == 'S'
				u_log2 ('debug', 'Eh uva para espumante')
				_oSQL := ClsSQL():New ()
				_oSQL:_sQuery := "SELECT COD_PARA_ESPUMANTE"
				_oSQL:_sQuery +=  " FROM VA_VFAMILIAS_UVAS"
				_oSQL:_sQuery += " WHERE COD_BASE = '" + _aItensCar [_nItemCar, 2] + "'"
				_aEspum = aclone (_oSQL:Qry2Array (.F., .F.))
				if len (_aEspum) == 0
					_sErros += "Nao encontrei codigo para espumante relacionado com a variedade " + _aItensCar [_nItemCar, 2]
					exit
				elseif len (_aEspum) > 1
					_sErros += "Encontrei mais de um codigo para espumante relacionado com a variedade " + _aItensCar [_nItemCar, 2]
					exit
				else
					if ! sb1 -> (dbseek (xfilial ("SB1") + _aEspum [1, 1], .F.))
						_sErros += "Variedade para espumante '" + _aEspum [1, 1] + "' nao encontrada no cadastro de itens."
						exit
					endif
				endif
			endif

			aadd (aCols, aclone (U_LinVazia (aHeader)))
			N = len (aCols)
			GDFieldPut ("ZF_ITEM",    strzero (_nItemCar, 2))
			GDFieldPut ("ZF_CADVITI", _aItensCar [_nItemCar, 1])
			GDFieldPut ("ZF_SIVIBE",  _aItensCar [_nItemCar, 5])
			GDFieldPut ("ZF_ITEMVIT", _nItemVit)
			GDFieldPut ("ZF_PRODUTO", sb1 -> b1_cod)
			GDFieldPut ("ZF_DESCRI",  sb1 -> b1_desc)
			GDFieldPut ("ZF_CONDUC",  _aCadVitic [_nItemVit, .CadVitSistCond])
			GDFieldPut ("ZF_EMBALAG", iif (_aItensCar [_nItemCar, 3] == 'G', 'GRANEL', iif (_aItensCar [_nItemCar, 3] == 'C', 'CAIXAS', _aItensCar [_nItemCar, 3])))
			GDFieldPut ("ZF_QTEMBAL", 1)
			GDFieldPut ("ZF_HRRECEB", left (time (), 5))
			GDFieldPut ("ZF_IDZA8",   _aItensCar [_nItemCar, 1])  // Por enquanto ainda eh igual ao cadastro viticola
			GDFieldPut ("ZF_OBS",     _sObs)
			u_logACols ()

			// Executa a validacao de linha
			if ! U_VA_RUS2L ()
				_sErros += 'Erro na validacao do item ' + cvaltochar (_nItemCar)
				exit
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
			private _RetGrvSZE := ""
			
			 // Gravacao pelo programa original.
			if U_VA_RUS2G ()
				_sCargaGer = _RetGrvSZE
			else
				_sCargaGer = ''
			endif
		endif
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	u_log2 ('info', 'Finalizando ' + procname ())
return _sCargaGer
