// Programa.: VA_ALTNAT
// Autor....: Cláudia Lionço
// Data.....: 08/06/2021
// Descricao: Tela para alteração da natureza em doc. de entrada. GLPI: 10083
//   
// #TipoDePrograma    #tela #atualizacao
// #Descricao         #Tela para alteração da natureza em doc. de entrada. GLPI: 10083
// #PalavasChave      #documento_de_entrada #natureza 
// #TabelasPrincipais #SF1 #SE2 
// #Modulos 		  #COM         
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------
#Include 'Protheus.ch'

User Function VA_ALTNAT(_sFilial, _sDoc, _sSerie, _sFornece, _sLoja)
    Local _aNat := {}
    Local _x    := 0
    Local _sNat := ""

    If U_ZZUVL ("130", __cUserID, .T.)
	
        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	    E2_NATUREZ "
        _oSQL:_sQuery += "     ,E2_CODRET "
        _oSQL:_sQuery += "     ,E2_DIRF "
        _oSQL:_sQuery += " FROM " + RetSQLName ("SE2") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND E2_FILIAL  = '" + _sFilial  + "' "
        _oSQL:_sQuery += " AND E2_NUM     = '" + _sDoc     + "' "
        _oSQL:_sQuery += " AND E2_PREFIXO = '" + _sSerie   + "' "
        _oSQL:_sQuery += " AND E2_FORNECE = '" + _sFornece + "' "
        _oSQL:_sQuery += " AND E2_LOJA    = '" + _sLoja    + "' "
        _aNat:= aclone (_oSQL:Qry2Array ())

        If len(_aNat) > 0
            For _x := 1 to Len(_aNat)
                _sNat    := _aNat[_x,1]
                _sCodRet := _aNat[_x,2]
                _sDirf   := _aNat[_x,3]
            Next

            If !empty(_sNat)
                If empty(_sCodRet) //.and. _sDirf == 2 // nao é retenção
                    NatAjust(_sFilial, _sDoc, _sSerie, _sFornece, _sLoja, _sNat)
                Else
                    u_help("Nota com retenção não permite alteração de natureza!")
                Endif
            Else
                u_help("Natureza não encontrada no documento de entrada selecionado!")
            EndIf
        Else
            u_help("Não encontrado titulos para o documento de entrada selecionado!")
        EndIf
    Else
        u_help(" Usuário sem acesso a rotina!")
    Endif
Return
//
// -------------------------------------------------------------------------------
// Realiza a gravação da nova natureza
Static Function NatAjust(_sFilial, _sDoc, _sSerie, _sFornece, _sLoja, _sNat)
    Local _lRet    := .F.
    Local _sNewNat := "          "
    local _sNF     := _sDoc + "/" + _sSerie
    Local _sFor    := _sFornece + "/" +  _sLoja + " - " + Posicione("SA2", 1, xFilial("SA2") + _sFornece ,"A2_NOME")
    Local oBut1
    Local oBut2
    Local oSay1
    Local oSay2
    Local oSay3
    Local oSay4
    Local oSay5
    Local oSay6
    Local oSay7
    Static oDlg

    DEFINE MSDIALOG oDlg TITLE "Atualizar Natureza" FROM 000, 000  TO 200, 400 COLORS 0, 16777215 PIXEL

    @ 010, 012 SAY oSay1 PROMPT "Nota Fiscal:" SIZE 035, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 010, 055 SAY oSay2 PROMPT _sNF SIZE 125, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 022, 012 SAY oSay3 PROMPT "Fornecedor:" SIZE 035, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 022, 055 SAY oSay4 PROMPT _sFor SIZE 125, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 035, 012 SAY oSay5 PROMPT "Natureza Atual:" SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 035, 055 SAY oSay6 PROMPT _sNat SIZE 050, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 047, 012 SAY oSay7 PROMPT "Natureza Nova:" SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 047, 055 MSGET oGet1 VAR _sNewNat SIZE 050, 010 F3 'SED' OF oDlg COLORS 0, 16777215 PIXEL
    //@ 047, 055 MSGET _sNewNat picture "@!" size 30, 11 F3 'NATF3'
    @ 070, 080 BUTTON oBut1 PROMPT "Cancelar" SIZE 037, 012 OF oDlg ACTION  (_lRet := .F., oDlg:End ()) PIXEL
    @ 070, 123 BUTTON oBut2 PROMPT "Salvar"   SIZE 037, 012 OF oDlg ACTION  (_lRet := .T., oDlg:End ()) PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED

    If _lRet

        _lRet2 := VerifNat(_sNewNat) // verifica se a natureza poderá ser gravada

        If _lRet2 
            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " UPDATE " + RetSQLName ("SE2") 
            _oSQL:_sQuery += "      SET  E2_NATUREZ = '" + alltrim(_sNewNat) + "'"
            _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
            _oSQL:_sQuery += " AND E2_FILIAL  = '" + _sFilial  + "' "
            _oSQL:_sQuery += " AND E2_NUM     = '" + _sDoc     + "' "
            _oSQL:_sQuery += " AND E2_PREFIXO = '" + _sSerie   + "' "
            _oSQL:_sQuery += " AND E2_FORNECE = '" + _sFornece + "' "
            _oSQL:_sQuery += " AND E2_LOJA    = '" + _sLoja    + "' "
            If _oSQL:Exec ()
                u_help("Atualização efetuada com sucesso!")
                //grava evento

                _oEvento    := NIL
                _oEvento := ClsEvent():new ()
                _oEvento:CodEven   = "SE2004"
                _oEvento:DtEvento  = date()
                _oEvento:Texto	   = "Alteração de natureza: NF " + _sFilial +"/"+ _sNF +" Nat. de:" + alltrim(_sNat) + " para " + alltrim(_sNewNat)
                _oEvento:Cliente   = _sFornece
                _oEvento:LojaCli   = _sLoja
                _oEvento:Grava ()
            Else
                u_help("Atualização não efetuada com sucesso!")
            EndIf
        Else
            u_help("A natureza " + alltrim(_sNewNat) + " está parametrizada para retenção. Não será possivel a troca de natureza.")
        EndIf
	EndIf

Return 
//
// -------------------------------------------------------------------------------
// Verifica se a natureza não é retenção, para poder alterar
Static Function VerifNat(_sNat)
    Local _lRet := .F.
    Local _aSED := {}

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += " 	   ED_CALCCOF"
    _oSQL:_sQuery += "    ,ED_CALCPIS"
    _oSQL:_sQuery += "    ,ED_CALCCSL"
    _oSQL:_sQuery += "    ,ED_PERCPIS"
    _oSQL:_sQuery += "    ,ED_PERCCOF"
    _oSQL:_sQuery += "    ,ED_PERCCSL"
    _oSQL:_sQuery += " FROM " + RetSQLName ("SED") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND ED_CODIGO    = '" + _sNat + "'"
    _aSED:= aclone (_oSQL:Qry2Array ())

    If Len(_aSED) > 0
        _sCCof := _aSED[1, 1]
        _sCPis := _aSED[1, 2]
        _sCCsl := _aSED[1, 3]
        _nPCof := _aSED[1, 4]
        _nPPis := _aSED[1, 5]
        _nPCsl := _aSED[1, 6]

        If _sCCof == 'N' .and. _sCPis == 'N' .and. _sCCsl == 'N' .and. _nPCof == 0 .and. _nPPis == 0 .and. _nPCsl == 0
            _lRet := .T.
        Else    
            _lRet := .F.
        EndIf
    EndIf
Return _lRet


