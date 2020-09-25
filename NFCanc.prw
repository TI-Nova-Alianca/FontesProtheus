// Programa...: NFCanc
// Autor......: Júlio Pedroni
// Data.......: 14/06/2017
// Descricao..: Tela de consulta de NFs Canceladas.
//
// Historico de alteracoes:
// 24/11/2019 - Robert  - Estava fixo na filial 01.
// 06/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Pergunte em Loop
//
// --------------------------------------------------------------------------
user function NFCanc()
	local   _aAreaAnt := U_ML_SRArea ()
	local   _aAmbAnt  := U_SalvaAmb ()
	private cPerg     := "NFCANC"

	_ValidPerg()
	Pergunte(cPerg, .T.)
	
	processa({||_Tela()})
//	do while Pergunte(cPerg, .T.)
//		processa({||_Tela()})
//	enddo

	U_SalvaAmb(_aAmbAnt)
	U_ML_SRArea(_aAreaAnt)
return
//
// --------------------------------------------------------------------------
static function _Tela()
	local _oSQL := NIL

	_oSQL := ClsSQL():New()
	_oSQL:_sQuery := ""
	
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	  ZN_DATA AS DATA, " 
	_oSQL:_sQuery += " 	  ZN_HORA AS HORA, " 
	_oSQL:_sQuery += " 	  SZN.ZN_NFS AS NOTA, " 
	_oSQL:_sQuery += " 	  SZN.ZN_SERIES AS SERIE, "
	_oSQL:_sQuery += " 	  ZN_USUARIO AS USUARIO, " 
	_oSQL:_sQuery += " 	  SZN.ZN_CLIENTE AS CLIENTE, " 
	_oSQL:_sQuery += " 	  SZN.ZN_LOJACLI AS LOJA_CLI, " 
	_oSQL:_sQuery += " 	  A1_NOME AS NOME, "
	_oSQL:_sQuery += " 	  SZN.ZN_TEXTO AS TEXTO "
	_oSQL:_sQuery += " FROM "	
	_oSQL:_sQuery += " 	  SZN010 SZN, "
	_oSQL:_sQuery += " 	  SA1010 SA1 "
	_oSQL:_sQuery += " WHERE " 
	_oSQL:_sQuery += " 	  SZN.D_E_L_E_T_ = '' AND " 
//	_oSQL:_sQuery += " 	  ZN_FILIAL = '01' AND " 
	_oSQL:_sQuery += " 	  ZN_FILIAL = '" + xfilial ("SF2") + "' AND " 
	_oSQL:_sQuery += " 	  ZN_CODEVEN = 'SF2001' AND " 
	_oSQL:_sQuery += " 	  ZN_DATA BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "' AND " 
	_oSQL:_sQuery += " 	  ZN_NFS BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "' AND "
	_oSQL:_sQuery += " 	  SZN.ZN_CLIENTE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' AND "
	_oSQL:_sQuery += " 	  SA1.D_E_L_E_T_ = '' AND " 
	_oSQL:_sQuery += " 	  SA1.A1_FILIAL = '  ' AND " 
	_oSQL:_sQuery += " 	  A1_COD = SZN.ZN_CLIENTE AND " 
	_oSQL:_sQuery += " 	  SA1.A1_LOJA = SZN.ZN_LOJACLI "
	_oSQL:_sQuery += " ORDER BY "
	_oSQL:_sQuery += "    DATA, "
	_oSQL:_sQuery += "    HORA, "
	_oSQL:_sQuery += "    NOTA, "
	_oSQL:_sQuery += "    CLIENTE "
	
	_oSQL:F3Array ('Consulta de Notas Fiscais Canceladas')
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                          Help
	aadd (_aRegsPerg, {01, "Data Inicial                  ", "D", 8,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {02, "Data Final                    ", "D", 8,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {03, "Nota Inicial                  ", "C", 9,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {04, "Nota Final                    ", "C", 9,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {05, "Cliente Inicial               ", "C", 6,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {06, "Cliente Final                 ", "C", 6,  0,  "",   "",    {},                             ""})

	U_ValPerg(cPerg,_aRegsPerg,{},_aDefaults)
Return
