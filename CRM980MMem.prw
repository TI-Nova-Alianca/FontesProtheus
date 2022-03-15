// Programa...: CRM980MDef
// Autor......: Cláudia Lionço
// Data.......: 15/03/2022
// Descricao..: Adiciona novas funcionalidades em Ações Relacionadas no browse
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Adiciona novas funcionalidades em Ações Relacionadas no browse
// #PalavasChave      #cadastro_de_cliente #codigo_matriz 
// #TabelasPrincipais #SA1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 15/03/2022 - Claudia - Criação de rotina para gravação de codigo matriz. GLPI: 11635
//
// -------------------------------------------------------------------------
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

User Function CRM980MDef()
    Local aRotina := {}
    //----------------------------------------------------------------------------------------------------------
    // [n][1] - Nome da Funcionalidade
    // [n][2] - Função de Usuário
    // [n][3] - Operação (1-Pesquisa; 2-Visualização; 3-Inclusão; 4-Alteração; 5-Exclusão)
    // [n][4] - Acesso relacionado a rotina, se esta posição não for informada nenhum acesso será validado
    //----------------------------------------------------------------------------------------------------------
    aAdd(aRotina,{"Incluir Cod. Matriz","u_VA_CODMAT()",4,0})
Return( aRotina )
//
// -------------------------------------------------------------------------
// Tela de cadastro do código matriz
User Function VA_CODMAT()
    Local oButton1  
    Local oGet1
    Local _sCodMat := space(6)
    Local oGet2
    Local _sLojMat := space(2)
    Local oSay1
    Local oSay2
    Local oSay3
    Local oSay4
    Local oSay5
    Local oSay6
    Local _sCliente := SA1->A1_COD +"/" + SA1->A1_LOJA
    Local _sNome    := SA1->A1_NOME
    Local _sMatOld  := SA1->A1_VACBASE +"/"+ A1_VALBASE
    Local _lRet := .F.
    Static oDlg

    DEFINE MSDIALOG oDlg TITLE "Incluir/Alterar Código Matriz" FROM 000, 000  TO 180, 320 COLORS 0, 16777215 PIXEL

        @ 007, 010 SAY oSay1 PROMPT "Cliente:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 020, 010 SAY oSay2 PROMPT "Nome" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 040, 010 SAY oSay3 PROMPT "Código Matriz" SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 052, 010 SAY oSay4 PROMPT "Loja" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 007, 040 SAY oSay5 PROMPT _sCliente SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 020, 040 SAY oSay6 PROMPT _sNome SIZE 115, 007 OF oDlg COLORS 0, 16777215 PIXEL
        @ 040, 050 MSGET oGet1 VAR _sCodMat SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
        @ 052, 050 MSGET oGet2 VAR _sLojMat SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
        @ 066, 072 BUTTON oButton1 PROMPT "Gravar" SIZE 037, 012 OF oDlg ACTION  (_lRet := .T., oDlg:End ()) PIXEL  


    ACTIVATE MSDIALOG oDlg CENTERED

    If _lRet
        _lRet2 := VerifCliente(_sCodMat, _sLojMat) // verifica se o cliente digitado existe

        If _lRet2 
            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " UPDATE " + RetSQLName ("SA1") 
            _oSQL:_sQuery += "      SET  A1_VACBASE = '"+alltrim(_sCodMat)+"', A1_VALBASE = '" + alltrim(_sLojMat) + "'"
            _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
            _oSQL:_sQuery += " AND A1_COD  = '" + SA1->A1_COD  + "' "
            _oSQL:_sQuery += " AND A1_LOJA = '" + SA1->A1_LOJA + "' "
            _oSQL:Log ()

            If _oSQL:Exec ()
                u_help("Atualização efetuada com sucesso!")

                _oEvento    := NIL
                _oEvento := ClsEvent():new ()
                _oEvento:CodEven   = "SA1005"
                _oEvento:DtEvento  = date()
                _oEvento:Texto	   = "Alteração: Cod.matriz Ant.:" + _sMatOld + " Cod.matriz Novo:" + alltrim(_sCodMat) + "/" + alltrim(_sLojMat)
                _oEvento:Cliente   = SA1->A1_COD
                _oEvento:LojaCli   = SA1->A1_NOME
                _oEvento:Grava ()
            Else
                u_help("Atualização não efetuada com sucesso!")
            EndIF
        EndIf
    EndIf
Return
//
// -------------------------------------------------------------------------
// Valida se o código matriz é um cliente cadastrado
Static Function VerifCliente(_sCodMat, _sLojMat) 
    Local _aDados := {}
    Local _lRet   := .F.

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT * FROM " + RetSQLName ("SA1") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND A1_COD  = '" + _sCodMat + "' "
    _oSQL:_sQuery += " AND A1_LOJA = '" + _sLojMat + "' "
    _oSQL:_sQuery += " AND A1_MSBLQL = '2' "
    _oSQL:Log ()
    _aDados := aclone (_oSQL:Qry2Array ())

    If Len(_aDados) > 0
       _lRet := .T.
    else
        u_help("Cliente não existe e/ou está bloqueado. Não pode ser utilizado como código matriz.")
    EndIf
Return _lRet
