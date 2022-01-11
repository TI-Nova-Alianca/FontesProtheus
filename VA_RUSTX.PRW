// Programa...: VA_RUSTX
// Autor......: Robert Koch
// Data.......: 03/01/2020
// Descricao..: Chama (re)transmissao do XML da contranota para a SEFAZ
//
// Historico de alteracoes:
//

// ------------------------------------------------------------------------------------
User Function va_rusTX ()
	local _aAreaAnt := U_ML_SRArea ()

	u_Log2 ('debug', 'Iniciando ' + procname ())
	if empty (sze -> ze_nfger)
		u_help ("Nao ha contranota gerada para esta carga.")
	else
		sf1 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
		if ! sf1 -> (dbseek (xfilial ("SF1") + sze -> ze_nfger + sze -> ze_serie + sze -> ze_assoc + sze -> ze_lojasso, .F.))
			u_help ("Contranota '" + sze -> ze_nfger + "' nao encontrada na tabela SF1")
		else
			CursorWait ()
			U_SpedAut ('E', sf1 -> f1_serie, sf1 -> f1_doc, sf1 -> f1_doc)
			CursorArrow ()
			dbselectarea ("SZE")
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return
