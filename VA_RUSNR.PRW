// Programa...: VA_RUSNR
// Autor......: Robert Koch
// Data.......: 05/02/2019
// Descricao..: Tela para informar NF de remessa de outra cooperativa. Usado para informar campos
//              especificos da tabela SZE quando for carga recebida de associados de outra cooperativa
//              e desejamos fazer amarracao com a NF de remessa correspondente.
//
// Historico de alteracoes:
// 09/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 -  SX3 
//
// --------------------------------------------------------------------------
User Function VA_RUSNR (_sQueFazer)
	if _sQueFazer == 'A'
		_Altera ()
	elseif _sQueFazer == 'V'
		_Valida ()
	endif
return
//
// --------------------------------------------------------------------------
static function _Altera ()
	local _aCampos := {}
	local i 	   := 1
	private aCpos  := {}
	private inclui := .F.
	private altera := .F.
	
	// Libera alteracao de campos especificos.
	aadd (_aCampos, "ZE_NFCOOP")
	aadd (_aCampos, "ZE_SNFCOOP")

//	DbSelectArea("SX3")
//	DbSetOrder(1)
//	DbSeek("SZE")
//	While !Eof() .and. SX3->X3_ARQUIVO == "SZE"
//		If X3Uso(SX3->X3_USADO) .and. ascan (_aCampos, alltrim (sx3 -> x3_campo)) > 0
//			aadd(aCpos,alltrim(SX3->X3_CAMPO))
//		EndIf
//		DbSkip()
//	End 

	_aCpoSX3 := FwSX3Util():GetAllFields('SZE')
	For i := 1 To Len(_aCpoSX3)
	    If(X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO')) .and. (ascan (_aCampos, GetSx3Cache(_aCpoSX3[i],'X3_CAMPO')) > 0 ))
	        aadd(aCpos, GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO'))
	        aadd(aCpos,'')
	    Endif
	Next i 
	
	AxAltera ("SZE", sze->(recno ()), 4, NIL, aCpos, NIL, NIL, "U_VA_RUSNR('V')")
Return
//
// --------------------------------------------------------------------------
static function _Valida ()
	local _lRet := .T.
	
	if _lRet .and. m->ze_coop != '000021'
		u_help ("Campo so deve ser informado quando cooperativa diferente de 000021")
		_lRet = .F.
	endif
	
	if _lRet
		sf1 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
		if ! sf1 -> (dbseek (xfilial ("SF1") + M->ZE_NFCOOP + M->ZE_SNFCOOP + m->ZE_COOP + m->ZE_LOJCOOP, .F.))
			u_help ("NF informada nao existe para o fornecedor " + m->ze_coop)
			_lRet = .F.
		endif
	endif
return _lRet
