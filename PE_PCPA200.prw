// Programa...: PE_PCPA200
// Autor......: Claudia Lionço
// Data.......: 17/05/2022
// Descricao..: Ponto entrada Estrutura
//
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto entrada Estrutura
// #PalavasChave      #ponto_de_entrada #estrutura  
// #TabelasPrincipais #SB1 
// #Modulos 		  #todos
//
// Historico de alteracoes:
//
//---------------------------------------------------------------------------------------------------------------
#Include "Protheus.ch" 
#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

User Function PCPA200() 
    Local aParam     := PARAMIXB
    Local xRet       := .T.
    Local oObj       := ""
    Local cIdPonto   := ""
    Local cIdModel   := ""
    Local lIsGrid    := .F.

    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid := (Len(aParam) > 3)

        If cIdPonto == "MODELPOS"               // Validacao 'tudo OK' ao clicar no Botao Confirmar
 
        ElseIf cIdPonto == "FORMPOS"            // apos configurações do formulario

        ElseIf cIdPonto == "FORMLINEPRE"        // Chamada na apos validacao da linha do formulario

        ElseIf cIdPonto == "FORMLINEPOS"        // Chamada na validacao da linha do formulario.
            If(oObj:IsFieldUpdated('G1_QUANT')) ;
                .OR. (oObj:IsFieldUpdated('G1_PERDA')) ;
                .OR. (oObj:IsFieldUpdated('G1_INI'));
                .OR. (oObj:IsFieldUpdated('G1_FIM'));
                .OR. (oObj:IsFieldUpdated('G1_GROPC'));
                .OR. (oObj:IsFieldUpdated('G1_REVINI'));
                .OR. (oObj:IsFieldUpdated('G1_REVFIM'));
                .OR. (oObj:IsFieldUpdated('G1_OPC'))

                _sProduto    := G1_COD
                _sComponente := oObj:GetValue('G1_COMP')                
                _sDesc       := posicione("SB1",1,XFILIAL("SB1") + _sComponente,"B1_DESC")  
 
                _GravaLog(_sProduto, _sComponente, _sDesc)
            Endif
        ElseIf cIdPonto == "MODELCOMMITTTS"     // Chamada apos a gravacao total do modelo e dentro da transacao
            
        ElseIf cIdPonto == "MODELCOMMITNTTS"    // Chamada apos a gravacao total do modelo e fora da transacao 

        ElseIf cIdPonto == "FORMCOMMITTTSPRE"   // Chamada apos a gravacao da tabela do formulario

        ElseIf cIdPonto == "FORMCOMMITTTSPOS"   // Chamada apos a gravacao da tabela do formulario

        ElseIf cIdPonto == "MODELCANCEL"        // No cancelamento do botao.

        ElseIf cIdPonto == "BUTTONBAR"          // Para a inclusão de botões na ControlBar

        EndIf
    EndIf
Return xRet
//
// ----------------------------------------------------------------------------------------------------------------
// Grava log
Static Function _GravaLog(_sProduto, _sComponente, _sDesc)
	
	// Cria evento dedo-duro para posterior gravacao em outro P.E. apos a efetivacao do movimento.
	_oEvento := ClsEvent():New ()
	_oEvento:Alias     = 'SG1'
	_oEvento:Texto     = "Alteração de estrutura de produto: " + alltrim(_sProduto) + chr (13) + chr (10) + ;
	 					 "Estrutura Nº: " + alltrim(_sProduto) + chr (13) + chr (10) + ;
	                     "Item Nº: "+ alltrim(_sComponente) + "-" + alltrim(_sDesc) + " foi alterado na estrutura."
	_oEvento:CodEven   = "SG1001"
	_oEvento:Produto   = alltrim(_sProduto)
	//_oEvento:MailToZZU = {"069"}
	
	_oEvento:Grava()
u_help("P.E. 3")
Return 
