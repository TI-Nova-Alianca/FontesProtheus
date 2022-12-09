// Programa...: ZA1
// Autor......: Robert Koch
// Data.......: 03/11/2022
// Descricao..: Funcoes genericas tabela ZA1 (geralmente chamadas via MBrowse)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Funcoes genericas tabela ZA1 (geralmente chamadas via MBrowse)
// #PalavasChave      #etiquetas #pallets
// #TabelasPrincipais #ZA1
// #Modulos           #PCP #EST

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
// Recebe chamada feita via botao 'imprime' do MBrowse do ZA1
user function ZA1ImpAv ()
	// Instancia objeto para impressao.
	_oEtiq := ClsEtiq ():New (ZA1->ZA1_CODIGO)
	_oEtiq:Imprime ()
return


// --------------------------------------------------------------------------
// Recebe chamadas feitas pelos botoes do MTA390MNU.
user function ZA1SD5 (_sQueFazer)
	local _aAreaAnt := U_ML_SRArea ()
	local _oEtiq    := CLsEtiq ():New ()
	local _sImpr    := space (2)
	local _oSQL     := NIL
	local _sEtiq    := ''
	local _xRet     := NIL

	if _sQueFazer == 'G'  // Gerar nova
		_xRet = ''
		_sEtiq = U_ZA1SD5 ('B')
		if ! empty (_sEtiq)
			u_help ("Ja existe a etiqueta " + _sEtiq + " gerada para este registro.",, .t.)
		else
			_oEtiq:NovaPorSD5 (sd5 -> d5_produto, sd5 -> d5_LoteCtl, sd5 -> d5_local, sd5 -> d5_NumSeq)
			if ! empty (_oEtiq:Codigo)
				_xRet = _oEtiq:Codigo  // Retorna o codigo da etiqueta gerada
				if u_msgyesno ("Etiqueta gerada: " + _oEtiq:Codigo + ". Deseja imprimi-la?")
					U_ZA1SD5 ('I')
				endif
			endif
		endif
	elseif _sQueFazer == 'I'  // Imprimir
		_xRet = ''
		_sEtiq = U_ZA1SD5 ('B')
		if empty (_sEtiq)
			u_help ("Nao encontrei etiqueta gerada para este registro (ou ja foi inutilizada).",, .t.)
		else
			_oEtiq := ClsEtiq ():New (_sEtiq)
			_sImpr = U_Get ("Selecione impressora", 'C', 2, '', 'ZX549', _sImpr, .f., '.t.')
			if ! empty (_sImpr)
				_xRet = _oEtiq:Imprime (_sImpr)
			endif
		endif
	
	elseif _sQueFazer == 'B'  // Buscar codigo da etiqueta gerada para este registro do SD5 (se existir)
		_xRet = ''
		if sd5 -> d5_origlan == 'MAN'  // Ateh o momento, geram-se etiquetas somente para origem=MAN
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT ZA1_CODIGO"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZA1") + " ZA1"
			_oSQL:_sQuery += " WHERE ZA1.D_E_L_E_T_  = ''"
			_oSQL:_sQuery +=   " AND ZA1.ZA1_FILIAL  = '" + xfilial ("ZA1")   + "'"
			_oSQL:_sQuery +=   " AND ZA1.ZA1_PROD    = '" + sd5 -> d5_produto + "'"
			_oSQL:_sQuery +=   " AND ZA1.ZA1_D5NSEQ  = '" + sd5 -> d5_numseq  + "'"
			_oSQL:_sQuery +=   " AND ZA1.ZA1_APONT  != 'I'"  // Se estiver inutilizada, ok
			_oSQL:Log ('[' + procname () + ']')
			_xRet = _oSQL:RetQry (1, .f.)
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _xRet
