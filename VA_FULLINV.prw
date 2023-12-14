// Programa.: VA_FULLINV
// Autor....: Cláudia Lionço
// Data.....: 11/12/2023
// Descricao: Importa estoque fullsoft
//
// Historico de alteracoes:
//
// -------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function VA_FULLINV()
	local _lContinua   := .T.
	local cCadastro    := "Importa estoque fullsoft"
	local aSays        := {}
	local aButtons     := {}
	local nOpca        := 0
	local _nLock       := 0
	Private cPerg      := "VA_FULLINV"
	private _ErroLog   :=""
	private _MErro     := .F.
	_Cnt := .T.

	u_logIni ()
	
	if _lContinua
		if ! u_zzuvl ('106', __cUserId, .T.)
			_lContinua = .F.
		endif
	endif

	If _lContinua // Somente uma estacao por vez
		_nLock := U_Semaforo (procname (), .F.)
		If _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
			return
		EndIf
	EndIf
	
	If _lContinua
		_ValidPerg ()
		If ! pergunte (cPerg, .T.)
			return
		Endif

		AADD(aSays,cCadastro)
        AADD(aSays,"")
        AADD(aSays,"")
        AADD(aButtons, { 1, .T.,{|| nOpca := If(_TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
        AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
        FormBatch( cCadastro, aSays, aButtons )

        If nOpca == 1
            Processa( { |lEnd| _Importa() } )
        Endif
		
		If _nLock > 0	// Libera semaforo.
			U_Semaforo (_nLock)
		EndIf

        _ImprimeRel()
	EndIf
Return
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
//
// --------------------------------------------------------------------------
// Importa arquivo
Static Function _Importa()
    Local _aDados   := {}
    Local _sLinkSrv := ""
    Local _x        := 0

	_VerificaLogs()
 
    _sLinkSrv = U_LkServer ('FULLWMS_AX01')

    _oSQL := ClsSQL():New ()  
	_oSQL:_sQuery := "" 		  
    _oSQL:_sQuery += " SELECT
    _oSQL:_sQuery += " 	    *
    _oSQL:_sQuery += " FROM OPENQUERY(" + _sLinkSrv + ", "
    _oSQL:_sQuery += " 'select  "
    _oSQL:_sQuery += " 	    item_cod_item_log AS ITEM_FULL "
    _oSQL:_sQuery += " 	    ,sum(qtd) as QTD "
    _oSQL:_sQuery += "  from v_alianca_estoques "
    _oSQL:_sQuery += " 	where empr_codemp = 1 "
    _oSQL:_sQuery += " 	group by item_cod_item_log ') "
    _aDados := _oSQL:Qry2Array()

    For _x:=1 to Len(_aDados)	
		IncProc("Importando dados...")
	
		dbSelectArea("SB7")
		dbSetOrder(5) // B7_FILIAL+B7_DOC+B7_COD+B7_LOCAL                                                                                                                                                                                                                                     
		dbGoTop()
		
		_sFilial := '01'
        _sDoc    := PADR(alltrim(mv_par01),9, ' ') 
		_sProd   := PADR(alltrim(_aDados[_x,1]),15, ' ')
		_sLocal  := '01'
		
		
		If dbSeek(_sFilial + _sDoc + _sProd + _sLocal)
			Reclock("SB7",.F.)
				SB7->B7_VAQTD := _aDados[_x,2] 
				SB7->B7_VAOBS := 'IMPORTADO DO FULLSOFT'
			SB7->(MsUnlock())
		Else
			//u_help(" O produto: " + alltrim(_sProd) + " no local " + _sLocal + " no documento " + alltrim(_sDoc) + " não encontrado!" )

            _oEvento := ClsEvent():new ()
            _oEvento:Texto   = "Produto:" + alltrim(_sProd) + " não encontrado no doc. " + _sDoc + "."
            _oEvento:NFSaida = _sDoc
            _oEvento:Produto = _sProd
            _oEvento:CodEven = 'SB7002'
            _oEvento:Grava ()
		EndIf
	Next
Return
//
// --------------------------------------------------------------------------
// verifica se tem va_veventos para o documento para limpar
Static Function _VerificaLogs()

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " DELETE FROM VA_VEVENTOS "
	_oSQL:_sQuery += " WHERE NF_SAIDA = '"+ mv_par01 +"' "
	_oSQL:Exec ()
Return
//
// --------------------------------------------------------------------------
// Imprime relatorio
Static Function _ImprimeRel
	
	oReport := ReportDef()
	oReport:PrintDialog()
	
Return
//
// -----------------------------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oSection2:= Nil

	oReport := TReport():New("VA_FULLINV","Inventario Fullsoft X Protheus",,{|oReport| PrintReport(oReport)},"Inventario Fullsoft X Protheus")
	
	oReport:lHeaderVisible := .T.
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()

	//SESSÃO 1 
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	oSection1:SetTotalInLine(.F.)	
	TRCell():New(oSection1,"COLUNA1", 	" ","Produto"		,	    			,15,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	" ","Descricao"		,       			,40,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	" ","Obs"			,    				,60,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)


	//SESSÃO2 
	oSection2 := TRSection():New(oReport," ",{""}, , , , , ,.F.,.F.,.F.) 
	
	oSection2:SetTotalInLine(.F.)
	TRCell():New(oSection2,"COLUNA1", 	" ","Produto"		,					,15,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA2", 	" ","Descricao"		,					,40,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	" ","Qtd.Protheus"	,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	" ","Qtd.FullSoft"	,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	
Return(oReport)
//
// -----------------------------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)	 
	Local _x        := 0

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   PRODUTO "
	_oSQL:_sQuery += "    ,SB1.B1_DESC "
	_oSQL:_sQuery += "    ,DESCRITIVO "
	_oSQL:_sQuery += " FROM VA_VEVENTOS "
	_oSQL:_sQuery += " LEFT JOIN SB1010 SB1 "
	_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND B1_COD = PRODUTO "
	_oSQL:_sQuery += " WHERE NF_SAIDA = '" + mv_par01 + "' "
	_aFull := _oSQL:Qry2Array()

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   B7_COD "
	_oSQL:_sQuery += "    ,SB1.B1_DESC "
	_oSQL:_sQuery += "    ,'NÃO ATUALIZADO' "
	_oSQL:_sQuery += " FROM SB7010 SB7 "
	_oSQL:_sQuery += " LEFT JOIN SB1010 SB1 "
	_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SB1.B1_COD = B7_COD "
	_oSQL:_sQuery += " WHERE SB7.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND B7_DOC = '" + mv_par01 + "' "
	_oSQL:_sQuery += " AND B7_LOCAL = '01' "
	_oSQL:_sQuery += " AND B7_VAOBS <> 'IMPORTADO DO FULLSOFT' "
	_aProtheus := _oSQL:Qry2Array()


	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := "" 
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   B7_COD "
	_oSQL:_sQuery += "    ,SB1.B1_DESC "
	_oSQL:_sQuery += "    ,B7_QUANT "
	_oSQL:_sQuery += "    ,B7_VAQTD "
	_oSQL:_sQuery += " FROM SB7010 SB7 "
	_oSQL:_sQuery += " LEFT JOIN SB1010 SB1 "
	_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SB1.B1_COD = B7_COD "
	_oSQL:_sQuery += " WHERE SB7.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND B7_DOC = '" + mv_par01 + "' "
	_oSQL:_sQuery += " AND B7_LOCAL = '01' "
	_oSQL:_sQuery += " AND B7_VAOBS = 'IMPORTADO DO FULLSOFT' "
	_oSQL:_sQuery += " AND B7_QUANT <> B7_VAQTD "
	_aDif := _oSQL:Qry2Array()

	oReport:ThinLine()
	oReport:PrintText(" " ,,50)
	oReport:PrintText("ITENS FULLSOFT NÃO ENCONTRADOS NO INVENTARIO DOC." + mv_par01 ,,50)
	oReport:PrintText(" " ,,50)
	oReport:ThinLine()

	oSection1:Init()

	For _x := 1 to Len(_aFull)
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| alltrim(_aFull[_x, 1]) }) 
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| alltrim(_aFull[_x, 2]) }) 
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| alltrim(_aFull[_x, 3]) }) 
		oSection1:Printline()
	Next
	
	oReport:PrintText(" " ,,50)
	oReport:ThinLine()
	oReport:PrintText(" " ,,50)
	oReport:PrintText("ITENS PROTHEUS NÃO ENCONTRADOS NO FULLSOFT " ,,50)
	oReport:PrintText(" " ,,50)
	oReport:ThinLine()
	
	For _x := 1 to Len(_aProtheus)
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| alltrim(_aProtheus[_x, 1]) }) 
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| alltrim(_aProtheus[_x, 2]) }) 
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| alltrim(_aProtheus[_x, 3]) }) 
		oSection1:Printline()
	Next
	
	oReport:PrintText(" " ,,50)
	oReport:ThinLine()
	oReport:PrintText(" " ,,50)
	oReport:PrintText("DIFERENÇA ENTRE ESTOQUE PROTHEUS X FULL " ,,50)
	oReport:PrintText(" " ,,50)
	oReport:ThinLine()

	oSection2:Init()
	For _x := 1 to Len(_aDif)
		oSection2:Cell("COLUNA1")	:SetBlock   ({|| alltrim(_aDif[_x, 1]) }) 
		oSection2:Cell("COLUNA2")	:SetBlock   ({|| alltrim(_aDif[_x, 2]) }) 
		oSection2:Cell("COLUNA3")	:SetBlock   ({|| _aDif[_x, 3] }) 
		oSection2:Cell("COLUNA4")	:SetBlock   ({|| _aDif[_x, 4] }) 
		oSection2:Printline()
	Next
	
	
	// Finaliza seções
	oSection2:Finish() 
	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg()
	local _aRegsPerg := {}
	//                     PERGUNT                 TIPO TAM DEC VALID F3        Opcoes Help
	aadd (_aRegsPerg, {01, "Documento", "C", 9,  0,  "",   "   ", {},    ""})	
	U_ValPerg (cPerg, _aRegsPerg)
Return
