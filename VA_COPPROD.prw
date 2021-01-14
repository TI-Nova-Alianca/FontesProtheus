// Programa...: VA_COPPROD
// Autor......: Cláudia Lionço
// Data.......: 11/01/2021
// Descricao..: Cópia de produtos SB1 e produto x fornecedor SA5
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Cópia de produtos SB1 e produto x fornecedor SA5
// #PalavasChave      #copia_de_produtos #produtoXfornecedor
// #TabelasPrincipais #SB1 #SA5
// #Modulos   		  #EST 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------------
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE 'Protheus.ch'
#INCLUDE 'FWMVCDef.ch'

User Function VA_COPPROD()
	Local _aDados 	:= {}
	Local _aProduto := {}
	Local _i 		:= 0
    Local _x        := 0
    Private _aRelat     := {}

    if ! U_ZZUVL ('124', __cUserId, .T.)
        u_help("Usuário sem acesso para a rotina 124")
		return
	endif

    cPerg   := "VA_COPPROD"
	_ValidPerg ()
	If ! pergunte (cPerg, .T.)
		return
	Endif
	
	cDir := alltrim(mv_par01)
	cArq := alltrim(mv_par02)
	cExt := alltrim(mv_par03)
	
	cFile := alltrim(cDir)+ Alltrim(cArq)+ alltrim(cExt)
	If !File(cFile)
		MsgStop("O arquivo " + cFile + " não foi encontrado. A importação será abortada!","[ZB1] - ATENCAO")
		Return
	EndIf
	
	_aDados = U_LeCSV (cFile, ';')

	For _i := 2 to len(_aDados)
		IncProc("Lendo planilha e gravando...")

		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT B1_FILIAL, B1_COD, B1_DESC, B1_TIPO, B1_UM, B1_LOCPAD, B1_LOCALIZ,"
        _oSQL:_sQuery += " B1_GRUPO, B1_ORIGEM, B1_PICM, B1_IPI, B1_CONTRAT, B1_POSIPI, "
        _oSQL:_sQuery += " B1_GRPEMB, B1_CODLIN, B1_VAMARCM, B1_VARMAAL, B1_GRTRIB, "
        _oSQL:_sQuery += " B1_APROPRI, B1_TE, B1_TIPCONV, B1_TIPE, B1_VAGRLP, B1_CONTA, B1_CONV"
		_oSQL:_sQuery += " FROM SB1010 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_= '' "
		_oSQL:_sQuery += " AND B1_COD = '" + alltrim(_aDados [_i, 1]) + "'"
		_aProduto := aclone (_oSQL:Qry2Array ())

		For _x := 1 to len(_aProduto)
            _aSB1 := {}
            _sProdOld := _aDados [_i, 1]
            _sProdNew := alltrim(_aProduto [_x, 2]) + 'C'

            aadd (_aSB1 ,{  _aProduto [_x, 1]           ,; // 1 Filial
                            _sProdNew                	,; // 2 Codigo
                            _aProduto [_x, 3]           ,; // 3 Descricao
                            _aProduto [_x, 4]           ,; // 4 Tipo
                            _aProduto [_x, 5]           ,; // 5 UM
                            _aProduto [_x, 6]           ,; // 6 locPad
                            _aProduto [_x, 7]           ,; // 7 localiz
                            _aProduto [_x, 8]           ,; // 8 grupo
                            _aProduto [_x, 9]	        ,; // 9 Origem
                            _aProduto [_x, 10]          ,; // 10 PICM
                            _aProduto [_x, 11]          ,; // 11 IPI
                            _aProduto [_x, 12]          ,; // 12 Contrat
                            _aProduto [_x, 13]          ,; // 13 PosIPI
                            _aProduto [_x, 14]          ,; // 14 GRPEMB
                            _aProduto [_x, 15]          ,; // 15 CodLin
                            _aProduto [_x, 16]          ,; // 16 VAMARCM
                            _aProduto [_x, 17]          ,; // 17 VARMAAL
                            _aProduto [_x, 18]          ,; // 18 GRUPO TRIBUTARIO
                            _aProduto [_x, 19]          ,; // 19 B1_APROPRI
                            _aProduto [_x, 20]          ,; // 20 B1_TE
                            _aProduto [_x, 21]          ,; // 21 B1_TIPCONV
                            _aProduto [_x, 22]          ,; // 22 B1_TIPE
                            _aProduto [_x, 23]          ,; // 23 B1_VAGRLP
                            _aProduto [_x, 24]          ,;  // B1_CONTA
                            _aProduto [_x, 25]          })  // B1_CONV
                            

            MsAguarde({|| U_VA_COPSB1(_aSB1, _sProdOld, _sProdNew, _aRelat)}, "Aguarde...", "Processando Registros...")

            //U_VA_COPSB1(_aSB1, _sProdOld, _sProdNew, _aRelat)
			
		Next
	Next
    // imprime relatório
    If len(_aRelat) > 0
        RelImportacao()
    EndIf
Return
//
// ------------------------------------------------------------------------------------------
// Realiza a cópia do produto
User Function VA_COPSB1(_aSB1, _sProdOld, _sProdNew, _aRelat)
	Local oModel        := Nil
    Local _x            := 0
	Private lMsErroAuto := .F.
 
	oModel  := FwLoadModel ("MATA010")
	oModel:SetOperation(MODEL_OPERATION_INSERT)
	oModel:Activate()
	oModel:SetValue("SB1MASTER","B1_FILIAL"     ,_aSB1[1, 1] )
	oModel:SetValue("SB1MASTER","B1_COD"        ,_aSB1[1, 2] )
	oModel:SetValue("SB1MASTER","B1_DESC"       ,_aSB1[1, 3] )
	oModel:SetValue("SB1MASTER","B1_TIPO"       ,"MC"        ) // _aSB1[1, 4] Solicit. por juliana 20210112
	oModel:SetValue("SB1MASTER","B1_UM"     	,_aSB1[1, 5] )
	oModel:SetValue("SB1MASTER","B1_LOCPAD" 	,_aSB1[1, 6] )
	oModel:SetValue("SB1MASTER","B1_LOCALIZ"    ,_aSB1[1, 7] )
    oModel:SetValue("SB1MASTER","B1_GRUPO"      ,_aSB1[1, 8] )
    oModel:SetValue("SB1MASTER","B1_ORIGEM"     ,_aSB1[1, 9] )
    oModel:SetValue("SB1MASTER","B1_PICM"       ,_aSB1[1,10] )
    oModel:SetValue("SB1MASTER","B1_IPI"        ,_aSB1[1,11] )
    oModel:SetValue("SB1MASTER","B1_CONTRAT"    ,_aSB1[1,12] )
    oModel:SetValue("SB1MASTER","B1_POSIPI"     ,_aSB1[1,13] )
    oModel:SetValue("SB1MASTER","B1_GRPEMB"     ,_aSB1[1,14] )
    oModel:SetValue("SB1MASTER","B1_CODLIN"     ,_aSB1[1,15] )
    oModel:SetValue("SB1MASTER","B1_VAMARCM"    ,_aSB1[1,16] )
    oModel:SetValue("SB1MASTER","B1_VARMAAL"    ,_aSB1[1,17] )
    oModel:SetValue("SB1MASTER","B1_GRTRIB"     ,"MC"        ) // _aSB1[1,18]
    oModel:SetValue("SB1MASTER","B1_APROPRI"    ,_aSB1[1,19] ) 
    oModel:SetValue("SB1MASTER","B1_TE"         ,_aSB1[1,20] ) 
    oModel:SetValue("SB1MASTER","B1_TIPCONV"    ,_aSB1[1,21] ) 
    oModel:SetValue("SB1MASTER","B1_TIPE"       ,_aSB1[1,22] ) 
    oModel:SetValue("SB1MASTER","B1_VAGRLP"     ,_aSB1[1,23] ) 
    oModel:SetValue("SB1MASTER","B1_CONTA"      ,_aSB1[1,24] ) 
    oModel:SetValue("SB1MASTER","B1_VATROUT"    ,"N"         ) 
    oModel:SetValue("SB1MASTER","B1_CONV"       ,_aSB1[1,25] ) 

    MsProcTxt(" Gravando registros...")
	If oModel:VldData()
		oModel:CommitData()
		
        //MsgInfo("Registro INCLUIDO! " + _aSB1[1,2], "Atenção")
        AADD (_aRelat , { _aSB1[1,2] ,; // produto
                       'IMPORTADO'   ,; // status
                       "-"           ,; // fornecedor
                       "-"           ,; // nome fornecedor
                       "-"           ,; // codigo prod/fornecedor
                       "SB1"         }) // tabela

        // INCLUSÃO DO COMPLEMENTO DO PRODUTO - SB5
         _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT B5_COD, B5_CEME, B5_CODZON, B5_MSIDENT"
        _oSQL:_sQuery += " FROM SB5010 "
        _oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
        _oSQL:_sQuery += " AND B5_COD ='" + alltrim(_sProdOld) + "'"
        _aCompl := aclone (_oSQL:Qry2Array ())

         If len(_aCompl) > 0
            For _x:= 1 to len(_aCompl)
                U_VA_CSB5(_aCompl, _x, _sProdNew)
            Next
        EndIf
        // ---------------------------------------------------------------------------------------------------
        // INCLUSÃO DE PRODUTO X FORNECEDOR
        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT A5_PRODUTO, A5_NOMPROD, A5_FORNECE, A5_LOJA, A5_NOMEFOR, A5_CODPRF, A5_TOLEDIF,"
        _oSQL:_sQuery += " A5_VAQTPAL, A5_VAQSOLW, A5_NOTA, A5_SKIPLOT, A5_TEMPLIM, A5_FABREV, A5_CODPRCA,"
        _oSQL:_sQuery += " A5_CODBAR, A5_TIPOCOT, A5_DIASSIT, A5_CODTAB, A5_TIPATU, A5_CODFIS, A5_NCMPRF, A5_DESCPRF,"
        _oSQL:_sQuery += " A5_CNO, A5_TESCP, A5_PE, A5_TIPE"
        _oSQL:_sQuery += " FROM SA5010 "
        _oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
        _oSQL:_sQuery += " AND A5_PRODUTO ='" + alltrim(_sProdOld) + "'"
        _aFornece := aclone (_oSQL:Qry2Array ())

        If len(_aFornece) > 0
            For _x:= 1 to len(_aFornece)
                U_VA_COPSA5(_aFornece, _x, _sProdNew, _aRelat)
            Next
        EndIf
	Else
        AADD (_aRelat , { _aSB1[1,2]     ,; // produto
                       'NÃO IMPORTADO'   ,; // status
                       "-"               ,; // fornecedor
                       "-"               ,; // nome fornecedor
                       "-"               ,; // codigo prod/fornecedor
                       "SB1"             }) // tabela

		//VarInfo("",oModel:GetErrorMessage())
	EndIf       
		 
	oModel:DeActivate()
	oModel:Destroy()
	 
	oModel := NIL
	 
Return 
//
// ------------------------------------------------------------------------------------------
// Realiza a cópia do produto x fornecedor
User Function VA_COPSA5(_aFornece, _x, _sProdNew, _aRelat)
    Local nOpc := 3
    Local oModelo := Nil

	oModelo := FWLoadModel('MATA061')

	oModelo:SetOperation(nOpc)
	oModelo:Activate()

	//Cabeçalho
	oModelo:SetValue('MdFieldSA5','A5_PRODUTO'   , _sProdNew        )
	oModelo:SetValue('MdFieldSA5','A5_NOMPROD'   , _aFornece[_x, 2] )
    oModelo:SetValue('MdGridSA5' ,'A5_FORNECE'   , _aFornece[_x, 3] )
    oModelo:SetValue('MdGridSA5' ,'A5_LOJA'      , _aFornece[_x, 4] )
    oModelo:SetValue('MdGridSA5' ,'A5_NOMEFOR'   , _aFornece[_x, 5] )
    oModelo:SetValue('MdGridSA5' ,'A5_CODPRF'    , _aFornece[_x, 6] )
    oModelo:SetValue('MdGridSA5' ,'A5_TOLEDIF'   , _aFornece[_x, 7] )
    oModelo:SetValue('MdGridSA5' ,'A5_VAQTPAL'   , _aFornece[_x, 8] )
    oModelo:SetValue('MdGridSA5' ,'A5_VAQSOLW'   , _aFornece[_x, 9] )
    oModelo:SetValue('MdGridSA5' ,'A5_NOTA'      , _aFornece[_x,10] )
    oModelo:SetValue('MdGridSA5' ,'A5_SKIPLOT'   , _aFornece[_x,11] )
    oModelo:SetValue('MdGridSA5' ,'A5_TEMPLIM'   , _aFornece[_x,12] )
    oModelo:SetValue('MdGridSA5' ,'A5_FABREV'    , _aFornece[_x,13] )
    oModelo:SetValue('MdGridSA5' ,'A5_CODPRCA'   , _aFornece[_x,14] )
    oModelo:SetValue('MdGridSA5' ,'A5_CODBAR'    , _aFornece[_x,15] )
    oModelo:SetValue('MdGridSA5' ,'A5_TIPOCOT'   , _aFornece[_x,16] )
    oModelo:SetValue('MdGridSA5' ,'A5_DIASSIT'   , _aFornece[_x,17] )
    oModelo:SetValue('MdGridSA5' ,'A5_CODTAB'    , _aFornece[_x,18] )
    oModelo:SetValue('MdGridSA5' ,'A5_TIPATU'    , _aFornece[_x,19] )
    oModelo:SetValue('MdGridSA5' ,'A5_CODFIS'    , _aFornece[_x,20] )
    oModelo:SetValue('MdGridSA5' ,'A5_NCMPRF'    , _aFornece[_x,21] )
    oModelo:SetValue('MdGridSA5' ,'A5_DESCPRF'   , _aFornece[_x,22] )
    oModelo:SetValue('MdGridSA5' ,'A5_CNO'       , _aFornece[_x,23] )
    oModelo:SetValue('MdGridSA5' ,'A5_TESCP'     , _aFornece[_x,24] )
    oModelo:SetValue('MdGridSA5' ,'A5_PE'        , _aFornece[_x,25] )
    oModelo:SetValue('MdGridSA5' ,'A5_TIPE'      , _aFornece[_x,26] )

	If oModelo:VldData()
		oModelo:CommitData()

        AADD (_aRelat , { _sProdNew       ,; // produto
                       'IMPORTADO'      ,; // status
                       _aFornece[_x, 3] ,; // fornecedor
                       _aFornece[_x, 5] ,; // nome fornecedor
                       _aFornece[_x, 6] ,; // codigo prod/fornecedor
                       "SA5"            }) // tabela

		//MsgInfo("Registro INCLUIDO! ", "Atenção")
	Else
        AADD (_aRelat , { _sProdNew       ,; // produto
                       'NÃO IMPORTADO'  ,; // status
                       _aFornece[_x, 3] ,; // fornecedor
                       _aFornece[_x, 5] ,; // nome fornecedor
                       _aFornece[_x, 6] ,; // codigo prod/fornecedor
                       "SA5"            }) // tabela

		//VarInfo("",oModelo:GetErrorMessage())
	EndIf  

	oModelo:DeActivate()

	oModelo:Destroy()

Return
//
// ------------------------------------------------------------------------------------------
// Realiza a cópia do produto x fornecedor
User Function VA_CSB5(_aCompl, _x, _sProdNew)
    Local oModel    := Nil

    //Para utilização da mesma, o modelo de dados chama-se MATA180M e nao MATA180
    oModel:= FwLoadModel("MATA180")
    oModel:SetOperation(MODEL_OPERATION_INSERT)
    oModel:Activate()

    oModel:SetValue("SB5MASTER","B5_COD"     , _sProdNew)
    oModel:SetValue("SB5MASTER","B5_CEME"    , _aCompl[_x, 2])
    oModel:SetValue("SB5MASTER","B5_CODZON"  , _aCompl[_x, 3])
    oModel:SetValue("SB5MASTER","B5_MSIDENT" , _aCompl[_x, 4])

    If oModel:VldData()
        oModel:CommitData()
    EndIf

    oModel:DeActivate()
    oModel:Destroy()
    oModel := NIL
Return
//
// --------------------------------------------------------------------------
// Relatorio de registros importados
Static Function RelImportacao()
	Private oReport
	//Private cPerg   := "VA_RELPORT"
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ---------------------------------------------------------------------------
// Cabeçalho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oBreak1

	oReport := TReport():New("VA_COPPROD","Cópia de produto e produto x fornecedor",cPerg,{|oReport| PrintReport(oReport)},"Cópia de produto e produto x fornecedor")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Produto"		    ,	    		,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Status"		    ,       		,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Fornecedor"		,       		,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA4", 	"" ,"Nome Fornecedor"	,       		,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Cod. ProdXFornece"	,       		,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Tabela"		    ,       		,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1  := oReport:Section(1)
	Local i          := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

	For i:=1 to Len(_aRelat)
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aRelat[i,1] }) 
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aRelat[i,2] }) 
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aRelat[i,3] }) 
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aRelat[i,4] }) 
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aRelat[i,5] }) 
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aRelat[i,6] }) 
		
		oSection1:PrintLine()
	Next

	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
    aadd (_aRegsPerg, {01, "Diretorio          ", "C", 40, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {02, "Nome do arquivo    ", "C", 20, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {03, "Extensão           ", "C",  4, 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
