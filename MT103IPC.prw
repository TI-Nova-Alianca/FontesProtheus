// Programa...: MT103IPC
// Autor......: Robert Koch
// Data.......: 25/02/2008
// Descricao..: P.E. para atualizar dados adicionais da NF entrada apos ler dados do pedido.
//
// Historico de alteracoes:
// 22/06/2012 - Robert - Avisa usuario para ajustar natureza quando pedido da obra planta nova.
// 12/09/2014 - Robert - Busca qualquer campo (antes desconsiderava virtuais e padrao do sistema).
// 19/09/2014 - Robert - Volta a considerar campos virtuais e padrao do sistema.
// 29/06/2018 - Robert - Copia especificamente o campo C7_DESCRI para D1_DESCRI.
//

// --------------------------------------------------------------------------
User Function MT103IPC()
	local _aAreaAnt := U_ML_SRArea ()
	local _nItem    := Paramixb[1]    // numero do item do acols
	//local _lObra    := .F.

	// Varre campos do SC7 e atualiza no SD1 os que tiverem nomes iguais.
	DbSelectArea("SX3")
	DbSeek("SC7")
	Do While !Eof() .And. (X3_ARQUIVO=="SC7")
		
		// Campos padrao devem ser deixados em paz (carreguei o D1_ITEM com o C7_ITEM, por
		// exemplo, e me ferrei ao juntar mais de um pedido na mesma nota).
//		// Algumas excecoes devem ser avaliadas (descricao, por exemplo).
//		If (SX3->X3_CONTEXT == "V" .Or. SX3->X3_PROPRI<>"U") .and. ! alltrim (upper(sx3 -> x3_campo)) $ "C7_DESCRI/" 
		If (SX3->X3_CONTEXT == "V" .Or. SX3->X3_PROPRI<>"U") 
			DbSelectArea("SX3")
			DbSkip()
			Loop
		EndIf

		DbSelectArea("SC7")
		_wVALPED := "SC7->"+SX3->X3_CAMPO
		_wVALNFE := "D1_"+Alltrim(SubStr(SX3->X3_CAMPO,4,7))
		
		// Se Exitir o Campo no SD1 com o mesmo nome Atualiza
		If SD1->(FieldPos(_wVALNFE)) > 0 .and.GDFieldPos (_wValNFE) > 0
			GDFieldPut (_wVALNFE, &(_wValPed), _nItem)
		Endif
		
		DbSelectArea("SX3")
		DbSkip()
	Enddo

	// Copia a descricao do pedido para a nota.
	GDFieldPut ("D1_DESCRI", sc7 -> c7_descri, _nItem)
	
	U_ML_SRArea (_aAreaAnt)
Return
