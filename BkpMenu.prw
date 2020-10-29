// Programa:  BkpMenu
// Autor:     Robert Koch
// Data:      27/10/2020
// Descricao: Efetua exportacao dos registros de tabelas do banco referentes aos menus do sistema.
//            Proposito inicial poder gerar copias de seguranca antes de fazer alguma manutencao.
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Exporta do banco de dados os registros de tabelas referentes aos menus do sistema.
// #PalavasChave      #auxiliar #backup #exportacao
// #TabelasPrincipais #MPMENU_FUNCTION #MPMENU_I18N #MPMENU_ITEM #MPMENU_KEY_WORDS #MPMENU_MENU #MPMENU_RW
// #Modulos           #cfg

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function BkpMenu (_lAuto)
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _lContinua := .T.
	local _aTabMnu   := {}
	local _nTabMnu   := 0
	local _sMsgRet   := ''
	local _sNomeBkp  := ''

	_lAuto = iif (_lAuto == NIL, .F., _lAuto)

	if _lContinua .and. ! _lAuto
		_lContinua = U_MsgYesNo ("Este programa cria copias de seguranca das tabelas de composicao dos menos do sistema. Continuar?")
	endif

	if _lContinua
		aadd (_aTabMnu, 'MPMENU_FUNCTION')
		aadd (_aTabMnu, 'MPMENU_I18N')
		aadd (_aTabMnu, 'MPMENU_ITEM')
		aadd (_aTabMnu, 'MPMENU_KEY_WORDS')
		aadd (_aTabMnu, 'MPMENU_MENU')
		aadd (_aTabMnu, 'MPMENU_RW')
		for _nTabMnu = 1 to len (_aTabMnu)
			_sNomeBkp = _aTabMnu [_nTabMnu] + "_bkp_" + dtos (date ()) + "_" + strtran (time (), ":", "")
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT * INTO " + _sNomeBkp
			_oSQL:_sQuery += " FROM " + _aTabMnu [_nTabMnu]
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				u_help ('Erro ao criar backup da tabela ' + _aTabMnu [_nTabMnu],, .t.)
				_lContinua = .F.
			else
				_sMsgRet += ' ' + _sNomeBkp
			endif
		next
	endif

	if _lContinua
		u_help ("Backups gerados em " + _sMsgRet)
		if type ("_sMsgRetWS") == 'C'
			_sMsgRetWS += "Backups gerados em " + _sMsgRet
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _lContinua
