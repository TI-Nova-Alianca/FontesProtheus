// Programa...: ZA1In
// Autor......: Robert Koch (com base no EtqPllIn de Julio Pedroni)
// Data.......: 14/12/2020
// Descricao..: Initilizar etiqueta (desmembrado do VA_EtqPll.prw)
//
// Historico de alteracoes:
// 14/12/2020 - Robert - Testava campos do ZA1 antes de posicionar no registro.
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #PalavasChave      #etiquetas #pallets
// #TabelasPrincipais #ZA1
// #Modulos           #PCP

#include "rwmake.ch"

// ----------------------------------------------------------------
User Function ZA1In (_sCodigo, _bMostraMsg)
	local _oSQL      := NIL
	local _lContinua := .T.
	
	u_log2 ('info', 'Iniciando ' + procname ())

	za1 -> (dbsetorder(1))
	if ! za1 -> (dbseek(xFilial("ZA1") + AllTrim(_sCodigo), .F.))
		u_help ("Etiqueta '" + _sCodigo + "' nao encontrada!",, .t.)
		_lContinua = .F.
	endif

	// Verifica se o usuario tem liberacao.
	if ! empty (za1 -> za1_op) .and. ! U_ZZUVL ('073', __cUserID, .T.)
		_lContinua = .F.
	endif
	if ! empty (za1 -> za1_doce) .and. ! U_ZZUVL ('074', __cUserID, .T.)
		_lContinua = .F.
	endif

	if ! empty (ZA1 -> ZA1_OP) .and. _lContinua
		u_help ("A etiqueta '" + alltrim(ZA1 -> ZA1_CODIGO) + "' nao pode ser inutilizada por ser uma etiqueta de ordem de producao.",, .t.)
		_lContinua := .F.
	endif

	if (ZA1 -> ZA1_APONT == 'I') .and. _lContinua
		u_help ("A etiqueta '" + alltrim(ZA1 -> ZA1_CODIGO) + "' ja encontra-se inutilizada.",, .t.)
		_lContinua := .F.
	endif

	if _lContinua
		if _bMostraMsg
			_lContinua = .F.
			_lContinua = U_MsgNoYes ("Confirma a inutilização da etiqueta?")
		endif
		
		if _lContinua
		
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " UPDATE " + RetSQLName ("ZA1")
			_oSQL:_sQuery += " SET ZA1_APONT = 'I'" 
			_oSQL:_sQuery += " WHERE ZA1_CODIGO = '" + ZA1 -> ZA1_CODIGO + "'"
			_oSQL:_sQuery += " AND D_E_L_E_T_ = ''"
			_oSQL:Exec ()
			
			u_help ("Etiqueta '" + alltrim(_sCodigo) + "' inutilizada!" + chr(13) + "(Remover do Recipiente)")
		endif
	endif
return _lContinua
