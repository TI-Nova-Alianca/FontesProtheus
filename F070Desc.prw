// Programa..: F070Desc
// Autor.....: Robert Koch
// Data......: 08/07/2008
// Cliente...: Alianca
// Descricao.: P.E. para validar valor desconto na tela de baixa de titulos a receber.
//             Criado inicialmente para informar composicao do desconto.
// 
// Tags para automatizar catalogo de customizacoes:oDePrograma    #ponto_de_entrada
// #Descricao		  #P.E. para validar valor desconto na tela de baixa de titulos a receber.
// #PalavasChave      #verbas #descontos #baixa 
// #TabelasPrincipais #ZA4 #ZA5 
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
// 31/07/2008 - Robert  - Criada possibilidade de fretes e outros descontos.
// 12/08/2008 - Robert  - Criada possibilidade de devolucoes e descontos simples.
// 09/03/2009 - Robert  - Criada possibilidade de campanhas de vendas e abertura/reinauguracao de loja.
// 15/10/2009 - Robert  - Criada possibilidade de multas contratuais.
// 15/04/2015 - Catia   - alteracoes para integracao com controle de verbas
// 30/04/2015 - Catia   - estava validando errado a verba de abertura/inauguracao de loja
// 15/06/2015 - Catia   - alterado status de utilizacao - testando pelo saldo da verba
// 10/07/2019 - Catia   - ajuste para que nao abra tela de descontos quando executa integracao com cartao de credito
// 10/10/2019 - Robert  - Nao permite desconto maior que o saldo da verba (GLPI 6800).
// 11/08/2020 - Cláudia - Limpar os dados digitados na tela em caso de cancelamento, evitando inclusao 
//                        de verbas improprias.GLPI:8099
// 03/09/2020 - Cláudia - Não permitir a chamada da tela de descontos nas baixas automaticas da cielo.
//                        A taxa cielo será emitida como um desconto.
// 24/09/2020 - Cláudia - Não permitir a chamada da tela de descontos nas baixas de rapel. GLPI: 8367
// 19/07/2021 - Cláudia - Não permitir a chamada da tela de descontos nas baixas automaticas do pagar.me.
//                        A taxa pagar.me será emitida como um desconto.
// 01/06/2022 - Claudia - Incluido parametro permitindo desativar regra de IPI e ST. GLPI: 12128
//
// ---------------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"

User Function F070Desc ()
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet     := .T.
	
	If !IsInCallStack("U_ZB2_CON") .and. !IsInCallStack("U_ZB1_CON") .and. !IsInCallStack("U_ZB3CON") .and. !IsInCallStack("U_VA_040BRAP") // Não chama tela de descontos qndo realizada a baixa de titulos cielo e baixa do rapel
	    _lRet = _Compos ()
	EndIf

	If IsInCallStack("U_VA_040BRAP")
		_lRet = _RapelAut ()
	EndIf

	U_ML_SRArea (_aAreaAnt)
Return _lRet
//
// -------------------------------------------------------------------------------------------------
// Tela para o usuario informar a composicao do desconto.
Static Function _Compos ()
	public  _nDesc   := paramixb [1]
	public  _sTotal  := "_E5VARapel + _E5VAEncar + _E5VAFeira + _E5VADOutr + _E5VADFret + _E5VADdesc + _E5VADDevo + _E5VADCmpV + _E5VADARei + _E5VADMulC"
	private _lRet    := .T.
	private _wfiltro := ''

	// Cria variaveis 'public' para serem vistas em outro ponto de entrada.
	if type ("_E5VARapel") == "U"
		public _E5VARapel := 0
	endif
	if type ("_E5VAEncar") == "U"
		public _E5VAEncar  := 0
	endif
	if 	type ("_E5VerEncar") == "U"	
		public _E5VerEncar := "      "
	endif
	if type ("_E5VAFeira") == "U"
		public _E5VAFeira  := 0
	endif
	if type ("_E5VerFeira") == "U"		
		public _E5VerFeira := "      "
	endif
	if type ("_E5VADOutr") == "U"
		public _E5VADOutr  := 0
	endif
	if type ("_E5VADFret") == "U"
		public _E5VADFret := 0
	endif
	if type ("_E5VerFret") == "U"		
		public _E5VerFret := "      "
	endif
	if type ("_E5VADDesc") == "U"
		public _E5VADDesc := 0
	endif
	if type ("_E5VADDevo") == "U"
		public _E5VADDevo := 0
	endif
	if type ("_E5VADCmpV") == "U"
		public _E5VADCmpV := 0
	endif
	if type ("_E5VerCmpV") == "U"		
		public _E5VerCmpV := "      "
	endif
	if type ("_E5VADARei") == "U"
		public _E5VADARei := 0
	endif
	if type ("_E5VerARei") == "U"		
		public _E5VerARei := "      "
	endif
	if type ("_E5VADMulC") == "U"
		public _E5VADMulC  := 0
	endif
	if type ("_E5VerMulC") == "U"			
		public _E5VerMulC  := "      "
	endif
	
	// inicia variaveis usadas para controle de verbas
	_wmatriz = fBuscaCpo ('SA1', 1, xfilial('SA1') + se1 -> e1_cliente + se1 -> e1_loja, "A1_VACBASE")
	_wverbas = fBuscaCpo ('SA1', 1, xfilial('SA1') + _wmatriz + '01', "A1_VERBA")
	
	do while _lRet .and. &(_sTotal) != _nDesc
		define msdialog _oDlg title "Composicao do desconto" from 0, 0 to 380, 500 of oMainWnd pixel
		@ 10,  20  say "Informe a composicao do desconto"
		@ 25,  20  say "Rapel"
		@ 40,  20  say "(***) Encartes/ponto extra"
		@ 55,  20  say "(***) Feiras"
		@ 70,  20  say "(***) Fretes"
		@ 85,  20  say "Descontos normais"
		@ 100, 20  say "Devolucoes"
		@ 115, 20  say "(***) Campanhas de vendas"
		@ 130, 20  say "(***) Abert/reinaugur.loja"
		@ 145, 20  say "(***) Multa contratual"
		@ 160, 20  say "Outros"
		@ 175, 20  say "Total"
		@ 25,  100 get _E5VARApel picture "@E 999,999.99" size 50, 11 
		@ 40,  100 get _E5VAEncar picture "@E 999,999.99" size 50, 11
		if _wverbas = '1'
			@ 40,  170 get _E5VerEncar picture "@!" size 30, 11 F3 'ZA4F1'"
		endif			
		@ 55,  100 get _E5VAFeira picture "@E 999,999.99" size 50, 11
		if _wverbas = '1'
			@ 55,  170 get _E5VerFeira picture "@!" size 30, 11 F3 'ZA4F2'"
		endif			
		@ 70,  100 get _E5VADFret picture "@E 999,999.99" size 50, 11
		if _wverbas = '1'
			@ 70,  170 get _E5VerFret picture "@!" size 30, 11 F3 'ZA4F3'"
		endif			
		@ 85,  100 get _E5VADDesc picture "@E 999,999.99" size 50, 11
		@ 100, 100 get _E5VADDevo picture "@E 999,999.99" size 50, 11
		@ 115, 100 get _E5VADCmpV picture "@E 999,999.99" size 50, 11
		if _wverbas = '1'
			@ 115,  170 get _E5VerCmpV picture "@!" size 30, 11 F3 'ZA4F4'"
		endif			
		@ 130, 100 get _E5VADARei picture "@E 999,999.99" size 50, 11
		if _wverbas = '1'
			@ 130,  170 get _E5VerARei picture "@!" size 30, 11 F3 'ZA4F5'"
		endif			
		@ 145, 100 get _E5VADMulC picture "@E 999,999.99" size 50, 11
		if _wverbas = '1'
			@ 145,  170 get _E5VerMulC picture "@!" size 30, 11 F3 'ZA4F6'"
		endif			
		@ 160, 100 get _E5VADOutr picture "@E 999,999.99" size 50, 11
		@ 175, 100 get &(_sTotal) picture "@E 999,999.99" size 50, 11 when .F.
		@ _oDlg:nClientHeight / 2 - 40, _oDlg:nClientWidth / 2 - 90 bmpbutton type 1 action ( iif(u_valida() = .T. , _oDlg:End (), u_help("Corrija informações de desconto!") )) 
		@ _oDlg:nClientHeight / 2 - 40, _oDlg:nClientWidth / 2 - 40 bmpbutton type 2 action (_lRet := u_limpaCmp()  ,_oDlg:End ())

		activate dialog _oDlg centered
	enddo

Return _lRet
//
// -------------------------------------------------------------------------------------------------
// valida valores x verbas utilizadas
User Function valida()
	local _nSaldoZA4 := 0
	local _valida    := .T.
	local _nVlrDesc  := 0
	local i			 := 0

	if &(_sTotal) <>  _nDesc
		u_help ("Soma dos valores diferente do desconto total (" + cvaltochar (_nDesc) + ").")
		_valida = .F.
	endif
	
	if _wverbas = '1'
		if _E5VAEncar >0
			if empty(_E5VerEncar)
				u_help("Verba para valor do desconto refente a Encarte não informada.")
				_valida = .F.
			endif
		else
			if ! empty(_E5VerEncar)
				u_help("Valor para valor do desconto refente a Encarte não informado.")
				_valida = .F.
			endif
		endif
		if _E5VAFeira >0
			if empty(_E5VerFeira)
				u_help("Verba para valor do desconto refente a Feira não informada.")
				_valida = .F.
			endif
		else
			if ! empty(_E5VerFeira)
				u_help("Valor do desconto refente a Feira não informado.")
				_valida = .F.
			endif
		endif
		if _E5VADFret >0
			if empty(_E5VerFret)
				u_help("Verba para valor do desconto refente a Frete não informada.")
				_valida = .F.
			endif
		else
			if ! empty(_E5VerFret)
				u_help("Valor do desconto refente a Frete não informado.")
				_valida = .F.
			endif
		endif
		if _E5VADCmpV >0
			if empty(_E5VerCmpV)
				u_help("Verba para valor do desconto refente a Campanha de Vendas não informada.")
				_valida = .F.
			endif
		else
			if ! empty(_E5VerCmpV)
				u_help("Valor do desconto refente a Campanha de Vendas não informado.")
				_valida = .F.
			endif
		endif
		if _E5VADARei >0
			if empty(_E5VerARei)
				u_help("Verba para valor do desconto refente a Abertura/Reinauguração não informada.")
				_valida = .F.
			endif
		else
			if ! empty(_E5VerARei)
				u_help("Valor do desconto refente a Abertura/Reinauguração não informado.")
				_valida = .F.
			endif
		endif
		if _E5VADMulC >0
			if empty(_E5VerMulC)
				u_help("Verba para valor do desconto refente a Multa Contratual não informada.")
				_valida = .F.	
			endif
		else
			if ! empty(_E5VerMulC)
				u_help("Valor do desconto refente a Multa Contratual não informado.")
				_valida = .F.
			endif
		endif
		
		for i=1 to 6
			do case 
				case i= 1
					_wnumverba = _E5VerEncar
					_wdesc = "Encarte"
					_nVlrDesc = _E5VAEncar
				case i= 2
					_wnumverba = _E5VerFeira
					_wdesc = "Feira"
					_nVlrDesc = _E5VAFeira
				case i=3					
					_wnumverba = _E5VerFret
					_wdesc = "Frete"
					_nVlrDesc = _E5VADFret
				case i=4					
					_wnumverba = _E5VerCmpV
					_wdesc = "Campanha de Vendas"
					_nVlrDesc = _E5VADCmpV
				case i=5					
					_wnumverba = _E5VerARei
					_wdesc = "Abertura e Reinauguração"
					_nVlrDesc = _E5VADARei
				case i=6					
					_wnumverba = _E5VerMulC
					_wdesc = "Multa Contratual"						
					_nVlrDesc = _E5VADMulC
			endcase	

			if !empty(@(_wnumverba))		
				if fBuscaCpo ('ZA4', 1, xfilial('Za4') + _wnumverba, "ZA4_CLI") <> _wmatriz
					u_help("Verba informada como desconto de " + _wdesc + " não pertence a este cliente.")
					_valida = .F.
				endif
			
				if fBuscaCpo ('ZA4', 1, xfilial('Za4') + _wnumverba, "ZA4_TLIB") <>  '2'
					u_help("Verba informada como desconto de " + _wdesc + " não liberada como desconto de titulos")
					_valida = .F.
				endif
				
				if empty(fBuscaCpo ('ZA4', 1, xfilial('Za4') + _wnumverba, "ZA4_DLIB"))
					u_help("Verba informada como desconto de " + _wdesc + " não liberada")
					_valida = .F.
				endif

				// Verifica se o valor informado fica dentro do saldo da verba.
				_nSaldoZA4 = U_SaldoZA4 (_wnumverba)
				if _nVlrDesc > _nSaldoZA4
					U_Help (_wdesc + ": Valor de desconto informado (" + cvaltochar (_nVlrDesc) + ") nao pode ser maior que o saldo (" + cvaltochar (_nSaldoZA4) + ") da verba.")
					_valida = .F.
				endif
			endif
		next
	endif

	// valida total de desconto x IPI X ST
	If GetMv('VA_ZA4DESC') == .T. 
		_valida := VerifIpiSt(_nDesc)
	EndIf
Return _valida
//
// -------------------------------------------------------------------------------------------------
// Realiza a limpeza dos campos no botão cancelar
User Function limpaCmp()
	_E5VARapel  := 0
	_E5VAEncar  := 0
	_E5VerEncar := "      "
	_E5VAFeira  := 0
	_E5VerFeira := "      "
	_E5VADOutr  := 0
	_E5VADFret  := 0
	_E5VerFret  := "      "
	_E5VADDesc  := 0
	_E5VADDevo  := 0
	_E5VADCmpV  := 0
	_E5VerCmpV  := "      "
	_E5VADARei  := 0
	_E5VerARei  := "      "
	_E5VADMulC  := 0
	_E5VerMulC  := "      "
Return .F.
//
// -------------------------------------------------------------------------------------------------
// valida se o desconto é maior que o valor de IPI e ST que será pago
Static Function VerifIpiSt(_nDesconto)
	Local _lRet    := .T.
	Local _parcela := se1 -> e1_parcela

	// quantidade de parcelas do titulo
	_qtdParc := 1
	_sQuery := ""
	_sQuery += " SELECT COUNT (*) "
	_sQuery += " FROM " +  RetSQLName ("SE1") + " AS SE1 "
	_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
	_sQuery += " AND E1_FILIAL  = '" + se1->e1_filial  +"'"
	_sQuery += " AND E1_NUM     = '" + se1->e1_num     + "'"
	_sQuery += " AND E1_PREFIXO = '" + se1->e1_prefixo + "'"
	_sQuery += " AND E1_CLIENTE = '" + se1->e1_cliente + "'"
	_sQuery += " AND E1_LOJA   	= '" + se1->e1_loja    + "'"
	_aParc := U_Qry2Array(_sQuery)
	
	If Len(_aParc) > 0
		_qtdParc := _aParc[1,1]
	Else
		_qtdParc := 1
	EndIf
	//
	// **********************************************************************************************
	// condição de pagamento para definir baixa de IPI e ST
	_sQuery := ""
	_sQuery += " SELECT"
	_sQuery += " 	 SC5.C5_FILIAL"	//01
	_sQuery += "    ,SC5.C5_NUM"	//02
	_sQuery += "    ,SC5.C5_CLIENTE"//03
	_sQuery += "    ,SC5.C5_LOJACLI"//04
	_sQuery += "    ,SC5.C5_CONDPAG"//05
	_sQuery += "	,SC5.C5_PARC1"	//06
	_sQuery += "    ,SC5.C5_PARC2"	//07	
	_sQuery += "    ,SC5.C5_PARC3"	//08
	_sQuery += "    ,SC5.C5_PARC4"	//09
	_sQuery += "    ,SC5.C5_PARC5"	//10
	_sQuery += "    ,SC5.C5_PARC6"	//11
	_sQuery += "    ,SC5.C5_PARC7"	//12
	_sQuery += "    ,SC5.C5_PARC8"	//13
	_sQuery += "    ,SC5.C5_PARC9"	//14
	_sQuery += "    ,SC5.C5_PARCA"	//15
	_sQuery += "    ,SC5.C5_PARCB"	//16
	_sQuery += "    ,SC5.C5_PARCC"	//17
	_sQuery += " FROM " +  RetSQLName ("SC5") + " AS SC5" 
	_sQuery += " WHERE SC5.D_E_L_E_T_ = ''"
	_sQuery += " AND SC5.C5_FILIAL  = '" + se1->e1_filial  + "'"
	_sQuery += " AND SC5.C5_NOTA    = '" + se1->e1_num     + "'"
	_sQuery += " AND SC5.C5_SERIE   = '" + se1->e1_prefixo + "'"
	_sQuery += " AND SC5.C5_CLIENTE = '" + se1->e1_cliente + "'"
	_sQuery += " AND SC5.C5_LOJACLI = '" + se1->e1_loja    + "'"
	_aCondPgto := U_Qry2Array(_sQuery)

	If Len(_aCondPgto) > 0
		_sPedFil 	:= _aCondPgto[1,1]
		_sPedNum	:= _aCondPgto[1,2]
		_sPedCli	:= _aCondPgto[1,3]
		_sPedLoj	:= _aCondPgto[1,4]
		_sCondPgto  := _aCondPgto[1,5]
		_sParc1		:= _aCondPgto[1,6]
		_sParc2		:= _aCondPgto[1,7]
		_sParc3		:= _aCondPgto[1,8]
		_sParc4		:= _aCondPgto[1,9]
		_sParc5		:= _aCondPgto[1,10]
		_sParc6		:= _aCondPgto[1,11]
		_sParc7		:= _aCondPgto[1,12]
		_sParc8		:= _aCondPgto[1,13]
		_sParc9		:= _aCondPgto[1,14]
		_sParcA		:= _aCondPgto[1,15]
		_sParcB		:= _aCondPgto[1,16]
		_sParcC		:= _aCondPgto[1,17]
		//
		_sCondTipo := Posicione("SE4",1,'  ' + _sCondPgto,"E4_TIPO")
		_sCondIPI  := Posicione("SE4",1,'  ' + _sCondPgto,"E4_IPI") 
	Else	
		_sCondTipo  := '1'
		_sCondIPI   := 'N'
		_sParc1		:= 100
		_sParc2		:= 100
		_sParc3		:= 100
		_sParc4		:= 100
		_sParc5		:= 100
		_sParc6		:= 100
		_sParc7		:= 100
		_sParc8		:= 100
		_sParc9		:= 100
		_sParcA		:= 100
		_sParcB		:= 100
		_sParcC		:= 100
	EndIf
	//
	// **********************************************************************************************
	// busca dados da nota de IP e ST 
	_vlrIpi 	:= 0
	_vlrST  	:= 0
	
	_sQuery := ""
	_sQuery += " SELECT "
	_sQuery += " 	  F2_VALBRUT  AS TOTAL_NF"
	_sQuery += "    , F2_VALIPI   AS IPI_NF"
	_sQuery += "    , F2_ICMSRET  AS ST_NF"
	_sQuery += "  FROM " +  RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "  WHERE SF2.D_E_L_E_T_  = ''" 
	_sQuery += "  AND SF2.F2_FILIAL   =  '" + se1 -> e1_filial    + "'"
	_sQuery += "  AND SF2.F2_DOC      =  '" + se1 -> e1_num       + "'"
	_sQuery += "  AND SF2.F2_SERIE    =  '" + se1 -> e1_prefixo   + "'"
	_sQuery += "  AND SF2.F2_CLIENTE  =  '" + se1 -> e1_cliente   + "'"
	_sQuery += "  AND SF2.F2_LOJA     =  '" + se1 -> e1_loja      + "'"
	_aNota := U_Qry2Array(_sQuery)
	
	If len(_aNota) > 0
		_ipiNota  := _aNota[1,2]
		_stNota	  := _aNota[1,3]

		If _sCondTipo == '9' // Escolhe o percentual de cada parcela
			Do Case 
				Case alltrim(_parcela) == '' 
					_vlrIpi := (_ipiNota * _sParc1) / 100
					_vlrST  := (_stNota  * _sParc1) / 100
				Case alltrim(_parcela) == 'A'
					_vlrIpi := (_ipiNota * _sParc1) / 100
					_vlrST  := (_stNota  * _sParc1) / 100 
				Case alltrim(_parcela) == 'B' 
					_vlrIpi := (_ipiNota * _sParc2) / 100
					_vlrST  := (_stNota  * _sParc2) / 100 
				Case alltrim(_parcela) == 'C' 
					_vlrIpi := (_ipiNota * _sParc3) / 100
					_vlrST  := (_stNota  * _sParc3) / 100 
				Case alltrim(_parcela) == 'D' 
					_vlrIpi := (_ipiNota * _sParc4) / 100
					_vlrST  := (_stNota  * _sParc4) / 100 
				Case alltrim(_parcela) == 'E' 
					_vlrIpi := (_ipiNota * _sParc5) / 100
					_vlrST  := (_stNota  * _sParc5) / 100 
				Case alltrim(_parcela) == 'F' 
					_vlrIpi := (_ipiNota * _sParc6) / 100
					_vlrST  := (_stNota  * _sParc6) / 100 
				Case alltrim(_parcela) == 'G' 
					_vlrIpi := (_ipiNota * _sParc7) / 100
					_vlrST  := (_stNota  * _sParc7) / 100 
				Case alltrim(_parcela) == 'H' 
					_vlrIpi := (_ipiNota * _sParc8) / 100
					_vlrST  := (_stNota  * _sParc8) / 100 
				Case alltrim(_parcela) == 'I' 
					_vlrIpi := (_ipiNota * _sParc9) / 100
					_vlrST  := (_stNota  * _sParc9) / 100 
				Case alltrim(_parcela) == 'J' 
					_vlrIpi := (_ipiNota * _sParcA) / 100
					_vlrST  := (_stNota  * _sParcA) / 100 
				Case alltrim(_parcela) == 'K'
					_vlrIpi := (_ipiNota * _sParcB) / 100
					_vlrST  := (_stNota  * _sParcB) / 100 
				Case alltrim(_parcela) == 'L'  
					_vlrIpi := (_ipiNota * _sParcC) / 100
					_vlrST  := (_stNota  * _sParcC) / 100 
			EndCase

		Else
			If _sCondIPI == 'N' // IPI distribuídos nas "N" parcelas
				_vlrIpi := _ipiNota/_qtdParc
				_vlrST  := _stNota/_qtdParc

			Else 				// IPI cobrado na primeira parcela
				If alltrim(se3->e3_parcela) == '' .or. alltrim(se3->e3_parcela) == 'A' // se for a primeira parcela, desconta IPI e ST
					_vlrIpi := _ipiNota
					_vlrST  := _stNota
				Else
					_vlrIpi := 0
					_vlrST  := 0
				EndIf
			EndIf
		EndIf
	else
		_vlrIpi := 0
		_vlrST  := 0
	endif

	If se1 -> e1_valor  < (_vlrIpi + _vlrST + _nDesconto)
		u_help('O valor de descontos + IPI + ST não pode ultrapassar o valor do título!')
		_lRet := .F.
	EndIf
Return _lRet
//
// -------------------------------------------------------------------------------------------------
// Incluir rapel para baixa automatica
Static Function _RapelAut ()
	private _lRet    := .T.

	// Cria variaveis 'public' para serem vistas em outro ponto de entrada.
	if type ("_E5VARapel") == "U"
		public _E5VARapel := 0
	endif
	if type ("_E5VAEncar") == "U"
		public _E5VAEncar  := 0
	endif
	if 	type ("_E5VerEncar") == "U"	
		public _E5VerEncar := "      "
	endif
	if type ("_E5VAFeira") == "U"
		public _E5VAFeira  := 0
	endif
	if type ("_E5VerFeira") == "U"		
		public _E5VerFeira := "      "
	endif
	if type ("_E5VADOutr") == "U"
		public _E5VADOutr  := 0
	endif
	if type ("_E5VADFret") == "U"
		public _E5VADFret := 0
	endif
	if type ("_E5VerFret") == "U"		
		public _E5VerFret := "      "
	endif
	if type ("_E5VADDesc") == "U"
		public _E5VADDesc := 0
	endif
	if type ("_E5VADDevo") == "U"
		public _E5VADDevo := 0
	endif
	if type ("_E5VADCmpV") == "U"
		public _E5VADCmpV := 0
	endif
	if type ("_E5VerCmpV") == "U"		
		public _E5VerCmpV := "      "
	endif
	if type ("_E5VADARei") == "U"
		public _E5VADARei := 0
	endif
	if type ("_E5VerARei") == "U"		
		public _E5VerARei := "      "
	endif
	if type ("_E5VADMulC") == "U"
		public _E5VADMulC  := 0
	endif
	if type ("_E5VerMulC") == "U"			
		public _E5VerMulC  := "      "
	endif

	// grava rapel
	 _E5VARapel := se1->e1_varapel
Return _lRet
