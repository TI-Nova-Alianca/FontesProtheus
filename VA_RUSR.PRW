// Programa...: VA_RUSR
// Autor......: Robert Koch
// Data.......: 18/01/2010
// Cliente....: Alianca
// Descricao..: Gera recibo recebimento de uva durante a safra (uso na balanca).
// Projeto....: Modulo safra
//
// Historico de alteracoes:
// 20/01/2013 - Robert - Ajustes para safra 2013.
//

// --------------------------------------------------------------------------
User Function va_rusR ()

	if sze -> ze_status == "1" .and. sze -> ze_aglutin != 'D'
		msgalert ("Falta segunda pesagem")
		return
	endif
	if sze -> ze_status == "C"
		msgalert ("Carga cancelada.")
		return
	endif
	if sze -> ze_coop == "000021"
		if ! msgnoyes ("Associados precisam gerar contranota. Confirma a impressao do recibo mesmo assim?")
			return
		endif
	endif

	cDesc1   := "Recibo de entrada de uva"
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SZE"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	Titulo   := cDesc1
	cPerg    := ""
	nomeprog := "VA_RUSR"
	wnrel    := "VA_RUSR"
	tamanho  := "P"
	limite   := 80
	nTipo    := 18
	m_pag    := 1
	li       := 80
	cCabec1  := ""
	cCabec2  := ""
	aOrd     := {}
	wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .T., NIL, tamanho, NIL, .F., NIL, NIL, .F., .T., NIL)
	If nLastKey == 27
		Return
	Endif
	delete file (__reldir + wnrel + ".##r")
	SetDefault (aReturn, cString)
	If nLastKey == 27
		Return
	Endif
	processa ({|| _Imprime ()})
	MS_FLUSH ()
	DbCommitAll ()
	If aReturn [5] == 1
		ourspool(wnrel)
	endif

	// Reaplica filtro no mbrowse.
//	Eval(_bFilBrwZE)
return



// --------------------------------------------------------------------------
static function _Imprime ()
	local _sNome   := ""
	local _sCPF    := ""
	local _sMun    := ""
	local _sEnd    := ""
	local _sCoop   := ""
	local _nMaxLin := 77
	local _sLinImp := ""
	local _oAssoc  := NIL

	li = _nMaxLin + 1
	procregua (3)

	// Encontra o cadastro do associado / fornecedor.
	if sze -> ze_coop $ "000021/001369"  // Alianca
		_oAssoc := ClsAssoc():New (sze -> ze_assoc, sze -> ze_lojasso)
		if ! _oAssoc:EhSocio ()
			u_help ("Fornecedor nao consta como associado!")
			return
		endif
		_sNome = _oAssoc:Nome
		_sCPF  = _oAssoc:CPF
		_sMun  = fBuscaCpo ("SA2", 1, xfilial ("SA2") + _oAssoc:Codigo + _oAssoc:Loja, 'A2_MUN')
		_sEnd  = fBuscaCpo ("SA2", 1, xfilial ("SA2") + _oAssoc:Codigo + _oAssoc:Loja, 'A2_END')
		_sCoop = sm0 -> m0_nomecom
	else
		szd -> (dbsetorder (3))  // ZD_FILIAL+ZD_FORNECE+ZD_LOJAFOR+ZD_COD+ZD_LOJA
		if szd -> (dbseek (xFilial ("SZD") + sze -> ze_coop + sze -> ze_lojcoop + sze -> ze_assoc + sze -> ze_lojasso, .F.))
			_sNome = sze -> ze_nomasso
			_sCPF  = szd -> zd_cpf
			_sMun  = szd -> zd_mun
			_sEnd  = szd -> zd_enderec
			_sCoop = fBuscaCpo ("SA2", 1, xfilial ("SA2") + sze -> ze_coop + sze -> ze_lojcoop, "A2_NOME")
		else
			sa2 -> (dbsetorder (1))
			if ! sa2 -> (dbseek (xFilial("SA2") + sze -> ze_assoc + sze -> ze_lojasso, .F.))
				msgalert ("Fornecedor nao cadastrado!")
				return
			else
				_sNome = sa2 -> a2_nome
				_sCPF  = sa2 -> a2_cgc
				_sMun  = sa2 -> a2_mun
				_sEnd  = sa2 -> a2_end
				_sCoop = ''
			endif
		endif
	endif

	
	// Nao puxa dados do SM0 por que, em caso de contingencia, vai ter que rodar em DBF com empresa teste.
	cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
	li ++
	@ li, 0 psay padc (alltrim (sm0 -> m0_nomecom), limite, " ")
	li ++
	@ li, 0 psay padc (Titulo + " - Carga " + sze -> ze_carga, limite, " ")
	li += 3
	@ li, 0 psay "NF produtor: " + sze -> ze_nfprod + "                                      " + dtoc (sze -> ze_data) + "   " + sze -> ze_hora
	li += 2
	@ li, 0 psay "Fornecedor...: " + _sNome + "  CPF: " + _sCPF
	li ++
	@ li, 0 psay "Endereco.....: " + _sEnd + "  " + _sMun
	li ++
	@ li, 0 psay "Coop.........: " + _sCoop
	li ++
	@ li, 0 psay "Placa veiculo: " + sze -> ze_placa
	li ++
	@ li, 0 psay "Peso bruto...: " + transform (sze -> ze_pesobru, "@E 999,999,999") + " Kg"
	li ++
	@ li, 0 psay "Peso tara....: " + transform (sze -> ze_pesotar, "@E 999,999,999") + " Kg"
	li ++
	@ li, 0 psay "Peso liquido.: " + transform (sze -> ze_pesobru - sze -> ze_pesotar, "@E 999,999,999") + " Kg"
	li += 2
	
	@ li, 0 psay "Produto                                          Embalagem        Peso Kg  Grau"
	li ++
	@ li, 0 psay "-------------------------------------------------------------------------------"
	li ++
	szf -> (dbsetorder (1))  // filial + safra + carga + item
	szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
	do while ! szf -> (eof ()) ;
		.and. szf -> zf_filial == xfilial ("SZF") ;
		.and. szf -> zf_safra  == sze -> ze_safra ;
		.and. szf -> zf_carga  == sze -> ze_carga
		if li > _nMaxLin
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		_sLinImp := U_TamFixo (alltrim (szf -> zf_produto) + " - " + fBuscaCpo ("SB1", 1, xfilial ("SB1") + szf -> zf_produto, "B1_DESC"), 45) + " "
		_sLinImp += transform (szf -> zf_qtembal, "@E 9,999") + " "
		_sLinImp += szf -> zf_embalag + " "
		_sLinImp += transform (szf -> zf_peso, "@E 999,999.99") + "   "
		_sLinImp += szf -> zf_grau
		@ li, 0 psay _sLinImp
		li ++
		szf -> (dbskip ())
	enddo
	
	// Marca como 'recibo impresso'
	reclock ("SZE", .F.)
	sze -> ze_status = "R"
	msunlock ()
	
return
