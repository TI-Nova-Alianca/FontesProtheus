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
// 30/08/2019 - Claudia - Alterado campo peso bruto para b1_pesbru.
// 02/10/2019 - Claudia - Criação da rotina de impressão de etiquetas de OP na impressora DATAMAX
// 24/01/2022 - Robert  - Vamos usar etiquetas no AX02, mesmo sem integracao com FullWMS (GLPI 11515).
// 02/02/2022 - Robert  - Imprime B8_DFABRIC e nao mais D1_DFABRIC como data de fabricacao nas etiq. de NF de entrada.
// 03/02/2022 - Claudia - Ajustada linha 628 de DTOC(SD1->B8_DFABRIC) para DTOC(SB8->B8_DFABRIC)
// 11/02/2022 - Robert  - Posicionava SB8 pelo D1_LOTEFOR. Alterado para posicionar pelo ZA1_PROD + D1_LOTECTL.
//                      - Posiciona o SB8 via query por que nao tem indice por produto+lote+local.
// 25/02/2022 - Robert  - Ajustes nas margens da etiq. de NF na impressora Argox/Datamax.
// 01/04/2022 - Robert  - Nao envia para FullWMS se for etiqueta de OP (envio vai ser feito noutro local) - GLPI 11825
// 11/05/2022 - Robert  - Quando reimpressao, imprime 'Reimpressa' em vez de 'Impressa'.
// 15/06/2022 - Robert  - Quando o produto nao controla lotes, nao tem data de
//                        validade, entao busca data atual+b1_prvalid (GLPI 12220)
// 18/07/2022 - Robert  - Nao formatava dt.valid como string na impressao do ZAG quando b1_rastro != 'L'
// 10/08/2022 - Robert  - Passa a retornar .T. ou .F. em caso de sucesso ou erro.
// 11/08/2022 - Robert  - Ajuste 'alias not in use' na impressao.
//                      - Grava msg em _oEtiq caso esteja instanciada.
// 12/08/2022 - Robert  - Revisao geral, reformatacao, melhorias na logica, adequacao para Datamax (GLPI 12474)
// 23/09/2022 - Robert  - Passa a (se nao receber) sempre instanciar ClsEtiq para leitura de alguns dados (GLPI 12220)
// 13/10/2022 - Robert  - Nao envia mais etiqueta para o Full apos impressao (fica por conta da rotina chamadora)
//                      - Criado tratamento para etiquetas geradas a partir do SD5 (GLPI 12651).
// 21/10/2022 - Robert  - Validar parametro VA_ETQOCBP: nao impressao cod.barras produto (GLPI 12344)
// 24/10/2022 - Robert  - Validar atributo :FinalidOP junto com parametro VA_ETQOCBP para nao impressao cod.barras produto (GLPI 12344)
// 09/12/2022 - Robert  - Nao busca mais nada do SB1 e SC2. Dados jah chegam como atributos do objeto.
// 08/02/2023 - Robert  - Eliminadas algumas linhas comentariadas.
// 10/03/2023 - Robert  - Tratamentos para novo campo ZAG_SEQ (ZA1_IDZAG passa a concatenar ZAG_DOC + ZAG_SEQ).
//

// -------------------------------------------------------------------------------------------------------------------
//user function ImpZA1 (_sEtiq, _sIdImpr, _oEtiq)
user function ImpZA1 (_sIdImpr, _oEtiq)
	local _aAreaAnt   := U_ML_SRArea ()
	local _lContinua  := .T.
	local _sAlmOri    := ''
	local _sTxtEtiq   := ''
//	local _oSQL       := NIL
	private _sEtqImp   := ''
	private _sProdImp  := ''
	private _sUMImp    := ''
	private _sQtdImp   := ''
	private _sDProImp1 := ''
	private _sDProImp2 := ''
	private _sDProImp3 := ''
	private _sPesoBImp := ''
	private _sCBarProd := ''
	private _sLoteImp  := ''
	private _sLtForImp := ''
	private _sVldLtImp := ''
	private _sDtFabImp := ''
	private _sFornImp1 := ""
	private _sFornImp2 := ""
	private _sSeqImp   := ""
	private _sDocImp   := ''
	private _sObsImp1  := ''
	private _sObsImp2  := ''
	private _sDImpImp  := ''
	private _sOPImp    := ''
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

	// Deixa o maximo de variaveis prontas para impressao, buscando manter
	// integridade entre as diferentes funcoes de impressao.
	if _lContinua
		_sEtqImp   = alltrim (_oEtiq:Codigo)
		_sProdImp  = alltrim (_oEtiq:Produto)
		_sUMImp    = _oEtiq:UM  //sb1 -> b1_um
		_sQtdImp   = alltrim (cvaltochar (_oEtiq:Quantidade))

		_sDProImp1 = substr (alltrim (_oEtiq:Produto) + ' - ' + _oEtiq:DescriProd, 1, 25)
		_sDProImp2 = substr (alltrim (_oEtiq:Produto) + ' - ' + _oEtiq:DescriProd, 26, 25)
		_sDProImp3 = substr (alltrim (_oEtiq:Produto) + ' - ' + _oEtiq:DescriProd, 51, 25)

		_sPesoBImp = alltrim (cvaltochar (_oEtiq:PesoBruto))
		_sDImpImp  = iif (za1 -> za1_impres == 'S', 'Reimpr:', 'Dt.Impr:') + dtoc (date ()) + ' ' + time ()
		_sVldLtImp = dtoc (_oEtiq:ValidLote)
		_sDtFabImp = dtoc (_oEtiq:DtFabrLote)
		if _oEtiq:B1_VAFullW == 'S'
			if empty (_oEtiq:B1_CodBar)
				u_help ("Produto '" + alltrim (_oEtiq:Produto) + "' nao tem codigo DUN14 informado no campo '" + alltrim (RetTitle ("B1_CODBAR")) + "'.",, .t.)
				_lContinua = .F.
			else
				_sCBarProd = alltrim (_oEtiq:B1_CodBar)  //sb1 -> b1_codbar)
			endif
		endif

		do case
		case ! empty (_oEtiq:IdZAG)
			zag -> (dbsetorder (1))  // ZAG_FILIAL+ ZAG_DOC + ZAG_SEQ
			if ! zag -> (dbseek (xfilial ("ZAG") + _oEtiq:IdZAG, .F.))
				u_help ("Documento de transferencia '" + _oEtiq:IdZAG + "' nao encontrado.",, .t.)
				_lContinua = .F.
			else
				_sDocImp  = 'Solic.transf:' + substr (_oEtiq:IdZAG, 1, 10) + '/' + substr (_oEtiq:IdZAG, 11, 2)
				_sLoteImp = _oEtiq:LoteProduto
				_sAlmOri  = zag -> zag_almori
				_sObsImp1 = left ('Tr.alm.' + zag -> zag_almori + ' -> ' + zag -> zag_almdst + ' (' + alltrim (zag -> zag_usrinc) + ')', 31)
				if zag -> zag_almdst != '01'  // Nao imprimir para nao aparecer 'devolucao', etc.
					_sObs2 = left (zag -> zag_motivo, 25)
				endif
			endif

		case ! empty (ZA1 -> ZA1_OP)
			_sOPImp   = 'OP: ' + substr (za1 -> za1_op, 1, 6) + '.' + substr (za1 -> za1_op, 7, 2) + '.' + substr (za1 -> za1_op, 9)
			_sLoteImp = iif (! empty (za1 -> za1_op), substr (za1 -> za1_op, 1, 8), '')
			sc2 -> (dbsetorder (1))
			if ! sc2 -> (dbseek (xfilial ("SC2") + ZA1 -> ZA1_OP, .F.))
				u_help ("A O.P. '" + AllTrim(ZA1 -> ZA1_OP) + "' referenciada pela etiqueta '" + _sEtqImp + "' nao foi encontrada.",, .t.)
				_lContinua = .F.
			else
				_sAlmOri = _oEtiq:AlmOrig //sc2 -> c2_local
				
				// O cod.barras da OP sobrepoe o do produto, pois vai ser usado no apontamento.
				_sCBarProd = alltrim (_oEtiq:CBEmbCol)  //sc2 -> c2_vaBarCx)
				
				// Sequencial de etiquetas (1 e 3, 2 de 3, ...) para ver se nao ficou alguma esquecida.
				if _oEtiq:QtEtqGrupo != 0 .and. _oEtiq:SeqNoGrupo != 0
					_sSeqImp = padc (alltrim (str (_oEtiq:SeqNoGrupo)) + '/' + alltrim (str (_oEtiq:QtEtqGrupo)), 9, ' ')
				else
					_sSeqImp = ''
				endif
			endif


		case ! empty (ZA1 -> ZA1_DOCE)
			_sDocImp = 'NF.' + alltrim (za1 -> za1_doce) + '/' + alltrim (za1 -> za1_seriee)
			sa2 -> (dbsetorder (1))
			if ! sa2 -> (dbseek (xfilial ("SA2") + ZA1->ZA1_FORNEC + ZA1->ZA1_LOJAF, .F.))
				u_help ("Fornecedor '" + ZA1->ZA1_FORNEC + '/' + ZA1->ZA1_LOJAF + "' referenciado na etiqueta '" + za1 -> za1_codigo + "' nao localizado!",, .t.)
				_lContinua = .F.
			else
				_sFornImp1 := substr ('Forn:' + SA2 -> a2_cod + '/' + sa2 -> a2_loja + ' - ' + SA2 -> A2_nome, 1, 25)
				_sFornImp2 := substr ('     ' + SA2 -> a2_cod + '/' + sa2 -> a2_loja + ' - ' + SA2 -> A2_nome, 26, 25)
				sd1 -> (dbsetorder (1))  // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
				if ! sd1 -> (dbseek (xfilial ("SD1") + ZA1->ZA1_DOCE + ZA1->ZA1_SERIEE + ZA1->ZA1_FORNEC + ZA1->ZA1_LOJAF + ZA1->ZA1_PROD + ZA1->ZA1_ITEM, .F.))
					u_help ("NF/fornecedor/produto/item " + ZA1->ZA1_DOCE + '/' + ZA1->ZA1_FORNEC + '/' + ZA1->ZA1_PROD + '/' + ZA1->ZA1_ITEM + " nao localizado na tabela SD1.",, .t.)
					_lContinua = .F.
				else
					_sLoteImp  = sd1 -> d1_lotectl
					_sLtForImp = sd1 -> d1_lotefor
					_sAlmOri   = sd1 -> d1_local
				endif
			endif

		case ! empty (_oEtiq:D5_NUMSEQ)  // Etiqueta gerada com base na tabela SD5.
			//u_logobj (_oEtiq)
			_sLoteImp = _oEtiq:LoteProduto
			_sAlmOri  = _oEtiq:AlmOrig

		otherwise
			u_help ("Tipo de etiqueta sem tratamento na leitura de dados iniciais para impressao no programa " + procname (),, .t.)
			_lContinua = .F.
		endcase
	endif

	// Se chegou aqui com todos os dados prontos, gera etiqueta em arquivo
	// temporario e copia-o para a porta selecionada.
	if _lContinua

		// Comandos iniciais e finais sao os mesmos, independente do tipo de etiqueta
		_sTxtEtiq = ''
		if _nModelImp == 1  // Sato
			_sTxtEtiq += _Esc + 'A'   + _Enter + _Esc + 'CS6' + _Enter + _Esc + 'Z'   + _Enter  // Velocidade
			_sTxtEtiq += _Esc + 'A'   + _Enter + _Esc + '#E1' + _Enter + _Esc + 'Z'   + _Enter  // Claridade
			_sTxtEtiq += _Esc + 'A' + _Enter  	  // Inicializa etiqueta
			_sTxtEtiq += _Esc + 'PC03,0' + _Enter  // Velocidade
			_sTxtEtiq += _Esc + 'PC09,2' + _Enter  // Darkness
			_sTxtEtiq += _Esc + '%1' + _Enter      // Rotacao

			// Adiciona 'miolo' da etiqueta, formatado conforme o tipo de aplicacao da etiqueta
			if ! empty (_oEtiq:OP)
				_sTxtEtiq += _FmtOP (_oEtiq)
			elseif ! empty (_oEtiq:IdZAG)
				_sTxtEtiq += _FmtZAG (_oEtiq)
			elseif ! empty (_oEtiq:DocEntrNum) .or. ! empty (_oEtiq:D5_NUMSEQ)
				_sTxtEtiq += _FmtNF (_oEtiq)
			else
				u_help ("Sem definicao de formatacao de etiqueta deste tipo na Sato.",, .t.)
			endif
			
			// Comandos finais da etiqueta.
			_sTxtEtiq += _Esc + 'Q1' + _Enter  // Quantidade
			_sTxtEtiq += _Esc + 'Z'  + _Enter  // Finaliza etiqueta

		elseif _nModelImp == 2  // Datamax

			_sTxtEtiq += chr (2) + 'f220' + _Enter  //  STX - inicio de etiqueta
			_sTxtEtiq += chr (1) + 'D' + _Enter  // SOH - inicio de header
			_sTxtEtiq += chr (2) + 'n' + _Enter
			_sTxtEtiq += chr (2) + 'L' + _Enter
			_sTxtEtiq += 'D11' + _Enter
			_sTxtEtiq += 'H13' + _Enter  // Temperatura
			_sTxtEtiq += 'PC'  + _Enter  // Velocidade
			
			// Adiciona 'miolo' da etiqueta, formatado conforme o tipo de aplicacao da etiqueta
			if ! empty (_oEtiq:OP)
				_sTxtEtiq += _FmtOP (_oEtiq)
			elseif ! empty (_oEtiq:IdZAG)
				_sTxtEtiq += _FmtZAG (_oEtiq)
			elseif ! empty (_oEtiq:DocEntrNum) .or. ! empty (_oEtiq:D5_NUMSEQ)
				_sTxtEtiq += _FmtNF (_oEtiq)
			else
				u_help ("Sem definicao de formatacao de etiqueta deste tipo na Datamax.",, .t.)
			endif
			
			// Comandos finais da etiqueta.
			_sTxtEtiq += 'Q0001' + _Enter
			_sTxtEtiq += 'E' + _Enter
		
		// ainda nao pronto
		elseif _nModelImp == 4  // BPLA usado pela Elgin L42 - manual online em https://docplayer.net/59879244-Programmer-s-manual-bpla.html
			_sTxtEtiq += chr (2) + 'L' + _Enter  //  STX - inicio de etiqueta
			_sTxtEtiq += 'n' + _Enter  // polegadas
			_sTxtEtiq += 'H25' + _Enter  // H=Temperatura (de 00 a 30)
			_sTxtEtiq += 'PE' + _Enter  // P=velocidade (de A a T)

			// Adiciona 'miolo' da etiqueta, formatado conforme o tipo de aplicacao da etiqueta
			if ! empty (_oEtiq:OP)
				_sTxtEtiq += _FmtOP (_oEtiq)
			elseif ! empty (_oEtiq:IdZAG)
				_sTxtEtiq += _FmtZAG (_oEtiq)
			elseif ! empty (_oEtiq:DocEntrNum) .or. ! empty (_oEtiq:D5_NUMSEQ)
				_sTxtEtiq += _FmtNF (_oEtiq)
			else
				u_help ("Sem definicao de formatacao de etiqueta deste tipo na Elgin.",, .t.)
			endif

			_sTxtEtiq += 'Q0001' + _Enter  // Quantidade
			_sTxtEtiq += 'E' + _Enter  // Final de etiqueta
		
		else
			u_help ("Sem definicao de comandos iniciais para este modelo de impressora.",, .t.)
		endif

		if _lContinua
			if alltrim (cUserName) == 'robert.koch'
				U_Log2 ('debug', '[' + procname () + ']' + _sTxtEtiq)
			endif
			_sArq = criatrab (NIL, .F.)
			_nHdl = fcreate (_sArq, 0)
			fwrite (_nHdl,_sTxtEtiq)
			fclose (_nHdl)
			copy file (_sArq) to (_sPortaImp)
			delete file (_sArq)
			u_log2 ('debug', '[' + procname () + ']Copiei etiq para ' + _sPortaImp)
			
			// Marca a etiqueta como jah impressa.
			if za1 -> za1_impres != 'S'
				reclock ("ZA1", .F.)
				za1 -> za1_impres = 'S'
				msunlock ()
				_oEtiq:Impressa = 'S'
			endif

			// Se tem objeto instanciado, nao custa nada gravar uma mensagem de retorno
			_oEtiq:UltMsg += 'Impressao enviada para ' + _sPortaImp

		endif
	endif
		
	U_ML_SRArea (_aAreaAnt)
Return _lContinua



// --------------------------------------------------------------------------
// Formatacao da etiqueta quando destina-se a OP
static function _FmtOP (_oEtiq)
	local _nMargEsq   := 0
	local _nMargSup   := 0
	local _sFmtOP     := ''
	local _lBarProdu  := .F.

	// Ateh este momento, o procedimento para OPs feitas em terceiros eh apontar 'de mentirinha'
	// como se tivesse sido produzida aqui, e enviar para a logistica. Robert, 24/10/2022
	if _oEtiq:FinalidOP == 'E' .or. GetMv ("VA_ETQOCBP") == 'S' .or. _oEtiq:ImprCBProd == 'S'
		_lBarProdu = .T.
	endif

	if _nModelImp == 1  // Impressora Sato
		if _lBarProdu
			_sFmtOP += _Esc + 'H0050' + _Esc + 'V0440'  // Coordenadas
			_sFmtOP += _Esc + 'BG02070'  // Define codigo de barras (tipo, tamanho, altura) ou fonte (espacamento, largura, altura e tipo)
			_sFmtOP += '>G' + _sCBarProd + _Enter  // Informacao a ser impressa no codigo de barras (estilo, dado)
		endif
		_sFmtOP += _Esc + 'H0130' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sDProImp1 + _Enter
		_sFmtOP += _Esc + 'H0155' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sDProImp2 + _Enter
		_sFmtOP += _Esc + 'H0180' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sDProImp3 + _Enter
		_sFmtOP += _Esc + 'H0310' + _Esc + 'V0220' + _Esc + '$B,032,045,0' + _Esc + '$=' + '______' + _Enter
		_sFmtOP += _Esc + 'H0350' + _Esc + 'V0180' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'OK' + _Enter
		_sFmtOP += _Esc + 'H0310' + _Esc + 'V0440' + _Esc + '$A,035,055,0' + _Esc + '$=' + 'Qtd: ' + _sQtdImp + ' ' + _sUMImp + _Enter
		_sFmtOP += _Esc + 'H0410' + _Esc + 'V0440' + _Esc + 'BG02110' + '>G' + _sEtqImp + _Enter
		_sFmtOP += _Esc + 'H0520' + _Esc + 'V0440' + _Esc + '$A,035,055,0' + _Esc + '$=' + 'Etq: ' + _sEtqImp + _Enter
		_sFmtOP += _Esc + 'H0540' + _Esc + 'V0170' + _Esc + '$A,025,028,0' + _Esc + '$=' + _sSeqImp + _Enter
		if ! empty (_sLoteImp)
			_sFmtOP += _Esc + 'H0600' + _Esc + 'V0440' + _Esc + 'BG02070' + '>G' + _sLoteImp + _Enter
			_sFmtOP += _Esc + 'H0670' + _Esc + 'V0440' + _Esc + '$A,035,045,0' + _Esc + '$=' + 'Lote: ' + _sLoteImp + _Enter
		endif
		_sFmtOP += _Esc + 'H0740' + _Esc + 'V0440' + _Esc + '$A,030,042,0' + _Esc + '$=' + _sDImpImp + _Enter
		_sFmtOP += _Esc + '%2' + _Enter // Rotacao
		_sFmtOP += _Esc + 'H0760' + _Esc + 'V00070' + _Esc + '$A,032,045,0' + _Esc + '$=' + 'OP: ' + _sOPImp + '  ' + 'P. Bruto: ' + _sPesoBImp + _Enter
		

	elseif _nModelImp == 2  // Impressora Datamax

		_nMargEsq = 15 //7
		_nMargSup = 30
		if _lBarProdu
			_sFmtOP += '4e72' + '000' + strzero (_nMargEsq, 4)       + strzero (_nMargSup +  10, 4) + _sCBarProd + _Enter // código de barra do produto
		endif
		_sFmtOP += '4211' + '000' + strzero (_nMargEsq, 4)       + strzero (_nMargSup +  30, 4) + _sDProImp1    + _Enter 	// descrição 
		_sFmtOP += '4211' + '000' + strzero (_nMargEsq, 4)       + strzero (_nMargSup +  45, 4) + _sDProImp2    + _Enter
		_sFmtOP += '4211' + '000' + strzero (_nMargEsq, 4)       + strzero (_nMargSup +  50, 4) + _sDProImp3    + _Enter
		_sFmtOP += '4311' + '000' + strzero (_nMargEsq, 4)       + strzero (_nMargSup + 120, 4) + 'QTD: ' + _sQtdImp + ' ' + _sUMImp + _Enter // quantidade
		_sFmtOP += '4211' + '000' + strzero (_nMargEsq + 120, 4) + strzero (_nMargSup + 135, 4) + '--------'    + _Enter // pontilhado
		_sFmtOP += '4211' + '000' + strzero (_nMargEsq + 120, 4) + strzero (_nMargSup + 145, 4) + '   OK'      + _Enter // OK
		_sFmtOP += '4e52' + '000' + strzero (_nMargEsq, 4)       + strzero (_nMargSup + 200, 4) + _sEtqImp    + _Enter // Código de barra etiqueta
		_sFmtOP += '4311' + '000' + strzero (_nMargEsq, 4)       + strzero (_nMargSup + 220, 4) + 'Etiq:' + _sEtqImp    + _Enter // Etiqueta
		_sFmtOP += '4211' + '000' + strzero (_nMargEsq + 140, 4) + strzero (_nMargSup + 225, 4) + _sSeqImp    + _Enter // Sequencia da etiqueta
		_sFmtOP += '4e52' + '000' + strzero (_nMargEsq, 4)       + strzero (_nMargSup + 280, 4) + _sLoteImp   + _Enter // Código de barras do lote
		_sFmtOP += '4311' + '000' + strzero (_nMargEsq, 4)       + strzero (_nMargSup + 300, 4) + 'LOTE:' + _sLoteImp + _Enter // Lote
		_sFmtOP += '4211' + '000' + strzero (_nMargEsq, 4)       + strzero (_nMargSup + 325, 4) + _sDImpImp + _Enter // Impressa em:
		_sFmtOP += '3311' + '000' + strzero (_nMargEsq + 210, 4) + strzero (_nMargSup + 335, 4) + _sOPImp + '  ' + 'Peso Bruto: ' + _sPesoBImp + _Enter // OP

	elseif _nModelImp == 4  // Impressora Elgin L42 (BPLA)

		// Formatacao BPLA:
		// A: rotacao (1 a 4)
		// B: 0-9=fonte(letras); A-T=cod.barras com linha legivel;a-t=sem linha legivel; X=grafico; Y-imagem
		// C: multiplicador de largura
		// D: multiplicador de altura
		// E: seletor de fonte / altura cod.barras
		// F: posicionamento (eixo X ou 'colunas')
		// G: posicionamento (eixo Y ou 'linhas')
		// H: dados (texto ou numeros para cod. barra)
		//           RBCDEEEFFFFGGGGH...
		_sFmtOP += '421100000150005posicao 15,5' + _Enter
		//_sFmtOP += '421100000150100posicao 15,100' + _Enter
		_sFmtOP += '421100000150200posicao 15,200' + _Enter
		_sFmtOP += '421100000150300posicao 15,300' + _Enter
		_sFmtOP += '421100000150350posicao 15,350' + _Enter
		_sFmtOP += '4E1204000150100' + _sEtqImp + _Enter // E=code128
		_sFmtOP += '4e1204000150250' + _sEtqImp + _Enter  // 4=rotacao;E=code128;1=unavailable;2=narrow bar width
		U_Log2 ('debug', _sFmtOP)
	endif

	if empty (_sFmtOP)
		u_help ("Sem tratamento para formatacao de impressao para este tipo de etiqueta no programa " + procname (),, .t.)
	endif
return _sFmtOP


// --------------------------------------------------------------------------
// Formatacao da etiqueta quando destina-se a uma transferencia da tabela ZAG
static function _FmtZAG (_oEtiq)
	local _nMargEsq   := 0
	local _nMargSup   := 0
	local _sFmtZAG    := ''

	if _nModelImp == 1  // Impressora Sato
		_sFmtZAG += _Esc + 'H0050' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sDProImp1 + _Enter
		_sFmtZAG += _Esc + 'H0075' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sDProImp2 + _Enter
		_sFmtZAG += _Esc + 'H0100' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sDProImp3 + _Enter
		_sFmtZAG += _Esc + 'H0150' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + Alltrim(_sDocImp) + _Enter
		_sFmtZAG += _Esc + 'H0200' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sObsImp1 + _Enter
		_sFmtZAG += _Esc + 'H0225' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sObsImp2 + _Enter
		_sFmtZAG += _Esc + 'H0300' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'Lote: ' + AllTrim(_sLoteImp) + _Enter
		_sFmtZAG += _Esc + 'H0335' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'Qtd: ' + Alltrim(_sQtdImp) + ' ' + AllTrim(_sUMImp) + _Enter
		_sFmtZAG += _Esc + 'H0400' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'Validade: ' + AllTrim(_sVldLtImp) + _Enter
		_sFmtZAG += _Esc + 'H0455' + _Esc + 'V0440' + _Esc + 'BG02110' + '>G' + AllTrim(_sEtqImp) + _Enter
		_sFmtZAG += _Esc + 'H0575' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'Etq: ' + AllTrim(_sEtqImp) + _Enter
		_sFmtZAG += _Esc + 'H0650' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'DATA: ____________________' + _Enter
		_sFmtZAG += _Esc + 'H0700' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'RESP: ____________________' + _Enter
		_sFmtZAG += _Esc + 'H0750' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'ASS.: ____________________' + _Enter

	elseif _nModelImp == 2  // Impressora Argox/Datamax
		_nMargEsq = 15 //7
		_nMargSup = 0
		_sFmtZAG += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup +  50, 4) + _sDProImp1 + _Enter
		_sFmtZAG += '4211' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup +  65, 4) + _sDProImp2 + _Enter
		_sFmtZAG += '4211' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup +  80, 4) + _sDProImp3 + _Enter
		_sFmtZAG += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 105, 4) + _sDocImp   + _Enter
		_sFmtZAG += '4211' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 120, 4) + _sObsImp1  + _Enter
		_sFmtZAG += '4211' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 135, 4) + _sObsImp2  + _Enter
		_sFmtZAG += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 160, 4) + 'Lote:' + _sLoteImp + _Enter
		_sFmtZAG += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 185, 4) + 'Qtd:' + _sQtdImp + ' ' + _sUMImp + _Enter
		_sFmtZAG += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 210, 4) + 'Validade:   ' + _sVldLtImp + _Enter
		_sFmtZAG += '4e52' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 260, 4) + _sEtqImp + _Enter  // Cod.barras
		_sFmtZAG += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 280, 4) + 'Etiqueta:   ' + _sEtqImp + _Enter
		_sFmtZAG += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 310, 4) + 'DATA: _______________' + _Enter
		_sFmtZAG += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 335, 4) + 'RESP: _______________' + _Enter
		_sFmtZAG += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 360, 4) + 'ASS.: _______________' + _Enter

	elseif _nModelImp == 4  // Impressora Elgin L42 (BPLA)
//			_sTxtEtiq += '1A3104000200020' + _oEtiq:Codigo + _Enter  // SOH - inicio de header

		// Formatacao BPLA:
		// R: rotacao (1 a 4)
		// B: 0-9=fonte(letras); A-T=cod.barras com linha legivel;a-t=sem linga legivel; X=grafico; Y-imagem
		// C: multiplicador de largura
		// D: multiplicador de altura
		// E: seletor de fonte / altura cod.barras
		// F: posicionamento (eixo X ou 'colunas')
		// G: posicionamento (eixo Y ou 'linhas')
		// H: dados (texto ou numeros para cod. barra)
		//           RBCDEEEFFFFGGGGH...
		_sFmtZAG += '421100000150005posicao 15,5' + _Enter
		_sFmtZAG += '421100000150200posicao 15,200' + _Enter
		_sFmtZAG += '421100000150300posicao 15,300' + _Enter
		_sFmtZAG += '421100000150350posicao 15,350' + _Enter
		_sFmtZAG += '4E1204000150100' + _sEtqImp + _Enter // E=code128
		_sFmtZAG += '4e1204000150250' + _sEtqImp + _Enter  // 4=rotacao;E=code128;1=unavailable;2=narrow bar width
	endif

	if empty (_sFmtZAG)
		u_help ("Sem tratamento para formatacao de impressao para este tipo de etiqueta no programa " + procname (),, .t.)
	endif
return _sFmtZAG


// --------------------------------------------------------------------------
// Formatacao da etiqueta quando originada por NF de entrada.
static function _FmtNF (_oEtiq)
	local _nMargEsq   := 0
	local _nMargSup   := 0
	local _sFmtNF     := ''

	if _nModelImp == 1  // Impressora Sato
		_sFmtNF += _Esc + 'H0050' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sDProImp1 + _Enter
		_sFmtNF += _Esc + 'H0075' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sDProImp2 + _Enter
		_sFmtNF += _Esc + 'H0100' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sDProImp3 + _Enter
		_sFmtNF += _Esc + 'H0150' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + Alltrim(_sDocImp) + _Enter
		_sFmtNF += _Esc + 'H0200' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sFornImp1 + _Enter
		_sFmtNF += _Esc + 'H0225' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + _sFornImp2 + _Enter
		if ! empty (_sLtForImp)
			_sFmtNF += _Esc + 'H0275' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'LOTE FORN: ' + AllTrim(_sLtForImp) + _Enter
		endif
		_sFmtNF += _Esc + 'H0300' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'LOTE INT: ' + AllTrim(_sLoteImp) + _Enter
		_sFmtNF += _Esc + 'H0325' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'QTD: ' + Alltrim(_sQtdImp) + ' ' + AllTrim(_sUMImp) + _Enter
		_sFmtNF += _Esc + 'H0375' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'FABRICACAO: ' + AllTrim(_sDtFabImp) + _Enter
		_sFmtNF += _Esc + 'H0400' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'VALIDADE: ' + AllTrim(_sVldLtImp) + _Enter
		_sFmtNF += _Esc + 'H0470' + _Esc + 'V0440' + _Esc + 'BG02110' + '>G' + AllTrim(_sEtqImp) + _Enter
		_sFmtNF += _Esc + 'H0600' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'ETQ: ' + AllTrim(_sEtqImp) + _Enter
		_sFmtNF += _Esc + 'H0650' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'DATA: ____________________' + _Enter
		_sFmtNF += _Esc + 'H0700' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'RESP: ____________________' + _Enter
		_sFmtNF += _Esc + 'H0750' + _Esc + 'V0440' + _Esc + '$B,025,028,0' + _Esc + '$=' + 'ASS.: ____________________' + _Enter

	elseif _nModelImp == 2  // Impressora Argox/Datamax
		_nMargEsq = 15 //7
		_nMargSup = 0
		_sFmtNF += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup +  50, 4) + _sDProImp1 + _Enter
		_sFmtNF += '4211' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup +  65, 4) + _sDProImp2 + _Enter
		_sFmtNF += '4211' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup +  80, 4) + _sDProImp3 + _Enter
		_sFmtNF += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 105, 4) + _sDocImp   + _Enter
		_sFmtNF += '4211' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 120, 4) + _sFornImp1 + _Enter
		_sFmtNF += '4211' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 135, 4) + _sFornImp2 + _Enter
		if ! empty (_sLtForImp)
			_sFmtNF += '4211' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 155, 4) + 'Lt.forn:' + _sLtForImp + _Enter
		endif
		_sFmtNF += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 175, 4) + 'Lt.int:' + _sLoteImp + _Enter
		_sFmtNF += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 200, 4) + 'Qtd:' + transform (ZA1->ZA1_QUANT, '@E 999,999,999.99') + ' ' + _sUMImp + _Enter
		_sFmtNF += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 220, 4) + 'FABRICACAO: ' + _sDtFabImp + _Enter
		_sFmtNF += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 240, 4) + 'VALIDADE:   ' + _sVldLtImp + _Enter
		_sFmtNF += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 267, 4) + 'ETIQUETA:   ' + _sEtqImp + _Enter
		_sFmtNF += '4e52' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 310, 4) + _sEtqImp + _Enter  // cod barras
		_sFmtNF += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 330, 4) + 'DATA: _______________' + _Enter
		_sFmtNF += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 350, 4) + 'RESP: _______________' + _Enter
		_sFmtNF += '4311' + '000' + strzero (_nMargEsq, 4) + strzero (_nMargSup + 370, 4) + 'ASS.: _______________' + _Enter
	endif
	if empty (_sFmtNF)
		u_help ("Sem tratamento para formatacao de impressao para este tipo de etiqueta no programa " + procname (),, .t.)
	endif
return _sFmtNF


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                         PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Impressora                    ", "C", 2,  0,  "",   "ZX549", {},                         ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
