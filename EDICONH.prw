// Programa...: EDICONH
// Autor......: Catia Cardoso
// Data.......: 23/10/2014
// Descricao..: Manutencao de arquivos EDI de conhecimentos
//
// Historico de alteracoes:
// 29/10/2014 - Catia   - erro ao gravar o ZAA_DIMP - qtde de documentos importados
// 26/11/2014 - Catia   - estava gravando o indicador de tipo de servico como numerico e era caracter
// 05/01/2015 - Catia   - erro ao tentar excluir um arquivo
// 05/02/2015 - Catia   - criada a opcao de marcar os INVALIDOS - CANCELADOS
// 10/02/2015 - Catia   - erro array of bound - linha 508
// 27/02/2015 - Catia   - enviar email para o coordenador logistico dos conhecimentos importados referenciando frete/kg
// 09/03/2015 - Catia   - dava erro na opcao de enviar email
// 11/06/2015 - Catia   - mascara para os valores no envio do email
// 20/10/2015 - Catia   - consulta CT'es - aumentar os campos que estavam muito pequenos para facilitar a consulta.
// 17/11/2015 - Catia   - validacao para identificar notas de saida - e verificar se o frete eh CIF
// 29/03/2016 - Catia   - correção do erro no SFT FT_ITEM (erro no produto - rotina automatica) - corrigido aqui
// 05/08/2016 - Catia   - erro SFT
// 04/10/2016 - Catia   - correção rotina de marcar os cancelados
// 06/07/2017 - Catia   - desabilitada a opcao de excluir e criada a opcao de desconsiderar
// 06/03/2018 - Catia   - alterado para que o programa use como data de digitação DATE e não database 
// 27/02/2019 - Catia   - incluida na consulta a opcao de ver o frete da nota que esta sendo associado o CONH se C ou F
// 08/04/2019 - Catia   - include TbiConn.ch 
// 03/03/2020 - Claudia - Ajustada criação de arquivo de trabalho conforme solicitação da release 12.1.25
// 21/07/2020 - Robert  - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Manutencao de arquivos EDI de conhecimentos
// #PalavasChave      #frete #conhecimentos_frete #EDI
// #TabelasPrincipais #ZAA #SF1 #SD1
// #Modulos           #COM #FAT

#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#Include "totvs.ch"

// ----------------------------------------------------------------------------------------------------------------------
User Function EDICONH()

	local   _aCores   := U_L_EDICONH (.T.)
	Private aRotina   := {}
	private cCadastro := "EDI CONH Fretes - Manutenção Arquivos"
	
	// verifica parametros usados no programa
	_xTES_c_ICMS := GetMv("ML_CTRTCIC")   // TES c/ ICMS
	if _xTES_c_ICMS = ' '
	    u_help ("Parametro ML_CTRTCIC, referente ao TES com ICMS, não informado no sistema.")
	    return    
	endif
	
	_xTES_s_ICMS := GetMv("ML_CTRTSIC")   // TES s/ ICMS
	if _xTES_s_ICMS = ' '
	    u_help ("Parametro ML_CTRTCIC, referente ao TES sem ICMS, não informado no sistema.")
	    return    
	endif
	
	_xPRODUTO    := Left(GetMv("ML_CTRPROD")+Space(15),15)   // Codigo do Produto
	if _xPRODUTO = ' '
	    u_help ("Parametro ML_CTRPROD, referente ao PRODUTO de frete, não informado no sistema.")
	    return    
	endif
	
	aadd (aRotina, {"&Pesquisar"            ,"AxPesqui"   , 0, 1})
	aadd (aRotina, {"&Visualizar"           ,"AxVisual"   , 0, 2})
	aadd (aRotina, {"&Importa"              ,"U_I_EDICONH", 0, 2})
	aadd (aRotina, {"&Valida XML"           ,"U_X_EDICONH", 0, 2})
	aadd (aRotina, {"&Consulta CTE's"       ,"U_C_EDICONH", 0, 2})
	aadd (aRotina, {"&Marca Invalidos"      ,"U_M_EDICONH", 0, 2})
	aadd (aRotina, {"&Desconsiderar"        ,"U_E_EDICONH", 0, 2})
	aadd (aRotina, {"&Verifica Arquivos"    ,"U_V_EDICONH", 0, 2})
	aadd (aRotina, {"&Legenda"              ,"U_L_EDICONH(.F.)", 0 ,5})
	
	Private cDelFunc := ".T."
	Private cString  := "ZAA"
	dbSelectArea(cString)
	dbSetOrder(1)
	
	mBrowse(,,,,cString,,,,,2, _aCores)

Return
// ----------------------------------------------------------------------------------------------------------------------
// Importa arquivo do EDI de conhecimentos
user function I_EDICONH()
    local _lContinua := .T.
    
    RegToMemory ("ZAA",.F.,.F.)
    
    if ZAA -> ZAA_STATUS = "I"
        u_help ("Arquivo já importado. Conhecimentos já gerados no sistema.")
        return 
    endif
    
    if ZAA -> ZAA_LAYOUT != "OK"
        u_help ("LAYOUT do arquivo incorreto. Entrar em contato com a TI.")
        return
    endif
    
    if ZAA -> ZAA_XML = "BX"
        u_help ("Devem ser baixados os XML referentes a este arquivo EDI.")
        return 
    endif
 
    if _lContinua   
        Processa({||_AbreArq( "I", zaa -> zaa_nomarq, zaa -> zaa_transp)},"Abrindo Arquivo ... " )
    endif 
    
return
// ----------------------------------------------------------------------------------------------------------------------
// Consulta arquivo do EDI de conhecimentos
user function C_EDICONH()
    local _lContinua := .T.
    
    RegToMemory ("ZAA",.F.,.F.)
    
    if ZAA -> ZAA_LAYOUT != "OK"
        u_help ("LAYOUT do arquivo incorreto. Função não pode ser executada.")
        return
    endif
    
    if _lContinua   
        Processa({||_AbreArq( "C", zaa -> zaa_nomarq)},"Abrindo Arquivo ... " )
    endif    
    
return
// ----------------------------------------------------------------------------------------------------------------------
// Marca Invalidos no arquivo do EDI de conhecimentos
user function M_EDICONH()
    local _lContinua := .T.
    
    RegToMemory ("ZAA",.F.,.F.)
    
    if ZAA -> ZAA_LAYOUT != "OK"
        u_help ("LAYOUT do arquivo incorreto. Função não pode ser executada.")
        return
    endif
    
    if ZAA -> ZAA_STATUS = "I"
        u_help ("Arquivo já importado. Não permitda essa função.")
        return 
    endif
    
    if _lContinua   
        Processa({||_AbreArq( "M", zaa -> zaa_nomarq)},"Abrindo Arquivo ... " )
    endif    
    
return
// ----------------------------------------------------------------------------------------------------------------------
// Marca Invalidos no arquivo do EDI de conhecimentos
user function V_EDICONH()
	Processa({||U_BATEDICONH()},"Verificando Arquivos ... " )
return
// ----------------------------------------------------------------------------------------------------------------------
// Exclusao.
user function E_EDICONH()

//	local _lContinua := .T.
	if ZAA -> ZAA_STATUS = "I"
        u_help ("Arquivo já importado. Não pode ser desconsiderado")
        return 
    endif
    
    if ZAA -> ZAA_STATUS = "D"
        u_help ("Arquivo já desconsiderado")
        return 
    endif
    
	reclock("ZAA", .F.)
       	ZAA->ZAA_STATUS := 'D'
       	ZAA->ZAA_DTIMP  := date()
    MsUnLock()
return
// ----------------------------------------------------------------------------------------------------------------------
// Valida XML
user function X_EDICONH()
    local _lContinua := .T.
    
    RegToMemory ("ZAA",.F.,.F.)
    
    if ZAA -> ZAA_STATUS = "I"
        u_help ("Arquivo já importado. Conhecimentos já gerados no sistema.")
        return 
    endif
    
    if ZAA -> ZAA_LAYOUT != "OK"
        u_help ("LAYOUT do arquivo incorreto. Entrar em contato com a TI")
        return
    endif
    
    if ZAA -> ZAA_XML = "OK" .AND. ZAA -> ZAA_STATUS = "NI"
        u_help ("XML já esta OK, arquivo pode ser importado.")
        return 
    endif
    
    if _lContinua   
        Processa({||_AbreArq( "V", zaa -> zaa_nomarq)},"Abrindo Arquivo ... " )
    endif
return
// ----------------------------------------------------------------------------------------------------------------------
// Abre Arquivo
Static Function _AbreArq(_xfuncao, _xArq, _XnomTransp)
    _xCaminho := "\EDI_CONH\CONEMB\LIDOS\"
    _xVararq1 := Alltrim(_xCaminho+Trim(_xArq))
    
    If !File( _xVararq1 )
        MsgAlert("Arquivo " + _xVararq1 + " Nao Existe","Importacao Cancelada!")
        Return(nil)
    Endif
    
//    _aEstru := {}
//    aadd(_aEstru,{'CAMPO','C',740,0})
//    
//    _cArq   := CriaTrab(_aEstru,.T.)
//    DbUseArea(.T.,,_cArq,'TRB',.T.,.F.)

	_aArqTrb := {}
	_aEstru  := {}
	aadd(_aEstru,{'CAMPO','C',740,0})	
	U_ArqTrb ("Cria", "TRB", _aEstru, {}, @_aArqTrb)		
    
    Append From &_xVararq1 SDF 
    
    do case 
        case _xfuncao = "V"
            Processa({||_Valida(_xArq)},"Validando XML ... " )
        case _xfuncao = "I"
            Processa({||_Importa(_xArq, _XnomTransp )},"Importando CTE's... " )
        case _xfuncao = "C"            
            Processa({||_Consulta(_xArq)},"Consulta CTE's do arquivo... " )
		case _xfuncao = "M"            
            Processa({||_MarcaInvalidos(_xArq)},"Marca CTE's invalidos ou cancelados ou que nao deseja importar ... " )            
    endcase    
    
    TRB->(DbCloseArea())
    
    //fErase(_cArq + '.dbf')
    u_arqtrb ("FechaTodos",,,, @_aArqTrb)
Return
// ------------------------------------------------------------------------------------
Static Function _MarcaInvalidos(_xArq1)
    local _lContinua := .T.
//    local _werro     := ""
//    local _werro1    := ""
    local _versao    := 681
    local _i		 := 0
    local i			 := 0
           
    // busca os conhecimentos na tabela auxiliar
    _sSQL := ""
    _sSQL += " SELECT 1" 
    _sSQL += "   FROM AUX_EDICONH"
    _sSQL += "  WHERE ARQUIVO = '" + _xArq1 + "' "
    
    aDados := U_Qry2Array(_sSQL)
     
    if len (aDados) = 0
     
        DbSelectArea("TRB")
        DbGoTop()
        _wcont :=0
        Do While _lContinua .and. !TRB->(Eof())
          
            IncProc("Verificando conhecimentos ... ")
            // le so registros referentes aos conhecimentos
            if SubStr(TRB->CAMPO,1,3) = '321'
                // identifica pelo transportador a versao do layout p/saber de onde buscar a chave
                _wtransp := SubStr(TRB->CAMPO,18,40) 
                if 'STILLO' $ _wtransp
                    _versao := 679
                endif
            endif
            if SubStr(TRB->CAMPO,1,3) <> '322'
                DbSelectArea("TRB")
                DbSkip()
                Loop
            EndIf
            _wcont++
            // atribui conteudos conforme arquivo
            _xCHAVE := SubStr(TRB->CAMPO,_versao,44)
            _xTPFRETE    := SubStr(TRB->CAMPO,39,1)
            _xSERIE      := cvaltochar (val (SubStr(TRB->CAMPO,14,4)))  // Serie do conhecimento
            if cvaltochar (val (substr (_xCHAVE, 23, 3))) != _xSERIE
                _xSERIE = cvaltochar (val (substr (_xCHAVE, 23, 3)))
            endif
            _xNFISCAL    := StrZero(Val(SubStr(TRB->CAMPO,19,12)),9,0)  // nro do conhecimento
            _xEMISSAO    := SubStr(TRB->CAMPO,31,8)                    // emissao do conhecimento
            _xEMISSAO    := SubStr(_xEMISSAO,1,2) + "/" + SubStr(_xEMISSAO,3,2) + "/" + SubStr(_xEMISSAO,5,4)   
            _xPESO       := SubStr(TRB->CAMPO,40,7)
            _xTOTAL      := SubStr(TRB->CAMPO,47,15)
            for _i=1 to 40
                _xserie := SubStr(TRB->CAMPO,222+11*_i,3)                   // Serie do NF
                _xnota  := StrZero(Val(SubStr(TRB->CAMPO,225+11*_i,08)),9,0)  // nro da NF
                if val(_xnota) > 0
                    // busca dados da nota no SF2
                    _xuf     := fbuscacpo ("SF2", 1, xfilial ("SF2") + _xnota + _xserie   , "F2_EST")
                    _xcliente:= fbuscacpo ("SF2", 1, xfilial ("SF2") + _xnota + _xserie   , "F2_CLIENTE")
                    _xloja   := fbuscacpo ("SF2", 1, xfilial ("SF2") + _xnota + _xserie   , "F2_LOJA")
                    _xvlrnota:= fbuscacpo ("SF2", 1, xfilial ("SF2") + _xnota + _xserie   , "F2_VALBRUT")
                    _xcidade := fbuscacpo ("SA1", 1, xfilial ("SA1") + _xcliente + _xloja , "A1_MUN")
                    _xnomcli := fbuscacpo ("SA1", 1, xfilial ("SA1") + _xcliente + _xloja , "A1_NOME")
                    _xvlrkg  := str( ROUND(VAL(_xTOTAL) / VAL(_xPESO) , 2) )
                    _xvlrperc:= str( ROUND(VAL(_xTOTAL) / _xvlrnota , 2) )
                    // grava tabela auxiliar
                    _sSQL := ""
                    _sSQL += " INSERT INTO AUX_EDICONH ( ARQUIVO, NUMCON, EMISSAO, VALOR, PESO" 
                    _sSQL += "                         , VLR_KG, NFSAIDA, SERIE, CIDADE, UF, RECNO "
                    _sSQL += "                         , FRETE_PERC, NOM_CLI)"
                    _sSQL += " VALUES ( '" + _xArq1 + "'"
                    _sSQL += "        , '" + _xNFISCAL + "'"
                    _sSQL += "        , '" + _xEMISSAO + "'"
                    _sSQL += "        , '" + _xTOTAL   + "'"
                    _sSQL += "        , '" + _xPESO    + "'"
                    _sSQL += "        , '" + _xvlrkg   + "'" 
                    _sSQL += "        , '" + _xnota    + "'"
                    _sSQL += "        , '" + _xserie   + "'"
                    _sSQL += "        , '" + _xcidade   + "'"
                    _sSQL += "        , '" + _xuf   + "'"  
                    _sSQL += "        , '" + strzero(_wcont,6) + "'"
                    _sSQL += "        , '" + _xvlrperc + "'"
                    _sSQL += "        , '" + _xnomcli + "')"
                endif                    
            next
            
            if TCSQLExec (_sSQL) < 0
                u_showmemo(_sSQL)
                return
            endif    
        
            DbSelectArea("TRB")
            DbSkip()
            Loop
        enddo
    endif                
    
    _sSQL := ""
    _sSQL += " SELECT ''"
    _sSQL += "      , RTRIM(NUMCON)"
    _sSQL += "      , RTRIM(EMISSAO)"
    _sSQL += "      , VALOR/100"
    _sSQL += "      , PESO/100"
    _sSQL += "      , VLR_KG"
    _sSQL += "      , RTRIM(NFSAIDA)
    _sSQL += "      , RTRIM(SERIE)"
    _sSQL += "      , RTRIM(CIDADE) 
    _sSQL += "      , RTRIM(UF)"
    _sSQL += "      , CANCELADO"
    _sSQL += "   FROM AUX_EDICONH"
    _sSQL += "  WHERE ARQUIVO = '" + _xArq1 + "' "
    //_sSQL += " ORDER BY NUMCON"
    _sSQL += " ORDER BY RECNO"
    
    _aDados := U_Qry2Array(_sSQL)
    _aColsMB = {}
	
	aadd (_aColsMB, {2,  "Num.CONH." , 40,  "@!"})
    aadd (_aColsMB, {3,  "Emissao"   , 40,  "@D"})
    aadd (_aColsMB, {4,  "Valor"     , 50,  "@E 999,999.99"})
    aadd (_aColsMB, {5,  "Peso"      , 50,  "@E 999,999.99"})
    aadd (_aColsMB, {6,  "Vlr KG"    , 50,  "@E 999,999.99"})
    aadd (_aColsMB, {7,  "NF Saida"  , 40,  "@!"})
    aadd (_aColsMB, {8,  "Serie"     , 10,  "@!"})
    aadd (_aColsMB, {9,  "Cidade"    , 60,  "@!"})
    aadd (_aColsMB, {10, "UF"        , 10,  "@!"})
    aadd (_aColsMB, {11, "Cancelado" , 20,  "@!"})
    
    for i=1 to len(_aDados)
    	_aDados[i,1] = .F.
    	if _aDados[i,11] = 'S'
    		_aDados[i,1] = .T.
    	endif
	next
	
	U_MBArray (@_aDados,"Marca Conhecimentos CANCELADOS", _aColsMB, 1,  oMainWnd:nClientWidth - 50 ,550, ".T.")
	
	for i=1 to len(_aDados)
		// marca como cancelados
		_sSQL := ""
		_sSQL += " UPDATE AUX_EDICONH"
		_sSQL += "    SET CANCELADO = '" + iif( _aDados[i,1]= .T., 'S', 'N') +"'"
		_sSQL += "  WHERE ARQUIVO   = '" + _xArq1 + "' "
		_sSQL += "    AND RECNO     = " + strzero(i,6)
		
		if TCSQLExec (_sSQL) < 0
            u_showmemo(_sSQL)
            return
        endif            
	next
return     
// ------------------------------------------------------------------------------------
Static Function _Consulta(_xArq1)
    local _lContinua := .T.
    //local _werro     := ""
    //local _werro1    := ""
    local _versao    := 681
    local _i 		 := 0
    
    // verifica se o arquivo ja esta na tabela auxiliar
    // se não estiver cria
    _sSQL := ""
    _sSQL += " SELECT 1" 
    _sSQL += "   FROM AUX_EDICONH"
    _sSQL += "  WHERE ARQUIVO = '" + _xArq1 + "' "
    
    aDados := U_Qry2Array(_sSQL)
    
	if len (aDados) = 0
        DbSelectArea("TRB")
        DbGoTop()
        _wcont :=0
        Do While _lContinua .and. !TRB->(Eof())
          
            IncProc("Montando consulta ... ")
            // le so registros referentes aos conhecimentos
            if SubStr(TRB->CAMPO,1,3) = '321'
                // identifica pelo transportador a versao do layout p/saber de onde buscar a chave
                _wtransp := SubStr(TRB->CAMPO,18,40) 
                if 'STILLO' $ _wtransp
                    _versao := 679
                endif
            endif
            if SubStr(TRB->CAMPO,1,3) <> '322'
                DbSelectArea("TRB")
                DbSkip()
                Loop
            EndIf
            _wcont++
            // atribui conteudos conforme arquivo
            _xCHAVE := SubStr(TRB->CAMPO,_versao,44)
            _xTPFRETE    := SubStr(TRB->CAMPO,39,1)
            _xSERIE      := cvaltochar (val (SubStr(TRB->CAMPO,14,4)))  // Serie do conhecimento
            if cvaltochar (val (substr (_xCHAVE, 23, 3))) != _xSERIE
                _xSERIE = cvaltochar (val (substr (_xCHAVE, 23, 3)))
            endif
            _xNFISCAL    := StrZero(Val(SubStr(TRB->CAMPO,19,12)),9,0)  // nro do conhecimento
            _xEMISSAO    := SubStr(TRB->CAMPO,31,8)                    // emissao do conhecimento
            _xEMISSAO    := SubStr(_xEMISSAO,1,2) + "/" + SubStr(_xEMISSAO,3,2) + "/" + SubStr(_xEMISSAO,5,4)   
            _xPESO       := SubStr(TRB->CAMPO,40,7)
            _xTOTAL      := SubStr(TRB->CAMPO,47,15)
            for _i=1 to 40
                _xserie := SubStr(TRB->CAMPO,222+11*_i,3)                   // Serie do NF
                _xnota  := StrZero(Val(SubStr(TRB->CAMPO,225+11*_i,08)),9,0)  // nro da NF
                if val(_xnota) > 0
                    // busca dados da nota no SF2
                    _xuf     := fbuscacpo ("SF2", 1, xfilial ("SF2") + _xnota + _xserie   , "F2_EST")
                    _xcliente:= fbuscacpo ("SF2", 1, xfilial ("SF2") + _xnota + _xserie   , "F2_CLIENTE")
                    _xloja   := fbuscacpo ("SF2", 1, xfilial ("SF2") + _xnota + _xserie   , "F2_LOJA")
                    _xvlrnota:= fbuscacpo ("SF2", 1, xfilial ("SF2") + _xnota + _xserie   , "F2_VALBRUT")
                    _xcidade := fbuscacpo ("SA1", 1, xfilial ("SA1") + _xcliente + _xloja , "A1_MUN")
                    _xnomcli := fbuscacpo ("SA1", 1, xfilial ("SA1") + _xcliente + _xloja , "A1_NOME")
                    _xfrete  := fbuscacpo ("SF2", 1, xfilial ("SF2") + _xnota + _xserie   , "F2_TPFRETE")
                    _xvlrkg  := str( ROUND(VAL(_xTOTAL) / VAL(_xPESO) , 2) )
                    _xvlrperc:= str( ROUND(VAL(_xTOTAL) / _xvlrnota , 2) )
                    // grava tabela auxiliar
                    _sSQL := ""
                    _sSQL += " INSERT INTO AUX_EDICONH ( ARQUIVO, NUMCON, EMISSAO, VALOR, PESO" 
                    _sSQL += "                         , VLR_KG, NFSAIDA, SERIE, CIDADE, UF, RECNO "
                    _sSQL += "                         , FRETE_PERC, NOM_CLI, FRETE)"
                    _sSQL += " VALUES ( '" + _xArq1 + "'"
                    _sSQL += "        , '" + _xNFISCAL + "'"
                    _sSQL += "        , '" + _xEMISSAO + "'"
                    _sSQL += "        , '" + _xTOTAL   + "'"
                    _sSQL += "        , '" + _xPESO    + "'"
                    _sSQL += "        , '" + _xvlrkg   + "'" 
                    _sSQL += "        , '" + _xnota    + "'"
                    _sSQL += "        , '" + _xserie   + "'"
                    _sSQL += "        , '" + _xcidade   + "'"
                    _sSQL += "        , '" + _xuf   + "'"  
                    _sSQL += "        , '" + strzero(_wcont,6) + "'"
                    _sSQL += "        , '" + _xvlrperc + "'"
                    _sSQL += "        , '" + _xnomcli + "'"
                    _sSQL += "        , '" + _xfrete + "')"
                endif                    
            next
            
            if TCSQLExec (_sSQL) < 0
                u_showmemo(_sSQL)
                return
            endif    
        
            DbSelectArea("TRB")
            DbSkip()
            Loop
        enddo
        
    endif                
    
    _sSQL := ""
    _sSQL += " SELECT RTRIM(NUMCON)"
    _sSQL += "      , RTRIM(EMISSAO)"
    _sSQL += "      , VALOR/100"
    _sSQL += "      , PESO/100"
    _sSQL += "      , VLR_KG"
    _sSQL += "      , FRETE_PERC"
    _sSQL += "      , RTRIM(NFSAIDA)"
    _sSQL += "      , LEFT(NOM_CLI,20)"
    _sSQL += "      , RTRIM(CIDADE)"
    _sSQL += "      , RTRIM(UF)"
    _sSQL += "      , FRETE"
    _sSQL += "      , CANCELADO"
    _sSQL += "   FROM AUX_EDICONH"
    _sSQL += "  WHERE ARQUIVO = '" + _xArq1 + "' "
    //_sSQL += " ORDER BY NUMCON"
    _sSQL += " ORDER BY RECNO"
    
    _aDados := U_Qry2Array(_sSQL)
    _aCols = {}
    aadd (_aCols, {1,  "Num.CONH." , 30,  "@!"})
    aadd (_aCols, {2,  "Emissao"   , 30,  "@D"})
    aadd (_aCols, {3,  "Valor"     , 40,  "@E 999,999.99"})
    aadd (_aCols, {4,  "Peso"      , 40,  "@E 999,999.99"})
    aadd (_aCols, {5,  "Vlr KG"    , 40,  "@E 999,999.99"})
    aadd (_aCols, {6,  "Frete %"   , 40,  "@E 999,999.99"})
    aadd (_aCols, {7,  "NF Saida"  , 30,  "@!"})
    aadd (_aCols, {8,  "Cliente"   ,100,  "@!"})
    aadd (_aCols, {9,  "Cidade"    , 50,  "@!"})
    aadd (_aCols, {10, "UF"        , 10,  "@!"})
    aadd (_aCols, {11, "Frete"     , 25,  "@!"})
    aadd (_aCols, {12, "Cancelado" , 10,  "@!"})
    
    U_F3Array (_aDados, "Consulta Conhecimentos do Arquivo", _aCols, oMainWnd:nClientWidth - 50, NIL, "")
return     
// ------------------------------------------------------------------------------------
Static Function _Valida(_xArq1)
    //local _lContinua := .T.
    local _werro     := ""
    //local _werro1    := ""
    local _versao    := 681
    
    
    // le arquivo de trabalho e verifica se existem os XMLs referentes ao conhecimentos
    DbSelectArea("TRB")
    DbGoTop()
    Do While !TRB->(Eof())
        if SubStr(TRB->CAMPO,1,3) = '321'
            // identifica pelo transportador a versao do layout p/saber de onde buscar a chave
            _wtransp := SubStr(TRB->CAMPO,18,40) 
            if 'STILLO' $ _wtransp
                _versao := 679
            endif
        endif
        if SubStr(TRB->CAMPO,1,3) <> '322'
            DbSelectArea("TRB")
            DbSkip()
            Loop
        Endif

        _xNFISCAL    := StrZero(Val(SubStr(TRB->CAMPO,19,12)),9,0)  // nro do conhecimento

         // verifica se o conhecimento esta marcado como cancelado
        _sSQL := ""
    	_sSQL += " SELECT CANCELADO" 
    	_sSQL += "   FROM AUX_EDICONH"
    	_sSQL += "  WHERE ARQUIVO = '" + _xArq1 + "' "
    	_sSQL += "    AND NUMCON  = '" + _xNFISCAL + "' "
    	
    	aDados := U_Qry2Array(_sSQL)
     	// se o conhecimento esta marcado como cancelado não importa
     	if len(aDados) > 0
    		if aDados[1,1] = 'S'
    			DbSelectArea("TRB")
            	DbSkip()
            	Loop
    		endif
		endif    		
    	 
        // Verifica se existe XML referente ao conhecimento
        _xCHAVE := SubStr(TRB->CAMPO,_versao,44)
        //u_showmemo(_xCHAVE)
        if _xCHAVE != ' '
        
            // verifica se ja existe o conhecimento no ZZX
            _sSQL := ""
            _sSQL += " SELECT *" 
            _sSQL += "   FROM ZZX010"
            _sSQL += "  WHERE D_E_L_E_T_ = ''"  
            _sSQL += "    AND ZZX_CHAVE  = '" + _xCHAVE + "'"
            _TemXML := U_Qry2Array(_sSQL)
            If len(_TemXML) =  0
                _werro += _xCHAVE
                _werro += chr (13) + chr (10)
            Endif
        endif     
        DbSelectArea("TRB")
        DbSkip()
        Loop
    enddo
    
    if len(_werro) > 0
        _werro += chr (13) + chr (10)
        _werro += "Conhecimentos sem XML no sistema. Baixar XML's dos CTe's conforme chaves acima." 
        _werro += chr (13) + chr (10)
        _werro += "Transportadora : " + _wtransp
        _werro += chr (13) + chr (10)
        u_showmemo(_werro)
    else
        // se ja tem os XML - atualiza o flag para OK
        reclock("ZAA", .F.)
        ZAA->ZAA_XML := 'OK' 
        MsUnLock()
    endif
    
return     
// ----------------------------------------------------------------------------------------------------------------------           
// Importa 
Static Function _Importa(_xArq1, _XnomTransp1)
    //local _aCampos   := {}
    local _xCONT     := 0
    local _xCONT_NAO := 0
    local _xCONT_CANC:= 0
    local _lContinua := .T.
    local _xFORNECE  := ' '
    local _xseries   := array(40)
    local _xnotas    := array(40)
    local _versao    := 681
    local _i		 := 0
    private _xNFCFORI := ""  // Deixar 'private' para ser vista por pontos de entrada.
    
    // busca dados do ITEM
    _xUM    := fbuscacpo ("SB1", 1, xfilial ("SB1") + _xPRODUTO,  "B1_UM")
    _xTP    := fbuscacpo ("SB1", 1, xfilial ("SB1") + _xPRODUTO,  "B1_TIPO")
    _xLOCAL := fbuscacpo ("SB1", 1, xfilial ("SB1") + _xPRODUTO,  "B1_LOCPAD")
    
    DbSelectArea("TRB")
    DbGoTop()
    Do While _lContinua .and. !TRB->(Eof())
          
        IncProc("Atualizando informacoes ... ")
        // le so registros referentes aos conhecimentos
        if SubStr(TRB->CAMPO,1,3) = '321'
            // identifica pelo transportador a versao do layout p/saber de onde buscar a chave
            _wtransp := SubStr(TRB->CAMPO,18,40) 
            if 'STILLO' $ _wtransp
                _versao := 679
            endif
        endif
        if SubStr(TRB->CAMPO,1,3) <> '322'
            DbSelectArea("TRB")
            DbSkip()
            Loop
        EndIf
        
        _xNFISCAL    := StrZero(Val(SubStr(TRB->CAMPO,19,12)),9,0)  // nro do conhecimento
        _xTOTAL      := Val(SubStr(TRB->CAMPO,47,15))/100
        
        // Se encontrar algum conhecimento de frete FOB
        _xTPFRETE      := SubStr(TRB->CAMPO,39,1)
        If _xTPFRETE <> 'C'
           MsgInfo("Frete não é CIF, provável que seja uma devolução de cliente. NÃO SERA IMPORTADO. Digitar pelo programa normal referenciando a NF de devolução.","Conhecimento : "+Transf(_xNFISCAL,"@E 999999999"))	
           DbSelectArea("TRB")
           DbSkip()
           Loop
        EndIf
        
        // verifica se o conhecimento esta marcado como cancelado
        _sSQL := ""
    	_sSQL += " SELECT CANCELADO" 
    	_sSQL += "   FROM AUX_EDICONH"
    	_sSQL += "  WHERE ARQUIVO = '" + _xArq1 + "' "
    	_sSQL += "    AND NUMCON  = '" + _xNFISCAL + "' "
    	
    	aDados := U_Qry2Array(_sSQL)
     	// se o conhecimento esta marcado como cancelado não importa
     	if len(aDados) > 0
    		if aDados[1,1] = 'S'
    			_xCONT_CANC := _xCONT_CANC+1
    			DbSelectArea("TRB")
            	DbSkip()
            	Loop
			endif            	
    	endif 
                   
        // Verifica se existe XML referente ao conhecimento
        _xCHAVE := SubStr(TRB->CAMPO,_versao,44)
        //u_showmemo(_xCHAVE)
             
        public _oClsFrtFr := ClsFrtFr():New ()
                
        // atribui conteudos conforme arquivo         
        _xSERIE      := cvaltochar (val (SubStr(TRB->CAMPO,14,4)))  // Serie do conhecimento
        // se a chave conforme a chave da NFE, estiver diferente da chave informada 
        // no arquivo - assume a chave da NFE.
        if cvaltochar (val (substr (_xCHAVE, 23, 3))) != _xSERIE
            _xSERIE = cvaltochar (val (substr (_xCHAVE, 23, 3)))
        endif
        
        _xEMISSAO    := SubStr(TRB->CAMPO,31,8)                    // emissao do conhecimento
        _xEMISSAO    := stod(SubStr(_xEMISSAO,5,4) + SubStr(_xEMISSAO,3,2) + SubStr(_xEMISSAO,1,2))  
        _xPESO       := Val(SubStr(TRB->CAMPO,40,7))/100
        _xVALICM     := Val(SubStr(TRB->CAMPO,81,15))/100
        _xCNPJ       := SubStr(TRB->CAMPO,205,14)
        
        // busca codigo e loja do fornecedor conforme o CNPJ
        _xFORNECE    := fbuscacpo ("SA2", 3, xfilial ("SA2") + _xCNPJ,  "A2_COD")
        _xLOJA       := fbuscacpo ("SA2", 3, xfilial ("SA2") + _xCNPJ,  "A2_LOJA")
        
        CA100For  := _xFORNECE
        cLoja     := _xLOJA
        _oClsFrtFr:_sFornece  = ca100for
        _oClsFrtFr:_sLoja     = cLoja
        //
        // Deixa variaveis carregadas para uso em ponto de entrada posterior.
        public _CA100For := _xFORNECE
        public _cLoja    := _xLOJA
        //
        // busca condicao do fornecedor, conforme cadastro
        _xCONDPAG := fbuscacpo ("SA2", 3, xfilial ("SA2") + _xCNPJ,  "A2_COND")
        if _xCONDPAG = ' '
            u_help ("Condição de pagamento não cadastrada para o fornecedor: " + _xFORNECE + "/" + _xLOJA )
            _lContinua = .F.
            return               
        endif
        
        // Testa se o CTE ja esta lancado - se estiver le o proximo, nem dá mensagem
        _sSQL := ""
        _sSQL += " SELECT 1" 
        _sSQL += "   FROM " + RetSQLName ("SF1") + " AS SF1 "
        _sSQL += "  WHERE SF1.D_E_L_E_T_ = ''"
        _sSQL += "    AND SF1.F1_DOC     = '" + _xNFISCAL + "' "
        _sSQL += "    AND SF1.F1_FORNECE = '" + _xFORNECE + "' "
        _sSQL += "    AND SF1.F1_LOJA    = '" + _xLOJA + "' "
        _sSQL += "    AND SF1.F1_EMISSAO = '" + dtos(_xEMISSAO) + "' "
        _sSQL += "    AND SF1.F1_FILIAL  = '" + xFilial('SF1') + "' "
        _sSQL += "    AND SF1.F1_TIPO    = 'N'"
        _jaSF1 := U_Qry2Array(_sSQL)
         
        if len (_jaSF1) > 0
           _xCONT_NAO += 1
           DbSelectArea("TRB")
           DbSkip()
           Loop
        endif
        
        _werro := 0
        for _i=1 to 40
            _xseries[_i] := SubStr(TRB->CAMPO,222+11*_i,3)                   // Serie do NF
            _xnotas[_i]  := StrZero(Val(SubStr(TRB->CAMPO,225+11*_i,08)),9,0)  // nro da NF
            _xNFCFORI    := _xnotas[_i]
            if val(_xnotas[_i] ) > 0
            	// valida serie nota no SF2
            	DbSelectArea("SF2")
        		DbSetOrder(1)
        		if DbSeek(xFilial("SF2") + _xnotas[_i] + _xseries[_i] ,.F.)
        			// inicializa objeto usado na rotina automatica
                	aadd (_oClsFrtFr:_aNaoPrev, array (3))
                 	_oClsFrtFr:_aNaoPrev [ _i, 1] = _xnotas[_i]
                 	_oClsFrtFr:_aNaoPrev [ _i, 2] = _xseries[_i]
                 	_oClsFrtFr:_aNaoPrev [ _i, 3] = '1'
				else
					_werro = 1						                 	
				endif                 	
            endif
        next   
        // se nao tem erro nas numeracoes de notas fiscais
        if _werro = 0       
	        // atribui conteudos conforme parametros de entrada
	        _xQUANT      := 1  // Fixo
	        // atribui o TES, conforme ICMS
	        If _xVALICM > 0
	            _xTES := _xTES_c_ICMS
	        Else
	            _xTES := _xTES_s_ICMS
	        Endif
	    
	        // inclui SF1
	        _aAutoSF1 := {}
	        AADD( _aAutoSF1, { "F1_FILIAL"   , xFilial('SF1')  , Nil } )
	        AADD( _aAutoSF1, { "F1_DOC"      , _xNFISCAL       , Nil } )
	        AADD( _aAutoSF1, { "F1_SERIE"    , _xSERIE         , Nil } )
	        AADD( _aAutoSF1, { "F1_TIPO"     , "N"             , Nil } )
	        AADD( _aAutoSF1, { "F1_FORMUL"   , "N"             , Nil } )
	        AADD( _aAutoSF1, { "F1_EMISSAO"  , _xEMISSAO       , Nil } )
	        AADD( _aAutoSF1, { "F1_FORNECE"  , _xFORNECE       , Nil } )
	        AADD( _aAutoSF1, { "F1_LOJA"     , _xLOJA          , Nil } )
	        AADD( _aAutoSF1, { "F1_ESPECIE"  , "CTE"           , Nil } )
	        AADD( _aAutoSF1, { "F1_COND"     , _xCONDPAG       , Nil } )
	        AADD( _aAutoSF1, { "F1_CHVNFE"   , _xCHAVE         , Nil } )
	        AADD( _aAutoSF1, { "F1_DTDIGIT"  , date()          , Nil } )
	             
	        _aAutoSF1 := aclone (U_OrdAuto (_aAutoSF1))
	
	        // inclui SD1
	        _aAutoSD1 := {}
	        _aLinhas  := {}
	        
	        AADD(_aLinhas , {"D1_FILIAL"  , xFilial('SD1'        )      , Nil } )
	        AADD(_aLinhas , {"D1_ITEM"    , StrZero(1,4)                , Nil } )
	        AADD(_aLinhas , {"D1_COD"     , _xPRODUTO                   , Nil } )
	        AADD(_aLinhas , {"D1_UM"      , _xUM                        , Nil } )
	        AADD(_aLinhas , {"D1_TP"      , _xTP                        , Nil } )
	        AADD(_aLinhas , {"D1_LOCAL"   , _xLOCAL                     , Nil } )
	        AADD(_aLinhas , {"D1_QUANT"   , 1                           , Nil } )
	        AADD(_aLinhas , {"D1_VUNIT"   , _xTOTAL                     , Nil } )
	        AADD(_aLinhas , {"D1_TOTAL"   , _xTOTAL                     , Nil } )
	        AADD(_aLinhas , {"D1_TES"     , _xTES                       , Nil } )
	        AADD(_aLinhas , {"D1_VALICM"  , _xVALICM                    , Nil } )
	        _aLinhas := aclone (U_OrdAuto (_aLinhas))
	        AADD( _aAutoSD1, aClone( _aLinhas ) )
	            
	        //u_showmemo(_xNFISCAL)
	        //u_showarray(_oClsFrtFr:_aNaoPrev)
	        
	        // Gera o Documento de Entrada
	        lMsHelpAuto := .F.  // se .t. direciona as mensagens de help
	        lMsErroAuto := .F.  // necessario a criacao
	        DbSelectArea("SF1")
	        Begin Transaction
	              MsExecAuto({|x,y,z|MATA103(x,y,z)},_aAutoSF1,_aAutoSD1,3)
	              If lMsErroAuto
	                  MostraErro()
	                  DisarmTransaction()
	              Else
	                  _xCONT += 1
	                  // atualiza SF1
	                  DbSelectArea("SF1")
	                  RecLock("SF1",.F.)
	                  	SF1->F1_VAFLAG   := 'S' // Flag Importacao
	                  MsUnLock()
                   
	              Endif
	        End Transaction
		else
			MsgInfo("Informacoes com erro. Notas referenciadas não encontradas","Conhecimento : "+Transf(_xNFISCAL,"@E 999999"))				        
		endif	        
      	DbSelectArea("TRB")
        DbSkip()
                       
    enddo
    
    if  _xCONT > 0
        // atualiza status para importado
        reclock("ZAA", .F.)
        ZAA->ZAA_STATUS := 'I'
        ZAA->ZAA_DTIMP  := date()
        ZAA->ZAA_DIMP   := STR(_xCONT)
        MsUnLock()
        
        MsgInfo("Foram importados: "+Transf(_xCONT,"@E 999999")+" conhecimentos","Importacao concluida!")
        
        // envia emails para o coordenador logistico
        Processa({||_EEmail(_xArq1, _xFornece, _xLoja, _XnomTransp1)},"Enviando Email ... " )
    endif    
    
    if _xCONT_NAO > 0
        MsgInfo("No arquivo, constam: "+Transf(_xCONT_NAO,"@E 999999")+" conhecimentos que já estão no sistema","")
    endif 
    
    if _xCONT_CANC > 0
        MsgInfo("No arquivo, constam: "+Transf(_xCONT_NAO,"@E 999999")+" conhecimentos marcados como CANCELADOS","")
    endif 

return(_xCONT)
// ----------------------------------------------------------------------------------------------------------------------
// envia emails 
Static Function _EEmail(_xArq1, _xFornece, _xLoja, _xNomTransp)

	   _aCols = {}
	   aadd (_aCols, {'CTe'         ,    'left'  ,  ''})
	   aadd (_aCols, {'Dt.Emissao'  ,    'left'  ,  ''})
	   aadd (_aCols, {'Valor'       ,    'right' ,  '@E 999,999.99'})
	   aadd (_aCols, {'Peso'        ,    'right' ,  '@E 999,999.99'})
	   aadd (_aCols, {'Valor/Kg'    ,    'right' ,  '@E 9,999.99'})
	   aadd (_aCols, {'Frete Perc.' ,    'right' ,  '@E 999.99'})
	   aadd (_aCols, {'Danfe'       ,    'left'  ,  ''})
	   aadd (_aCols, {'Cliente'     ,    'left'  ,  ''})
	   aadd (_aCols, {'Cidade'      ,    'left'  ,  ''})
	   aadd (_aCols, {'Estado'      ,    'left'  ,  ''})
		
	   // Somente os pedidos que tem previsao de entrega nos proximos 5 dias
	   _oSQL := ClsSQL():New ()
	   _oSQL:_sQuery := ""
	   _oSQL:_sQuery += " SELECT RTRIM(NUMCON)"
       _oSQL:_sQuery += "	  	, RTRIM(EMISSAO)"
       _oSQL:_sQuery += "		, VALOR/100"
       _oSQL:_sQuery += "		, PESO/100"
       _oSQL:_sQuery += "		, VLR_KG"
       _oSQL:_sQuery += "		, FRETE_PERC"
       _oSQL:_sQuery += "		, RTRIM(NFSAIDA)"
       _oSQL:_sQuery += "		, LEFT(NOM_CLI,20)"
       _oSQL:_sQuery += "		, RTRIM(CIDADE)"
       _oSQL:_sQuery += "		, RTRIM(UF)"
   	   _oSQL:_sQuery += "   FROM AUX_EDICONH"
	   _oSQL:_sQuery += "		INNER JOIN SF1010 SF1  "
	   _oSQL:_sQuery += "             ON (SF1.D_E_L_E_T_ = '' "
	   _oSQL:_sQuery += "                 AND SF1.F1_DOC     =  RTRIM(NUMCON)"
	   _oSQL:_sQuery += "				  AND SF1.F1_FORNECE = '" + _xFORNECE + "' "
	   _oSQL:_sQuery += "		 		  AND SF1.F1_LOJA    = '" + _xLOJA + "' "
	   _oSQL:_sQuery += "				  AND SF1.F1_FILIAL  = '" + xFilial('SF1') + "' "
	   _oSQL:_sQuery += "				  AND SF1.F1_TIPO    = 'N'"
	   _oSQL:_sQuery += "				  AND SF1.F1_VAFLAG  = 'S')"
 	   _oSQL:_sQuery += "   WHERE ARQUIVO = '" + _xArq1 + "' "
	   _oSQL:_sQuery += "   ORDER BY RECNO"
	    
	    //u_showmemo(_oSQL:_sQuery)
	    
	   if len (_oSQL:Qry2Array (.T., .F.)) > 0
	   
	        _sMsg = _oSQL:Qry2HTM ("CTe's Importados - Verificar Frete/KG - " + _xNomTransp, _aCols, "", .F.)
	     	U_ZZUNU ({'007'}, "CTe's Importados - Verificar Frete/KG - " + _xNomTransp, _sMsg, .F., cEmpAnt, cFilAnt, "") // Coordenador logistica
	   endif
return
// ----------------------------------------------------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function L_EDICONH (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i	   := 0
	
    aadd (_aCores, {"ZAA->ZAA_STATUS = 'D'"															  , 'BR_BRANCO'  , 'Desconsiderado'})
    aadd (_aCores, {"ZAA->ZAA_STATUS = 'NI' .AND. ZAA->ZAA_LAYOUT != 'OK' " 						  , 'BR_VERMELHO', 'Layout Inválido'})
    aadd (_aCores, {"ZAA->ZAA_STATUS = 'NI' .AND. ZAA->ZAA_LAYOUT  = 'OK' .AND. ZAA->ZAA_XML = 'BX' " , 'BR_AMARELO' , 'Baixar XML'})
    aadd (_aCores, {"ZAA->ZAA_STATUS = 'NI' .AND. ZAA->ZAA_LAYOUT  = 'OK' .AND. ZAA->ZAA_XML = 'OK' " , 'BR_VERDE'   , 'Arquivo Não Importado'})
    aadd (_aCores, {"ZAA->ZAA_STATUS = 'I'"															  , 'BR_AZUL'    , 'Arquivo Importado'})

	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return
