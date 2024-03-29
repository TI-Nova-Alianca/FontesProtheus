// Programa:   VA_CCR2
// Autor:      Robert Koch
// Data:       04/05/2020
// Descricao:  Relatorio de calculo de custo de reposicao respeitando estrutura do produto acabado.
//             Criado com base no VA_CCR.PRW
//
// Historico de alteracoes:
// 06/05/2020 - Robert - Tamanho campo numero NF ajustado de 6 para 9 posicoes.
// 03/03/2023 - Robert - Possibilidade de retornar em formato XML, para posterior uso pelo web service/NaWeb
// 26/04/2023 - Robert - Ajustes retorno em XML
//

/*
- A sele��o de itens a listar se baseia na estrutura dos itens fabricados, por isso os par�metros citam 'estrutura'.
- As colunas iniciais (CODIGO,DESCRICAO,SEQ_ESTRUT,NIVEL) s�o geradas a partir da leitura da estrutura do item citado na coluna CODIGO, da� o motivo da repeti��o do mesmo.

- As demais colunas se referem sempre aos componentes encontrados na estrutura:
- QUANT_ESTR busca a quantidade necess�ria para a fabrica��o de uma unidade/caixa do produto final
- CUSTO_STD e DT_CUS_STD: s�o lidas do cadastro do componente e trazem, respectivamente, o seu custo de reposi��o atual e a data em que teve a �ltima altera��o.

- Colunas com nome iniciado por UC trazem dados da �ltimas compras:
- UC_CUS_01, UC_CUS_02, ... valores calculados de pre�o de reposi��o para a �ltima compra, pen�ltima, ... com a seguinte f�rmula:
(vl.produtos + seguro + despesa - desconto - ICMS (quando houver cr�dito) + frete - PIS - COFINS) / quantidade
- UC_DAT_01, UC_DAT_02, ... datas nas notas fiscais consideradas para o respectivo c�lculo
- Para confer�ncia s�o listados os dados da �ltima nota de entrada, nas colunas UC_NF, UC_FORNEC, UC_VALMERC, UC_SEGURO, UC_DESPESA, UC_DESCONT,  UC_CREDICM, UC_FRETE, UC_PIS, UC_COFINS, UC_QUANT

- CM_ULT_01, CM_ULT_02, ... �ltimos custos m�dios do componente nesta filial.
*/

// --------------------------------------------------------------------------
user function VA_CCR2 (_lAutomat, _lGeraXML)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	private _sXMLCCR := ''  // Deixar PRIVATE para ser alimentado pela subrotina.

	cPerg    := "VA_CCR2"
	_ValidPerg ()
	pergunte (cPerg, .F.)
	if _lAuto .or. pergunte (cPerg, .T.)
		processa ({|| _GeraPlan (_lGeraXML)})
	endif
return _sXMLCCR




// --------------------------------------------------------------------------
static function _GeraPlan (_lGeraXML)
	local _aCampos   := {}
	local _nCampo    := 0
	local _aArqtrb   := {}
	local _nUltCom   := 0
	local _aPais := {}
	local _nPai := 0
	local _aEstr := {}
	local _nComp := 0

	u_logsx1 (cperg)

	// Cria arquivo de trabalho para guardar os dados dos componentes das estruturas.
	// Todos estes campos devem existir, tambem, no arq. de trabalho _estrut.
	_aCampos = {}
	aadd (_aCampos, {"COMPON",     "C", 15, 0})
	aadd (_aCampos, {"tp_comp",    "C", 2,  0})
	aadd (_aCampos, {"DESC_comp",  "C", 60, 0})
	aadd (_aCampos, {"UN_MED_com", "C", 2,  0})
	aadd (_aCampos, {"CUSTO_STD",  "N", 15, 8})
	aadd (_aCampos, {"DT_CUS_STD", "D", 8,  0})
	for _nUltCom = 1 to 3
		aadd (_aCampos, {"UC_Cus_" + strzero (_nUltCom, 2), "N", 18, 4})
		aadd (_aCampos, {"UC_Dat_" + strzero (_nUltCom, 2), "D", 8,  0})
	next
	aadd (_aCampos, {"UC_NF",      "C", 9,  0})
	aadd (_aCampos, {"UC_FORNEC",  "C", 6,  0})
	aadd (_aCampos, {"UC_valmerc", "N", 18, 2})
	aadd (_aCampos, {"UC_seguro",  "N", 18, 2})
	aadd (_aCampos, {"UC_despesa", "N", 18, 2})
	aadd (_aCampos, {"UC_descont", "N", 18, 2})
	aadd (_aCampos, {"uc_credicm", "N", 18, 2})
	aadd (_aCampos, {"UC_frete",   "N", 18, 2})
	aadd (_aCampos, {"UC_pis",     "N", 18, 2})
	aadd (_aCampos, {"UC_cofins",  "N", 18, 2})
	aadd (_aCampos, {"UC_quant",   "N", 18, 2})
	aadd (_aCampos, {"CM_ult_01",  "N", 18, 2})
	aadd (_aCampos, {"CM_ult_02",  "N", 18, 2})
	aadd (_aCampos, {"CM_ult_03",  "N", 18, 2})

	U_ArqTrb ("Cria", "_comp", _aCampos, {'compon'}, @_aArqTrb)

	// Cria arquivo de trabalho para preparar resultado para usuario.
	// Vai conter os campos do componente mais alguns campos adicionais
	// indicando em qual estrutura foi encontrado.
	_aCampos = {}
	aadd (_aCampos, {"CODIGO",     "C", 15, 0})
	aadd (_aCampos, {"DESCRICAO",  "C", 60, 0})
	aadd (_aCampos, {"seq_estrut", "C", 3,  0})
	aadd (_aCampos, {"NIVEL",      "N", 2,  0})
	aadd (_aCampos, {"Quant_estr", "N", 18, 4})
	aadd (_aCampos, {"COMPON",     "C", 15, 0})
	aadd (_aCampos, {"tp_comp",    "C", 2,  0})
	aadd (_aCampos, {"DESC_comp",  "C", 60, 0})
	aadd (_aCampos, {"UN_MED_com", "C", 2,  0})
	aadd (_aCampos, {"CUSTO_STD",  "N", 15, 8})
	aadd (_aCampos, {"DT_CUS_STD", "D", 8,  0})
	for _nUltCom = 1 to 3
		aadd (_aCampos, {"UC_Cus_" + strzero (_nUltCom, 2), "N", 18, 4})
		aadd (_aCampos, {"UC_Dat_" + strzero (_nUltCom, 2), "D", 8,  0})
	next
	aadd (_aCampos, {"UC_NF",      "C", 9,  0})
	aadd (_aCampos, {"UC_FORNEC",  "C", 6,  0})
	aadd (_aCampos, {"UC_valmerc", "N", 18, 2})
	aadd (_aCampos, {"UC_seguro",  "N", 18, 2})
	aadd (_aCampos, {"UC_despesa", "N", 18, 2})
	aadd (_aCampos, {"UC_descont", "N", 18, 2})
	aadd (_aCampos, {"uc_credicm", "N", 18, 2})
	aadd (_aCampos, {"UC_frete",   "N", 18, 2})
	aadd (_aCampos, {"UC_pis",     "N", 18, 2})
	aadd (_aCampos, {"UC_cofins",  "N", 18, 2})
	aadd (_aCampos, {"UC_quant",   "N", 18, 2})
	aadd (_aCampos, {"CM_ult_01",  "N", 18, 2})
	aadd (_aCampos, {"CM_ult_02",  "N", 18, 2})
	aadd (_aCampos, {"CM_ult_03",  "N", 18, 2})
	U_ArqTrb ("Cria", "_estrut", _aCampos, {'codigo+seq_estrut'}, @_aArqTrb)

	// Monta lista de produtos pais cujas estruturas devem ser abertas.
	sb1 -> (dbsetorder (1))
	sb1 -> (dbseek (xfilial ("SB1") + mv_par01, .T.))
	do while ! sb1 -> (eof ()) .and. sb1 -> b1_filial == xfilial ("SB1") .and. sb1 -> b1_cod <= mv_par02
		if sb1 -> b1_tipo < mv_par03 .or. sb1 -> b1_tipo > mv_par04
			sb1 -> (dbskip ())
			loop
		endif
		if sb1 -> b1_codlin < mv_par06 .or. sb1 -> b1_codlin > mv_par07
			sb1 -> (dbskip ())
			loop
		endif
		if mv_par05 == 1 .and. (sb1 -> b1_vaforal == 'S' .or. sb1 -> b1_msblql == '1')
			sb1 -> (dbskip ())
			loop
		endif
		aadd (_aPais, {sb1 -> b1_cod, sb1 -> b1_desc, sb1 -> b1_revatu})
		sb1 -> (dbskip ())
	enddo
	//u_log ('pais:', _aPais)

	// Leitura de estruturas cujos componentes devem ser analisados.
	for _nPai = 1 to len (_aPais)
	//	u_logIni ('Pai ' + _aPais [_nPai, 1])
//		_aEstr := aclone (U_ML_Comp2 (_aPais [_nPai, 1], 1, '.t.', dDataBase, .F., .F., .F., .F., .F., '', .F., '.f.', .f., .F., _aPais [_nPai, 3]))
		_aEstr := aclone (U_ML_Comp2 (_aPais [_nPai, 1], 1, '.t.', dDataBase, .F., .F., .F., .F., .F., '', .F., '.f.', .T., .F., _aPais [_nPai, 3]))
//		u_log (_aEstr)

		// Varre estrutura do produto verificando se o componente deve ser considerado.
		for _nComp = 1 to len (_aEstr)
			if ! sb1 -> (dbseek (xfilial ("SB1") + _aEstr [_nComp, 2], .F.))
				u_help ("Cadastro do componente '" + _aEstr [_nComp, 2] + "' nao encontrado!")
			else
				// Mao de obra e uva nao interessam
				if ! sb1 -> b1_tipo $ 'MO' .and. ! sb1 -> b1_grupo $ '0400'
					// Se o componente jah consta na tabela de componentes, aproveita-o. Senao, busca seus dados e acrescenta-o na tabela para possivel uso em outra estrutura.
					if ! _comp -> (dbseek (_aEstr [_nComp, 2], .F.))
						reclock ('_comp', .T.)
						_comp -> compon     = _aEstr [_nComp, 2]
						_comp -> tp_comp    = sb1 -> b1_tipo
						_comp -> desc_comp  = sb1 -> b1_desc
						_comp -> un_med_com = sb1 -> b1_um
						_comp -> custo_std  = sb1 -> b1_custd
						_comp -> dt_cus_std = sb1 -> b1_datref
					
						// Atualiza o restante dos dados do componente.
						_AtuComp ()


		//				// PREENCHE COM DADOS FICTICIOS (DURANTE TESTES, PARA EXECUTAR MAIS RAPIDO)
		//				_comp -> UN_MED_com = 'CX'
		//				_comp -> tp_comp    = 'PA'
		//				//_comp -> custo_std  = 36
		//				_comp -> UC_Cus_01  = 1
		//				_comp -> UC_Dat_01  = stod ('20230327')
		//				_comp -> UC_Cus_02  = 2
		//				_comp -> UC_Dat_02  = stod ('20230327')
		//				_comp -> UC_Cus_03  = 3
		//				_comp -> UC_Dat_03  = stod ('20230327')



						msunlock ()
					endif

					// Agora tenho o arquivo de trabalho _comp posicionado no componente atual
					// da estrutura. Posso gravar o registro no arquivo de retorno para o usuario.
					reclock ('_estrut', .T.)
					_estrut -> codigo     = _aPais [_nPai, 1]
					_estrut -> descricao  = _aPais [_nPai, 2]
					_estrut -> seq_estrut = strzero (_nComp, 3)
					_estrut -> nivel      = _aEstr [_nComp, 1] // + 1
					_estrut -> quant_estr = _aEstr [_nComp, 4]

					// Copia todos os campos que contem nomes iguais.
					for _nCampo = 1 to _comp -> (fcount ())
						_sCampo = _comp -> (FieldName (_nCampo))
						_estrut -> &(_sCampo) := _comp -> &(_sCampo)
					next
					msunlock ()
				endif
			endif
		next
	//	u_logFim ('Pai ' + _aPais [_nPai, 1])
	next

//	_comp -> (dbgotop ())
//	u_logtrb ('_comp', .t.)

//	_estrut -> (dbgotop ())
//	u_logtrb ('_estrut', .t.)
	_estrut -> (dbgotop ())

	if _lGeraXML
		_GeraXML ()
	else
		U_Trb2XLS ('_estrut')
	endif

	U_ArqTrb ("FechaTodos",,,, @_aArqTrb)
return


// --------------------------------------------------------------------------
// Atualiza dados do componente
static function _AtuComp ()
	local _nUltCom := 0
	local _oSQL    := NIL
	local _sAliasQ := ''
	local _nUltMed := 0
	local _sCampo  := ''

	// Busca dados de ultimas compras.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := "SELECT CUSREPUNI, D1_DTDIGIT, D1_DOC, D1_FORNECE, D1_TOTAL, D1_SEGURO, D1_DESPESA,"
	_oSQL:_sQuery +=       " D1_VALDESC, F4_CREDICM, D1_VALICM, CONHFRETE, D1_VALIMP6, D1_VALIMP5, D1_QUANT"
	_oSQL:_sQuery += " FROM VA_ULTCOMP ('', 'zz', '" + _comp -> compon + "', 3)"
//	_oSQL:Log ()
	_oUltCom := ClsAUtil():New (_oSQL:Qry2Array (.F., .F.))
	if len (_oUltCom:_aArray) > 0
//		_comp -> c_std_calc = _oUltCom:_aArray [1, 1]
		//_comp -> Dt_Cus_Cal = stod (_oUltCom:_aArray [1, 2])
		//_comp -> Med_Ult_Co = _oUltCom:MediaCol (1)
		//_comp -> M_Antiga   = stod (_oUltCom:_aArray [len (_oUltCom:_aArray), 2])
		//_comp -> M_Recente  = stod (_oUltCom:_aArray [1, 2])

		// Busca dados abertos das ultimas compras
		// Inicia o preenchimento pela ultima compra e vai 'voltando' para que a ultima coluna sempre esteja
		// preenchida (pode nao haver tantas ultimas compras quanto solicitado pelo usuario).
		for _nUltCom = len (_oUltCom:_aArray) to 1 step -1
			_comp -> &("UC_Cus_" + strzero (_nUltCom, 2)) = _oUltCom:_aArray [_nUltCom, 1]
			_comp -> &("UC_Dat_" + strzero (_nUltCom, 2)) = stod (_oUltCom:_aArray [_nUltCom, 2])
		next

		// Grava dados abertos da ultima compra, para possibilitar a conferencia do calculo
		_comp -> UC_NF      = _oUltCom:_aArray [1, 3]
		_comp -> UC_FORNEC  = _oUltCom:_aArray [1, 4]
		_comp -> UC_valmerc = _oUltCom:_aArray [1, 5]
		_comp -> UC_seguro  = _oUltCom:_aArray [1, 6]
		_comp -> UC_despesa = _oUltCom:_aArray [1, 7]
		_comp -> UC_descont = _oUltCom:_aArray [1, 8]
		_comp -> uc_credicm = iif (_oUltCom:_aArray [1, 9] == 'S', _oUltCom:_aArray [1, 10], 0)
		_comp -> UC_frete   = _oUltCom:_aArray [1, 11]
		_comp -> UC_pis     = _oUltCom:_aArray [1, 12]
		_comp -> UC_cofins  = _oUltCom:_aArray [1, 13]
		_comp -> UC_quant   = _oUltCom:_aArray [1, 14]
	else
		U_Log2 ('info', '[' + procname () + ']Sem dados de ultimas compras para ' + _comp -> compon)
	endif

	// Busca ultimos custos medios
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := "SELECT TOP 3 sum (B9_VINI1) / sum (B9_QINI) VALOR"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB9") + " SB9 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND B9_FILIAL  = '" + xfilial ("SB9") + "'"
	_oSQL:_sQuery +=   " AND B9_COD     = '" + _comp -> compon + "'"
	_oSQL:_sQuery +=   " AND B9_QINI    > 0"
	_oSQL:_sQuery += " GROUP BY B9_DATA"
	_oSQL:_sQuery += " HAVING sum (B9_VINI1) / sum (B9_QINI) > 0"
	_oSQL:_sQuery += " ORDER BY B9_DATA DESC"
//	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.F.)
	_nUltMed = 1
	do while ! (_sAliasQ) -> (eof ())
		_sCampo = 'CM_ULT_' + strzero (_nUltMed, 2)
		_comp -> &(_sCampo) = (_sAliasQ) -> valor
		_nUltMed ++
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
return


// --------------------------------------------------------------------------
// Gera uma string XML a partir dos dados do arquivo de trabalho.
static function _GeraXML ()
	local _nHdl     := ''
	local _nNivel   := -1
	local _sItemPai := ''
	local _oPilhaIte := NIL

	// Cria 'pilhas' para controlar quantas tags de niveis e itens foram abertas.
	_oPilhaIte := ClsPilha ():New ()

	U_Log2 ('debug', '[' + procname () + ']gerando XML')
	_sXMLCCR = '<?xml version="1.0" encoding="UTF-8"?>'
	_sXMLCCR = '<estrutura>'
	_estrut -> (dbgotop ())
	_sItemPai = _estrut -> codigo
	do while ! _estrut -> (eof ())
		U_Log2 ('debug', '[' + procname () + ']Li ' + alltrim (_estrut -> compon) + ' niv=' + cvaltochar (_estrut -> nivel) + '  _nNivel=' + cvaltochar (_nNivel) + '  topo=' + cvaltochar (_oPilhaIte:RetTopo ()))

		// Se o nivel do arquivo aumentou, preciso aumentar as tags junto
		do while _estrut -> nivel > _nNivel
			_nNivel ++
			if _nNivel == 0  // O GX quer somente quando nivel = 0
				_sXMLCCR += '<nivel_' + alltrim (str (_estrut -> nivel)) + '>'
			endif
			U_Log2 ('aviso', '[' + procname () + ']abrindo nivel ' + cvaltochar (_estrut -> nivel) + ' para ' + _estrut -> compon)
		enddo

//		// Informa no XML "nao tente ler proximo nivel, por que nao existe."
//		if _estrut -> nivel <= _nNivel .and. _oPilhaIte:Altura() > 0
//			if _oPilhaIte:RetTopo () == _nNivel
//				//TESTE
//				IF _NNIVEL != 4
//					_sXMLCCR += '<nivel_' + cvaltochar (_nNivel + 1) + '></nivel_' + cvaltochar (_nNivel + 1) + '>'
//				ENDIF
//			endif
//		endif

		// Se tenho tag <item> aberta (do registro anterior) com mesmo nivel, devo fecha-la.
		if _estrut -> nivel == _nNivel .and. _oPilhaIte:Altura() > 0
			if _oPilhaIte:RetTopo () == _nNivel
				_sXMLCCR += '</nivel_' + cvaltochar (_nNivel) + 'Item>'
				_oPilhaIte:Desempilha ()
				U_Log2 ('debug', '[' + procname () + ']Fechei <item> e desempilhei por que tinha um aberto do registro anterior.')
			else
				U_Log2 ('debug', '[' + procname () + ']Nao vou fechar item por que o topo da pilha tem ' + cvaltochar (_oPilhaIte:RetTopo ()))
			endif
		endif

		// Se o nivel do arquivo diminuiu, preciso diminuir as tags junto
		_ReduzNiv (_estrut -> nivel, @_nNivel, @_oPilhaIte)

		// Se trocar de item pai, preciso identificar isso fechando o nivel 0 atual e abrindo um novo.
		if _estrut -> codigo != _sItemPai
			_sXMLCCR += '</nivel_0>'
			_sXMLCCR += '<nivel_0>'
			_sItemPai = _estrut -> codigo
		endif

		if _nNivel > 0  // SDT do NaWeb nao quer a tag <item> no nivel 0
			_sXMLCCR += '<nivel_' + cvaltochar (_nNivel) + 'Item>'
			_oPilhaIte:Empilha (_nNivel)
			U_Log2 ('debug', '[' + procname () + ']Empilhei ' + cvaltochar (_oPilhaIte:RetTopo ()) + ' antes de exportar ' + alltrim (_estrut -> compon))
		endif
		_sXMLCCR += '<cod>' + alltrim (_estrut -> compon) + '</cod>'
		_sXMLCCR += '<descr>' + alltrim (_estrut -> desc_comp) + '</descr>'
		_sXMLCCR += '<tipo>' + alltrim (_estrut -> tp_comp) + '</tipo>'
		_sXMLCCR += '<quant>' + cvaltochar (_estrut -> quant_estr) + '</quant>'
		_sXMLCCR += '<um>' + alltrim (_estrut -> un_med_com) + '</um>'
		_sXMLCCR += '<custo_std>' + cvaltochar (_estrut -> custo_std) + '</custo_std>'
		_sXMLCCR += '<uc01_prc>'  + cvaltochar (_estrut -> uc_cus_01) + '</uc01_prc>'
		_sXMLCCR += '<uc01_data>' + cvaltochar (_estrut -> uc_dat_01) + '</uc01_data>'
		_sXMLCCR += '<uc02_prc>'  + cvaltochar (_estrut -> uc_cus_02) + '</uc02_prc>'
		_sXMLCCR += '<uc02_data>' + cvaltochar (_estrut -> uc_dat_02) + '</uc02_data>'
		_sXMLCCR += '<uc03_prc>'  + cvaltochar (_estrut -> uc_cus_03) + '</uc03_prc>'
		_sXMLCCR += '<uc03_data>' + cvaltochar (_estrut -> uc_dat_03) + '</uc03_data>'
		_sXMLCCR += '<custo>0</custo>'

		_estrut -> (dbskip ())
	enddo

	// Verifica o que ficou por fechar (itens e niveis)
	U_Log2 ('debug', '[' + procname () + ']Terminei de ler o arquivo')

	// Informa no XML "nao tente ler proximo nivel, por que nao existe."
//	_sXMLCCR += '<nivel_' + cvaltochar (_nNivel + 1) + '></nivel_' + cvaltochar (_nNivel + 1) + '>'

	_ReduzNiv (0, @_nNivel, @_oPilhaIte)

	_sXMLCCR += '</nivel_0>'
	_sXMLCCR += '</estrutura>'
	
	_sXMLCCR = U_NoAcento (_sXMLCCR)
	_sXMLCCR = EncodeUTF8 (_sXMLCCR)

	// Exporta para arquivo, durante a implementacao, para conferencia.
	_sArqXML := 'c:\temp\va_ccr2.xml'
	if file (_sArqXML)
		delete file (_sArqXml)
	endif
	_nHdl = fcreate (_sArqXML, 0)
	fwrite (_nHdl, _sXMLCCR)
	fclose (_nHdl)
return


// --------------------------------------------------------------------------
static function _ReduzNiv (_nParaQual, _nNivel, _oPilhaIte)
	do while _nParaQual < _nNivel
		U_Log2 ('debug', '[' + procname () + ']  Comparando topo da pilha (' + cvaltochar (_oPilhaIte:RetTopo ()) + ') com _nNivel (' + cvaltochar (_nNivel) + ') antes de reduzir o nivel')
		if _oPilhaIte:RetTopo () == _nNivel
			U_Log2 ('aviso', '[' + procname () + ']  Fechando item e desempilhando por que vou reduzir o nivel.')
			_sXMLCCR += '</nivel_' + cvaltochar (_nNivel) + 'Item>'
			_oPilhaIte:Desempilha ()
		endif
		U_Log2 ('aviso', '[' + procname () + ']  Fechando nivel ' + cvaltochar (_nNivel))
		_nNivel --
	//	if _nNivel == 0  // O GX quer somente quando nivel = 0
	//		_sXMLCCR += '</nivel_' + alltrim (str (_nNivel)) + '>'
	//	endif
		U_Log2 ('debug', '[' + procname () + ']  Comparando topo da pilha (' + cvaltochar (_oPilhaIte:RetTopo ()) + ') com _nNivel (' + cvaltochar (_nNivel) + ') depois de reduzir o nivel')
		if _oPilhaIte:RetTopo () == _nNivel
			U_Log2 ('aviso', '[' + procname () + ']  Fechando item e desempilhando depois de reduzir o nivel.')
			_sXMLCCR += '</nivel_' + cvaltochar (_nNivel) + 'Item>'
			_oPilhaIte:Desempilha ()
		endif
	enddo
return


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                           Help
	aadd (_aRegsPerg, {01, "Produto (estrutura) inicial   ", "C", 15, 0,  "",   "SB1  ", {},                              ""})
	aadd (_aRegsPerg, {02, "Produto (estrutura) final     ", "C", 15, 0,  "",   "SB1  ", {},                              ""})
	aadd (_aRegsPerg, {03, "Tipo produto (estrut.) inicial", "C", 2,  0,  "",   "02   ", {},                              ""})
	aadd (_aRegsPerg, {04, "Tipo produto (estrut.) final  ", "C", 2,  0,  "",   "02   ", {},                              ""})
	aadd (_aRegsPerg, {05, "Situacao produto (estrutura)  ", "N", 1,  0,  "",   "     ", {'Apenas ativos', 'Todos'},      ""})
	aadd (_aRegsPerg, {06, "Linha coml. (estrut.) inicial ", "C", 2,  0,  "",   "ZX539", {},                              ""})
	aadd (_aRegsPerg, {07, "Linha coml. (estrut.) final   ", "C", 2,  0,  "",   "ZX539", {},                              ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
