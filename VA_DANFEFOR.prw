
// Programa...: VA_DANFEFOR
// Autor......: Claudia Lionço
// Data.......: 21/02/2025
// Descricao..: Rotina para exportação de xml e danfe
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Rotina
// #Descricao         #Rotina para exportação de xml e danfe
// #PalavasChave      #danfe #xml #geracao_pdf
// #TabelasPrincipais #SF1 #SF2 #SD1 #SD2
// #Modulos           #FAT
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------
#INCLUDE "PROTHEUS.CH" 
#include "rptdef.ch"  // Para ter a definicao da variavel IMP_PDF

User Function VA_DANFEFOR()
    Local _aNFs   := {}
    Local _x      := 0
    Private cPerg := "VA_DANFEFOR"
    
	_ValidPerg()
	Pergunte(cPerg,.T.)

    //if mv_par05 == 1
        _oSQL := ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	   F1_DOC "
        _oSQL:_sQuery += "    ,F1_SERIE "
        _oSQL:_sQuery += " FROM " + RetSQLName ("SF1") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND F1_FILIAL = '"+ xFilial("SF1") +"' "
        _oSQL:_sQuery += " AND F1_FORNECE = '"+ mv_par01 +"' "
        _oSQL:_sQuery += " AND F1_SERIE = '"+ mv_par04+ "' "
        _oSQL:_sQuery += " AND F1_EMISSAO BETWEEN '" + dtos(mv_par02) + "' AND '" + dtos(mv_par03) + "' "
    // else
    //     _oSQL := ClsSQL ():New ()
    //     _oSQL:_sQuery := ""
    //     _oSQL:_sQuery += " SELECT "
    //     _oSQL:_sQuery += " 	   F2_DOC "
    //     _oSQL:_sQuery += "    ,F2_SERIE "
    //     _oSQL:_sQuery += " FROM " + RetSQLName ("SF2") 
    //     _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    //     _oSQL:_sQuery += " AND F2_FILIAL = '"+ xFilial("SF2") +"' "
    //     _oSQL:_sQuery += " AND F2_CLIENTE = '"+ mv_par01 +"' "
    //     _oSQL:_sQuery += " AND F2_SERIE = '"+ mv_par04+ "' "
    //     _oSQL:_sQuery += " AND F2_EMISSAO BETWEEN '" + dtos(mv_par02) + "' AND '" + dtos(mv_par03) + "' "
    // endif

    _aNFs := aclone (_oSQL:Qry2Array ())

    u_help("Encontradas " + alltrim(str(len(_aNFs))) + " notas para imprimir")
    For _x:=1 to Len(_aNFs)
        //chama a rotina
        _GeraDanfe(_aNFs[_x,1], _aNFs[_x,2], "C:\TEMP\", 1)
    Next

    u_help("Notas geradas em C:\temp\")
Return
//
// ------------------------------------------------------------------------
// Gera Danfe em PDF
Static Function _GeraDanfe(cNota, cSerie, cPasta, nTipo)
    Local aArea     := GetArea()
    Local cIdent    := ""
    Local cArquivo  := ""
    Local oDanfe    := Nil
    Local lEnd      := .F.
    Local nTamNota  := TamSX3('F2_DOC')[1]
    Local nTamSerie := TamSX3('F2_SERIE')[1]
    Local dDataDe   := sToD("20000101")
    Local dDataAt   := sToD("20500101")
    Private PixelX
    Private PixelY
    Private nConsNeg
    Private nConsTex
    Private oRetNF
    Private nColAux
       
    //Se existir nota
    If ! Empty(cNota)
        //Pega o IDENT da empresa
        cIdent := RetIdEnti()
           
        //Se o último caracter da pasta não for barra, será barra para integridade
        If SubStr(cPasta, Len(cPasta), 1) != "\"
            cPasta += "\"
        EndIf
           
        //Gera o XML da Nota
        cArquivo := cNota + "_" + dToS(Date()) + "_" + StrTran(Time(), ":", "-")
        _GeraSpedXML(cNota, cSerie, cPasta + cArquivo  + ".xml", .F.)
           
        //Define as perguntas da DANFE
        Pergunte("NFSIGW",.F.)
        MV_PAR01 := PadR(cNota,  nTamNota)     //Nota Inicial
        MV_PAR02 := PadR(cNota,  nTamNota)     //Nota Final
        MV_PAR03 := PadR(cSerie, nTamSerie)    //Série da Nota
        MV_PAR04 := nTipo                      //Tipo de NF 1-entrada/ 2-saida
        MV_PAR05 := 1                          //Frente e Verso = Sim
        MV_PAR06 := 2                          //DANFE simplificado = Nao
        MV_PAR07 := dDataDe                    //Data De
        MV_PAR08 := dDataAt                    //Data Até
           
        //Cria a Danfe
        oDanfe := FWMSPrinter():New(cArquivo, IMP_PDF, .F., , .T.)
           
        //Propriedades da DANFE
        oDanfe:SetResolution(78)
        oDanfe:SetPortrait()
        oDanfe:SetPaperSize(DMPAPER_A4)
        oDanfe:SetMargin(60, 60, 60, 60)
           
        //Força a impressão em PDF
        oDanfe:nDevice  := 6
        oDanfe:cPathPDF := cPasta                
        oDanfe:lServer  := .F.
        oDanfe:lViewPDF := .F.
           
        //Variáveis obrigatórias da DANFE (pode colocar outras abaixo)
        PixelX    := oDanfe:nLogPixelX()
        PixelY    := oDanfe:nLogPixelY()
        nConsNeg  := 0.4
        nConsTex  := 0.5
        oRetNF    := Nil
        nColAux   := 0
           
        //Chamando a impressão da danfe no RDMAKE
        RptStatus({|lEnd| u_DanfeProc(@oDanfe, @lEnd, cIdent, , , .F.)}, "Imprimindo Danfe...")
        oDanfe:Print()
    EndIf
       
    RestArea(aArea)
Return
//
// ------------------------------------------------------------------------
// Gera XML
Static Function _GeraSpedXML(cDocumento, cSerie, cArqXML, lMostra)
    Local aArea        := GetArea()
    Local cURLTss      := PadR(GetNewPar("MV_SPEDURL","http://"),250)  
    Local oWebServ
    Local cIdEnt       := RetIdEnti()
    Local cTextoXML    := ""
    Local oFileXML
    Default cDocumento := ""
    Default cSerie     := ""
    Default cArqXML    := GetTempPath()+"arquivo_"+cSerie+cDocumento+".xml"
    Default lMostra    := .F.
        
    //Se tiver documento
    If !Empty(cDocumento)
        cDocumento := PadR(cDocumento, TamSX3('F2_DOC')[1])
        cSerie     := PadR(cSerie,     TamSX3('F2_SERIE')[1])
            
        //Instancia a conexão com o WebService do TSS    
        oWebServ:= WSNFeSBRA():New()
        oWebServ:cUSERTOKEN        := "TOTVS"
        oWebServ:cID_ENT           := cIdEnt
        oWebServ:oWSNFEID          := NFESBRA_NFES2():New()
        oWebServ:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
        aAdd(oWebServ:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
        aTail(oWebServ:oWSNFEID:oWSNotas:oWSNFESID2):cID := (cSerie+cDocumento)
        oWebServ:nDIASPARAEXCLUSAO := 0
        oWebServ:_URL              := AllTrim(cURLTss)+"/NFeSBRA.apw"
            
        //Se tiver notas
        If oWebServ:RetornaNotas()
            
            //Se tiver dados
            If Len(oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3) > 0
                
                //Se tiver sido cancelada
                If oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA != Nil
                    cTextoXML := oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA:cXML
                        
                //Senão, pega o xml normal (foi alterado abaixo conforme dica do Jorge Alberto)
                Else
                    cTextoXML := '<?xml version="1.0" encoding="UTF-8"?>'
                    cTextoXML += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
                    cTextoXML += oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXML
                    cTextoXML += oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXMLPROT
                    cTextoXML += '</nfeProc>'
                EndIf
                    
                //Gera o arquivo
                oFileXML := FWFileWriter():New(cArqXML, .T.)
                oFileXML:SetEncodeUTF8(.T.)
                oFileXML:Create()
                oFileXML:Write(cTextoXML)
                oFileXML:Close()
                    
                //Se for para mostrar, será mostrado um aviso com o conteúdo
                If lMostra
                    Aviso("GeraSpedXML", cTextoXML, {"Ok"}, 3)
                EndIf
                    
            //Caso não encontre as notas, mostra mensagem
            Else
                ConOut("GeraSpedXML > Verificar parâmetros, documento e série não encontrados ("+cDocumento+"/"+cSerie+")...")
                    
                If lMostra
                    Aviso("GeraSpedXML", "Verificar parâmetros, documento e série não encontrados ("+cDocumento+"/"+cSerie+")...", {"Ok"}, 3)
                EndIf
            EndIf
            
        //Senão, houve erros na classe
        Else
            ConOut("GeraSpedXML > "+IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3))+"...")
                
            If lMostra
                Aviso("GeraSpedXML", IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3)), {"Ok"}, 3)
            EndIf
        EndIf
    EndIf
    RestArea(aArea)
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT            TIPO TAM DEC VALID F3     Opcoes                      						                        Help
    aadd (_aRegsPerg, {01, "Associado     ", "C", 6, 0,  "",  "SA2", {},                         								                    ""})
    aadd (_aRegsPerg, {02, "Dt.Emissao de ", "D", 8, 0,  "",  "   ", {},                         								                    ""})
    aadd (_aRegsPerg, {03, "Dt.Emissao até", "D", 8, 0,  "",  "   ", {},                         								                    ""})
    aadd (_aRegsPerg, {04, "Série NF"      , "C", 3, 0,  "",  "   ", {},                         								                    ""})
    //aadd (_aRegsPerg, {05, "Tipo NF"       , "N", 1, 0,  "",  "   ", {"Entrada","Saida"},                         								    ""})
 
    U_ValPerg (cPerg, _aRegsPerg)
Return
