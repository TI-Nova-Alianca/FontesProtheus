// Programa...: VA_M700D
// Autor......: Cláudia Lionço
// Data.......: 06/07/2023
// Descricao..: Deleta documento de Previsão de vendas
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Deleta documento de Previsão de vendas
// #PalavasChave      #vendas 
// #TabelasPrincipais #SC4
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------
User Function VA_M700D()

    cPerg   := "VA_MT700D"
	_ValidPerg ()
	If ! pergunte (cPerg, .T.)
		return
	Endif

    If !empty(mv_par01)
        MsgRun("Deletando registros...", "Previsão de venda", {|| DelReg(mv_par01) })
    else
        u_help("Documento vazio. Não será possível a exclusão!")
    EndIf

    u_help("Exclusão efetuada!")
Return
//
// -------------------------------------------------------------------------------------
// Deleta registros
Static Function DelReg(mv_par01) 

    dbselectarea("SC4")
    dbsetorder(3) // C4_FILIAL+C4_DOC+C4_ITEM+C4_PRODUTO+DTOS(C4_DATA)
    while !eof() .and. dbseek(xFilial("SC4") + mv_par01)
        reclock("SC4", .F.)
            SC4 -> (dbdelete())
        msunlock()
    dbskip()
	enddo
Return
//
// -------------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
    aadd (_aRegsPerg, {01, "Documento          ", "C", 9, 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return

