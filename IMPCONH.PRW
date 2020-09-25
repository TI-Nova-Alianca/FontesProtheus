// Programa...: IMPCONH
// Autor......: Catia Cardoso
// Data.......: 18/10/2014
// Descricao..: Importacao de Conhecimentos de Fretes
// ------------------------------------------------------------------------------------
//
// Historico de alteracoes:
// 08/04/2019 - Catia  - include TbiConn.ch 
// 04/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25
// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "rwmake.ch"

User Function IMPCONH(_lAutomat)
	Local cCadastro := "Importa Conhecimentos de Frete"
    Local aSays     := {}
    Local aButtons  := {}
    Local nOpca     := 0
    Local lPerg     := .F.
    public CA100For := ''
    public cLoja    := ''
    private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
    private _sArqLog := U_NomeLog ()
    u_logID ()

    Private cPerg   := "IMPCONH"
    _ValidPerg()
    Pergunte(cPerg,.F.)

    AADD(aSays,"Este programa tem como objetivos: importar Conhecimentos de Frete sobre VENDAS;")
    AADD(aSays,"validar a existência dos XML dos mesmos; agilizar o processo e minimizar erros.")
    AADD(aSays,"")
    
    AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
    AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
    AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
    
    FormBatch( cCadastro, aSays, aButtons )
    
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
    
    If nOpca == 1
       Processa( { |lEnd| Continua() } )
    Endif

Return(.T.)
//
// --------------------------------------------------------------------------
Static Function Continua()
    _xCaminho := ""
	_xVararq1 := Alltrim(_xCaminho+Trim(mv_par01))
	
	If !File( _xVararq1 )
		MsgAlert("Arquivo " + _xVararq1 + " Nao Existe","Importacao Cancelada!")
		Return(nil)
	Endif
	
//	_aEstru := {}
//	aadd(_aEstru,{'CAMPO','C',740,0})
//	_cArq   := CriaTrab(_aEstru,.T.)
//	DbUseArea(.T.,,_cArq,'TRB',.T.,.F.)

	_aArqTrb := {}
	_aEstru  := {}
	aadd(_aEstru,{'CAMPO','C',740,0})	
	U_ArqTrb ("Cria", "TRB", _aEstru, {}, @_aArqTrb)	
	
	Append From &_xVararq1 SDF 
		
	Processa({||_Importa()},"Importando arquivo ... " )
	
	TRB->(DbCloseArea())
	u_arqtrb ("FechaTodos",,,, @_aArqTrb)
	//Erase(_cArq + '.dbf')
Return
//
// ------------------------------------------------------------------------------------
Static Function _Importa()
    local _aArqTrb   := {}
    local _aCampos   := {}
    local _xCONT     := 0
    local _lContinua := .T.
    local _xFORNECE  := ' '
    local _xseries   := array(40)
    local _xnotas    := array(40)
    local _werro     := ""
    local _werro1    := ""
    local _versao    := 681
    local _i		 := 0
    private _xNFCFORI := ""  // Deixar 'private' para ser vista por pontos de entrada.
    
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
            If len(_TemXML) > 0
               DbSelectArea("TRB")
               DbSkip()
               Loop
            Else
                // grava erro SEM XML
                _werro += _xCHAVE
                _werro += chr (13) + chr (10)  
            Endif
        Else   
            // grava erro SEM CHAVE
            _werro1 += StrZero(Val(SubStr(TRB->CAMPO,19,12)),9,0)
            _werro1 += chr (13) + chr (10)
        endif     
        DbSelectArea("TRB")
        DbSkip()
    enddo
    
    _werro := "" // nao esquecer de tirar
        
    if len(_werro) > 0
        _werro += chr (13) + chr (10)
        _werro += "Conhecimentos sem XML no sistema. Baixar XML's dos CTe's conforme chaves acima." 
        _werro += chr (13) + chr (10)
        _werro += "Transportadora : " + _wtransp
        _werro += chr (13) + chr (10)
        u_showmemo(_werro)
        return
    else         
	    
	     if len(_werro1) > 0
            _werro1 += chr (13) + chr (10)
            _werro1 += "Conhecimentos sem Chave no arquivo. Layout não esta correto."
            _werro1 += chr (13) + chr (10)
            _werro1 += "Entrar em contato com a transportadora: " + _wtransp
            _werro1 += chr (13) + chr (10)
            u_showmemo(_werro1)
            return
        endif         
            
        // busca dados do ITEM
        _xUM    := fbuscacpo ("SB1", 1, xfilial ("SB1") + _xPRODUTO,  "B1_UM")
        _xTP    := fbuscacpo ("SB1", 1, xfilial ("SB1") + _xPRODUTO,  "B1_TIPO")
        _xLOCAL := fbuscacpo ("SB1", 1, xfilial ("SB1") + _xPRODUTO,  "B1_LOCPAD")
    
        DbSelectArea("TRB")
	     DbGoTop()
	     Do While _lContinua .and. !TRB->(Eof())
	      
		      IncProc("Atualizando informacoes ... ")
		      // le so registros referentes aos conhecimentos
		      if SubStr(TRB->CAMPO,1,3) <> '322'
                DbSelectArea("TRB")
                DbSkip()
                Loop
             EndIf
         
             // Se encontrar algum conhecimento de frete FOB
             _xTPFRETE      := SubStr(TRB->CAMPO,39,1)
             If _xTPFRETE <> 'C'
                MsgAlert("Encontrado conhecimento com Frete FOB. Importação Cancelada!")
                return
             EndIf
         
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
             _xNFISCAL    := StrZero(Val(SubStr(TRB->CAMPO,19,12)),9,0)  // nro do conhecimento
             _xEMISSAO    := SubStr(TRB->CAMPO,31,8)                    // emissao do conhecimento
             _xEMISSAO    := stod(SubStr(_xEMISSAO,5,4) + SubStr(_xEMISSAO,3,2) + SubStr(_xEMISSAO,1,2))  
             _xPESO       := Val(SubStr(TRB->CAMPO,40,7))/100
             _xTOTAL      := Val(SubStr(TRB->CAMPO,47,15))/100
             _xVALICM     := Val(SubStr(TRB->CAMPO,81,15))/100
             _xCNPJ       := SubStr(TRB->CAMPO,205,14)
             for _i=1 to 40
                 _xseries[_i] := SubStr(TRB->CAMPO,222+11*_i,3)                   // Serie do NF
                 _xnotas[_i]  := StrZero(Val(SubStr(TRB->CAMPO,225+11*_i,08)),9,0)  // nro da NF
                 _xNFCFORI    := _xnotas[_i]
                 if val(_xnotas[_i] ) > 0 
                     aadd (_oClsFrtFr:_aNaoPrev, array (3))
                     _oClsFrtFr:_aNaoPrev [ _i, 1] = _xnotas[_i]
                     _oClsFrtFr:_aNaoPrev [ _i, 2] = _xseries[_i]
                     _oClsFrtFr:_aNaoPrev [ _i, 3] = 1
                 endif
             next    
               
             // atribui conteudos conforme parametros de entrada
             _xQUANT      := 1  // Fixo
             // atribui o TES, conforme ICMS
             If _xVALICM > 0
                _xTES := _xTES_c_ICMS
             Else
                _xTES := _xTES_s_ICMS
             Endif
           
             if _xFORNECE = ' '     
                 // busca codigo e loja do fornecedor conforme o CNPJ
                 _xFORNECE := fbuscacpo ("SA2", 3, xfilial ("SA2") + _xCNPJ,  "A2_COD")
                 _xLOJA    := fbuscacpo ("SA2", 3, xfilial ("SA2") + _xCNPJ,  "A2_LOJA")
                 CA100For  := _xFORNECE
                 cLoja     := _xLOJA
                 _oClsFrtFr:_sFornece  = ca100for
                 _oClsFrtFr:_sLoja     = cLoja

                 // Deixa variaveis carregadas para uso em ponto de entrada posterior.
                 public _CA100For := _xFORNECE
                 public _cLoja    := _xLOJA

                 // busca condicao do fornecedor, conforme cadastro
                 _xCONDPAG := fbuscacpo ("SA2", 3, xfilial ("SA2") + _xCNPJ,  "A2_COND")
                 if _xCONDPAG = ' '
                    u_help ("Condição de pagamento não cadastrada para o fornecedor: " + _xFORNECE + "/" + _xLOJA )
                    return               
                 endif
             endif
            
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
			           DbSelectArea("SF1")
			           RecLock("SF1",.F.)
			           SF1->F1_VAFLAG   := 'S' // Flag Importacao
			           MsUnLock()
		           Endif
		      End Transaction
       
            DbSelectArea("TRB")
            DbSkip()
                       
	       enddo
       endif	       
   
	U_ArqTrb ("FechaTodos",,,, @_aArqTrb)
	MsgInfo("Foram importados: "+Transf(_xCONT,"@E 999999")+" Conhecimentos","Importacao concluida!")
Return(nil)
//
// --------------------------------------------------------------------------
Static Function _ValidPerg()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes          Help
    aadd (_aRegsPerg, {01, "Arquivo a importar     ", "C", 60, 0,  "",  "DIR", {},             ""})
    
	U_ValPerg (cPerg, _aRegsPerg)
Return
//
// --------------------------------------------------------------------------
Static Function _TudoOk()
	Local _aArea    := GetArea()
	Local _lRet     := .T.
	RestArea(_aArea)
Return(_lRet)
