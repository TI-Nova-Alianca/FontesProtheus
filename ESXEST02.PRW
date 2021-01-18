// Programa:   EsxEst02
// Autor:      Robert Koch (creditos: Eduardo Candido)
// Data:       2013
// Descricao:  Ajuste do custo dos produtos VD conforme valor informado (complemento safra)
//
// Historico de alteracoes:
// 21/06/2013 - Robert - Criado parametro para gerar entradas ou saidas
//                     - Passa a gravar campo D3_VACHVEX para controle da rotina.
//                     - Em caso de problemas com algum produto, aborta a execucao da rotina.
// 29/06/2016 - Robert - Verifica se o usuario tem liberacao para uso desta rotina.
// 09/05/2017 - Robert - Prepara valores em array para nao fazer 2 leituras de estoque.
//                     - Desconsidera saldos muito pequenos.
//                     - Melhoradas mensagens para o usuario.
// 07/08/2017 - Robert - Desconsidera saldos ATUAIS (nao apenas na data de referencia) muito pequenos.
//                     - Passa a usar o metodo Dist3() da classe ClsAUtil para fazer a distribuicao, com 2 decimais.
// 10/08/2017 - Robert - Passa a desconsiderar produtos com B1_AGREGCU != '1' (de terceiros)
// 08/04/2019 - Catia  - include TbiConn.ch 
// 15/07/2019 - Robert - Marca SD3 como deletado (antes deletava fisicamente) na remocao de movtos. anteriores.
//                     - Verifica se o periodo encontra-se fechado.
//                     - Grava evento
// 20/07/2020 - Robert - Permissao para executar passa a validar acesso 104 e nao mais 069.
//                     - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Gera entrada de valor em itens tipo VD para distribuir complemento de preco de compra de safra.
// #PalavasChave      #complemento #safra
// #TabelasPrincipais #SD3
// #Modulos           #EST
//
//

// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

User function ESXEST02()
	local _lContinua := .T.
	Private cPerg    := 'ESXEST02'
	u_logId ()

	if ! U_MsgNoYes ("Existe a intencao de melhorar este processo para que o rateio seja feito somente nos itens produzidos na safra em questao. Deseja continuar mesmo assim?")
		return
	endif

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua
		_lContinua = U_ZZUVL ('104', __cUserID, .T.)
	endif

	if _lContinua
		_ValidPerg()
		U_GravaSX1 (cPerg, '01', lastday (getmv('MV_ULMES')+1))
		if Pergunte(cPerg, .T.)
			processa ({|| esxest01a()},"Processando ...")
		endif
	endif
Return



// --------------------------------------------------------------------------
Static Function esxest01a()
	local _oSQL      := NIL
	local _lContinua := .T.
	local _ddfim     := dtos(mv_par01)
	local _ddini     := substr(_ddfim,1,6) + '01'
	local _sChaveSD3 := "U_ESXEST02"
	local _nTotal    := 0
	local _aRequis   := {}
	local _aSaldo    := {}
	local _nPar02    := mv_par02
	local _nPar03    := mv_par03
	local _nGerados  := 0
//	local _nQtdMin   := 0.01  // Quantidade minima em estoque para receber rateio.
	local _nVlrDist  := 0
	local _aItens    := {}
	local _nItem     := 0
	local _oAux      := NIL
	local _oEvento   := NIL

	// Periodo nao pode estar fechado
	if stod (_ddfim) <= getmv ("MV_ULMES")
		u_help ("Periodo ja encerrado (MV_ULMES).")
		_lContinua = .F.
	endif
	if _lContinua .and. stod (_ddfim) <= getmv('MV_DBLQMOV',.F.,'20000101')
		u_help ('Processo nao pode rodar com bloqueio de data (MV_DBLQMOV)',, .T.)
		_lContinua = .F.
	endif

	if _lContinua
		_oEvento := ClsEvent ():New ()
		_oEvento:Texto := "Iniciando processo rateio complemento compra safra"
		_oEvento:CodEven = 'SD3005'
		_oEvento:LeParam (cPerg)
		_oEvento:Grava ()
	endif

	// Remove movimentos se ja existirem
	if _lContinua
		_oSQL := ClsSQL():New ()
//		_oSQL:_sQuery := "DELETE  "
//		_oSQL:_sQuery += "FROM SD3010 "
		_oSQL:_sQuery := "UPDATE " + RetSQLName ("SD3")
		_oSQL:_sQuery += " SET D_E_L_E_T_ = '*'"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ' ' "
		_oSQL:_sQuery += " AND D3_FILIAL = '"  + XFilial("SD3") + "' "
		_oSQL:_sQuery += " AND D3_EMISSAO BETWEEN '" + _ddini + "' AND '"  + _ddfim + "' "
		_oSQL:_sQuery += " AND D3_VACHVEX = '" + _sChaveSD3 + "'"
		u_log (_oSQL:_sQuery)
		_lContinua = _oSQL:Exec ()
	endif

	if _lContinua
		// Busca estoques dos produtos do tipo VD
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := "SELECT B2_COD, B2_LOCAL, 0, 0 "
		_oSQL:_sQuery += " FROM " + RetSQLName ("SB2") + " SB2, " + RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery += " WHERE SB2.D_E_L_E_T_ = ' ' "
		_oSQL:_sQuery += " AND SB1.D_E_L_E_T_ = ' ' "
		_oSQL:_sQuery += " AND B2_FILIAL = '"  + XFilial("SB2") + "' "
		_oSQL:_sQuery += " AND B1_FILIAL = '"  + XFilial("SB1") + "' "
		_oSQL:_sQuery += " AND B2_COD = B1_COD "
		_oSQL:_sQuery += " AND B1_TIPO = 'VD' "
		_oSQL:_sQuery += " AND B1_AGREGCU != '1' "
		_oSQL:_sQuery += " ORDER BY B2_COD, B2_LOCAL "
		u_log (_oSQL:_sQuery)
		_aItens := aclone (_oSQL:Qry2Array ())
		if len (_aItens) == 0
			u_help ("Nao encontrei itens tipo VD para distribuir o valor.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		procregua (len (_aItens))
		_nTotal := 0
		for _nItem = 1 to len (_aItens)
			incproc ('Verificando estoque ' + _aItens [_nItem, 1])
			_asaldo := aclone (calcest(_aItens [_nItem, 1], _aItens [_nItem, 2], stod(_ddfim)+1))
	//		if _aSaldo [1] >= 0.1  // Para evitar itens com saldo infimo, que apenas gera problema no recalculo do medio.
			
			// Para evitar itens com saldo infimo (tanto na data de referencia como na data atual), que apenas
			// gera problema no recalculo do medio, testa antes de gravar na array.
			if _aSaldo [1] >= 0.1
				_nSldAtu = fBuscaCpo ("SB2", 1, xfilial ("SB2") + _aItens [_nItem, 1] + _aItens [_nItem, 2], "B2_QATU")
				if _nSldAtu == 0 .or. _nSldAtu > 0.1
					_aItens [_nItem, 3] = _asaldo[1]
					_ntotal += _asaldo[1]
				endif
			endif
		next
		u_log ('Estoques:', _aItens)
		if _nTotal == 0
			u_help ("Nao encontrei itens tipo VD com saldo em estoque para distribuir o valor.")
			_lContinua = .F.
		endif
	endif

	// Distribui o valor proporcionalmente ao estoque dos itens.
	if _lContinua
		_nVlrDist = 0
/*
		for _nItem = 1 to len (_aItens)
			_aItens [_nItem, 4] = _nPar02 / _nTotal * _aItens [_nItem, 3]
			_nVlrDist += _aItens [_nItem, 4]
		next
*/
		_oAux := ClsAUtil ():New (_aItens)
		_oAux:Dist3 (3, 4, _nPar02, 2)
		_aItens := aclone (_oAux:_aArray)

		// soh pra gerar log
		for _nItem = 1 to len (_aItens)
			_nVlrDist += _aItens [_nItem, 4]
		next
		u_log ('distribuidos:', _aItens, 'total=', _nVlrDist)
	endif
	_nVlrDist = 0

	// Gera movimento de valor para os itens
	if _lContinua
		procregua (len (_aItens))
		for _nItem = 1 to len (_aItens)
			incproc ('Distribuindo valor item ' + _aItens [_nItem, 1])
			if _aItens [_nItem, 4] > 0
				_aRequis	:=	{}
				aadd( _aRequis, {"D3_FILIAL",  xFilial("SD3"), NIL})
				aadd( _aRequis, {"D3_TM",      iif (_nPar03 == 1, "413", '513'), NIL})
				aadd( _aRequis, {"D3_COD",     _aItens [_nItem, 1], NIL})
				aadd( _aRequis, {"D3_QUANT",   0, NIL})
				aadd( _aRequis, {"D3_LOCAL",   _aItens [_nItem, 2], NIL})
				aadd( _aRequis, {"D3_CUSTO1",  _aItens [_nItem, 4], NIL})
				aadd( _aRequis, {"D3_EMISSAO", stod(_ddfim), NIL})
				aadd( _aRequis, {"D3_VACHVEX", _sChaveSD3, NIL})
				aadd( _aRequis, {"D3_VAMOTIV", "Rateio Complemento Safra", NIL})
				_aRequis := aclone (U_OrdAuto (_aRequis))
				u_log (_aRequis)
				lMSErroAuto := .f.
				MSExecAuto({|x| MATA240(x)}, _aRequis)
				If lMsErroAuto
					_lContinua = .F.
					Msginfo ("Erro ao fazer o ajuste de valor de estoque")
					mostraerro()
				else
					_nGerados ++
					_nVlrDist += _aItens [_nItem, 4]
				endif
			endif
		next
	endif
	
	u_help ("Processo finalizado " + iif (_lContinua, "com sucesso. ", "COM PROBLEMAS. ") + chr (13) + chr (10) + ;
	        cvaltochar (_nGerados) + " movimentacoes de estoque geradas." + chr (13) + chr (10) + chr (13) + chr (10) + ;
	        "Valor distribuido: " + cvaltochar (_nVlrDist))
Return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

//                     PERGUNT                           TIPO TAM DEC VALID                         F3  Opcoes                Help
	aadd (_aRegsPerg, {01, "Ultimo dia mes processamento  ", "D", 8,  0,  "mv_par01>getmv('MV_ULMES')", "", {},                   ""})
	aadd (_aRegsPerg, {02, "Valor a distribuir            ", "N", 11, 2,  "",                           "", {},                   ""})
	aadd (_aRegsPerg, {03, "Gerar qual movto.de estoque?  ", "N", 1,  0,  "",                           "", {"Entrada", "Saida"}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
