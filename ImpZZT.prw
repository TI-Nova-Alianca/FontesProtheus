// Programa...: ImpZZT
// Autor......: Robert Koch (versao inicial Leandro Perondi - DWT - 11/09/2013)
// Data.......: 06/03/2019
// Descricao..: Impressao de tickets de portaria (tabela ZZT)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Impressao de tickets de portaria (tabela ZZT)
// #PalavasChave      #controle_de_portaria #ticket #impressao
// #TabelasPrincipais #ZZT
// #Modulos           #COOP
//
// Historico de alteracoes:
// 20/01/2020 - Robert  - Impr. de ticket de safra passa a ser completa, 
//                        e somente em seguida imprime dados de portaria.
// 20/01/2020 - Robert  - Novos parametros chamada geracao ticket safra. 
//                        Melhorias para integracao com safra.
// 16/02/2023 - Robert  - Impressao mensagem velociade maxima.
// 07/08/2024 - Claudia - Incluido % de diferença de peso. GLPI: 15743
//
// --------------------------------------------------------------------------------------------------------
user function ImpZZT(_sCodTick, _sIdImpr, _nQtVias)
	local _aAreaAnt   := U_ML_SRArea()
	local _nTamLin    := 41
	local _sTicket    := ""
	local _nVia       := 0
	local _oSQL       := NIL
	local _sCargDAK   := ""
	local _lContinua  := .T.
	private _Enter    := chr(13)+chr(10)
	private _sArq     := ""
	private _nHdl     := 0
	private cPerg     := "IMPZZT"
	static _sPortaImp := ""  // Tipo STATIC para que o programa abra as perguntas apenas na primeira execucao.
	static _nModelImp := 0   // Tipo STATIC para que o programa abra as perguntas apenas na primeira execucao.
	
	// Se recebi a identificacao da impressora, nao preciso perguntar ao usuario.
	if ! empty(_sIdImpr)
		_sPortaImp = U_RetZX5('49', _sIdImpr, 'ZX5_49CAM')
		_nModelImp = val(U_RetZX5('49', _sIdImpr, 'ZX5_49LING'))
	else
		// Je jah definido na execucao anterior (por isso a variavel eh STATIC), nao pergunto mais.
		if empty(_sPortaImp) .or. empty(_nModelImp)
			_ValidPerg()
			if Pergunte(cPerg)
				_sPortaImp = U_RetZX5('49', mv_par01, 'ZX5_49CAM')
				_nModelImp = val(U_RetZX5('49', mv_par01, 'ZX5_49LING'))
			else
				_lContinua = .F.
			endif
		endif
	endif
	
	if _lContinua
		if empty(_sPortaImp) .or. empty(_nModelImp)
			u_help("Impressora '" + _sIdImpr + "' nao cadastrada ou sem caminho / linguagem informados.")
			_lContinua = .F.
		endif
	endif

	// Busca ticket informado
    if _lContinua
        dbselectarea("ZZT")
        dbsetorder(1)
        dbseek(xFilial("ZZT") + _sCodTick)

        if ! found()
            u_help("Ticket '" + _sCodTick + "' nao encontrado!")
            _lContinua = .F.
        endif
    endif

    if _lContinua

        // Formata o ticket usando a linguagem 'ESC/Bema' para impressora Bematech MP4000 / 4200
		if _nModelImp == 3  // Impressora Bematech
			// Se for um ticket de safra, imprime o ticket original da safra logo no inicio.
			if !empty(ZZT->ZZT_CARGA) .and. !empty(ZZT->ZZT_SAFRA)
				sze -> (dbsetorder(1))
				if sze -> (dbseek(xfilial ("SZF") + ZZT->ZZT_SAFRA + ZZT->ZZT_CARGA, .F.))
					if empty(zzt->zzt_pessai)  // 1a. pesagem
						_sTicket += U_VA_RusTk(1,, 1, {}, 'Bematech', .F.)
					else  // 2a. pesagem
						_sTicket += U_VA_RusTk(2,, 2, {}, 'Bematech', .F.)
					endif
					_sTicket += _Enter
					_sTicket += _Enter
					_sTicket += padc('--------- Controle de portaria ----------', _nTamLin, ' ') + _Enter
				else
					u_help("Safra/carga '" + ZZT->ZZT_SAFRA + '/' + ZZT->ZZT_CARGA + "' nao localizada na tabela SZE.",, .t.)
				endif
				//u_log ('funcao padrao da safra retornou o seguinte:', _sTicket)
			else
				_sTicket := ""
				_sTicket += chr(27) + '@' + _Enter  // Inicializa impressora
				_sTicket += padc(left (alltrim(sm0 -> m0_nomecom), _nTamLin), _nTamLin, ' ') + _Enter
				_sTicket += 'Ticket ' + alltrim(iif(zzt -> zzt_entsai == 'E', 'Entr. ', 'Saida ')) + alltrim(ZZT->ZZT_COD) + '   Placa: ' + alltrim(ZZT->ZZT_PLACA) + _Enter
			endif
			_sTicket += 'Entrada:' + dtoc(ZZT->ZZT_DTENT) + '  ' + ZZT->ZZT_HRENT + '  ' + transform (ZZT->ZZT_PESENT, "@E 999,999,999") + ' Kg' + _Enter
			if ! empty(ZZT->ZZT_DTSAI) .or. ! empty(ZZT->ZZT_HRSAI) .or. ! empty(ZZT->ZZT_PESSAI)
				_sTicket += 'Saida  :' + dtoc(ZZT->ZZT_DTSAI) + '  ' + ZZT->ZZT_HRSAI + '  ' + transform (ZZT->ZZT_PESSAI, "@E 999,999,999") + ' Kg' + _Enter
			endif
			if zzt -> zzt_pespal != 0
				_sTicket += '        Peso pallets/chapatex: ' + transform(zzt -> zzt_pespal, "@E 999,999") + ' Kg' + _Enter
			endif
			if ! empty (zzt -> zzt_pesliq)
				_sTicket += '                Peso liquido:  ' + transform(zzt -> zzt_pesliq, "@E 999,999") + ' Kg' + _Enter
			endif
			if zzt -> zzt_motivo == '2'
				_sTicket += '                     Peso NF:  ' + transform(zzt -> zzt_pesonf, "@E 999,999") + ' Kg' + _Enter
				_sTicket += '              Diferenca peso:  ' + transform(zzt -> zzt_difpes, "@E 999,999") + ' Kg' + _Enter
				_sTicket += '                               ' + transform(zzt->zzt_difpes / zzt->zzt_pesliq * 100, "@E 999.999") + ' %' + _Enter
			endif
			_sTicket += _Enter
			if ! empty(zzt -> zzt_forn) .and. ! empty(zzt -> zzt_lojf) .and. empty(zzt -> zzt_carga)
				_sTicket += left('Fornec: ' + zzt -> zzt_forn + '/' + zzt -> zzt_lojf + '-' + fBuscaCpo('SA2', 1, xfilial("SA2") + zzt -> zzt_forn + zzt -> zzt_lojf, "A2_NOME"), _nTamLin) + _Enter
			endif
			if ! empty(zzt -> zzt_client) .and. ! empty(zzt -> zzt_lojac)
				_sTicket += left('Cliente: ' + zzt -> zzt_client + '/' + zzt -> zzt_lojac + '-' + fBuscaCpo('SA1', 1, xfilial("SA1") + zzt -> zzt_client + zzt -> zzt_lojac, "A1_NOME"), _nTamLin) + _Enter
			endif
			if ! empty(zzt -> zzt_transp)
				_sTicket += left('Transp: ' + alltrim(zzt -> zzt_transp) + '-' + FBUSCACPO("SA4",1,XFILIAL("SA4")+ZZT->ZZT_TRANSP,'A4_NOME'), _nTamLin) + _Enter
			endif
			if ! empty(zzt -> zzt_motor)
				_sRGMot = alltrim (fBuscaCpo("DA4", 1, xfilial ("DA4") + zzt -> zzt_motor, "DA4_RG"))
				if ! empty(_sRGMot)
					_sTicket += left('Mot.: ' + zzt -> zzt_motor + '-' + fBuscaCpo ("DA4", 1, xfilial("DA4") + zzt -> zzt_motor, "DA4_NOME"), _nTamLin - (len(_sRgMot) + 4)) + ' RG:' + _sRGMot + _Enter
				else
					_sTicket += left('Mot.: ' + zzt -> zzt_motor + '-' + fBuscaCpo ("DA4", 1, xfilial("DA4") + zzt -> zzt_motor, "DA4_NOME"), _nTamLin) + _Enter
				endif
			else
				if ! empty(zzt -> zzt_nome)
					_sTicket += left('Mot.: ' + zzt -> zzt_nome, _nTamLin) + _Enter
				endif
			endif
			if ! empty(zzt -> zzt_ajud1)
				_sTicket += left('Ajud: ' + zzt -> zzt_ajud1 + '-' + fBuscaCpo("DAU", 1, xfilial("DAU") + zzt -> zzt_ajud1, "DAU_NOME"), _nTamLin) + _Enter
			endif
			if ! empty(zzt -> zzt_ajud2)
				_sTicket += left('Ajud: ' + zzt -> zzt_ajud2 + '-' + fBuscaCpo("DAU", 1, xfilial("DAU") + zzt -> zzt_ajud2, "DAU_NOME"), _nTamLin) + _Enter
			endif
			if ! empty(zzt -> zzt_ajud3)
				_sTicket += left('Ajud: ' + zzt -> zzt_ajud3 + '-' + fBuscaCpo("DAU", 1, xfilial("DAU") + zzt -> zzt_ajud3, "DAU_NOME"), _nTamLin) + _Enter
			endif
			if ! empty(zzt -> zzt_destin)
				_sTicket += left('Dest: ' + zzt -> zzt_destino, _nTamLin) + _Enter
			endif
			if ! empty(zzt -> zzt_nf)
				_sTicket += left('NF: ' + zzt -> zzt_nf, _nTamLin) + _Enter
			endif

			// Cargas (OMS)
			_oSQL := ClsSQL():New()
			_oSQL:_sQuery += " SELECT DISTINCT DAK_COD"
			_oSQL:_sQuery += " FROM " + RetSQLName("DAK")
			_oSQL:_sQuery += " WHERE D_E_L_E_T_  = ''"
			_oSQL:_sQuery += " AND DAK_FILIAL  = '" + xfilial("DAK") + "'"
			_oSQL:_sQuery += " AND DAK_VATKP   = '" + zzt -> zzt_cod + "'"
			_sCargDAK = _oSQL:Qry2Str(1, ',')

			if ! empty(_sCargDAK)
				_sTicket += 'Carga(s)OMS:' + _sCargDAK + _Enter
			endif

			// Imprime observacao em ateh 2 linhas.
			if ! empty(zzt -> zzt_obs)
				_sObs1    = U_TamFixo("Obs.:" + zzt -> zzt_obs, _nTamLin)
				_sTicket += _sObs1 + _Enter
				_sObs2    = alltrim(substr (zzt -> zzt_obs, len(_sObs1) - 5))
				if ! empty(_sObs2)
					_sTicket += U_TamFixo("     " + _sObs2, _nTamLin) + _Enter
				endif
			endif
		
			// Codigo de barras CODE128
			_sCodBar = alltrim (_sCodTick)
			_sTicket += chr(29)  					// Comando para codigo de barras
			_sTicket += 'H2'  						// Habilita 'human readable information' no codigo de barras.
			_sTicket += chr(29) + 'h' + chr (80)  	// Altura do codigo de barras (entre 1 e 255. Default = 162)
			_sTicket += chr(29) + 'kI'  			// Seleciona CODE128
			_sTicket += chr(11) + _Enter 			// Seta o 'tamanho' do que vai constar nas barras. Teoricamente seriam 9 posicoes, mas ele cortava os dois digitos finais, entao somei 2. vai saber...
			_sTicket += _sCodBar + _Enter  			// Conteudo do codigo de barras

			if zzt -> zzt_motivo == '2' .and. empty(zzt->zzt_pessai)  // Veiculo entrando para coleta.
				_sTicket += U_TamFixo('Ass.motorista:____________________________', _nTamLin) + _Enter
				_sTicket += _Enter
				_sTicket += U_TamFixo('No.pallets:_______________________________', _nTamLin) + _Enter
				_sTicket += _Enter
				_sTicket += U_TamFixo('Ass.liberador:____________________________', _nTamLin) + _Enter
				_sTicket += _Enter
			endif

			// Solicitado pela CIPA em 16/02/2023
			if empty(ZZT->ZZT_CARGA) .and. empty(ZZT->ZZT_SAFRA)
				_sTicket += padc ('ATENCAO: limite de velocidade nas', _nTamLin, ' ')    + _Enter
				_sTicket += padc ('dependencias da cooperativa: 20 Km/h', _nTamLin, ' ') + _Enter
			endif

			// Deixa linhas em branco para avancar papel ateh poder rasgar o ticket.
			_sTicket += _Enter
			_sTicket += _Enter
			_sTicket += _Enter
			_sTicket += _Enter
			
			// Comando de corte parcial de papel
			_sTicket += chr(27) + 'i' + _Enter

		else
			u_help ("Etiqueta nao disponivel para o modelo de impressora '" + cvaltochar(_nModelImp) + "'",, .t.)
		endif
	endif

	// Grava ticket em arquivo e copia para a porta destino.
	if _lContinua .and. ! empty(_sTicket)
		_sArq := CriaTrab(NIL, .F.)
		_nHdl = fcreate(_sArq, 0)

		fwrite(_nHdl, _sTicket)
		fclose(_nHdl)
		for _nVia = 1 to _nQtVias
			copy file(_sArq) to (alltrim(_sPortaImp))
		next
		delete file (_sArq)
	endif

	if cUserName = 'robert.koch'
		U_Log2('debug', '[' + procname() + ']' + _sTicket)
	endif

	U_ML_SRArea(_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                         PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Impressora                    ", "C", 2,  0,  "",   "ZX549", {},                         ""})

	U_ValPerg(cPerg, _aRegsPerg, {}, _aDefaults)
return
