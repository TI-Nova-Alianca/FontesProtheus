// Programa:   AjBasTes
// Autor:      Robert Koch
// Data:       18/06/2012 (original: VA_ATF2.prw de 23/11/2011)
// Descricao:  Verifica necessidade de ajustar parametros quando atualiza a base teste
//             Criado com base na funcao CheckSeque de Wilson Godoy / Rodrigo
//             Util para ajustar a base teste apos copia de dados da quente.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Verifica necessidade de ajustar parametros quando atualiza a base teste
// #PalavasChave      #atualizacao_de_base #base_teste
// #TabelasPrincipais #SM0
// #Modulos 		  #todos 
//
// Historico de alteracoes:
// 17/07/2018 - Robert  - Atualiza parametros de NF-e e NFC-e
// 05/06/2019 - Robert  - Atualiza tabelas SPED050, SPED150 e TSSTR1
// 11/11/2019 - Robert  - Atualiza sequencial do SC5.
// 09/06/2020 - Robert  - Passa a executar todas as empresas/filiais no mesmo loop.
// 14/08/2020 - Cláudia - retirado parametros e looping conforme solicitação da verção 25. GLPI: 7339
//
//
// -------------------------------------------------------------------------------------------------
user function AjBasTes ()
	Local cNext
	Local aAreaSD1
	Local aAreaSD2
	Local aAreaSD3
	Local cNum,cGreat := Space(Len(Criavar("D1_NUMSEQ")))
	Local cAlias      := Alias()
	local lxProxNum   := NIL
	local _oSQL       := NIL
	local _oClsNFe    := NIL
	local _sSeqC5     := ""
	local _mv_docseq  := GetMv ('MV_DOCSEQ')
	local _mv_spedurl := GetMv ('MV_SPEDURL')
	local _mv_nfceurl := GetMv ('MV_NFCEURL')
	local _mv_tafsurl := GetMv ('MV_TAFSURL')
	local _mv_nfcetok := GetMv ('MV_NFCETOK')
	local _mv_nfceidt := GetMv ('MV_NFCEIDT')

	if ! U_MsgNoYes ('ATENCAO: Este programa ajusta varios parametros para serem usados em ambiente de teste/homologacao. Foi criado para ser executado NA BASE TESTE depois que a mesma foi atualizada com os dados da quente. Confirma?')
		return
	endif
	if ! "TESTE" $ upper (GetEnvServer ())
		if ! U_MsgNoYes ('Este ambiente NAO PARECE SER DA BASE TESTE. Confirma a execucao assim mesmo?')
			return
		endif
	endif	

	u_log2 ('info', '-----------------------------------------------------')
	u_log2 ('info', 'Ajustando parametros diversos para adequar base teste')
	
	IF lxProxNum == Nil
		lxProxNum := ExistBlock("XPROXNUM")
	Endif
	IF lxProxNum
		__lNoErro := .t.
		Return Nil
	Endif

	chkfile ("SD1")
	chkfile ("SD2")
	chkfile ("SD3")
	
	sm0 -> (dbgotop ())

	do while ! sm0 -> (eof ())
		cEmpAnt = sm0 -> m0_codigo
		cFilAnt = sm0 -> m0_codfil
		IF Select("SD1") > 0
			dbSelectArea("SD1")
			aAreaSD1 := GetArea()
			dbSetOrder(4)
			dbSeek(cFilAnt+"zzzzzz",.T.)
			dbSkip(-1)
			IF D1_FILIAL == cFilAnt
				cNum := D1_NUMSEQ
			Else
				cNum := Space(Len(D1_NUMSEQ))
			Endif
			IF cNum > cGreat
				cGreat := cNum
			Endif
			RestArea(aAreaSD1)
		Endif
		IF Select("SD2") > 0
			dbSelectArea("SD2")
			aAreaSD2 := GetArea()
			dbSetOrder(4)
			dbSeek(cFilAnt+"zzzzzz",.T.)
			dbSkip(-1)
			IF D2_FILIAL == cFilAnt
				cNum := D2_NUMSEQ
			Else
				cNum := Space(Len(D2_NUMSEQ))
			Endif
			IF cNum > cGreat
				cGreat := cNum
			Endif
			RestArea(aAreaSD2)
		Endif
		IF Select("SD3") > 0
			dbSelectArea("SD3")
			aAreaSD3 := GetArea()
			dbSetOrder(4)
			dbSeek(cFilAnt+"zzzzzz",.T.)
			dbSkip(-1)
			IF D3_FILIAL == cFilAnt
				cNum := D3_NUMSEQ
			Else
				cNum := Space(Len(D3_NUMSEQ))
			Endif
			IF cNum > cGreat
				cGreat := cNum
			Endif
			RestArea(aAreaSD3)
		Endif
	
		cNext := ProxNum(.f.)
		
		IF cGreat >= cNext
			u_log2 ('info', 'Alterando MV_DOCSEQ (conteudo anterior: ' + alltrim (_mv_docseq) + ') para ' + cGreat)
			PutMv ("MV_DOCSEQ", cGreat)
		Endif

		u_log2 ('info', 'Alterando MV_SPEDURL (conteudo anterior: ' + alltrim (_mv_spedurl) + ')')
		PutMv ('MV_SPEDURL', 'HTTP://192.168.1.3:8073')

		u_log2 ('info', 'Alterando MV_NFCEURL (conteudo anterior: ' + alltrim (_mv_nfceurl) + ')')
		PutMv ('MV_NFCEURL', 'HTTP://192.168.1.3:8073')

		u_log2 ('info', 'Alterando MV_TAFSURL (conteudo anterior: ' + alltrim (_mv_tafsurl) + ')')
		PutMv ('MV_TAFSURL', 'HTTP://192.168.1.3:8073')

		u_log2 ('info', 'Alterando MV_NFCETOK (conteudo anterior: ' + alltrim (_mv_nfcetok) + ')')
		PutMv ('MV_NFCETOK', '5C69E546-0126-462A-9277-45F205EA4503')

		u_log2 ('info', 'Alterando MV_NFCEIDT (conteudo anterior: ' + alltrim (_mv_nfceidt) + ')')
		PutMv ('MV_NFCEIDT', '000002')

		// Muda NFe e NFCe para 'homologacao'
		_oClsNFe := ClsNFe ():New ()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "UPDATE SPED000 SET CONTEUDO='2' WHERE D_E_L_E_T_ = '' AND PARAMETRO IN ('MV_AMBIENT', 'MV_AMBCCE', 'MV_AMBMDFE', 'MV_AMBNFCE') AND ID_ENT = '" + _oClsNFe:GetEntid () + "'"
		_oSQL:Log ()
		_oSQL:Exec ()

		// Ajusta qualquer NF/cupom pendente nas tabelas SPED/TSS para evitar que o TSS fique tentando retransmitir.
		_oClsNFe := ClsNFe ():New ()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "UPDATE SPED050 SET STATUS = 5 WHERE STATUS in (1, 2, 4)"
		_oSQL:Log ()
		_oSQL:Exec ()
		_oSQL:_sQuery := "UPDATE SPED050 SET STATUSCANC = 2 WHERE STATUSCANC = 1"
		_oSQL:Log ()
		_oSQL:Exec ()
		_oSQL:_sQuery := "UPDATE SPED050 SET STATUSMAIL = 3 WHERE STATUS = 6 AND STATUSMAIL = 0"
		_oSQL:Log ()
		_oSQL:Exec ()
		_oSQL:_sQuery := "UPDATE SPED050 SET STATUSMAIL = 3 WHERE STATUSMAIL = 1"
		_oSQL:Log ()
		_oSQL:Exec ()
		_oSQL:_sQuery := "UPDATE SPED150 SET STATUS = 5 WHERE STATUS in (1, 2, 4)"
		_oSQL:Log ()
		_oSQL:Exec ()
		_oSQL:_sQuery := "UPDATE SPED150 SET STATUSMAIL = 3 WHERE STATUSMAIL = 1"
		_oSQL:Log ()
		_oSQL:Exec ()
		_oSQL:_sQuery := "UPDATE TSSTR1 SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
		_oSQL:Log ()
		_oSQL:Exec ()

		// Deixa somente os batches aptos a rodar na base teste (pode ocorrer de termos um RPO no servico batch da teste que nao desconsidere esse campo)
		_oSQL:_sQuery := "UPDATE " + RetSQLName ("ZZ6")"
		_oSQL:_sQuery += " SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
		_oSQL:_sQuery += " WHERE ZZ6_AMBTST != 'S'"
		_oSQL:Log ()
		_oSQL:Exec ()

		// Ajusta sequencial do C5_NUM (na verdade teria que ver se voltamos a usar o inicializador padrao do sistema...)
		u_log2 ('info', 'Ajustando sequencial SC5')
		//_sSeqC5 := getmv ("VA_INIC5NU", .t., '000000')
		_sSeqC5 := _UseGetMv("VA_INIC5NU", .t., '000000')
		_sSeqC5 = iif (empty (_sSeqC5), '', _sSeqC5)

		sc5 -> (dbsetorder (1))
		do while sc5 -> (dbseek (cFilAnt + _sSeqC5, .F.))
			_sSeqC5 = soma1 (_sSeqC5)
		enddo
		//putmv ("VA_INIC5NU", _sSeqC5)
		_UsePutMv("VA_INIC5NU", _sSeqC5)
		u_log2 ('info', 'Sequencial SC5 ajustado para ' + _sSeqC5)

		sm0 -> (dbskip ())
	enddo

	IF !Empty(cAlias)
		dbSelectArea(cAlias)
	Endif

	U_ShowLog ()
Return Nil
//
// ----------------------------------------------------------------------------
// GetMV
Static Function _UseGetMv(cMv_par, lConsulta, xDefault)
	_Valor := getmv(cMv_par, lConsulta, xDefault)
Return _Valor
//
// ----------------------------------------------------------------------------
// PutMv
Static Function _UsePutMv(cMv_par, _valor)
	putmv(cMv_par, _valor)
Return 
