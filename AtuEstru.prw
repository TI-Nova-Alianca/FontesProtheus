// Programa:  AtuEstru
// Autor:     Robert Koch
// Descricao: Atualiza estrutura de uma tabela exportando-a para DBF, fazendo DROP e reimportando os dados.
//            Aprecie com moderacao!

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Faz a exportacao dos dados de uma tabela para CTREE, exclui-a, recria-a conforme dicionario de dados e reimporta os dados.
// #PalavasChave      #manutencao #reimportacao #chkfile
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
// 17/08/2018 - Robert - Faz backup apenas no SQL por questao de performance.
// 15/09/2018 - Robert - Perdia os reg.originais por que reimportada do DBF. Criado tratamento para ler do backup.
//                     - Melhoradas verificacoes e mensagens.
// 06/04/2019 - Robert - Desconsidera registros deletados.
// 07/02/2020 - Robert - Melhorado retorno de mensagens quando chamado via web service.
// 01/04/2020 - Robert - Criado parametro _sCondApp.
// 24/10/2020 - Robert - Melhorados logs
//                     - Inseridos tags para catalogo de programas.
//

// --------------------------------------------------------------------------
user function AtuEstru (_sAlias, _sCondApp)
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _lContinua := .T.
	local _sNomeBkp  := ''
	local _nRegOri   := 0
	local _nRegExp   := 0
	local _nRegImp   := 0
	local _sAliasBkp := ""

	u_log2 ('info','Tentando atualizar estrutura da tabela ' + _sAlias)
	if _lContinua
		if ! ChkFile (_sAlias, .T.)
			u_help ("Impossivel abrir tabela '" + _sAlias + "' exclusiva.",, .t.)
			_lContinua = .F.
		else
//			_nRegOri = (_sAlias) -> (reccount ())
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT COUNT (*) FROM " + RetSQLName (_sAlias) + " WHERE D_E_L_E_T_ != '*'"
			_nRegOri = _oSQL:RetQry ()
		endif
	endif
	if _lContinua
		dbselectarea (_sAlias)
		// vou fazer bkp apenas no SQL ---> copy to ('\' + RetSQLName (_sAlias) + "_bkp")
		(_sAlias) -> (dbclosearea ())
		dbselectarea ("SM0")
		u_log2 ('info', 'Criando backup no SQL (' + cvaltochar (_nRegOri) + ' registros)')
		_sNomeBkp = RetSQLName (_sAlias) + "_BKP_" + dtos (date ()) + strtran (time (), ':', '')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT * INTO " + _sNomeBkp + " FROM " + RetSQLName (_sAlias)
		_oSQL:Log ()
		if _lContinua
			if ! _oSQL:Exec ()
				u_help ('Erro ao criar backup: ' + _sNomeBkp,, .t.)
				_lContinua = .F.
			else
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT COUNT (*) FROM " + _sNomeBkp + " WHERE D_E_L_E_T_ != '*'"
				_nRegExp = _oSQL:RetQry ()
			endif
		endif
	endif
	if _lContinua
		u_log2 ('info', 'Efetuando DROP')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "drop table " + RetSQLName (_sAlias)
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			u_help ("DROP da tabela " + _sAlias + " nao deu certo.",, .t.)
			_lContinua = .F.
		endif
	endif
	if _lContinua
		u_log2 ('info', 'Iniciando Chkfile')
		if ! chkfile (_sAlias)
			u_help ("Nao foi possivel recriar a tabela " + _sAlias,, .t.)
			_lContinua = .F.
		else
		
			// Abre tabela backup para reimportar os dados.
			u_log2 ('info', 'Reimportando dados')
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT * FROM " + _sNomeBkp + " WHERE D_E_L_E_T_ != '*'"
			_sAliasBkp = _oSQL:Qry2Trb (.T.)
			(_sAliasBkp) -> (dbgotop ())
			dbselectarea (_sAlias)
			if ! empty (_sCondApp)
				append from (_sAliasBkp) for &(_sCondApp)
			else
				append from (_sAliasBkp)
			endif
			_nRegImp = (_sAlias) -> (reccount ())
			(_sAliasBkp) -> (dbclosearea ())
			(_sAlias) -> (dbclosearea ())
			dbselectarea ("SM0")
			u_log2 ('info','Append finalizado')
		endif
	endif

	if _nRegImp != _nRegOri .and. empty (_sCondApp)
		u_help ('Problemas com a tabela ' + _sAlias + ': ' + cvaltochar (_nRegOri) + ' reg.iniciais; ' + cvaltochar (_nRegExp) + ' exportados; ' + cvaltochar (_nRegImp) + ' reimportados.',, .t.)
		_lContinua = .F.
	endif
	if _lContinua
		if type ("_sMsgRetWS") == 'C'
			_sMsgRetWS += _sAlias + ': ' + cvaltochar (_nRegImp) + ' de ' + cvaltochar (_nRegOri) + ' registros reimportados.'
		endif
		u_help (_sAlias + ': ' + cvaltochar (_nRegImp) + ' de ' + cvaltochar (_nRegOri) + ' registros reimportados.')
	endif

	U_ML_SRArea (_aAreaAnt)
	u_log2 ('info', 'Processo ' + procname () + ' finalizado.')
return _lContinua
