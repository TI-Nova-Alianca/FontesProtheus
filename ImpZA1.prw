// Programa...: ImpZA1
// Autor......: Robert Koch (versao inicial Leandro Perondi - DWT - 11/12/2013)
// Data.......: 18/10/2018
// Descricao..: Impressao de etiquetas para pallets
//
// Historico de alteracoes:
// 05/03/2019 - Andre   - Acrescentado Peso nas etiquetas de O.P
// 15/08/2019 - Robert  - Imprime B1_CODBAR e nao mais B1_VADUNCX no codigo de barras do produto.
// 22/08/2019 - Robert  - Se o produto nao controla via FullWMS, imprimia o cod.do produto nas barras. 
//                        Agora nao vai imprimir nada.
// 30/08/2019 - Claudia - Alterado campo b1_p_brt para b1_pesbru.
// 02/10/2019 - Claudia - Criação da rotina de impressão de etiquetas de OP na impressora DATAMAX
// 24/01/2022 - Robert  - Vamos usar etiquetas no AX02, mesmo sem integracao com FullWMS (GLPI 11515).
// 02/02/2022 - Robert  - Imprime B8_DFABRIC e nao mais D1_DFABRIC como data de fabricacao nas etiq. de NF de entrada.
// 03/02/2022 - Claudia - Ajustada linha 628 de DTOC(SD1->B8_DFABRIC) para DTOC(SB8->B8_DFABRIC)
// 11/02/2022 - Robert  - Posicionava SB8 pelo D1_LOTEFOR. Alterado para posicionar pelo ZA1_PROD + D1_LOTECTL.
//                      - Posiciona o SB8 via query por que nao tem indice por produto+lote+local.
// 25/02/2022 - Robert  - Ajustes nas margens da etiq. de NF na impressora Argox/Datamax.
// 01/04/2022 - Robert  - Nao envia para FullWMS se for etiqueta de OP (envio vai ser feito noutro local) - GLPI 11825
// 11/05/2022 - Robert  - Quando reimpressao, imprime 'Reimpressa' em vez de 'Impressa'.
//

// -------------------------------------------------------------------------------------------------------------------
user function ImpZA1 (_sCodigo, _sIdImpr)
	local _aAreaAnt   := U_ML_SRArea ()
	local _lContinua  := .T.
	private _Enter    := chr(13)+chr(10)
	private _Esc      := chr(27)
	private _sArq     := ""
	private _nHdl     := 0
	private cPerg     := "ETQPLLT"
	static _sPortaImp := ""  // Tipo STATIC para que o programa abra as perguntas apenas na primeira execucao.
	static _nModelImp := 0   // Tipo STATIC para que o programa abra as perguntas apenas na primeira execucao.

	// Se recebi a identificacao da impressora, nao preciso perguntar ao usuario.
	if ! empty (_sIdImpr)
		_sPortaImp = U_RetZX5 ('49', _sIdImpr, 'ZX5_49CAM')
		_nModelImp = val (U_RetZX5 ('49', _sIdImpr, 'ZX5_49LING'))
	else
		// Je jah definido na execucao anterior (por isso a variavel eh STATIC), nao pergunto mais.
		if empty (_sPortaImp) .or. empty (_nModelImp)
			_ValidPerg()
			if Pergunte(cPerg)
				_sPortaImp = U_RetZX5 ('49', mv_par01, 'ZX5_49CAM')
				_nModelImp = val (U_RetZX5 ('49', mv_par01, 'ZX5_49LING'))
			else
				_lContinua = .F.
			endif
		endif
	endif
	
	if _lContinua
		if empty (_sPortaImp) .or. empty (_nModelImp)
			u_help ("Impressora '" + _sIdImpr + "' nao cadastrada ou sem caminho / linguagem informados.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		za1 -> (dbsetorder(1))
		if ! za1 -> (dbseek(xFilial("ZA1") + _sCodigo, .F.))
			u_help ("Etiqueta '" + _sCodigo + "' nao encontrada!",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		sb1 -> (dbsetorder(1))
		if ! sb1 -> (dbseek (xFilial("SB1") + za1 -> za1_prod, .F.))
			u_help ("Produto da etiqueta ('" + za1 -> za1_prod + "') nco cadastrado.",, .t.)
			_lContinua = .F.
		endif
	endif
	/* etiqueta de OP - datamax
	f220
	D
	n
	L
	D11
	H13
	PC
	4e72000000700607896100502206
	4211000000700804417 - SUCO DE UVA TINTO
	421100000070095INTEGRAL ALIANCA PET FD 6 
	421100000070110X900ML                   
	421100000070125            
	431100000070180QTD: 170 FD
	431100001300195------
	421100001300205   OK
	4e52000000702602000238917
	431100000070285ETQ: 2000238917 
	421100001500285 1/14    
	4e520000007034010382101
	431100000070360Lote: 10382101
	421100000070380 
	431100000070400Impressa em: 01/10/2019
	331100002300400OP.103821.01.001 P. BRUTO 1045.5
	Q0001
	E
	*/
	/* formatacao inicial de etiqueta de insumos para uso na Argox OS 214:
	f220
	D
	n
	L
	D11
	H13
	PC
	431100000100030A234567890123456789012
	421100000100045A234567890123456789012345678
	421100000100060A234567890123456789012345678
	431100000100085NF:123456789/123
	421100000100100FORN:123456/01 - 12345678901
	421100000100115A234567890123456789012345678
	431100000100135LT.FOR:123456789012345
	431100000100155LT.INT:1234567890
	431100000100180QT:999.999.999,99 UN
	431100000100200FABRICACAO:12/12/1234
	431100000100220VALIDADE:  12/12/1234
	431100000100250ETIQUETA:  2000012345
	4e52000001003002000012345
	431100000100350DATA: _______________
	431100000100375RESP: _______________
	431100000100400ASS.: _______________
	Q0001
	E
	*/

	/* Exemplo de etiqueta de insumos para uso na Sato 403e:
	A
	CS6
	Z
	A
	#E1
	Z
	A
	PC03,0
	PC09,2
	%1
	H0050V0440$B,025,028,0$=4062 - PREFORMA PET 60G C
	H0075V0440$B,025,028,0$=LARA 2LTS NECK 38MM      
	H0100V0440$B,025,028,0$=                 
	H0150V0440$B,025,028,0$=NF: 000033749
	H0200V0440$B,025,028,0$=000402 - PANIZZON INDUS E
	H0225V0440$B,025,028,0$= COMER DE PLASTICOS LTDA
	H0275V0440$B,025,028,0$=LOTE FORN: 
	H0300V0440$B,025,028,0$=LOTE INT: 
	H0325V0440$B,025,028,0$=QTD: 1000 UN
	H0375V0440$B,025,028,0$=FABRICACAO: /  /
	H0400V0440$B,025,028,0$=VALIDADE: 03/03/2018
	H0425V0440$B,025,028,0$=ETQ: 0000085013
	H0475V0440BG02110>G0000085013
	H0650V0440$B,025,028,0$=DATA: ____________________
	H0700V0440$B,025,028,0$=RESP: ____________________
	H0750V0440$B,025,028,0$=ASS.: ____________________
	*/

	if _lContinua
		_sArq = criatrab (NIL, .F.)
		_nHdl = fcreate (_sArq, 0)

		// Verifica o tipo de etiqueta
		if ! empty (ZA1 -> ZA1_IdZAG)
			_lContinua = _ImpZAG ()
		elseif ! empty (ZA1 -> ZA1_OP)
			_lContinua = _ImpOP ()
		elseif ! empty (ZA1 -> ZA1_DOCE)
			_lContinua = _ImpNF ()
		else
			u_help ("Sem tratamento para este tipo de etiqueta no programa " + procname (),, .t.)
		endif

		if _lContinua
			fclose (_nHdl)
			//u_log2 ('debug', memoread (_sArq))
			copy file (_sArq) to (_sPortaImp)
			u_log2 ('debug', 'copiei etiq para ' + _sPortaImp)
			delete file (_sArq)

	// Penso que o fato de uma etiqueta estar impressa nao significa que jah precise
	// ser enviada para o FullWMS. Vou deixar isso a cargo do ClsEtiq().
			// Etiquetas (quando necessario) sao enviadas para o Full somente depois de impressas
			if za1 -> za1_impres == 'S'
				if empty (za1 -> za1_op)  // Etiquetas de OP sao enviadas somente depois de apontadas (P.E. SD3250I)
					U_EnvEtFul (za1 -> za1_codigo, .F.)
				endif
			endif
		endif
	endif
		
	U_ML_SRArea (_aAreaAnt)
Return



// --------------------------------------------------------------------------
static function _ImpZAG ()
	local _sDoc       := ""
	local _sDataV     := ""
	local _sUM        := ""
	local _sDescri1   := ""
	local _sDescri2   := ""
	local _sDescri3   := ""
	local _sLoteI	  := ""				
	local _lContinua  := .T.
	local _sMargEsq   := ""
	local _sObs1      := ''
	local _sObs2      := ''
	
	zag -> (dbsetorder (1))  // ZAG_FILIAL+ ZAG_DOC
	if ! zag -> (dbseek (xfilial ("ZAG") + za1 -> za1_idZAG, .F.))
		u_help ("Documento de transferencia '" + za1 -> za1_idZAG + "' nao encontrado.")
		_lContinua = .F.
	endif
	
	if _lContinua
		// Prepara dados para impressao.
		_sProd  := Alltrim(ZA1->ZA1_PROD)
		_sQtd   := Alltrim(cvaltochar(ZA1->ZA1_QUANT)) 
		_sCod   := Alltrim(ZA1->ZA1_CODIGO)
		_sDoc   := Alltrim(za1 -> za1_IdZAG)
		_sLoteI	:= zag -> zag_lotori
		_sUM    := sb1 -> b1_um
		_sObs1  := left ('Transf alm.' + zag -> zag_almori + ' -> ' + zag -> zag_almdst, 25)
		_sObs2  := left (zag -> zag_motivo, 25)
		
		// Quando mexer aqui, ajustar tambem o fonte que exporta para o WMS (EnvEtFul.prw)
//		SB8 -> (dbsetorder (4))  // FILIAL+LOTEFOR+PRODUTO+LOCAL
//		if SB8 -> (dbseek (xfilial ("SB8") + zag -> zag_lotori + ZA1 -> ZA1_PROD, .T.))
//			_sDataV := DTOC(SB8->B8_DTVALID)
//		else
//			_sDataV := DTOC(ctod (''))
//		endif
		// Quando mexer aqui, ajustar tambem o fonte que exporta para o WMS (EnvEtFul.prw)
		if ! _AchaSB8 (ZA1 -> ZA1_PROD, zag -> zag_lotori, zag -> zag_almori)
			u_help ("Lote '" + zag -> zag_lotori + "' do produto '" + za1 -> za1_prod + "' referenciado pela solicitacao de transferencia '" + zag -> zag_IdZAG + "' nao foi localizado na tabela SB8",, .t.)
			_lContinua = .F.
		else
			_sDataV := DTOC(SB8->B8_DTVALID)
		endif
	endif

	if _lContinua .and. _nModelImp == 1  // Impressora Sato
		_sDescri1 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 1, 25)
		_sDescri2 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 26, 25)
		_sDescri3 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 51, 25)

		fwrite (_nHdl, _Esc + 'A'   + _Enter + _Esc + 'CS6' + _Enter + _Esc + 'Z'   + _Enter)  // Velocidade
		fwrite (_nHdl, _Esc + 'A'   + _Enter + _Esc + '#E1' + _Enter + _Esc + 'Z'   + _Enter)  // Claridade
		fwrite (_nHdl, _Esc + 'A' + _Enter)      // Inicializa etiqueta
		fwrite (_nHdl, _Esc + 'PC03,0' + _Enter) // Velocidade
		fwrite (_nHdl, _Esc + 'PC09,2' + _Enter) // Darkness
		fwrite (_nHdl, _Esc + '%1' + _Enter)     // Rotacao
		
		// Produto em mais de uma linha
		fwrite (_nHdl, _Esc + 'H0050')		 		      // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		      // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		  // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + _sDescri1 + _Enter ) // Informacao a ser impressa
				
		fwrite (_nHdl, _Esc + 'H0075')		 		      // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		      // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		  // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + _sDescri2 + _Enter ) // Informacao a ser impressa
		
		fwrite (_nHdl, _Esc + 'H0100')		 		      // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		      // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		  // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + _sDescri3 + _Enter ) // Informacao a ser impressa
		
		fwrite (_nHdl, _Esc + 'H0150')		 		                              // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                              // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                          // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'Doc: ' + Alltrim(_sDoc) + _Enter ) // Informacao a ser impressa
		
		// Observacoes - linha 1
		fwrite (_nHdl, _Esc + 'H0200')		 		      // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		      // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		  // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + _sObs1 + _Enter ) // Informacao a ser impressa
				
		// Observacoes - linha 2
		fwrite (_nHdl, _Esc + 'H0225')		 		      // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		      // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		  // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + _sObs2 + _Enter ) // Informacao a ser impressa

		fwrite (_nHdl, _Esc + 'H0300')		 		                                   // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                   // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                               // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'Lote: ' + AllTrim(_sLoteI) + _Enter) // Informacao a ser impressa

		fwrite (_nHdl, _Esc + 'H0325')		 		                                                                       // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                                                       // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                                                                   // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'Qtd: ' + Alltrim(_sQtd) + ' ' + AllTrim(_sUM) + _Enter) // Informacao a ser impressa

		fwrite (_nHdl, _Esc + 'H0400')		 		                                                                       // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                                                       // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                                                                   // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'Validade: ' + AllTrim(_sDataV) + _Enter) // Informacao a ser impressa

		fwrite (_nHdl, _Esc + 'H0425')		 		                                   // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                   // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                               // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'Etq: ' + AllTrim(_sCod) + _Enter) // Informacao a ser impressa

		// Codigo de barras com o numero da etiqueta.
		fwrite (_nHdl, _Esc + 'H0475')		 		// Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
		fwrite (_nHdl, _Esc + 'BG02110')	 			// Define ccdigo de barras (tipo, tamanho, altura)
		fwrite (_nHdl, '>G' + AllTrim(_sCod) + _Enter )			// Informacao a ser impressa no ccdigo de barras (estilo, dado)

		fwrite (_nHdl, _Esc + 'H0650')		 		                                   // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                   // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                               // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'DATA: ____________________' + _Enter) // Informacao a ser impressa

		fwrite (_nHdl, _Esc + 'H0700')		 		                                   // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                   // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                               // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'RESP: ____________________' + _Enter) // Informacao a ser impressa
		
		fwrite (_nHdl, _Esc + 'H0750')		 		                                   // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                   // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                               // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'ASS.: ____________________' + _Enter) // Informacao a ser impressa

		fwrite (_nHdl, _Esc + 'Q1' + _Enter)		 	// Define quantidade
		fwrite (_nHdl, _Esc + 'Z'  + _Enter)  	 		// Finaliza etiqueta

		reclock ("ZA1", .F.)
		za1 -> za1_impres = 'S'
		msunlock ()

	elseif _nModelImp == 2  // Impressora Argox/Datamax
		
		_sDescri1 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 1, 20)
		_sDescri2 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 21, 28)
		_sDescri3 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 49, 28)

		_sMargEsq = '070'
		fwrite (_nHdl, chr (2) + 'f220' + _Enter)  //  STX - inicio de etiqueta
		fwrite (_nHdl, chr (1) + 'D' + _Enter)  // SOH - inicio de header
		fwrite (_nHdl, chr (2) + 'n' + _Enter)
		fwrite (_nHdl, chr (2) + 'L' + _Enter)
		fwrite (_nHdl, 'D11' + _Enter)
		fwrite (_nHdl, 'H13' + _Enter)  // Temperatura
		fwrite (_nHdl, 'PC' + _Enter)  // Velocidade
		fwrite (_nHdl, '431100000' + _sMargEsq + '050' + _sDescri1 + _Enter)
		fwrite (_nHdl, '421100000' + _sMargEsq + '065' + _sDescri2 + _Enter)
		fwrite (_nHdl, '421100000' + _sMargEsq + '080' + _sDescri3 + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '105' + 'Doc: ' + Alltrim(_sDoc) + _Enter)
		fwrite (_nHdl, '421100000' + _sMargEsq + '120' + _sObs1 + _Enter)
		fwrite (_nHdl, '421100000' + _sMargEsq + '135' + _sObs2 + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '175' + 'Lote:' + _sLoteI + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '200' + 'Qtd:' + transform (ZA1->ZA1_QUANT, '@E 999,999,999.99') + ' ' + _sUM + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '240' + 'Validade:   ' + _sDataV + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '270' + 'Etiqueta:   ' + ZA1->ZA1_CODIGO + _Enter)
		fwrite (_nHdl, '4e5200000' + _sMargEsq + '320' + ZA1->ZA1_CODIGO + _Enter)  // cod barras
		fwrite (_nHdl, '431100000' + _sMargEsq + '350' + 'DATA: _______________' + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '375' + 'RESP: _______________' + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '400' + 'ASS.: _______________' + _Enter)
		fwrite (_nHdl, 'Q0001' + _Enter)
		fwrite (_nHdl, 'E' + _Enter)
		reclock ("ZA1", .F.)
		za1 -> za1_impres = 'S'
		msunlock ()
	elseif _lContinua
		u_help ("Impossivel imprimir etiqueta '" + za1 -> za1_codigo + "': formato nao disponivel para o modelo de impressora '" + cvaltochar (_nModelImp) + "'",, .t.)
		_lContinua = .F.
	endif
return _lContinua



// --------------------------------------------------------------------------
static function _ImpOP ()
	local _sOP        := ""
	local _sPbrt      := ""
	local _sData      := ""
	local _sLote      := ""
	local _sUM        := ""
	local _sDescri1   := ""
	local _sDescri2   := ""
	local _sDescri3   := ""
	local _sSeqEtq    := ""
	local _lContinua  := .T.

	if _lContinua .and. ! empty (ZA1 -> ZA1_OP)
		sc2 -> (dbsetorder (1))
		if ! sc2 -> (dbseek (xfilial ("SC2") + ZA1 -> ZA1_OP, .F.))
			_lContinua = U_MsgNoYes ("A O.P. '" + AllTrim(ZA1 -> ZA1_OP) + "' referenciada por esta etiqueta nao foi encontrada. Deseja imprimir a etiqueta assim mesmo?")
		endif
	endif

	if _lContinua

		// Prepara dados para impressao.
		_sProd := Alltrim(ZA1->ZA1_PROD)
		_sQtd  := Alltrim(cvaltochar(ZA1->ZA1_QUANT)) 
		_sCod  := Alltrim(ZA1->ZA1_CODIGO)
		_sOP   := Alltrim(ZA1->ZA1_OP)
		_sPbrt := Alltrim(cvaltochar(SB1->B1_PESBRU*ZA1_QUANT))

		if sc2 -> c2_vaqtetq != 0 .and. za1 -> za1_seq != 0
			_sSeqEtq = padc (alltrim (str (za1 -> za1_seq)) + '/' + alltrim (str (sc2 -> c2_vaqtetq)), 9, ' ')
		else
			_sSeqEtq = ''
		endif

		_sLote := iif (! empty (_sOP), substr (_sOP, 1, 8), '')
		_sData = dtoc (fBuscaCpo ("SC2", 1, xfilial ("SC2") + _sOP, "C2_DATPRF"))
		_sUM = sb1 -> b1_um
		_sDescri1 = substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 1, 25)
		_sDescri2 = substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 26, 25)
		_sDescri3 = substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 51, 25)

		Do Case
			Case _nModelImp == 1  // Impressora Sato

				// configuracao de velocidade
				fwrite (_nHdl, _Esc + 'A'   + _Enter)
				fwrite (_nHdl, _Esc + 'CS6' + _Enter)
				fwrite (_nHdl, _Esc + 'Z'   + _Enter)
				
				// configuracao de claridade
				fwrite (_nHdl, _Esc + 'A'   + _Enter)
				fwrite (_nHdl, _Esc + '#E1' + _Enter)
				fwrite (_nHdl, _Esc + 'Z'   + _Enter)
				
				// impressco das etiquetas
				fwrite (_nHdl, _Esc + 'A' + _Enter)  	  // Inicializa etiqueta
				fwrite (_nHdl, _Esc + 'PC03,0' + _Enter)  // Velocidade
				fwrite (_nHdl, _Esc + 'PC09,2' + _Enter)  // Darkness
				fwrite (_nHdl, _Esc + '%1' + _Enter)      // Rotacao
		
				// Codigo de barras do produto.
				fwrite (_nHdl, _Esc + 'H0050')		 		// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
				fwrite (_nHdl, _Esc + 'BG02070')	 			// Define ccdigo de barras (tipo, tamanho, altura)
				if sb1 -> b1_vafullw == 'S'
					if empty (sb1 -> b1_codbar)
						u_help ("Produto '" + alltrim (sb1 -> b1_cod) + "' nao tem codigo DUN14 informado no campo '" + alltrim (RetTitle ("B1_CODBAR")) + "'.")
					else
						fwrite (_nHdl, '>G' + alltrim (sb1 -> b1_codbar) + _Enter )			// Informacao a ser impressa no ccdigo de barras (estilo, dado)
					endif
				//else
				//	fwrite (_nHdl, '>G' + _sProd + _Enter )			// Informacao a ser impressa no ccdigo de barras (estilo, dado)
				endif
			
				// Codigo e descricao do produto - linha 1
				fwrite (_nHdl, _Esc + 'H0130')		 		// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
				fwrite (_nHdl, _Esc + '$B,025,028,0')	 		// Define fonte (espacamento, largura, altura e tipo)
				fwrite (_nHdl, _Esc + '$=' + _sDescri1 + _Enter )	// Informacao a ser impressa
						
				// Codigo e descricao do produto - linha 2
				fwrite (_nHdl, _Esc + 'H0155')		 		// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
				fwrite (_nHdl, _Esc + '$B,025,028,0')	 		// Define fonte (espacamento, largura, altura e tipo)
				fwrite (_nHdl, _Esc + '$=' + _sDescri2 + _Enter )	// Informacao a ser impressa
				
				// Codigo e descricao do produto - linha 3
				fwrite (_nHdl, _Esc + 'H0180')		 		// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
				fwrite (_nHdl, _Esc + '$B,025,028,0')	 		// Define fonte (espacamento, largura, altura e tipo)
				fwrite (_nHdl, _Esc + '$=' + _sDescri3 + _Enter )	// Informacao a ser impressa
				
				// Linha para OK.
				fwrite (_nHdl, _Esc + 'H0310')		 				// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0220')		 				// Define ponto vertical
				fwrite (_nHdl, _Esc + '$B,032,045,0')	 			// Define fonte (espacamento, largura, altura e tipo)
				fwrite (_nHdl, _Esc + '$=' + '______' + _Enter )	// Informacao a ser impressa
			
				// Verificado
				fwrite (_nHdl, _Esc + 'H0350')		 				// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0180')		 				// Define ponto vertical
				fwrite (_nHdl, _Esc + '$B,025,028,0')	 			// Define fonte (espacamento, largura, altura e tipo)
				fwrite (_nHdl, _Esc + '$=' + 'OK' + _Enter )	// Informacao a ser impressa
				
				// Linha legivel da quantidade.
				fwrite (_nHdl, _Esc + 'H0310')		 		// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
				fwrite (_nHdl, _Esc + '$A,035,055,0')	 		// Define fonte (espacamento, largura, altura e tipo)
				fwrite (_nHdl, _Esc + '$=' + 'Qtd: ' + _sQtd + ' ' + _sUM + _Enter )	// Informacao a ser impressa
				
				// Codigo de barras com o numero da etiqueta.
				fwrite (_nHdl, _Esc + 'H0410')		 		// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
				fwrite (_nHdl, _Esc + 'BG02110')	 			// Define ccdigo de barras (tipo, tamanho, altura)
				fwrite (_nHdl, '>G' + _sCod + _Enter )			// Informacao a ser impressa no ccdigo de barras (estilo, dado)
			
				// Linha legivel com o numero da etiqueta.
				fwrite (_nHdl, _Esc + 'H0520')		 		// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
				fwrite (_nHdl, _Esc + '$A,035,055,0')	 		// Define fonte (espacamento, largura, altura e tipo)
				fwrite (_nHdl, _Esc + '$=' + 'Etq: ' + _sCod + _Enter )	// Informacao a ser impressa
			
				// Linha legivel com a sequencia da etiqueta dentro do grupo (1 de 3, 2 de 3, ...)
				fwrite (_nHdl, _Esc + 'H0540')		 		// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0170')		 		// Define ponto vertical
				fwrite (_nHdl, _Esc + '$A,025,028,0')	 		// Define fonte (espacamento, largura, altura e tipo)
				fwrite (_nHdl, _Esc + '$=' + _sSeqEtq + _Enter )	// Informacao a ser impressa
		
				// Codigo de barras com o numero do lote.
				if ! empty (_sLote)
					fwrite (_nHdl, _Esc + 'H0600')		 		// Define ponto horizontal
					fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
					fwrite (_nHdl, _Esc + 'BG02070')	 			// Define ccdigo de barras (tipo, tamanho, altura)
					fwrite (_nHdl, '>G' + _sLote + _Enter )			// Informacao a ser impressa no ccdigo de barras (estilo, dado)
		
					// Linha legivel com o numero do lote.
					fwrite (_nHdl, _Esc + 'H0670')		 		// Define ponto horizontal
					fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
					fwrite (_nHdl, _Esc + '$A,035,045,0')	 		// Define fonte (espacamento, largura, altura e tipo)
					fwrite (_nHdl, _Esc + '$=' + 'Lote: ' + _sLote + _Enter )	// Informacao a ser impressa
				endif
			
				// Linha legivel com a data.
				fwrite (_nHdl, _Esc + 'H0740')		 		// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
				fwrite (_nHdl, _Esc + '$A,030,042,0')	 	// Define fonte (espacamento, largura, altura e tipo)
			//	fwrite (_nHdl, _Esc + '$=' + 'Impressa em: ' + dtoc (date ()) + _Enter )	// Informacao a ser impressa
				fwrite (_nHdl, _Esc + '$=' + iif (za1 -> za1_impres == 'S', 'Re', 'I') + 'mpressa em: ' + dtoc (date ()) + _Enter )	// Informacao a ser impressa
			
				// Linha legivel numero da OP
				fwrite (_nHdl, _Esc + '%2' + _Enter)	 	// Define rotacao
				fwrite (_nHdl, _Esc + 'H0760')		 		// Define ponto horizontal
				fwrite (_nHdl, _Esc + 'V00070')		 		// Define ponto vertical
				fwrite (_nHdl, _Esc + '$A,032,045,0')	 	// Define fonte (espacamento, largura, altura e tipo)
				fwrite (_nHdl, _Esc + '$=' + 'OP: ' + substr (_sOP, 1, 6) + '.' + substr (_sOP, 7, 2) + '.' + substr (_sOP, 9) + '  ' + 'P. Bruto: ' + _sPbrt + _Enter )	// Informacao a ser impressa
				
				fwrite (_nHdl, _Esc + 'Q1' + _Enter)		 	// Define quantidade
				fwrite (_nHdl, _Esc + 'Z'  + _Enter)  	 		// Finaliza etiqueta
	
				reclock ("ZA1", .F.)
				za1 -> za1_impres = 'S'
				msunlock ()
				
			Case _nModelImp == 2  // Impressora Datamax
			
				if sb1 -> b1_vafullw == 'S'   // busca codigo de barra do produto
					if empty (sb1 -> b1_codbar)
						u_help ("Produto '" + alltrim (sb1 -> b1_cod) + "' nao tem codigo DUN14 informado no campo '" + alltrim (RetTitle ("B1_CODBAR")) + "'.")
					else
						_sCodBarProd := alltrim (sb1 -> b1_codbar) 		
					endif
				endif
				
				_sQtdProd 	:= 'Qtd: ' + _sQtd + ' ' + _sUM 
				_sPnt 		:= '------'
				_TamFont 	:= '000'
				_sOK 		:= '  OK'
				_sCodBarEtq := Alltrim(ZA1->ZA1_CODIGO)
				_sEtq		:= 'ETQ: ' + Alltrim(ZA1->ZA1_CODIGO)
				_sLoteDesc	:= 'LOTE: ' + _sLote 
				// _sImpressa	:= 'Impressa em: ' + dtoc (date ())
				_sImpressa	:= iif (za1 -> za1_impres == 'S', 'Re', 'I') + 'mpressa em: ' + dtoc (date ())
				_sDescOp    := 'OP: ' + substr (_sOP, 1, 6) + '.' + substr (_sOP, 7, 2) + '.' + substr (_sOP, 9) + '  ' + 'P. Bruto: ' + _sPbrt 
				
				fwrite (_nHdl, chr (2) + 'f220' + _Enter)  //  STX - inicio de etiqueta
				fwrite (_nHdl, chr (1) + 'D' + _Enter)  // SOH - inicio de header
				fwrite (_nHdl, chr (2) + 'n' + _Enter)
				fwrite (_nHdl, chr (2) + 'L' + _Enter)
				fwrite (_nHdl, 'D11' + _Enter)
				fwrite (_nHdl, 'H13' + _Enter)  // Temperatura
				fwrite (_nHdl, 'PC'  + _Enter)  // Velocidade
				fwrite (_nHdl, '4e72' + _TamFont + '0007' + '0060' + _sCodBarProd + _Enter) // código de barra do produto
				fwrite (_nHdl, '4211' + _TamFont + '0007' + '0080' + _sDescri1    + _Enter) 	// descrição 
				fwrite (_nHdl, '4211' + _TamFont + '0007' + '0095' + _sDescri2    + _Enter)
				fwrite (_nHdl, '4211' + _TamFont + '0007' + '0110' + _sDescri3    + _Enter)
				fwrite (_nHdl, '4211' + _TamFont + '0007' + '0125' + _Enter)
				fwrite (_nHdl, '4311' + _TamFont + '0007' + '0180' + _sQtdProd   + _Enter) // quantidade
				fwrite (_nHdl, '4311' + _TamFont + '0130' + '0195' + _sPnt		 + _Enter) // pontilhado
				fwrite (_nHdl, '4211' + _TamFont + '0130' + '0205' + _sOK		 + _Enter) // OK
				fwrite (_nHdl, '4e52' + _TamFont + '0007' + '0260' + _sCodBarEtq + _Enter) // Código de barra etiqueta
				fwrite (_nHdl, '4311' + _TamFont + '0007' + '0285' + _sEtq		 + _Enter) // Etiqueta
				fwrite (_nHdl, '4211' + _TamFont + '0150' + '0285' + _sSeqEtq    + _Enter) // Sequencia da etiqueta
				fwrite (_nHdl, '4e52' + _TamFont + '0007' + '0340' + _sLote		 + _Enter) // Código de barras do lote
				fwrite (_nHdl, '4311' + _TamFont + '0007' + '0360' + _sLoteDesc	 + _Enter) // Lote
				fwrite (_nHdl, '4211' + _TamFont + '0007' + '0380' + _Enter) 
				fwrite (_nHdl, '4311' + _TamFont + '0007' + '0400' + _sImpressa	 + _Enter) // Impressa em:
				fwrite (_nHdl, '3311' + _TamFont + '0230' + '0400' + _sDescOp  	 + _Enter) // OP
				fwrite (_nHdl, 'Q0001' + _Enter)
				fwrite (_nHdl, 'E' + _Enter)
				
				reclock ("ZA1", .F.)
				za1 -> za1_impres = 'S'
				msunlock ()
			
			Otherwise
//			u_help ("Etiqueta nao disponivel para o modelo de impressora '" + cvaltochar (_nModelImp) + "'")
			u_help ("Impossivel imprimir etiqueta '" + za1 -> za1_codigo + "': formato nao disponivel para o modelo de impressora '" + cvaltochar (_nModelImp) + "'",, .t.)
			_lContinua = .F.
		EndCase
	endif
return _lContinua



// --------------------------------------------------------------------------
static function _ImpNF ()
	local _sDoc       := ""
	local _sDataF     := ""
	local _sDataV     := ""
	local _sUM        := ""
	local _sDescri1   := ""
	local _sDescri2   := ""
	local _sDescri3   := ""
	local _sNome1     := ""
	local _sNome2     := ""
	local _sLoteF	  := "" 
	local _sLoteI	  := ""				
	local _lContinua  := .T.
	local _sMargEsq   := ""

	if _lContinua
		// Prepara dados para impressao.
		_sProd := Alltrim(ZA1->ZA1_PROD)
		_sQtd  := Alltrim(cvaltochar(ZA1->ZA1_QUANT)) 
		_sCod  := Alltrim(ZA1->ZA1_CODIGO)
		
		// Prepara dados para impressao.
		_sDoc := Alltrim(za1 -> za1_doce) + '/' + alltrim (za1 -> za1_seriee)
		SA2 -> (dbsetorder (1))
		SA2 -> (dbseek (xfilial ("SA2") + ZA1->ZA1_FORNEC + ZA1->ZA1_LOJAF, .F.))
		SD1 -> (dbsetorder (1))  // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
		if ! SD1 -> (dbseek (xfilial ("SD1") + ZA1->ZA1_DOCE + ZA1->ZA1_SERIEE + ZA1->ZA1_FORNEC + ZA1->ZA1_LOJAF + ZA1->ZA1_PROD + ZA1->ZA1_ITEM, .F.))
			u_help ("Item nao encontrado na NF",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_sLoteF	:= SD1->D1_LOTEFOR 
		_sLoteI	:= SD1->D1_LOTECTL
		_sQtd   := Alltrim(cvaltochar(ZA1->ZA1_QUANT)) 
		_sUM    := sb1 -> b1_um
		
		// Quando mexer aqui, ajustar tambem o fonte que exporta para o WMS (EnvEtFul.prw)
		if ! _AchaSB8 (ZA1 -> ZA1_PROD, sd1 -> d1_lotectl, sd1 -> d1_local)
			u_help ("Lote '" + sd1 -> d1_lotectl + "' do produto '" + za1 -> za1_prod + "' referenciado pela nota '" + sd1 -> d1_doc + "' nao foi localizado na tabela SB8",, .t.)
			_lContinua = .F.
		else
			_sDataV := DTOC(SB8->B8_DTVALID)
			_sDataF := DTOC(SB8->B8_DFABRIC)
		endif
	endif

	if _lContinua .and. _nModelImp == 1  // Impressora Sato

		_sDescri1 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 1, 25)
		_sDescri2 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 26, 25)
		_sDescri3 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 51, 25)
		_sNome1 := substr (alltrim (SA2 -> a2_cod) + ' - ' + SA2 -> A2_nome, 1, 25)
		_sNome2 := substr (alltrim (SA2 -> a2_cod) + ' - ' + SA2 -> A2_nome, 26, 25)

		// configuracao de velocidade
		fwrite (_nHdl, _Esc + 'A'   + _Enter)
		fwrite (_nHdl, _Esc + 'CS6' + _Enter)
		fwrite (_nHdl, _Esc + 'Z'   + _Enter)
		
		// configuracao de claridade
		fwrite (_nHdl, _Esc + 'A'   + _Enter)
		fwrite (_nHdl, _Esc + '#E1' + _Enter)
		fwrite (_nHdl, _Esc + 'Z'   + _Enter)
		
		// impressco das etiquetas
		fwrite (_nHdl, _Esc + 'A' + _Enter)      // Inicializa etiqueta
		fwrite (_nHdl, _Esc + 'PC03,0' + _Enter) // Velocidade
		fwrite (_nHdl, _Esc + 'PC09,2' + _Enter) // Darkness
		fwrite (_nHdl, _Esc + '%1' + _Enter)     // Rotacao
		
		// codigo e descricao do produto - linha 1
		fwrite (_nHdl, _Esc + 'H0050')		 		      // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		      // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		  // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + _sDescri1 + _Enter ) // Informacao a ser impressa
				
		// codigo e descricao do produto - linha 2
		fwrite (_nHdl, _Esc + 'H0075')		 		      // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		      // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		  // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + _sDescri2 + _Enter ) // Informacao a ser impressa
		
		// codigo e descricao do produto - linha 3
		fwrite (_nHdl, _Esc + 'H0100')		 		      // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		      // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		  // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + _sDescri3 + _Enter ) // Informacao a ser impressa
		
		// H0125 (linha em branco)

		// linha legivel com o numero da nota.
		fwrite (_nHdl, _Esc + 'H0150')		 		                              // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                              // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                          // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'NF: ' + Alltrim(_sDoc) + _Enter ) // Informacao a ser impressa
		
		// H0175 (linha em branco)
		
		// codigo e nome do fornecedor - linha 1
		fwrite (_nHdl, _Esc + 'H0200')		 		      // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		      // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		  // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + _sNome1 + _Enter ) // Informacao a ser impressa
				
		// codigo e nome do fornecedor - linha 2
		fwrite (_nHdl, _Esc + 'H0225')		 		      // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		      // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		  // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + _sNome2 + _Enter ) // Informacao a ser impressa

		// H0250 (linha em branco)

		// linha legivel com o lote do fornecedor.
		fwrite (_nHdl, _Esc + 'H0275')		 		                                    // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                    // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                                // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'LOTE FORN: ' + AllTrim(_sLoteF) + _Enter) // Informacao a ser impressa

		// linha legivel com o lote interno.
		fwrite (_nHdl, _Esc + 'H0300')		 		                                   // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                   // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                               // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'LOTE INT: ' + AllTrim(_sLoteI) + _Enter) // Informacao a ser impressa

		// linha legivel da quantidade.
		fwrite (_nHdl, _Esc + 'H0325')		 		                                                                       // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                                                       // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                                                                   // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'QTD: ' + Alltrim(_sQtd) + ' ' + AllTrim(_sUM) + _Enter) // Informacao a ser impressa

		// H0350 (linha em branco)
		
		// linha legivel da fabricacao.
		fwrite (_nHdl, _Esc + 'H0375')		 		                                                                       // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                                                       // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                                                                   // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'FABRICACAO: ' + AllTrim(_sDataF) + _Enter) // Informacao a ser impressa

		// linha legivel do vencimento.
		fwrite (_nHdl, _Esc + 'H0400')		 		                                                                       // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                                                       // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                                                                   // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'VALIDADE: ' + AllTrim(_sDataV) + _Enter) // Informacao a ser impressa

		// linha legivel com o lote interno.
		fwrite (_nHdl, _Esc + 'H0425')		 		                                   // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                   // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                               // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'ETQ: ' + AllTrim(_sCod) + _Enter) // Informacao a ser impressa

		// H0450 (linha em branco)
		
		// Codigo de barras com o numero da etiqueta.
		fwrite (_nHdl, _Esc + 'H0475')		 		// Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		// Define ponto vertical
		fwrite (_nHdl, _Esc + 'BG02110')	 			// Define ccdigo de barras (tipo, tamanho, altura)
		fwrite (_nHdl, '>G' + AllTrim(_sCod) + _Enter )			// Informacao a ser impressa no ccdigo de barras (estilo, dado)

		// H0550 (linha em branco)

		// linha legivel com o lote interno.
		fwrite (_nHdl, _Esc + 'H0650')		 		                                   // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                   // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                               // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'DATA: ____________________' + _Enter) // Informacao a ser impressa

		// H0600 (linha em branco)

		// linha legivel com o lote interno.
		fwrite (_nHdl, _Esc + 'H0700')		 		                                   // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                   // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                               // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'RESP: ____________________' + _Enter) // Informacao a ser impressa
		
		// H0650 (linha em branco)

		// linha legivel com o lote interno.
		fwrite (_nHdl, _Esc + 'H0750')		 		                                   // Define ponto horizontal
		fwrite (_nHdl, _Esc + 'V0440')		 		                                   // Define ponto vertical
		fwrite (_nHdl, _Esc + '$B,025,028,0')	 		                               // Define fonte (espacamento, largura, altura e tipo)
		fwrite (_nHdl, _Esc + '$=' + 'ASS.: ____________________' + _Enter) // Informacao a ser impressa

		fwrite (_nHdl, _Esc + 'Q1' + _Enter)		 	// Define quantidade
		fwrite (_nHdl, _Esc + 'Z'  + _Enter)  	 		// Finaliza etiqueta

		reclock ("ZA1", .F.)
		za1 -> za1_impres = 'S'
		msunlock ()

	elseif _lContinua .and. _nModelImp == 2  // Impressora Argox/Datamax
		
		_sDescri1 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 1, 20)
		_sDescri2 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 21, 28)
		_sDescri3 := substr (alltrim (sb1 -> b1_cod) + ' - ' + sb1 -> b1_desc, 49, 28)
		_sNome1 := substr ('FORN:' + SA2 -> a2_cod + '/' + sa2 -> a2_loja + ' - ' + SA2 -> A2_nome, 1, 28)
		_sNome2 := substr ('FORN:' + SA2 -> a2_cod + '/' + sa2 -> a2_loja + ' - ' + SA2 -> A2_nome, 29, 28)

		_sMargEsq = '200' //'070'
		fwrite (_nHdl, chr (2) + 'f220' + _Enter)  //  STX - inicio de etiqueta
		fwrite (_nHdl, chr (1) + 'D' + _Enter)  // SOH - inicio de header
		fwrite (_nHdl, chr (2) + 'n' + _Enter)
		fwrite (_nHdl, chr (2) + 'L' + _Enter)
		fwrite (_nHdl, 'D11' + _Enter)
		fwrite (_nHdl, 'H13' + _Enter)  // Temperatura
		fwrite (_nHdl, 'PC' + _Enter)  // Velocidade
		fwrite (_nHdl, '431100000' + _sMargEsq + '050' + _sDescri1 + _Enter)
		fwrite (_nHdl, '421100000' + _sMargEsq + '065' + _sDescri2 + _Enter)
		fwrite (_nHdl, '421100000' + _sMargEsq + '080' + _sDescri3 + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '105' + 'NF: ' + Alltrim(_sDoc) + _Enter)
		fwrite (_nHdl, '421100000' + _sMargEsq + '120' + _sNome1 + _Enter)
		fwrite (_nHdl, '421100000' + _sMargEsq + '135' + _sNome2 + _Enter)

		fwrite (_nHdl, '421100000' + _sMargEsq + '155' + 'Lt.forn:' + _sLoteF + _Enter)
		
		fwrite (_nHdl, '431100000' + _sMargEsq + '175' + 'Lt.int:' + _sLoteI + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '200' + 'Qtd:' + transform (ZA1->ZA1_QUANT, '@E 999,999,999.99') + ' ' + _sUM + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '220' + 'FABRICACAO: ' + _sDataF + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '240' + 'VALIDADE:   ' + _sDataV + _Enter)
	//	fwrite (_nHdl, '431100000' + _sMargEsq + '270' + 'ETIQUETA:   ' + ZA1->ZA1_CODIGO + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '267' + 'ETIQUETA:   ' + ZA1->ZA1_CODIGO + _Enter)
	//	fwrite (_nHdl, '4e5200000' + _sMargEsq + '320' + ZA1->ZA1_CODIGO + _Enter)  // cod barras
		fwrite (_nHdl, '4e5200000' + _sMargEsq + '310' + ZA1->ZA1_CODIGO + _Enter)  // cod barras
	//	fwrite (_nHdl, '431100000' + _sMargEsq + '350' + 'DATA: _______________' + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '330' + 'DATA: _______________' + _Enter)
	//	fwrite (_nHdl, '431100000' + _sMargEsq + '375' + 'RESP: _______________' + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '350' + 'RESP: _______________' + _Enter)
	//	fwrite (_nHdl, '431100000' + _sMargEsq + '400' + 'ASS.: _______________' + _Enter)
		fwrite (_nHdl, '431100000' + _sMargEsq + '370' + 'ASS.: _______________' + _Enter)
		fwrite (_nHdl, 'Q0001' + _Enter)
		fwrite (_nHdl, 'E' + _Enter)
		reclock ("ZA1", .F.)
		za1 -> za1_impres = 'S'
		msunlock ()
	elseif _lContinua
		u_help ("Impossivel imprimir etiqueta '" + za1 -> za1_codigo + "': formato nao disponivel para o modelo de impressora '" + cvaltochar (_nModelImp) + "'",, .t.)
		_lContinua = .F.
	endif
return _lContinua



// --------------------------------------------------------------------------
// Posiciona tabela SB8 no registro referente ao lote solicitado.
static function _AchaSB8 (_sProduto, _sLote, _sAlmox)
	local _lRet    := .T.
	local _nRegSB8 := 0
	local _oSQL    := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery := "SELECT ISNULL (SB8.R_E_C_N_O_, 0)"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB8") + " SB8"
	_oSQL:_sQuery += " WHERE SB8.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SB8.B8_FILIAL   = '" + xfilial ("SB8") + "'"
	_oSQL:_sQuery +=   " AND SB8.B8_PRODUTO  = '" + _sProduto + "'"
	_oSQL:_sQuery +=   " AND SB8.B8_LOTECTL  = '" + _sLote    + "'"
	_oSQL:_sQuery +=   " AND SB8.B8_LOCAL    = '" + _sAlmox   + "'"
	_nRegSB8 = _oSQL:RetQry (1, .f.)
	if _nRegSB8 == 0
		_lRet = .F.
	else
		sb8 -> (dbgoto (_nRegSB8))
	endif
return _lRet



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                         PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Impressora                    ", "C", 2,  0,  "",   "ZX549", {},                         ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
