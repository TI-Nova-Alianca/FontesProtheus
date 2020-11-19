// Programa:   VA_RPS
// Autor:      Robert Koch (royalties para Jose Vergani ref. formatacao de impressao)
// Data:       05/01/2009 (inicio) a 14/12/2009 (versao inicial)
// Cliente:    Alianca
// Descricao:  Impressao grafica do recibo de pagamento de salarios.
//
// Historico de alteracoes:
// 26/03/2010 - Robert - Nao considera mais o campo RA_SITFOLH.
// 03/08/2010 - Robert - Ajustes impressao em mais de um recibo (muitas verbas).
//                     - Criada opcao de imprimir 2 recibos por folha.
// 06/12/2010 - Robert - Quando tinha 18 lctos a imprimir, perdia o 18o.
// 21/11/2012 - Robert - Passa a buscar 'data de pagamento' apenas quando a verba representar um provento.
// 16/07/2014 - Catia  - Buscar 'data de pagamento' na maior data referente a uma verba um provento.
//

#include "colors.ch"

// --------------------------------------------------------------------------
user function VA_RPS ()
	Local cCadastro := "Impressao de recibos de pagamento de salario"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	//private _sArqLog := U_NomeLog ()
	//u_logID ()

	Private cPerg   := "VA_RPS"
	_ValidPerg()
	Pergunte(cPerg,.F.)      // Pergunta no SX1

	AADD(aSays, "Este programa tem como objetivo imprimir recibos de pagamento")
	AADD(aSays, "de salarios em formato grafico.")
	AADD(aSays, "")
	AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
	AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
	AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
	
	FormBatch( cCadastro, aSays, aButtons )
	
	If nOpca == 1
		Processa( { |lEnd| _Gera() } )
	endif
return



// --------------------------------------------------------------------------
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _nVia      := 0
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _aCodFol   := {}
	local _cNroHoras := &("{ || If(SRC->RC_QTDSEM > 0, SRC->RC_QTDSEM, SRC->RC_HORAS) }")
	local _aCodBenef := {}
	local aOrdBag    := {}
	local cMesArqRef := ""
	local cArqMov    := ""
	local cAliasMov  := ""
	local _dDatPag   := ctod ("")
	local _aInfo     := {}
	private _oPrn    := NIL
	Private _aLanca  := {}
	Private _aProve  := {}
	Private _aDesco  := {}
	Private _aBases  := {}
	private _oCour8N   := TFont():New("Courier New",,8,,.T.,,,,,.F.)
	private _oCour10   := TFont():New("Courier New",,10,,.F.,,,,,.F.)
	private _oCour10N  := TFont():New("Courier New",,10,,.T.,,,,,.F.)
	private _oCour12   := TFont():New("Courier New",,12,,.F.,,,,,.F.)
	private _oCour12N  := TFont():New("Courier New",,12,,.T.,,,,,.F.)
	private _oCour14N  := TFont():New("Courier New",,14,,.T.,,,,,.F.)
	private _oCour16N  := TFont():New("Courier New",,16,,.T.,,,,,.F.)
	private _oArial7   := TFont():New("Arial",,7,,.F.,,,,,.F.)
	private _oArial8   := TFont():New("Arial",,8,,.F.,,,,,.F.)
	private _oArial8N  := TFont():New("Arial",,8,,.T.,,,,,.F.)
	private _oArial10N := TFont():New("Arial",,10,,.T.,,,,,.F.)
	private _oArial10  := TFont():New("Arial",,10,,.F.,,,,,.F.)
	private _oArial16N := TFont():New("Arial",,16,,.T.,,,,,.F.)
	private _sPosPag   := "S"  // Controla posicionamento na pagina: [S]uperior ou [I]nferior (2 recibos por folha A4).

	// Seleciona arquivo de origem (meses anteriores sao lidos dos arquivos 'RC' e nao do 'SRC' normal).
	cMesAnoRef := StrZero(Month(mv_par01),2) + StrZero(Year(mv_par01),4)
	If mv_par07 == 4
		cMesArqRef := "13" + Right(cMesAnoRef,4)
	Else
		cMesArqRef := cMesAnoRef
	Endif
	If !OpenSrc( cMesArqRef, @cAliasMov, @aOrdBag, @cArqMov, @mv_par01 , NIL , .F. )
		Return
	Endif

	// Inicializa objeto para impressao
	_oPrn:=TMSPrinter():New(" Relatorio de Pagamento de Salario ")
	_oPrn:Setup()            // Impressora Padrão
	_oPrn:SetPortrait()

	//u_logsx1 ()

	// Busca funcionarios para impressao
	_sQuery := ""
	_sQuery += " SELECT SRA.RA_FILIAL, SRA.RA_MAT, SRA.RA_NOME, SRA.RA_BCDEPSA, SRA.RA_CTDEPSA, CTT_DESC01, SRA.RA_SALARIO, SRJ.RJ_DESC, RA_PIS, RA_CC "
	_sQuery += "   FROM "+RETSQLName("SRJ")+" SRJ, "
	_sQuery += "        "+RETSQLName("SRA")+" SRA, "
	_sQuery += "        "+RETSQLName("CTT")+" CTT "
	_sQuery += "  WHERE SRJ.D_E_L_E_T_ = ' ' "
	_sQuery += "    AND SRJ.RJ_FILIAL  = '"+xFilial("SRJ")+"' "
	_sQuery += "    AND SRA.D_E_L_E_T_ = ' ' "
	_sQuery += "    AND SRA.RA_FILIAL  = '"+xFilial("SRA")+"'"
	_sQuery += "    AND CTT.D_E_L_E_T_ = ' ' "
	_sQuery += "    AND CTT.CTT_FILIAL = '"+xFilial("CTT")+"'"
	_sQuery += "    AND SRA.RA_MAT BETWEEN '"+mv_par02+"' AND '"+mv_par03+"' "
	_sQuery += "    AND SRA.RA_CC  BETWEEN '"+mv_par04+"' AND '"+mv_par05+"' "
	_sQuery += "    AND SRJ.RJ_FUNCAO  = SRA.RA_CODFUNC "
	_sQuery += "    AND CTT.CTT_CUSTO  = SRA.RA_CC "
	_sQuery += " ORDER BY SRA.RA_NOME "
	// u_log (_squery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.T., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .F., .T.)
	(_sAliasQ) -> (DbGoTop())
	Do While ! (_sAliasQ) -> (Eof())
		// u_log ("Mat:", (_saliasq) -> ra_mat)

		If ! Fp_CodFol(@_aCodFol,Sra->Ra_Filial) .Or. ! fInfo(@_aInfo,Sra->Ra_Filial)
			//u_log ("Nao passou no teste inicial")
			(_sAliasQ) -> (dbskip ())
			loop
		Endif

		// Leitura dos dados conforme o tipo de folha a imprimir
		_nTotVenc := _nTotDesc := _nHoras := _nBaseIr := _nAteLim := _nBaseFgts := _nFgts := _nBaseINSS := _nBaseIrFe := 0
		_aLanca = {}
		If mv_par07 == 1 .OR. mv_par07 == 2  // Adiantamento ou folha
			dbSelectArea("SRC")
			dbSetOrder(1)
			If dbSeek((_sAliasQ)->RA_FILIAL + (_sAliasQ)->RA_MAT)
				While !Eof() .And. SRC->RC_FILIAL+SRC->RC_MAT == (_sAliasQ)->RA_FILIAL+(_sAliasQ)->RA_MAT
					If SRC->RC_SEMANA # mv_par06
						dbSkip()
						Loop
					Endif
					if fBuscaCpo ("SRV", 1, xfilial ("SRV") + src -> rc_pd, "RV_TIPOCOD") == '1'
						if src -> rc_data > _dDatPag
						   _dDatPag = src -> rc_data
						endif   
					endif
					If (mv_par07 == 1) .And. (Src->Rc_Pd == _aCodFol[7,1])      // Desconto de Adto
						_SomaPdRec("P",_aCodFol[6,1],Eval(_cNroHoras),SRC->RC_VALOR)
						_nTotVenc += Src->Rc_Valor
					Elseif (mv_par07 == 1) .And. (Src->Rc_Pd == _aCodFol[12,1])
						_SomaPdRec("D",_aCodFol[9,1],Eval(_cNroHoras),SRC->RC_VALOR)
						_nTotDesc += SRC->RC_VALOR
					Elseif (mv_par07 == 1) .And. (Src->Rc_Pd == _aCodFol[8,1])
						_SomaPdRec("P",_aCodFol[8,1],Eval(_cNroHoras),SRC->RC_VALOR)
						_nTotVenc += SRC->RC_VALOR
					Else
						If PosSrv( Src->Rc_Pd , (_sAliasQ)->RA_FILIAL , "RV_TIPOCOD" ) == "1"
							If (mv_par07 # 1) .Or. (mv_par07 == 1 .And. SRV->RV_ADIANTA == "S")
								_nHoras := Eval(_cNroHoras)
								_SomaPdRec("P",SRC->RC_PD,_nHoras,SRC->RC_VALOR)
								_nTotVenc += Src->Rc_Valor
							Endif
						Elseif SRV->RV_TIPOCOD == "2"
							If (mv_par07 # 1) .Or. (mv_par07 == 1 .And. SRV->RV_ADIANTA == "S")
								_SomaPdRec("D",SRC->RC_PD,Eval(_cNroHoras),SRC->RC_VALOR)
								_nTotDesc += Src->Rc_Valor
							Endif
						Elseif SRV->RV_TIPOCOD == "3"
							If (mv_par07 # 1) .Or. (mv_par07 == 1 .And. SRV->RV_ADIANTA == "S")
								_SomaPdRec("B",SRC->RC_PD,Eval(_cNroHoras),SRC->RC_VALOR)
							Endif
						Endif
					Endif
					If mv_par07 = 1
						If SRC->RC_PD == _aCodFol[10,1]
							_nBaseIR := SRC->RC_VALOR
						Endif
					ElseIf SRC->RC_PD == _aCodFol[13,1]
						_nAteLim += SRC->RC_VALOR
					Elseif SRC->RC_PD$ _aCodFol[108,1]+'*'+_aCodFol[17,1]
						_nBaseFgts += SRC->RC_VALOR
					Elseif SRC->RC_PD$ _aCodFol[109,1]+'*'+_aCodFol[18,1]
						_nFgts += SRC->RC_VALOR
					Elseif SRC->RC_PD == _aCodFol[15,1]
						_nBaseIr += SRC->RC_VALOR
					Elseif SRC->RC_PD == _aCodFol[16,1]
						_nBaseIrFe += SRC->RC_VALOR
					Endif

					if src -> rc_pd == _aCodFol [13, 1] .or. src -> rc_pd == _aCodFol [221, 1]  // 13=nao prolabore; 221=prolabore
						_nBaseINSS += src -> rc_valor
					endif

					dbSelectArea("SRC")
					dbSkip()
				Enddo
			Endif
		Elseif mv_par07 == 3  // 1a. parcela 13o. salario
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Busca os codigos de pensao definidos no cadastro beneficiario³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			fBusCadBenef(@_aCodBenef, "131",{_aCodFol[172,1]})
			dbSelectArea("SRC")
			dbSetOrder(1)
			If dbSeek((_sAliasQ)->RA_FILIAL + (_sAliasQ)->RA_MAT)
				While !Eof() .And. (_sAliasQ)->RA_FILIAL + (_sAliasQ)->RA_MAT == SRC->RC_FILIAL + SRC->RC_MAT
					if fBuscaCpo ("SRV", 1, xfilial ("SRV") + src -> rc_pd, "RV_TIPOCOD") == '1'
						if src -> rc_data > _dDatPag
						   _dDatPag = src -> rc_data
						endif
					endif
					If SRC->RC_PD == _aCodFol[22,1]
						_SomaPdRec("P",SRC->RC_PD,Eval(_cNroHoras),SRC->RC_VALOR)
						_nTotVenc += SRC->RC_VALOR
					Elseif Ascan(_aCodBenef, { |x| x[1] == SRC->RC_PD }) > 0
						_SomaPdRec("D",SRC->RC_PD,Eval(_cNroHoras),SRC->RC_VALOR)
						_nTotDesc += SRC->RC_VALOR
					Elseif SRC->RC_PD == _aCodFol[108,1] .Or. SRC->RC_PD == _aCodFol[109,1] .Or. SRC->RC_PD == _aCodFol[173,1]
						_SomaPdRec("B",SRC->RC_PD,Eval(_cNroHoras),SRC->RC_VALOR)
					Endif
					If SRC->RC_PD == _aCodFol[108,1]
						_nBaseFgts := SRC->RC_VALOR
					Elseif SRC->RC_PD == _aCodFol[109,1]
						_nFgts     := SRC->RC_VALOR
					Endif
					dbSelectArea("SRC")
					dbSkip()
				Enddo
			Endif
		Elseif mv_par07 == 4  // 2a. parcela 13o. salario
			dbSelectArea("SRI")
			dbSetOrder(2)
			If dbSeek((_sAliasQ)->RA_FILIAL + (_sAliasQ)->RA_CC + (_sAliasQ)->RA_MAT)
				While !Eof() .And. (_sAliasQ)->RA_FILIAL + (_sAliasQ)->RA_CC + (_sAliasQ)->RA_MAT == SRI->RI_FILIAL + SRI->RI_CC + SRI->RI_MAT
					if fBuscaCpo ("SRV", 1, xfilial ("SRV") + sri -> ri_pd, "RV_TIPOCOD") == '1'
						if sri -> ri_data > _dDatPag
                        _dDatPag = sri -> ri_data
						endif
					endif
					If PosSrv( SRI->RI_PD , (_sAliasQ)->RA_FILIAL , "RV_TIPOCOD" ) == "1"
						_SomaPdRec("P",SRI->RI_PD,SRI->RI_HORAS,SRI->RI_VALOR)
						_nTotVenc = _nTotVenc + SRI->RI_VALOR
					Elseif SRV->RV_TIPOCOD == "2"
						_SomaPdRec("D",SRI->RI_PD,SRI->RI_HORAS,SRI->RI_VALOR)
						_nTotDesc = _nTotDesc + SRI->RI_VALOR
					Elseif SRV->RV_TIPOCOD == "3"
						_SomaPdRec("B",SRI->RI_PD,SRI->RI_HORAS,SRI->RI_VALOR)
					Endif
					If SRI->RI_PD == _aCodFol[19,1]
						_nAteLim += SRI->RI_VALOR
					Elseif SRI->RI_PD$ _aCodFol[108,1]
						_nBaseFgts += SRI->RI_VALOR
					Elseif SRI->RI_PD$ _aCodFol[109,1]
						_nFgts += SRI->RI_VALOR
					Elseif SRI->RI_PD == _aCodFol[27,1]
						_nBaseIr += SRI->RI_VALOR
					Endif

					if src -> rc_pd == _aCodFol [13, 1] .or. src -> rc_pd == _aCodFol [221, 1]  // 13=nao prolabore; 221=prolabore
						_nBaseINSS += src -> rc_valor
					endif

					dbSkip()
				Enddo
			Endif
		Elseif mv_par07 == 5  // Valores extras
			dbSelectArea("SR1")
			dbSetOrder(1)
			If dbSeek( (_sAliasQ)->RA_FILIAL + (_sAliasQ)->RA_MAT )
				While !Eof() .And. (_sAliasQ)->RA_FILIAL + (_sAliasQ)->RA_MAT ==	SR1->R1_FILIAL + SR1->R1_MAT
					If mv_par06 # "99"
						If SR1->R1_SEMANA # mv_par06
							dbSkip()
							Loop
						Endif
					Endif
					if fBuscaCpo ("SRV", 1, xfilial ("SRV") + sr1 -> r1_pd, "RV_TIPOCOD") == '1'
						if sr1 -> r1_data > _dDatPag
                        _dDatPag = sr1 -> r1_data
                     endif   
					endif
					If PosSrv( SR1->R1_PD , (_sAliasQ)->RA_FILIAL , "RV_TIPOCOD" ) == "1"
						_SomaPdRec("P",SR1->R1_PD,SR1->R1_HORAS,SR1->R1_VALOR)
						_nTotVenc = _nTotVenc + SR1->R1_VALOR
					Elseif SRV->RV_TIPOCOD == "2"
						_SomaPdRec("D",SR1->R1_PD,SR1->R1_HORAS,SR1->R1_VALOR)
						_nTotDesc = _nTotDesc + SR1->R1_VALOR
					Elseif SRV->RV_TIPOCOD == "3"
						_SomaPdRec("B",SR1->R1_PD,SR1->R1_HORAS,SR1->R1_VALOR)
					Endif

					if src -> rc_pd == _aCodFol [13, 1] .or. src -> rc_pd == _aCodFol [221, 1]  // 13=nao prolabore; 221=prolabore
						_nBaseINSS += src -> rc_valor
					endif

					dbskip()
				Enddo
			Endif
		Endif
		
		// u_log ("alanca:",_aLanca)

		if len (_aLanca) > 0
			for _nVia = 1 to mv_par08
				// u_logIni ("Via " + cvaltochar (_nVia))
				_Imprime (_aLanca, 1, _nTotVenc, _nTotDesc, _nBaseFgts, _nFgts, _nBaseIr, _sAliasQ, _nBaseINSS, _dDatPag)
				// u_logFim ("Via " + cvaltochar (_nVia))
			next
		endif

		(_sAliasQ) -> (Dbskip())
	enddo
	(_sAliasQ) -> (Dbclosearea())
	dbselectarea ("SRA")

	// Caso tenha sido usado um arquivo 'RC', retorna arquivo default do sistema.
	If !Empty( cAliasMov )
		fFimArqMov( cAliasMov , aOrdBag , cArqMov )
	EndIf

	_oPrn:Preview ()
	_oPrn:End()
return



// --------------------------------------------------------------------------
// Somar as Verbas no Array
static Function _SomaPdRec(cTipo,cPd,_nHoras,nValor)
	Local Desc_paga
	Desc_paga := DescPd(cPd,Sra->Ra_Filial)  // mostra como pagto
	If cTipo # 'B'
		//--Array para Recibo Pre-Impresso
		nPos := Ascan(_aLanca,{ |X| X[2] = cPd })
		If nPos == 0
			Aadd(_aLanca,{cTipo,cPd,Desc_Paga,_nHoras,nValor})
		Else
			_aLanca[nPos,4] += _nHoras
			_aLanca[nPos,5] += nValor
		Endif
	Endif
Return



// --------------------------------------------------------------------------
Static Function _Imprime (_aVerbas, _nVerbaIni, _nTotVenc, _nTotDesc, _nBaseFgts, _nFgts, _nBaseIr, _sAliasQ, _nBaseINSS, _dDatPag)
	//local _nPagAtual := 1
	//local _nLinAtual := 0
	local _nMargSup  := 40
	//local _nMargInf  := 50
	local _nMargEsq  := 40
	local _nAltPag   := 1400
	local _nLargPag  := 2350
	local _nVerba    := 0
	local _oBrush    := TBrush():New( , CLR_HGRAY )
	local _nLinha	 := 0

		// Inicia nova pagina caso deva posicionar na parte superior
	//, ou o usuario tenha selecionado um recibo por folha.
	if _sPosPag == "S" // .or. mv_par09 == 1
		_oPrn:StartPage ()
	endif

	// Box em toda a folha soh pra conferencia.
	//_oPrn:Box(0, 0, 3100, 2350)

	// Redefine margem superior a cada impressao, pois sao feitas duas
	// impressoes por folha A4.
	//_nMargSup = iif (_sPosPag == "S", 40, _nAltPag + 150)
	_nMargSup = iif (_sPosPag == "S", 50, _nAltPag + 330)

	// Monta uma caixa em torno de todo o recibo.
	_oPrn:Box(_nMargSup + 20, _nMargEsq + 20, _nMargSup + _nAltPag + 50, _nLargPag - _nMargEsq)
	
	// Cabecalho
	_oPrn:Say (_nMargSup + 40,  _nMargEsq + 40, left (sm0 -> m0_nomecom, 55), _oCour10N, 100)
	_oPrn:Say (_nMargSup + 80,  _nMargEsq + 40, left ("Setor: " + (_sAliasQ) -> CTT_DESC01, 55), _oCour10, 100)
	_oPrn:Say (_nMargSup + 120, _nMargEsq + 40, left (transform (sm0 -> m0_cgc, "@R 99.999.999/9999-99") + "   " + alltrim (sm0 -> m0_cidcob) + "-" + sm0 -> m0_estcob, 55), _oCour10, 100)
	
	_oPrn:Say (_nMargSup + 50,  _nMargEsq + 1300, "Recibo de Pagamento de Salário", _oArial16N, 100)
	_oPrn:Say (_nMargSup + 120, _nMargEsq + 1990, mesextenso (mv_par01) + "/" + strzero (year (mv_par01), 4), _oArial10, 100)
	
	// Identificacao do funcionario, com moldura
	_oPrn:Box(_nMargSup + 190, _nMargEsq + 40, _nMargSup + 290, _nLargPag - _nMargEsq - 20)
	_oPrn:Say (_nMargSup + 200,  _nMargEsq + 50,   "Matrícula", _oArial8, 100)
	_oPrn:Say (_nMargSup + 200,  _nMargEsq + 250,  "Nome do funcionário", _oArial8, 100)
	_oPrn:Say (_nMargSup + 200,  _nMargEsq + 1250, "Função", _oArial8, 100)
	_oPrn:Say (_nMargSup + 200,  _nMargEsq + 2150, "Filial", _oArial8, 100)
	_oPrn:Say (_nMargSup + 240,  _nMargEsq + 50, (_sAliasQ) -> ra_mat, _oCour12N, 100)
	_oPrn:Say (_nMargSup + 240,  _nMargEsq + 250, padr (left ((_sAliasQ) -> ra_nome, 30), 40, " "), _oCour12N, 100)
	_oPrn:Say (_nMargSup + 240,  _nMargEsq + 1250, left ((_sAliasQ) -> RJ_DESC, 34), _oCour12, 100)
	_oPrn:Say (_nMargSup + 240,  _nMargEsq + 2150, (_sAliasQ) -> ra_filial, _oCour12N, 100)


	// Impressao dos dados das verbas
	_oPrn:Say (_nMargSup + 315,  _nMargEsq + 50, "Código", _oArial8, 100)
	_oPrn:Say (_nMargSup + 315,  _nMargEsq + 250, "Descricao", _oArial8, 100)
	_oPrn:Say (_nMargSup + 315,  _nMargEsq + 1280, "Referência", _oArial8, 100)
	_oPrn:Say (_nMargSup + 315,  _nMargEsq + 1670, "Vencimentos", _oArial8, 100)
	_oPrn:Say (_nMargSup + 315,  _nMargEsq + 2100, "Descontos", _oArial8, 100)

	_nLinVerba = 310
	_nVerba = 0
	for _nLinha = 1 to 17
		// u_log ("Iniciando while com _nLinha = ", _nLinha, "e _nVerbaIni=",_nverbaini)

		// Linha para separar a proxima verba
		if _nLinha % 2 == 0
			_oPrn:FillRect ({_nMargSup + _nLinVerba + _nLinha * 40 - 1, _nMargEsq + 40, _nMargSup + _nLinVerba + (_nLinha + 1) * 40, _nMargEsq + 2250}, _oBrush)
		endif

		// Se ainda tem verbas a imprimir...
		if _nVerbaIni <= len (_aVerbas)
			// u_log ("imprimindo verba", _nVerbaIni)
			_oPrn:Say (_nMargSup + _nLinVerba + _nLinha * 40,  _nMargEsq + 50,   _aVerbas [_nVerbaIni, 2], _oCour12, 100)
			_oPrn:Say (_nMargSup + _nLinVerba + _nLinha * 40,  _nMargEsq + 250,  _aVerbas [_nVerbaIni, 3], _oCour12, 100)
			_oPrn:Say (_nMargSup + _nLinVerba + _nLinha * 40,  _nMargEsq + 1065, transform (_aVerbas [_nVerbaIni, 4], "999,999,999.99"), _oCour12, 100)
			if _aVerbas [_nVerbaIni, 1] == "P"
				_oPrn:Say (_nMargSup + _nLinVerba + _nLinha * 40,  _nMargEsq + 1480, transform (_aVerbas [_nVerbaIni, 5], "999,999,999.99"), _oCour12, 100)
			else
				_oPrn:Say (_nMargSup + _nLinVerba + _nLinha * 40,  _nMargEsq + 1880, transform (_aVerbas [_nVerbaIni, 5], "999,999,999.99"), _oCour12, 100)
			endif
			
		else  // Nao tem mais verbas a imprimir. Preenche as demais linhas com asteriscos.
			// u_log ("gerando asterisco para linha ", _nLinha)
			_oPrn:Say (_nMargSup + _nLinVerba + _nLinha * 40,  _nMargEsq + 250,  space (_nLinha) + "*", _oCour12, 100)
		endif

		_nVerbaIni ++
	next
	
	// Linhas verticais para separar as verbas em colunas
	_oPrn:Line (_nMargSup + 350, _nMargEsq + 230,  _nMargSup + _nAltPag - 330, _nMargEsq + 230)
	_oPrn:Line (_nMargSup + 350, _nMargEsq + 1050, _nMargSup + _nAltPag - 330, _nMargEsq + 1050)
	_oPrn:Line (_nMargSup + 350, _nMargEsq + 1450, _nMargSup + _nAltPag - 330, _nMargEsq + 1450)
	_oPrn:Line (_nMargSup + 350, _nMargEsq + 1850, _nMargSup + _nAltPag - 330, _nMargEsq + 1850)

	// Linha para encerramento da impressao das verbas.
	_oPrn:Line (_nMargSup + _nAltPag - 320, _nMargEsq + 40, _nMargSup + _nAltPag - 320, _nMargEsq + 2250)
	_oPrn:Line (_nMargSup + _nAltPag - 319, _nMargEsq + 40, _nMargSup + _nAltPag - 319, _nMargEsq + 2250)
	_oPrn:Line (_nMargSup + _nAltPag - 318, _nMargEsq + 40, _nMargSup + _nAltPag - 318, _nMargEsq + 2250)
	
	// Caixas para os valores de bases
	_oPrn:Line (_nMargSup + _nAltPag - 170, _nMargEsq + 40,   _nMargSup + _nAltPag - 170, _nMargEsq + 2250)
	_oPrn:Line (_nMargSup + _nAltPag - 90,  _nMargEsq + 40,   _nMargSup + _nAltPag - 90,  _nMargEsq + 2250)
	_oPrn:Line (_nMargSup + _nAltPag - 170, _nMargEsq + 40,   _nMargSup + _nAltPag - 90,  _nMargEsq + 40)
	_oPrn:Line (_nMargSup + _nAltPag - 170, _nMargEsq + 480,  _nMargSup + _nAltPag - 90,  _nMargEsq + 480)
	_oPrn:Line (_nMargSup + _nAltPag - 170, _nMargEsq + 900,  _nMargSup + _nAltPag - 90,  _nMargEsq + 900)
	_oPrn:Line (_nMargSup + _nAltPag - 170, _nMargEsq + 1340, _nMargSup + _nAltPag - 90,  _nMargEsq + 1340)
	_oPrn:Line (_nMargSup + _nAltPag - 170, _nMargEsq + 1790, _nMargSup + _nAltPag - 90,  _nMargEsq + 1790)
	_oPrn:Line (_nMargSup + _nAltPag - 170, _nMargEsq + 2250, _nMargSup + _nAltPag - 90,  _nMargEsq + 2250)
	
	// Soh imprime valores de rodape se for a ultima pagina.
	//if _nVerbaIni >= len (_aVerbas)
	if _nVerbaIni > len (_aVerbas)
		_oPrn:Say (_nMargSup + _nAltPag - 310,  _nMargEsq + 60, "Data de pagamento: " + dtoc (_dDatPag), _oArial8, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 265,  _nMargEsq + 60, "PIS: " + (_sAliasQ) -> ra_pis, _oArial8, 100)
	
		// Dados bancarios
		_oPrn:Say (_nMargSup + _nAltPag - 310,  _nMargEsq + 650, "Dados bancarios:", _oArial8, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 310,  _nMargEsq + 920, "Banco: " + left ((_sAliasQ) -> ra_BcDepSa, 3), _oArial8, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 265,  _nMargEsq + 920, "Ag/cta: " + alltrim (substr ((_sAliasQ) -> ra_BcDepSa, 4)) + " / " + (_sAliasQ) -> ra_CtDepSa, _oArial8, 100)
		
		// Totais de vencimentos, descontos e valor liquido
		_oPrn:Say (_nMargSup + _nAltPag - 310,  _nMargEsq + 1600,  "Total vencimentos:", _oArial8, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 315,  _nMargEsq + 1800,  transform (_nTotVenc, "@E 9,999,999,999.99"), _oCour12, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 265,  _nMargEsq + 1600,  "Total descontos:", _oArial8, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 270,  _nMargEsq + 1800,  transform (_nTotDesc, "@E 9,999,999,999.99"), _oCour12, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 220,  _nMargEsq + 1600,  "Valor líquido:", _oArial10N, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 225,  _nMargEsq + 1730,  transform (_nTotVenc - _nTotDesc, "@E 9,999,999,999.99"), _oCour14N, 100)
	
		// Valores de bases
		_oPrn:Say (_nMargSup + _nAltPag - 165,  _nMargEsq + 60,   "Salário base", _oArial7, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 165,  _nMargEsq + 490,  "Base INSS",    _oArial7, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 165,  _nMargEsq + 920 , "Base FGTS",    _oArial7, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 165,  _nMargEsq + 1350, "FGTS do mês",  _oArial7, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 165,  _nMargEsq + 1800, "Base IRRF",    _oArial7, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 140,  _nMargEsq + 50,   transform ((_sAliasQ) -> ra_salario, "@E 9,999,999,999.99"), _oCour12, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 140,  _nMargEsq + 470,  transform (_nBaseINSS, "@E 9,999,999,999.99"), _oCour12, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 140,  _nMargEsq + 900 , transform (_nBaseFgts, "@E 9,999,999,999.99"), _oCour12, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 140,  _nMargEsq + 1350, transform (_nFgts, "@E 9,999,999,999.99"), _oCour12, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 140,  _nMargEsq + 1800, transform (_nBaseIr, "@E 9,999,999,999.99"), _oCour12, 100)
		
		// Local para assinatura
		_oPrn:Say (_nMargSup + _nAltPag - 36,  _nMargEsq + 40, "Recebi a importância líquida discriminada neste recibo em _____/_____/_____.      _________________________________________", _oArial10, 100)
		_oPrn:Say (_nMargSup + _nAltPag - 0,  _nMargEsq + 1650, "Assinatura do funcionário", _oArial8, 100)
	else
		_oPrn:Say (_nMargSup + _nAltPag - 300,  _nMargEsq + 250, "* * * Continua na proxima pagina * * *", _oCour12, 100)
	endif

	// Inverte local de impressao (inferior/superior) do proximo recibo.
	if _sPosPag == "I" .or. mv_par09 == 1  // Um recibo por folha
		_sPosPag = "S"
	else
		_sPosPag = "I"
	endif

	// Se a proxima impressao eh na parte superior da folha, entao eh por que a folha atual deve ser terminada.
	if _sPosPag == "S"
		_oPrn:EndPage()
	endif

	// Chama nova impressao, caso necessario
	//if _nVerbaIni < len (_aVerbas)
	if _nVerbaIni <= len (_aVerbas)
		// u_log ("Chamando nova impressao (recursiva)")
		_Imprime (_aVerbas, _nVerbaIni, _nTotVenc, _nTotDesc, _nBaseFgts, _nFgts, _nBaseIr, _sAliasQ, _nBaseINSS, _dDatPag)
	endif

	
	// u_logFim ()
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM                      DEC VALID        F3     Opcoes             Help
	aadd (_aRegsPerg, {01, "Data de referencia            ", "D", 8,                       0,  "",          "   ", {},                ""})
	aadd (_aRegsPerg, {02, "Matricula de                  ", "C", TamSX3 ("RA_MAT")[1],    0,  "",          "SRA", {},                ""})
	aadd (_aRegsPerg, {03, "Matricula ate                 ", "C", TamSX3 ("RA_MAT")[1],    0,  "",          "SRA", {},                ""})
	aadd (_aRegsPerg, {04, "Centro de custo de            ", "C", TamSX3 ("RA_CC")[1],     0,  "",          "CTT", {},                ""})
	aadd (_aRegsPerg, {05, "Centro de custo ate           ", "C", TamSX3 ("RA_CC")[1],     0,  "",          "CTT", {},                ""})
	aadd (_aRegsPerg, {06, "Semana                        ", "C", TamSX3 ("RC_SEMANA")[1], 0,  "",          "   ", {},                ""})
	aadd (_aRegsPerg, {07, "Origem dos valores            ", "N", 1,                       0,  "",          "   ", {"Adto.", "Folha", "1a. parc 13o.", "2a. parc 13o.", "Extras"}, ""})
	aadd (_aRegsPerg, {08, "Numero de vias                ", "N", 1,                       0,  "",          "   ", {},                ""})
	aadd (_aRegsPerg, {09, "Quant. recibos por folha      ", "N", 1,                       0,  "",          "   ", {"1", "2"},        ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
