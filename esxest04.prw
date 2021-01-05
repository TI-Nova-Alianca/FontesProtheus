// Programa:   ESXEst04
// Autor:      Eduardo Candido
// Data:       01/10/2012
// Descricao:  Replica requisicoes de produtos MOD para produtos AO- e GF- no arquivo SD3,
//             para posterior valorizacao no recalculo do custo medio.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Desmembra requisicoes de itens MMM em AP-, AO-, GF- para posterior recalculo do custo medio.
// #PalavasChave      #mao_de_obra
// #TabelasPrincipais #SD3
// #Modulos           #EST

// Historico de alteracoes:
// 06/11/2014 - Robert - Verifica se os codigos jah existem no SB2, senao cria-os.
// 15/03/2016 - Robert - Passa a usar a classe ClsSQL ()
//                     - Criado tratamento para item 'AP-'
// 29/06/2016 - Robert - Verifica se o usuario tem liberacao para uso desta rotina.
// 16/07/2019 - Robert - Marca SD3 como deletado (antes deletava fisicamente) na remocao de movtos. anteriores.
//                     - Grava evento
// 20/07/2020 - Robert - Permissao para executar passa a validar acesso 102 e nao mais 069.
//                     - Inseridas tags para catalogacao de fontes
// 14/10/2020 - Robert - Desconsidera item 'MMMSAFRA' usado em simulacoes de rateio de safra (por enquanto apenas na base teste).
// 04/01/2021 - Robert - Habilitado novamente o MMMSAFRA, melhorados logs.
//

// -------------------------------------------------------------------------------
User Function esxest04 ()
	local _lContinua := .T.
	Private cPerg    := "ESXEST04"

	u_logId ()

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua
		_lContinua = U_ZZUVL ('102', __cUserID, .T.)
	endif

	if _lContinua
		_ValidPerg()
		if pergunte(cPerg,.T.)
			Processa({|lEnd|_Roda()})
		endif
	endif
return



// -------------------------------------------------------------------------------
Static function _Roda()
	local _sChaveSD3 := "U_ESXEST04"
	local _sProduto  := ""
	local _sTM       := '950'
	local _oSQL      := NIL
	local _lContinua := .T.
	local _sAliasQ   := ""
	local _aNovos    := {'AO-', 'GF-', 'AP-'}
	local _nNovo     := 0
	local _nGerados  := 0
	local _oEvento   := NIL

	if _lContinua .and. mv_par01 <= getmv('MV_ULMES',.F.,'20000101')
		u_help ('Processo nao pode rodar em mes fechado !!!')
		_lContinua = .F.
	endif

	if _lContinua
		 _lContinua = U_msgyesno ('Este programa replica as requisicoes de produtos MMM em ordens de producao para AO, GF e AP, gerando movimentos ' + _sTM + ' para posterior custeio das OP. Confirma?')
	endif

	if _lContinua
		_oEvento := ClsEvent ():New ()
		_oEvento:Texto := "Iniciando processo rateio complemento compra safra"
		_oEvento:CodEven = 'SD3006'
		_oEvento:LeParam (cPerg)
		_oEvento:Grava ()
	endif

	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
//		_oSQL:_sQuery += "DELETE " + RetSQLName ("SD3")
		_oSQL:_sQuery := "UPDATE " + RetSQLName ("SD3")
		_oSQL:_sQuery +=   " SET D_E_L_E_T_ = '*'"
		_oSQL:_sQuery += " WHERE D3_FILIAL  = '" + xfilial("SD3") + "'"
		_oSQL:_sQuery +=   " AND D3_TM      = '" + _sTM + "'"
		_oSQL:_sQuery +=   " AND left (D3_COD, 3) IN ('AO-', 'GF-', 'AP-')"
		_oSQL:_sQuery +=   " AND D3_EMISSAO BETWEEN '" + DtoS(MV_PAR01)+"' AND '"+DtoS(MV_PAR02) + "'"
		_oSQL:_sQuery +=   " AND D3_VACHVEX = '" + _sChaveSD3 + "'"
		_oSQL:Log ()
		_lContinua = _oSQL:Exec ()
	endif

	// Busca movimentos a serem desmembrados.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT * "
		_oSQL:_sQuery +=  " FROM " + RetSqlName ('SD3') + " SD3 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND D3_FILIAL   = '" + xfilial ("SD3") + "'"
		_oSQL:_sQuery +=   " AND D3_ESTORNO != 'S'"
		_oSQL:_sQuery +=   " AND D3_OP      != ''"
		_oSQL:_sQuery +=   " AND D3_EMISSAO BETWEEN '" + DtoS(MV_PAR01) + "' AND '" + DtoS(MV_PAR02) + "'"
		_oSQL:_sQuery +=   " AND LEFT(D3_COD,3) = 'MMM'"
//		_oSQL:_sQuery +=   " AND D3_COD != 'MMMSAFRA'"  // Item usado em simulacoes de rateio de safra (por enquanto apenas na base teste)
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.T.)

		// Para cada movimento de MMM em ordem de producao, gera equivalentes MO-, GF- e AP-
		procRegua ((_sAliasQ) -> (reccount ()))
		(_sAliasQ)->(dbgotop())
		while _lContinua .and. ! (_sAliasQ)->(eof())
			IncProc()
			
			for _nNovo = 1 to len (_aNovos)
				
				// Gera codigo do produto a ser inserido na movimentacao da OP.
				_sProduto = _aNovos [_nNovo] + substr ((_sAliasQ) -> d3_cod, 4) //, tamsx3("D3_COD")[1]-4+1)

				sb1->(dbsetorder(1))
				if !(sb1->(dbseek(XFilial("SB1")+ _sProduto)))
					U_Help ("Produto '" + _sProduto + "' nao cadastrado para MO/GGF. Verifique se foi movimentado um CC que nao existe nesta filial. Processo vai ser abortado.",, .T.)
					_lContinua = .F.
					exit
				endif
	
				sb2->(dbsetorder(1))
				if !sb2->(dbseek(XFilial("SB2") + _sProduto + (_sAliasQ) -> d3_local))
					CriaSB2(_sProduto, (_sAliasQ) -> d3_local)
				endif
	
		 		// Nao usa rotina automatica por que as OPs jah estao encerradas e precisa manter o D3_NUMSEQ original.
				u_log2 ('info', 'Gerando movto ' + _sTM + ' para produto ' + _sProduto + ' e OP ' + (_sAliasQ)->d3_op)
				reclock ("SD3", .T.)
				sd3 -> d3_filial  := xFilial("SD3")
				sd3 -> d3_tm      := _sTM
				sd3 -> d3_cod     := _sProduto
				sd3 -> d3_um      := (_sAliasQ)->d3_um
				sd3 -> d3_quant   := (_sAliasQ)->d3_quant
				sd3 -> d3_cf      := (_sAliasQ)->d3_cf  //'RE0'
				sd3 -> d3_op      := (_sAliasQ)->d3_op
				sd3 -> d3_local   := (_sAliasQ)->d3_local
				sd3 -> d3_doc     := (_sAliasQ)->d3_doc
				sd3 -> d3_emissao := (_sAliasQ)->d3_emissao
				sd3 -> d3_grupo   := sb1 -> b1_grupo  //(_sAliasQ)->d3_grupo
				sd3 -> d3_numseq  := (_sAliasQ)->d3_numseq
				sd3 -> d3_tipo    := sb1 -> b1_tipo  //iif(left(_aNovos[_nNovo],2)=='AO','GF','GF')
				sd3 -> d3_usuario := CUSERNAME
				sd3 -> d3_chave   := 'E0'
				sd3 -> d3_ident   := (_sAliasQ)->d3_ident
				sd3 -> d3_vamotiv := (_sAliasQ)->d3_vamotiv
				sd3 -> d3_vachvex := _sChaveSD3
				msunlock ()
				_nGerados ++
			next
			(_sAliasQ)->(dbskip())
		Enddo
		(_sAliasQ)->(dbclosearea())
		u_help ("Processo finalizado " + chr (13) + chr (10) + cvaltochar (_nGerados) + " movimentacoes de estoque geradas.")
	endif
Return



// -------------------------------------------------------------------------------
Static Function _ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3  Opcoes  Help
	aadd (_aRegsPerg, {01, "Data inicial                  ", "D", 8,  0,  "",   "", {},     "Data inicial a ser considerada"})
	aadd (_aRegsPerg, {02, "Data final                    ", "D", 8,  0,  "",   "", {},     "Data final a ser considerada"})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
