// Programa...: ZX5_13
// Autor......: Robert Koch
// Data.......: 17/04/2017
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
// 24/12/2018 - Robert - Passa a safra como filtro para a funcao de alteracao do ZX5.
// 08/01/2019 - Robert - Passa campos para ordenacao do aCols.
// 16/05/2023 - Robert - Criado botao para listar as variedades ligadas ao grupo.
// 17/05/2023 - Robert - Criado botao para simular precos.
// 10/11/2023 - Robert - Criado botao para exportar a tabela em HTML.
// 30/12/2023 - Robert - Permite receber a safra como parametro.
//

#include "VA_INCLU.prw"

// --------------------------------------------------------------------------
User Function ZX5_13 (_sCodTab)
	local _sSafra   := space (4)
	local _aOrd     := {'ZX5_13SAFR', 'ZX5_13GRUP'}
	local _aBotAdic := {}

	if ! empty (_sCodTab)
		_sSafra = _sCodTab
	endif

	aadd (_aBotAdic, {"Variedades",    {|| U_ZX5_13LV (.t.)}, "Variedades",    "Variedades",    {|| .T.}})
//	aadd (_aBotAdic, {"Simular",       {|| U_ZX5_13SP ()},    "Simular",       "Simular",       {|| .T.}})
	aadd (_aBotAdic, {"Exportar HTML", {|| U_ZX5_13H  ()},    "Exportar HTML", "Exportar HTML", {|| .T.}})

	if U_ZZUVL ('051')
		do while .t.
			_sSafra = U_Get ('Cod.tabela (vazio=todas)', 'C', 4, '', '', _sSafra, .F., '.t.')
			if _sSafra == NIL .or. empty (_sSafra)
				U_ZX5A (4, "13", "U_ZX5_13LO ()", "allwaystrue ()", .T., NIL, _aOrd, _aBotAdic)
			else
				U_ZX5A (4, "13", "U_ZX5_13LO ()", "allwaystrue ()", .T., "zx5_13safr=='" + _sSafra + "'", _aOrd, _aBotAdic)
			endif
			if ! u_msgyesno ("Deseja abrir a tela novamente?")
				exit
			endif
		enddo
	endif
return


// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_13LO ()
	local _lRet := .T.
return _lRet


// --------------------------------------------------------------------------
// Listar as variedades ligadas ao grupo.
User Function ZX5_13LV (_lComTela)
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _oSQL := NIL
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT ZX5_14PROD AS VARIEDADE"
	_oSQL:_sQuery +=      ", RTRIM (B1_DESC) AS DESCRICAO"
	_oSQL:_sQuery +=      ", B1_VACOR AS COR"
	_oSQL:_sQuery +=      ", B1_VATTR AS TINTOREA"
	_oSQL:_sQuery +=      ", B1_VARUVA AS FINA_COMUM"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5, "
	_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " WHERE ZX5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_TABELA = '14'"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_14SAFR = '" + GDFieldGet ("ZX5_13SAFR") + "'"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_14GRUP = '" + GDFieldGet ("ZX5_13GRUP") + "'"
	_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=   " AND SB1.B1_COD     = ZX5_14PROD"
	_oSQL:_sQuery += " ORDER BY B1_DESC"
	_oSQL:Log ('[' + procname () + ']')
	if _lComTela
		_oSQL:F3Array ('Variedades ligadas ao grupo ' + GDFieldGet ("ZX5_13GRUP"), .t.)
	else
		_oSQL:Qry2Array (.f., .f.)
	endif
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return _oSQL:_xRetQry


// --------------------------------------------------------------------------
// Simular lista de precos.
User Function ZX5_13SP ()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local _aVaried    := {}
	local _sVaried    := ''
	local _aRetPrc    := {}
	local _aRetTbl    := {}
	local _nRetTbl    := 0
	local _aPrecos    := {}
	local _aCols      := {}
	local _sSafra     := GDFieldGet ("ZX5_13SAFR")
	local _sMsgSup    := ''
	static _sConduc   := 'L'
	static _sIntOuDec := 'I'

	u_help ("MELHORAR ESTA CONSULTA, POIS LEVA EM CONTA A FILIAL ATUAL (VINIFERAS, NA F01 E F09, ENTRAM COMO ISABEL)")
	u_help ("Lembrando: Para ter efeito, voce deve, antes, salvar os dados desta tela.")
	_aVaried = aclone (U_ZX5_13LV (.f.))
	if len (_aVaried) > 0
		_sVaried = U_ZX5_13LV (.f.) [1, 1]
	endif
	if empty (_sVaried)
		u_help ("Nao consegui identificar nenhuma variedade neste grupo, para poder simular precos.",, .t.)
	else
		_sConduc = U_Get ("Sistema de conducao [L/E]", 'C', 1, '@!', '', _sConduc, .F., '.t.')
		_sIntOuDec = U_Get ("Listar apenas graus [I]nteiros, ou com [D]ecimais?", 'C', 1, '@!', '', _sIntOuDec, .F., '.t.')

		_aCols := {}
		aadd (_aCols, {1, 'Grau',           30, '@E 99.99'})
		aadd (_aCols, {2, 'Prc compra',     60, '@E 9999.9999'})
		aadd (_aCols, {3, 'Prc CONAB',      60, '@E 9999.9999'})
		aadd (_aCols, {4, '% agio Alianca', 60, '@E 9999.9999'})
		aadd (_aCols, {5, '% agio MOC',     60, '@E 9999.9999'})

		do case
		case _sSafra == '2023'
			_aRetPrc = aclone (U_PrcUva23 (cFilAnt, _sVaried, 15, 'B', _sConduc, .T., .T.))
			_aRetTbl = aclone (_aRetPrc [4])
			U_Log2 ('debug', _aRetTbl)
			if ! empty (_aRetPrc [3])  // Possiveis mensagens do programa de calculo do preco
				U_Log2 ('debug', '[' + procname () + ']' + _aRetPrc [3])
			endif
			_aPrecos = {}
			for _nRetTbl = 1 to len (_aRetTbl)
				if _sIntOuDec == 'D' .or. _aRetTbl [_nRetTbl, .PrcUvaColGrau] == int (_aRetTbl [_nRetTbl, .PrcUvaColGrau])
					aadd (_aPrecos, {;
						_aRetTbl [_nRetTbl, .PrcUvaColGrau],;
						_aRetTbl [_nRetTbl, .PrcUvaColPrcCompra],;
						_aRetTbl [_nRetTbl, .PrcUvaColPrcMOC],;
						_aRetTbl [_nRetTbl, .PrcUvaColPercAgioAlianca],;
						_aRetTbl [_nRetTbl, .PrcUvaColPercAgioMOC];
						})
				endif
			next
			U_Log2 ('debug', '[' + procname () + ']_aPrecos:')
			U_Log2 ('debug', _aPrecos)
			_sMsgSup = 'Simulando variedade ' + alltrim (_sVaried) + ' - ' + alltrim (fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sVaried, "B1_DESC")) + ' (conducao = ' + _sConduc + ')'
			U_F3Array (_aPrecos, 'Precos simulados', _aCols, NIL, NIL, _sMsgSup, _aRetPrc [3], .t., 'C', TFont():New ("Courier New", 6, 14))
		otherwise
			u_help ("Sem tratamento para esta safra.",, .t.)
		endcase
	endif
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return


// --------------------------------------------------------------------------
// Exporta tabela em formato HTML
user function ZX5_13H ()
	local _sHTML   := ''
	local _nHdl    := 0
	local _sArq    := ''
	local _sCodTab := GDFieldGet ("ZX5_13SAFR")
	local _sVarUva := ''
	local _sConduc := ''
	local _sTipoTab := 'C'  // Por enquanto, apenas [C]ompra
	local _oTbUva  := NIL
	
	if left (GDFieldGet ("ZX5_13GRUP"), 1) == '1'
		_sVarUva = 'C'
	elseif left (GDFieldGet ("ZX5_13GRUP"), 1) $ '2/3'
		_sVarUva = 'F'
	endif

	if left (GDFieldGet ("ZX5_13GRUP"), 1) == '1'
		_sConduc = 'L'
	elseif left (GDFieldGet ("ZX5_13GRUP"), 1) == '2'
		_sConduc = 'E'
	elseif left (GDFieldGet ("ZX5_13GRUP"), 1) == '3'
		_sConduc = 'L'
	endif

	_oTbUva := ClsTbUva ():New ()
	_oTbUva:GeraAtrib (_sCodTab, _sTipoTab, _sVarUva, _sConduc, 'I')

	if empty (_oTbUva:CodTabela)
		u_help (_oTbUva:UltMsg,, .t.)
	else
		// Exporta para arquivo e manda abrir no navegador.
		_sHTML = _oTbUva:GeraHTM ()
		if empty (_sHTML)
			u_help (_oTbUva:UltMsg,, .t.)
		else
			_sArq := 'c:\temp\TabUva_' + _sCodTab + '_' + _sTipoTab + _sVarUva + _sConduc + '.htm'
			if file (_sArq)
				delete file (_sArq)
			endif
			_nHdl = fcreate (_sArq, 0)
			fwrite (_nHdl, _sHtml)
			fclose (_nHdl)
			ShellExecute ("Open", _sArq, "", "", 1)
		endif
	endif
return
