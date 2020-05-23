// Programa:   VA_CCR2
// Autor:      Robert Koch
// Data:       04/05/2020
// Descricao:  Relatorio de calculo de custo de reposicao respeitando estrutura do produto acabado.
//             Criado com base no VA_CCR.PRW
//
// Historico de alteracoes:
// 06/05/2020 - Robert - Tamanho campo numero NF ajustado de 6 para 9 posicoes.
//

/*
- A seleção de itens a listar se baseia na estrutura dos itens fabricados, por isso os parâmetros citam 'estrutura'.
- As colunas iniciais (CODIGO,DESCRICAO,SEQ_ESTRUT,NIVEL) são geradas a partir da leitura da estrutura do item citado na coluna CODIGO, daí o motivo da repetição do mesmo.

- As demais colunas se referem sempre aos componentes encontrados na estrutura:
- QUANT_ESTR busca a quantidade necessária para a fabricação de uma unidade/caixa do produto final
- CUSTO_STD e DT_CUS_STD: são lidas do cadastro do componente e trazem, respectivamente, o seu custo de reposição atual e a data em que teve a última alteração.

- Colunas com nome iniciado por UC trazem dados da últimas compras:
- UC_CUS_01, UC_CUS_02, ... valores calculados de preço de reposição para a última compra, penúltima, ... com a seguinte fórmula:
(vl.produtos + seguro + despesa - desconto - ICMS (quando houver crédito) + frete - PIS - COFINS) / quantidade
- UC_DAT_01, UC_DAT_02, ... datas nas notas fiscais consideradas para o respectivo cálculo
- Para conferência são listados os dados da última nota de entrada, nas colunas UC_NF, UC_FORNEC, UC_VALMERC, UC_SEGURO, UC_DESPESA, UC_DESCONT,  UC_CREDICM, UC_FRETE, UC_PIS, UC_COFINS, UC_QUANT

- CM_ULT_01, CM_ULT_02, ... últimos custos médios do componente nesta filial.
*/
// --------------------------------------------------------------------------
user function VA_CCR2 (_lAutomat)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	
	cPerg    := "VA_CCR2"
	_ValidPerg ()
	pergunte (cPerg, .F.)
	if _lAuto .or. pergunte (cPerg, .T.)
		processa ({|| _GeraPlan ()})
	endif
return




// --------------------------------------------------------------------------
static function _GeraPlan ()
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
	u_log ('pais:', _aPais)

	// Leitura de estruturas cujos componentes devem ser analisados.
	for _nPai = 1 to len (_aPais)
		u_logIni ('Pai ' + _aPais [_nPai, 1])
		_aEstr := aclone (U_ML_Comp2 (_aPais [_nPai, 1], 1, '.t.', dDataBase, .F., .F., .F., .F., .F., '', .F., '.f.', .f., .F., _aPais [_nPai, 3]))
		u_log (_aEstr)

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
						msunlock ()
//					else
//						u_log ('componente', _aEstr [_nComp, 2], 'jah estava em _compon')
					endif

					// Agora tenho o arquivo de trabalho _comp posicionado no componente atual
					// da estrutura. Posso gravar o registro no arquivo de retorno par o usuario.
					reclock ('_estrut', .T.)
					_estrut -> codigo     = _aPais [_nPai, 1]
					_estrut -> descricao  = _aPais [_nPai, 2]
					_estrut -> seq_estrut = strzero (_nComp, 3)
					_estrut -> nivel      = _aEstr [_nComp, 1] + 1
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
		u_logFim ('Pai ' + _aPais [_nPai, 1])
	next

//	_comp -> (dbgotop ())
//	u_logtrb ('_comp', .t.)

//	_estrut -> (dbgotop ())
//	u_logtrb ('_estrut', .t.)

	// Exporta o arquivo de trabalho para planilha.
	U_Trb2XLS ('_estrut')

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
		u_log ('Sem dados de ultimas compras')
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
