// Programa.:  FA070CAN
// Autor....:  Catia Cardoso
// Data.....:  08/09/2015
// Descricao:  P.E. antes cancelamento baixa manual de contas a receber
//             Criado inicialmente para atualizar verbas de clientes
// 
// Tags para automatizar catalogo de customizacoes:
// #Programa          #ponto_de_entrada
// #Descricao		  #P.E. antes cancelamento baixa manual de contas a receber
// #PalavasChave      #verbas #descontos #baixa #rapel
// #TabelasPrincipais #ZA4 #ZA5 
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
// 22/01/2016 - Catia   - Erro ao cancelar uma baixa que tinha verba
// 03/08/2018 - Catia   - Não estava voltando a verba pra pendente
// 27/09/2018 - Catia   - Ajuste pq não estava voltando o status de utilizada no ZA4 corretamente
// 17/06/2019 - Robert  - Verifica se o SE5 encontra-se em EOF antes de gravar (quando chamado a partir da exclusao).
// 10/10/2019 - Robert  - Valida campo ZA5_SEQSE5 para limpeza do ZA5 (GLPI 6785)
// 11/11/2019 - Robert  - Tratamento campo ZA5_FILIAL (tabela passar de compartilhada para exclusiva). GLPI 6987.
// 23/05/2022 - Claudia - Incluido o estorno do rapel. GLPI: 8916
//
// -----------------------------------------------------------------------------------------------------------------
user function FA070Can ()
	local _aAreaAnt := U_ML_SRArea ()
	u_logIni ()

	// grava tabela SE5
	u_logtrb ('SE5', .f.)
	if ! se5 -> (eof ())  // Pode estar em EOF quando chamado a partir da exclusao.
		u_log ('vou gravar e5_vauser')
		RecLock("SE5",.F.)
		SE5->E5_VAUSER   := alltrim(cUserName)
		MsUnLock()
		u_log ('gravei se5')
	endif

	// Atualiza verbas.
	if SE5-> E5_VLDESCO > 0 	
		_AtuZA5()
	endif

	// Cancela rapel
	if GetMV('VA_RAPEL')
		_AtuZC0()
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
//
// --------------------------------------------------------------------------
// Atualiza verbas
static function _AtuZA5 ()
	local _aVerbas := {}
	local _nVerba := 0
	local _oSQL   := ClsSQL ():New ()

	u_logIni ()

	// verifica se o lcto que ta sendo excluido esta amarrado a alguma verba
	_oSQL:_sQuery  = "" 
	_oSQL:_sQuery += " SELECT ZA5_NUM"
	_oSQL:_sQuery += "      , ZA5_SEQ"
	_oSQL:_sQuery += "   FROM "+ RetSQLName ("ZA5")
	_oSQL:_sQuery += "  WHERE D_E_L_E_T_  = ''"
	_oSQL:_sQuery += "    AND ZA5_FILIAL  = '" + xfilial ("ZA5")   + "'"
	_oSQL:_sQuery += "    AND ZA5_DOC     = '" + se1 -> e1_num     + "'"
	_oSQL:_sQuery += "    AND ZA5_PREFIX  = '" + se1 -> e1_prefixo + "'"
	_oSQL:_sQuery += "    AND ZA5_PARC    = '" + se1 -> e1_parcela + "'"
	_oSQL:_sQuery += "    AND ZA5_TIPO    = '" + se1 -> e1_tipo    + "'"
	_oSQL:_sQuery += "    AND ZA5_SEQSE5  = '" + se5 -> e5_seq     + "'"
	//_oSQL:_sQuery += " 	AND ZA5_VLR      = " + cValToChar (se5 -> e5_vldesco)
	// nao posso usar o e5_data por que no za5 eh gravado com dDataBase --> _oSQL:_sQuery += " 	AND ZA5_DTA      = '" + dtos(se5 -> e5_data) + "'"
	_oSQL:Log ()
	_aVerbas := aclone (_oSQL:Qry2Array ())
	u_log ('registros encontrados no ZA5:', _aVerbas)

	for _nVerba = 1 to len (_aVerbas)
		// marca como excluido o lcto do ZA5
		_oSQL:_sQuery  = " " 
		_oSQL:_sQuery += " UPDATE " + RetSQLName ("ZA5")
		_oSQL:_sQuery += "    SET D_E_L_E_T_ = '*'" 
		_oSQL:_sQuery += "  WHERE D_E_L_E_T_ = ''" 
		_oSQL:_sQuery += "    AND ZA5_FILIAL = '" + xfilial ("ZA5")   + "'"
		_oSQL:_sQuery += "    AND ZA5_NUM    = '" + _aVerbas [_nVerba, 1]      + "'"
		_oSQL:_sQuery += "    AND ZA5_SEQSE5 = '" + se5 -> e5_seq              + "'"
		_oSQL:_sQuery += "    AND ZA5_SEQ    = '" + str (_aVerbas [_nVerba,2]) + "'"
		_oSQL:Log ()
		_oSQL:Exec ()
		
		// Atualiza status da verba.
		U_AtuZA4 (_aVerbas[1,1])
	next

	u_logFim ()
return
//
// --------------------------------------------------------------------------
// Estorna rapel
Static Function _AtuZC0()
	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	ZC0_RAPEL "
	_oSQL:_sQuery += " FROM ZC0010 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND ZC0_FILIAL = '"+ se1->e1_filial  +"' "
	_oSQL:_sQuery += " AND ZC0_CODCLI = '"+ se1->e1_cliente +"' "
	_oSQL:_sQuery += " AND ZC0_LOJCLI = '"+ se1->e1_loja    +"' "
	_oSQL:_sQuery += " AND ZC0_DOC    = '"+ se1->e1_num     +"' "
	_oSQL:_sQuery += " AND ZC0_SERIE  = '"+ se1->e1_prefixo +"' "
	_oSQL:_sQuery += " AND ZC0_PARCEL = '"+ se1->e1_parcela +"' "
	_oSQL:Log ()
	_aRapel := aclone (_oSQL:Qry2Array ())

	If len(_aRapel) > 0
		_oCtaRapel := ClsCtaRap():New ()

		_sRede := _oCtaRapel:BuscaRede(se1->e1_cliente, se1->e1_loja)

		_oCtaRapel:Filial  	 = se1->e1_filial
		_oCtaRapel:Rede      = _sRede	
		_oCtaRapel:LojaRed   = se1->e1_loja
		_oCtaRapel:Cliente 	 = se1->e1_cliente
		_oCtaRapel:LojaCli	 = se1->e1_loja
		_oCtaRapel:TM      	 = '05' 	
		_oCtaRapel:Data    	 = date()
		_oCtaRapel:Hora    	 = time()
		_oCtaRapel:Usuario 	 = cusername 
		_oCtaRapel:Histor  	 = 'Estorno de rapel por cancelamento de baixa de titulo' 
		_oCtaRapel:Documento = se1->e1_num
		_oCtaRapel:Serie 	 = se1->e1_prefixo
		_oCtaRapel:Parcela	 = se1->e1_parcela
		_oCtaRapel:Rapel	 = _aRapel[1,1]
		_oCtaRapel:Origem	 = procname()

		If _oCtaRapel:Grava (.F.)
			_oEvento := ClsEvent():New ()
			_oEvento:Alias     = 'ZC0'
			_oEvento:Texto     = "Estorno rapel "+ se1->e1_parcela + se1->e1_num + "/" + se1->e1_prefixo
			_oEvento:CodEven   = 'ZC0001'
			_oEvento:Cliente   = se1->e1_cliente
			_oEvento:LojaCli   = se1->e1_loja
			_oEvento:NFSaida   = se1->e1_num
			_oEvento:SerieSaid = se1->e1_prefixo
			_oEvento:Grava()
		EndIf
	EndIf
Return
