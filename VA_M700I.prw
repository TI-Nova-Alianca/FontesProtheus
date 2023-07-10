// Programa...: VA_M700I
// Autor......: Cláudia Lionço
// Data.......: 05/07/2023
// Descricao..: Importa Previsão de vendas
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Importa Previsão de vendas
// #PalavasChave      #vendas 
// #TabelasPrincipais #SC4
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------------------
User Function VA_M700I()
	Local cArq        := ""
	Local cMascara    := ".CSV|*.CSV"
	Local cTitulo     := "Importar arquivo"
	Local nMascpad    := 0
	Local cDirIni     := "\"
	Local lSalvar     := .T.
	Local nOpcoes     := GETF_LOCALHARD
	Local lArvore     := .F.
	Local cLinha  	  := ""
	Local aDados  	  := {}

    PRIVATE lMsErroAuto := .F.
    PRIVATE lAutoErrNoFile := .T.
	
	cArq := cGetFile( cMascara, cTitulo, nMascpad, cDirIni, lSalvar, nOpcoes, lArvore)

	If !File(cArq)
		MsgStop("O arquivo '" + cArq + "' não foi encontrado. Importação não realizada!","ATENCAO")
		Return
	EndIf

	FT_FUSE(cArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()

	While !FT_FEOF()
		cLinha := FT_FREADLN()
		AADD(aDados,Separa(cLinha,";",.T.))
		FT_FSKIP()		
	EndDo  

    MsgRun("Importando registros...", "Previsão de venda", {|| ImpReg(aDados) })
    
    u_help("Importação finalizada!")
Return
//
// ---------------------------------------------------------------------------------------------------
// Retorna documento
Static Function _BuscaDocumento()
    local _oSQL  := NIL
    Local _aDoc  := {}
    Local _x     := ""
    Local _sDoc  := ""

    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := " SELECT MAX(C4_DOC) FROM " + RetSQLName ("SC4") 
    _oSQL:_sQuery += " WHERE C4_FILIAL = '" + xFilial("SC4") + "'"
    _aDoc := aclone (_oSQL:Qry2Array (.F., .F.))

    If Len(_aDoc) > 0
        For _x:=1 to Len(_aDoc)
            _nNumero := val(_aDoc[_x, 1])
            _nNumero += 1
        Next
    else
        _nNumero := 1
    EndIf

    _sDoc := padl(alltrim(str(_nNumero)),9,'0')
    
Return _sDoc
//
// ---------------------------------------------------------------------------------------------------
// Importa os registros
Static Function ImpReg(aDados)
	Local _x		  := 0
    Local _y		  := 0
    Local _sDoc       := ""
    
    _sDoc := _BuscaDocumento()

    For _x:= 2 to Len(aDados)
        dbselectarea("SC4")
	    dbgotop()

        _sLinha := PADL(alltrim(aDados[_x, 1]),2,'0')
        _sMarca := PADL(alltrim(aDados[_x, 3]),2,'0')
        _sProd  := aDados[_x, 5] 
        _sAno   := year(date())     
    
        For _y:=1 to 12
            Do Case
                Case _y == 1
                    _nQtd := val(aDados[_x, 7])
                    _dDta := stod(alltrim(str(_sAno)) + '0101')
            
                Case _y == 2
                    _nQtd := val(aDados[_x, 8])
                    _dDta := stod(alltrim(str(_sAno)) + '0201')

                Case _y == 3
                    _nQtd := val(aDados[_x, 9])
                    _dDta := stod(alltrim(str(_sAno)) + '0301')

                Case _y == 4
                    _nQtd := val(aDados[_x,10])
                    _dDta := stod(alltrim(str(_sAno))+ '0401')

                Case _y == 5
                    _nQtd := val(aDados[_x,11])
                    _dDta := stod(alltrim(str(_sAno)) + '0501')

                Case _y == 6
                    _nQtd := val(aDados[_x,12])
                    _dDta := stod(alltrim(str(_sAno)) + '0601')

                Case _y == 7
                    _nQtd := val(aDados[_x,13])
                    _dDta := stod(alltrim(str(_sAno)) + '0701')

                Case _y == 8
                    _nQtd := val(aDados[_x,14])
                    _dDta := stod(alltrim(str(_sAno)) + '0801')

                Case _y == 9
                    _nQtd := val(aDados[_x,15])
                    _dDta := stod(alltrim(str(_sAno)) + '0901')

                Case _y == 10
                    _nQtd := val(aDados[_x,16])
                    _dDta := stod(alltrim(str(_sAno)) + '1001')

                Case _y == 11
                    _nQtd := val(aDados[_x,17])
                    _dDta := stod(alltrim(str(_sAno)) + '1101')

                Case _y == 12
                    _nQtd := val(aDados[_x,18])
                    _dDta := stod(alltrim(str(_sAno)) + '1201')

            EndCase

            reclock("SC4",.T.)
                SC4 -> C4_FILIAL    := xFilial("SC4")
                SC4 -> C4_PRODUTO   := _sProd
                SC4 -> C4_LOCAL     :=  '01'
                SC4 -> C4_DOC       := _sDoc
                SC4 -> C4_QUANT     := _nQtd
                SC4 -> C4_DATA      := _dDta
                SC4 -> C4_CODLIN    := _sLinha
                SC4 -> C4_VAMARCM   := _sMarca
			msunlock()
        Next
    Next

    dbselectarea("SC4")
	dbclosearea()
Return 
