//  Programa...: VA_COMMAIL
//  Autor......: Cláudia Lionço
//  Data.......: 25/06/2020
//  Descricao..: Relatório de Comissoes para envio em PDF - Reescrito para novo modelo TREPORT 
//			     e alterações de verbas/comissões.
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de Comissoes para envio em PDF
// #PalavasChave      #comissoes #verbas #bonificação #comissões #representante #comissão 
// #TabelasPrincipais #SE3 #SE1 #SF2 #SD2 #SE5 #SA3
// #Modulos 		  #FIN 
//
//  Historico de alteracoes:
//  07/12/2020 - Claudia - Incluido valor de indenização no totalizador do PDF de comissão. GLPI: 8991 
//  04/01/2020 - Claudia - Incluido o codigo e nome da empresa/filial. GLPI: 8925
//  08/01/2021 - Claudia - Alterada a indenização, pegando direto o Total da comissão 
//               e dividindo por 12. GLPI: 9099
//  05/05/2021 - Cláudia - Adicionado valor de frete + seguro + despesas acessorias. GLPI: 9895
//  07/05/2021 - Claudia - Retirado _mvsim1:= GetMv ("MV_SIMB1") devido a erros R27. 
//  07/06/2021 - Claudia - Inicializado o parametro de nome de vendedor com vazio, para casos onde 
//                         vendedro não possua notas no mes, mas está ativo.
//  26/10/2021 - Claudia - Realizado ajuste quando tem dois vendedores. GLPI: 11124
//  12/01/2022 - Claudia - Criada nova validação para indenização. GLPI: 11361
//  06/11/2023 - Claudia - Criada validação conforme GLPI: 14465
//  08/11/2023 - Claudia - Incluido o calculo de valores de verbas, sem necessidade 
//                         da impressão em relatorio. GLPI: 14475
//
// ----------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "rwmake.ch"
#include 'fivewin.ch'
#include 'topconn.ch'
#INCLUDE "TBICONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"

#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User Function VA_COMMAIL()
	cString := "SE3"
    cDesc1  := "Relatório de Comissões"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "VA_COMMAIL"
    wnrel   := "VA_COMMAIL"
    nTipo   := 0

	_ValidPerg()
	Pergunte(cPerg,.T.)

	If ! u_zzuvl ('046', __cUserId, .T.)
		return
	Else
		If mv_par05 != 2
			msgalert("Só é possível enviar por email, se as comissoes ja estiverem geradas no financeiro.")
			return
		Else		
			MsgRun("Aguarde o processamento...", "Comissão em PDF", {|| _GeraPDF_Email()}) // gera PDF e manda por email							
			 
		Endif													
	Endif	
Return
//
// --------------------------------------------------------------------------
// Gera PDF
Static Function _GeraPDF_Email()	
	Local _y 			 := 0
	Local _aItens   	 := {}
	Local _dDtaPt        := ""
	Local _aDev          := {}
	Private _oSQL        := ClsSQL():New ()
	Private oPrint       := TMSPrinter():New(OemToAnsi('Relatorio de Comissoes'))
	Private oBrush       := TBrush():New(,4)
	Private oPen         := TPen():New(0,5,CLR_BLACK)
	Private oFont12n     := TFont():New('Tahoma',12,12,,.T.,,,,.T.,.F.)
	Private oFont13      := TFont():New('Tahoma',13,13,,.T.,,,,.T.,.F.)
	Private oFont22      := TFont():New('Arial',22,22,,.T.,,,,.T.,.F.)
	Private nLinha       := 0
	
	// Define diretório
	_dMes := mesextenso(substr(dtos(mv_par01),5,2))
	
	cDestino := "\comissoes\" + _dMes +'\'
	makedir (cDestino)
	_cPathPDF := "S:\Protheus12\protheus_data\comissoes\" + _dMes +'\'
	
	_oSQL  := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	// verifica quais vendedores deseja enviar o relatorio por email
	_oSQL:_sQuery += "  SELECT DISTINCT(SE3.E3_VEND) AS VENDEDOR"
	_oSQL:_sQuery += "       , SA3.A3_EMAIL          AS EMAIL"
	_oSQL:_sQuery += "       , SA3.A3_INDENIZ        AS INDENIZ"
	_oSQL:_sQuery += "       , SA3.A3_INDEBKP        AS INDENIZ_BKP"
	_oSQL:_sQuery += "       , SA2.A2_SIMPNAC        AS SIMPLES"
	_oSQL:_sQuery += "       , SE3.E3_DATA           AS DTPAG"
	_oSQL:_sQuery += "       , SA2.A2_BANCO          AS BANCO"
	_oSQL:_sQuery += "       , RTRIM(SA2.A2_AGENCIA) + '-' + RTRIM(SA2.A2_DVAGE) AS AGENCIA"
	_oSQL:_sQuery += "       , RTRIM(SA2.A2_NUMCON)  + '-' + RTRIM(SA2.A2_DVCTA) AS CONTA"
	_oSQL:_sQuery += "    FROM " + RetSQLName ("SE3") + " AS SE3 "
	_oSQL:_sQuery += " 	  	INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
	_oSQL:_sQuery += " 		 	ON (SA3.D_E_L_E_T_    = ''"
	_oSQL:_sQuery += " 		 	    AND SA3.A3_FILIAL = '' "
	_oSQL:_sQuery += " 			 	AND SA3.A3_COD = SE3.E3_VEND)"
	_oSQL:_sQuery += "  	INNER JOIN " + RetSQLName ("SA2") + " AS SA2 "
    _oSQL:_sQuery += "          ON (SA2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "           	AND SA2.A2_COD        = SA3.A3_FORNECE"
    _oSQL:_sQuery += "              AND SA2.A2_LOJA       = SA3.A3_LOJA)"
    _oSQL:_sQuery += "   WHERE SE3.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "     AND SE3.E3_FILIAL  = '" + xFilial('SE3') + "' "
    _oSQL:_sQuery += "     AND SE3.E3_VEND NOT IN " + FormatIn (alltrim (GetMv ('MV_VENDDIR')), '/') // desconsidera os vendedores diretos
    _oSQL:_sQuery += "     AND SE3.E3_VEND    BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
    _oSQL:_sQuery += "     AND SE3.E3_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _oSQL:_sQuery += "     AND SE3.E3_DATA != '' "

    _oSQL:Log ()
	_sAliasVend = _oSQL:Qry2Trb (.f.)
	
    count to _nRecCount
    procregua (_nRecCount)
    
    // le arquivo de trabalho dos vendedores a gerar email
    (_sAliasVend) -> (DBGoTop ())
    Do While ! (_sAliasVend) -> (Eof ())
    	_sVend    := (_sAliasVend) -> VENDEDOR
		_sNomeVend:= ""
		_dDtaPgto := stod((_sAliasVend) -> DTPAG)
		
    	_cFile := "RelCom_" + ALLTRIM(_sVend) //nome do arquivo padrão, deve ser alterado para não sobrescrever
    	delete file(cDestino + _cFile)
    	
    	// define objeto
		oPrint := FWMSPrinter():New(_cFile, IMP_PDF, .T., , .T.)
    	oPrint:SetResolution(72)
		oPrint:SetLandscape()
		oPrint:SetPaperSize(DMPAPER_A4)
		oPrint:SetMargin(60,60,60,60) // nEsquerda, nSuperior, nDireita, nInferior
		oPrint:cPathPDF := _cPathPDF  // Caso seja utilizada impressão em IMP_PDF
    
		_aTotVend := {0,0,0,0,0,0,0,0,0,0,0,0}
    	_wpag     := 0
    	nLinha    := 4000
	
		_sAliasQ = U_VA_COMEXE(mv_par01, mv_par02, _sVend, mv_par05) // Consulta principal
		(_sAliasQ) -> (dbgotop ())

		_nTotComis    := 0
		_nTotPerComis := 0
		_nTotBaseLib  := 0
		_nTotBaseTit  := 0
		_nTotVlrRec   := 0
		_nTotVlrDesc  := 0
		_nTotVlrTit   := 0	
		
		Do while ! (_sAliasQ) -> (eof ())
			
			// define faviáries
			_sFilial    := (_sAliasQ) -> FILIAL
			_sNota      := (_sAliasQ) -> NUMERO
			_sSerie     := (_sAliasQ) -> PREFIXO
			_sParcela   := (_sAliasQ) -> PARCELA
			_sTipo      := (_sAliasQ) -> E3_TIPO
			_sCliente   := (_sAliasQ) -> CODCLI
			_sLoja      := (_sAliasQ) -> LOJA
			_nBaseComis	:= (_sAliasQ) -> BASE_COMIS
			_nVlrComis  := (_sAliasQ) -> VLR_COMIS
			_VlrDescNf  := (_sAliasQ) -> BONIF_NF
			_vlrFreSeg  := (_sAliasQ) -> FRETE_NF + (_sAliasQ) -> SEGURO + (_sAliasQ) -> DESPESA // frete+ seguro + outras despesas acessorias 
			_nBaseNota  := (_sAliasQ) -> TOTAL_NF - (_sAliasQ) -> IPI_NF - (_sAliasQ) -> ST_NF - _vlrFreSeg - _VlrDescNf 
			//_nBaseNota  := (_sAliasQ) -> TOTAL_NF - (_sAliasQ) -> IPI_NF  - (_sAliasQ) -> ST_NF - (_sAliasQ) -> FRETE_NF - _VlrDescNf 
			_sDataVenc  := STOD((_sAliasQ) -> VENCIMENTO)
			_nSimples   := (_sAliasQ) -> SIMPLES
			_sTipIndeniz:= (_sAliasQ) -> INDENIZ
			_sTipIndBKP := (_sAliasQ) -> INDENIZ_BKP
			_sBanco     := (_sAliasQ) -> BANCO
			_sNomeBanco := (_sAliasQ) -> NOMEBANCO
			_nAgencia   := (_sAliasQ) -> AGENCIA
			_nConta     := (_sAliasQ) -> CONTA
			_sNomeVend  := alltrim((_sAliasQ) -> NOM_VEND) 
			_nIpiNota	:= (_sAliasQ) -> IPI_NF
			_nStNota	:= (_sAliasQ) -> ST_NF
			
			_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
			
			_sParcNew := MontaParcelas(_sFilial,_sNota,_sSerie,_sCliente,_sLoja,_sParcela)
		
			// IMPRIME NOTA
			oPrint:Say(nLinha,0045, (_sAliasQ) -> NUMERO	  	 				            		,oFont12n)
			oPrint:Say(nLinha,0195, _sParcNew 			  					    		            ,oFont12n)
			If mv_par06 = 1
				oPrint:Say(nLinha,0470, left((_sAliasQ) -> NOMECLIENTE,35) 	 			  			,oFont12n)
			Else
				oPrint:Say(nLinha,0470, left((_sAliasQ) -> NOMEREDUZIDO,35) 	 					,oFont12n)
			EndIf
			oPrint:Say(nLinha,1045, TransForm((_sAliasQ) -> TOTAL_NF  		, '@E 9,999,999.99')  	,oFont12n)

			oPrint:Say(nLinha,1245, TransForm((_sAliasQ) -> BASE_TIT  		, '@E 9,999,999.99')  	,oFont12n) 
			oPrint:Say(nLinha,1475, dtoc(_sDataVenc)  			        							,oFont12n)
			oPrint:Say(nLinha,1645, TransForm((_sAliasQ) -> VALOR_TIT 		,   '@E 999,999.99') 	,oFont12n)
			oPrint:Say(nLinha,1845, TransForm((_sAliasQ) -> VLR_DESCONTO    , '@E 9,999,999.99') 	,oFont12n)
			oPrint:Say(nLinha,2045, TransForm((_sAliasQ) -> VLR_RECEBIDO    , '@E 9,999,999.99') 	,oFont12n)
			oPrint:Say(nLinha,2285, TransForm((_sAliasQ) -> BASE_COMIS 		, '@E 9,999,999.99') 	,oFont12n)
			If mv_par08 = 1
				oPrint:Say(nLinha,2525, TransForm((_sAliasQ) -> PERCENTUAL  ,   	 '@E 99.99') 	,oFont12n)
			Endif
			oPrint:Say(nLinha,2645, TransForm((_sAliasQ) -> VLR_COMIS  		, '@E 9,999,999.99') 	,oFont12n)	
			
			nLinha += 50
			
			// Acumula valores das notas
			_nTotComis    += (_sAliasQ) -> VLR_COMIS
			_nTotPerComis += (_sAliasQ) -> PERCENTUAL
			_nTotBaseLib  += (_sAliasQ) -> BASE_COMIS
			_nTotBaseTit  += (_sAliasQ) -> BASE_TIT	
			_nTotVlrRec   += (_sAliasQ) -> VLR_RECEBIDO
			_nTotVlrDesc  += (_sAliasQ) -> VLR_DESCONTO
			_nTotVlrTit   += (_sAliasQ) -> VALOR_TIT
			
			// Imprime itens da nota
			If mv_par08 == 2 
				
				_aItens = U_VA_COMITNF(_sFilial, _sNota, _sSerie, _nBaseComis, _nVlrComis, _nBaseNota, _sVend)

				For _y := 1 to len(_aItens)
				
					_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
			
					oPrint:Say(nLinha,0100, alltrim(_aItens[_y,1]) 	 			  	 			,oFont12n)
					oPrint:Say(nLinha,0200, alltrim(_aItens[_y,2])	 			  	 			,oFont12n)
					oPrint:Say(nLinha,1045, TransForm( _aItens[_y,3]    , '@E 9,999,999.99') 	,oFont12n)
					oPrint:Say(nLinha,2285, TransForm( _aItens[_y,4]    , '@E 9,999,999.99') 	,oFont12n)
					oPrint:Say(nLinha,2525, TransForm( _aItens[_y,5]    , 		 '@E 99.99') 	,oFont12n)
					oPrint:Say(nLinha,2645, TransForm( _aItens[_y,6]    , '@E 9,999,999.99') 	,oFont12n)	
					nLinha += 50
							
				Next
			EndIf
						
			(_sAliasQ) -> (dbskip ())
		EndDo	
		//-----------------------------------------------------------------------------------------------------------------
		//Busca verbas descontadas
		//
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += "     ZB0_TIPO"
		_oSQL:_sQuery += "    ,ZB0_VENVER"
		_oSQL:_sQuery += "    ,ZB0_VENNF"
		_oSQL:_sQuery += "    ,ZB0_NUM"
		_oSQL:_sQuery += "    ,ZB0_DOC"
		_oSQL:_sQuery += "    ,ZB0_PREFIX"
		_oSQL:_sQuery += "    ,ZB0_CLI"
		_oSQL:_sQuery += "    ,ZB0_LOJA"
		_oSQL:_sQuery += "    ,ZB0_PERCOM"
		_oSQL:_sQuery += "    ,ZB0_VLBASE"
		_oSQL:_sQuery += "    ,ZB0_VLCOMS"
		_oSQL:_sQuery += "    ,CASE"
		_oSQL:_sQuery += " 			WHEN ZB0_ACRDES = 'D' THEN 'DESCONTO'"
		_oSQL:_sQuery += " 			ELSE 'ACRESCIMO'"
		_oSQL:_sQuery += "     END AS ACRDES"
		_oSQL:_sQuery += "    ,ZB0_DTAPGT"
		_oSQL:_sQuery += " FROM " + RetSQLName ("ZB0") 
		_oSQL:_sQuery += " WHERE D_E_L_E_T_='' "
		_oSQL:_sQuery += " AND ZB0_FILIAL = '" +  xFilial('ZB0')  +"'" 
		_oSQL:_sQuery += " AND ZB0_DATA BETWEEN '" + DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) +"'"
		_oSQL:_sQuery += " AND ZB0_VENDCH = '"+_sVend+"'"
		_oSQL:Log ()
				
		_aDescVerb  = aclone (_oSQL:Qry2Array ())		
		
		_nVlrTVerbas := 0
		_nVlrBon     := 0
		_nVlrVer     := 0
			
		If mv_par10 == 2
			If len(_aDescVerb)> 0 
				oPrint:Say(nLinha,0100, " *** DESCONTOS DE VERBAS/BONIFICAÇÕES:"	 	,oFont12n)
				nLinha += 50
				
				oPrint:Say(nLinha,0100, "Tipo" 	 			  	 	 ,oFont12n)
				oPrint:Say(nLinha,0600, "Vend.Verba" 	 			 ,oFont12n)
				oPrint:Say(nLinha,0800, "Vend.NF" 	 			  	 ,oFont12n)
				oPrint:Say(nLinha,1000, "Verba" 	 			  	 ,oFont12n)
				oPrint:Say(nLinha,1300, "Nota/Série" 	 			 ,oFont12n)
				oPrint:Say(nLinha,1600, "Cliente/Loja" 	 			 ,oFont12n)
				oPrint:Say(nLinha,1900, "Percentual" 	 			 ,oFont12n)
				oPrint:Say(nLinha,2200, "Base/valor" 	 			 ,oFont12n)
				oPrint:Say(nLinha,2500, "Comissao" 	 		 		 ,oFont12n)
				oPrint:Say(nLinha,2800, "Valor" 	 		 		 ,oFont12n)
				nLinha += 50
			EndIf
		EndIf
			
		For _y := 1 to len(_aDescVerb)
			_dDtaPt := DTOS(_aDescVerb[_y,13])
			If mv_par10 == 2
				_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
				
				// Descrição de tipo
				_sTipoZb0 := ""
				Do Case
					Case alltrim(_aDescVerb[_y,1]) == '1'
						_sTipoZb0 := '1 - VERBAS S/ MOV. NO TITULO'
						
					Case alltrim(_aDescVerb[_y,1]) == '2'
						_sTipoZb0 := '2 - VERBA DE OUTROS NO TITULO'
						
					Case alltrim(_aDescVerb[_y,1]) == '3'
						_sTipoZb0 := '3 - BONIFICAÇÕES' 
						
					Case alltrim(_aDescVerb[_y,1]) == '4'
						_sTipoZb0 := '4 - VERBAS BOLETO/DEPOSITO'
						
					Case alltrim(_aDescVerb[_y,1]) == '5'
						_sTipoZb0 := '5 - VERBA EM TITULO DE OUTROS'
						
					Case alltrim(_aDescVerb[_y,1]) == '6'
						_sTipoZb0 := '6 - VERBA EM TITULO SEM COMISSÃO'
				EndCase
			EndIf	
			Do Case
			
				Case mv_par11 == 2 .and. ( empty(_dDtaPt) .or. _dDtaPt =='19000101')  // pagas
					// registro sem data de pgto nao entra nas pagas
				Case mv_par11 == 3 	.and.  _dDtaPt != '19000101'  // em aberto
					// registro com data de pagamento n entra nos registros em aberto
				Otherwise
					If mv_par10 == 2
						oPrint:Say(nLinha,0100, alltrim(_sTipoZb0 )  	 									,oFont12n)
						oPrint:Say(nLinha,0600, alltrim(_aDescVerb[_y,2])									,oFont12n)
						oPrint:Say(nLinha,0800, alltrim(_aDescVerb[_y,3])	 								,oFont12n)
						oPrint:Say(nLinha,1000, alltrim(_aDescVerb[_y,4])	 								,oFont12n)
						oPrint:Say(nLinha,1300, alltrim(_aDescVerb[_y,5]) +"/"+ alltrim(_aDescVerb[_y,6])	,oFont12n)
						oPrint:Say(nLinha,1600, alltrim(_aDescVerb[_y,7]) +"/"+ alltrim(_aDescVerb[_y,8])	,oFont12n)
						oPrint:Say(nLinha,1900, TransForm(_aDescVerb[_y, 9] , '@E 9,999,999.99') 	 		,oFont12n)
						oPrint:Say(nLinha,2200, TransForm(_aDescVerb[_y,10] , '@E 9,999,999.99') 		 	,oFont12n)
						oPrint:Say(nLinha,2500, TransForm(_aDescVerb[_y,11] , '@E 9,999,999.99') 		 	,oFont12n)
						oPrint:Say(nLinha,2800,   alltrim(_aDescVerb[_y,12])  	 							,oFont12n)
						
						nLinha += 50
					EndIf
					//If alltrim(_aDescVerb[_y,1]) == '3 - BONIFICAÇÕES'
					If alltrim(_aDescVerb[_y,1]) == '3'
						_nVlrBon += _aDescVerb[_y,11]
					Else
						_nVlrVer += _aDescVerb[_y,11]
					EndIf
			EndCase	
		Next
		nLinha += 50
		
		If len(_aDescVerb)
			_nVlrBon:= ROUND(_nVlrBon,2)
			_nVlrVer:= ROUND(_nVlrVer,2)
			_nVlrTVerbas := _nVlrBon+_nVlrVer
			
			If mv_par10 == 2
				nLinha += 50
				oPrint:Say(nLinha,0150,  "TOTAIS DE VERBAS PARA DESCONTO " +  TransForm(_nVlrTVerbas, '@E 9,999,999.99') 	,oFont12n)
				nLinha += 50
			EndIf
		EndIf
		//
		// ----------------------------------------------------------------------------------------------------------
		// DEVOLUÇÕES

		_aDev = U_VA_COMDEV(mv_par01, mv_par02, _sVend)

		If mv_par10 == 2
			nLinha += 50
			nLinha += 50
			If len(_aDev)> 0 
				oPrint:Say(nLinha,0100, " *** DESCONTOS DE DEVOLUÇÃO:"	 	,oFont12n)
				nLinha += 50
				
				oPrint:Say(nLinha,0100, "Título" 	 			  	 ,oFont12n)
				oPrint:Say(nLinha,0600, "Prefixo" 	 			     ,oFont12n)
				oPrint:Say(nLinha,0800, "Parcela" 	 			  	 ,oFont12n)
				oPrint:Say(nLinha,1000, "Cliente/Loja" 	 			 ,oFont12n)
				oPrint:Say(nLinha,1300, "Nome" 	 			 		 ,oFont12n)
				oPrint:Say(nLinha,1900, "Valor Mov." 	 			 ,oFont12n)
				oPrint:Say(nLinha,2200, "% Comis.Médio" 	 		 ,oFont12n)
				oPrint:Say(nLinha,2500, "Comissão" 	 		   		 ,oFont12n)
				nLinha += 50
			EndIf
		EndIf

		_nTotDev := 0
		_nValor := 0
		For _y := 1 to len(_aDev)
			If  _aDev[_y,12] == 'P' .and. _aDev[_y,13] == 'CMP'
				_nValor := _aDev[_y,11] * -1
			else
				_nValor := _aDev[_y,11]
			endif

			If mv_par10 == 2
				_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
			
				oPrint:Say(nLinha,0100, alltrim(_aDev[_y,2]) 	 			  	 			,oFont12n)
				oPrint:Say(nLinha,0600, alltrim(_aDev[_y,3]) 	 			  	 			,oFont12n)
				oPrint:Say(nLinha,0800, alltrim(_aDev[_y,4]) 	 			  	 			,oFont12n)
				oPrint:Say(nLinha,1000, alltrim(_aDev[_y,5] +"/" + _aDev[_y,6]) 			,oFont12n)
				oPrint:Say(nLinha,1300, alltrim(_aDev[_y,7]) 	 			  	 			,oFont12n)
				oPrint:Say(nLinha,1900, TransForm( _aDev[_y,8] , '@E 9,999,999.99') 		,oFont12n)
				oPrint:Say(nLinha,1900, TransForm( _aDev[_y,10] , '@E 999.99') 				,oFont12n)
				oPrint:Say(nLinha,1900, TransForm( _nValor , '@E 9,999,999.99') 			,oFont12n)

				nLinha += 50
			EndIf
			_nTotDev += _nValor
					
		Next
		nLinha += 50

		If len(_aDev)
			_nTotDev:= ROUND(_nTotDev,2)
			
			If mv_par10 == 2
				nLinha += 50
				oPrint:Say(nLinha,0150,  "TOTAIS DE DEVOLUÇÕES PARA DESCONTO " +  TransForm(_nTotDev, '@E 9,999,999.99') 	,oFont12n)
				nLinha += 50
			EndIf
		EndIf
		nLinha += 50
		//
		// ----------------------------------------------------------------------------------------------------------
		// TOTALIZADORES
		_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho

		nLinha += 50
		oPrint:Say(nLinha,0150,  "RESUMO DO CÁLCULO DE COMISSÕES "  + AllTrim(_sVend) + " - " + AllTrim(_sNomeVend)			,oFont12n)
		_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho

		nLinha += 50
		oPrint:Say(nLinha,0150,  "BASE COMISSÃO LIBERADA:" 											,oFont12n)
		oPrint:Say(nLinha,0900,  PADL('R$' + Transform(_nTotBaseLib, "@E 999,999,999.99"),20,' ')	,oFont12n)

		_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
		nLinha += 50		
		oPrint:Say(nLinha,0150,  "COMISSÕES OUTRAS VERBAS:" 													,oFont12n)
		oPrint:Say(nLinha,0900,  PADL('R$' + Transform(_nVlrVer, "@E 999,999,999.99"),20,' ') 		,oFont12n)

		_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
		nLinha += 50
		oPrint:Say(nLinha,0150,  "COMISSÕES OUTROS DESCONTOS/BONIFICAÇÕES:"									,oFont12n)
		oPrint:Say(nLinha,0900,  PADL('R$' + Transform(_nVlrBon, "@E 999,999,999.99"),20,' ')   	,oFont12n)

		_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
		nLinha += 50
		oPrint:Say(nLinha,0150,  "COMISSÕES DEVOLUÇÕES:"									,oFont12n)
		oPrint:Say(nLinha,0900,  PADL('R$' + Transform(_nTotDev, "@E 999,999,999.99"),20,' ')   	,oFont12n)

		_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
		nLinha += 50
		
		// Desconta verbas
		If _nVlrTVerbas < 0
			_nVlrTVerbas = _nVlrTVerbas * -1
			_nVlrCom:= _nTotComis - _nVlrTVerbas
		Else
			_nVlrCom:= _nTotComis + _nVlrTVerbas
		EndIf
		
		// Descontas as devoluções
		If _nTotDev < 0
			_nTotDev = _nTotDev * -1
			_nVlrCom:= _nVlrCom - _nTotDev
		Else
			_nVlrCom:= _nVlrCom + _nTotDev
		EndIf

		_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
		oPrint:Say(nLinha,0150,  "COMISSÃO TOTAL:"													,oFont12n)
		oPrint:Say(nLinha,0900,  PADL('R$' + Transform(_nVlrCom, "@E 999,999,999.99"),20,' ')   	,oFont12n)
		nLinha += 50	
		
		// IR - so faz a retenção de IR para representantes que NAO ESTAO no simples nacional
		_nVlrIR := 0
		If _nSimples != '1' // 1=SIM
			_nVlrIR = ROUND(_nVlrCom * 1.5 /100 , 2)
			If _nVlrIR > 10
				_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
				oPrint:Say(nLinha,0150,  "TOTAL DO IR:"														,oFont12n)
				oPrint:Say(nLinha,0900,  PADL('R$' + Transform(_nVlrIR, "@E 999,999,999.99"),20,' ')		,oFont12n)
				nLinha += 50	
			Else
				_nVlrIR = 0            	
			Endif            	
		EndIf	
		
		_ImprimeCabec(_sVend, _sNomeVend, @_wpag, @nlinha) // Imprime cabeçalho
		oPrint:Say(nLinha,0150,  "TOTAL COMISSÃO A RECEBER:"												,oFont12n)
		oPrint:Say(nLinha,0900,  PADL('R$' + Transform(_nVlrCom - _nVlrIR, "@E 999,999,999.99"),20,' ')   	,oFont12n)
		nLinha += 50
		
		If (nLinha/50) > 32
		    _wpag += 1	
			xCabec(_sVend, _sNomeVend)
			nlinha := 600
		Endif
		// ----------------------------------------------------------------------------------------------------------
		// Indenização
		//_nTotalInde := _nTotComis - _nVlrTVerbas - _nTotDev// Sem IR
		_nTotalInde:=_nVlrCom // alterado para pegar ja direta a comissão total

		If dtos(mv_par02) < '20220101'
			_sTpInd := _sTipIndBKP 
		else
			_sTpInd := _sTipIndeniz
		EndIf

		_nIndeniz = ROUND(_nTotalInde /12 , 2)

		oPrint:Say(nLinha,0150,  "VLR INDENIZAÇÃO 1/12 " + IIF (_sTpInd ='S', 'PAGA', 'PROVISIONADA')	+":" ,oFont12n)
		oPrint:Say(nLinha,0900,  PADL('R$' + Transform(_nIndeniz, "@E 999,999,999.99"),20,' ')   		 ,oFont12n)
		nLinha += 100

		If _sTpInd ='S' 
			_vIRind := 0
			If _nSimples != '1'
				_vIRind = ROUND(_nIndeniz * 15 /100 , 2)
				If _vIRind > 10
					
				Else
					_vIRind := 0
				Endif
			Endif
		Endif
		
		If (nLinha/50) > 32
		    _wpag += 1	
			xCabec(_sVend, _sNomeVend)
			nlinha := 600
		Endif
		// ----------------------------------------------------------------------------------------------------------
		// Imprime box : DADOS PARA EMISSAO NOTA FISCAL e DADOS INDENIZAÇÃO 1/2 AVOS
		
		nLinha += 50 // linha em branco
	        
		oPrint:Box( nLinha - 30	, 400, nLinha + 30 , 1300)
		oPrint:Say( nLinha		, 550, OemToAnsi('DADOS PARA EMISSAO NOTA FISCAL')		,oFont13)
		
		If _sTpInd ='S'
			oPrint:Box( nLinha - 30	,   1600, nLinha + 30, 2500)
			oPrint:Say( nLinha, 		1750, OemToAnsi('DADOS INDENIZAÇÃO 1/2 AVOS')	,oFont13)
		Endif
		nLinha += 50
		
		oPrint:Box( nLinha - 30, 400, nLinha + 30, 1300)
		oPrint:Say( nLinha, 	 450, OemToAnsi('VALOR COMISSÃO                       ' + TransForm( _nVlrCom, '@E  9,999,999.99'))		,oFont13)
		
		If _sTpInd ='S'
			oPrint:Box( nLinha - 30 , 1600, nLinha + 30	, 2500)
			oPrint:Say(nLinha		, 1650, OemToAnsi('VALOR                                ' + TransForm( _nIndeniz , '@E  9,999,999.99')) ,oFont13)
		Endif
		
		nLinha += 50
		
		oPrint:Box( nLinha - 30 , 400, nLinha + 30	, 1300)
		oPrint:Say( nLinha		, 450, OemToAnsi('VALOR IR                             '      + TransForm( _nVlrIR    , '@E  9,999,999.99'))	,oFont13)
		
		If _sTpInd ='S' .and. _nSimples != '1'
			oPrint:Box( nLinha - 30 , 1600, nLinha + 30	, 2500)
			oPrint:Say( nLinha		, 1650, OemToAnsi('VALOR IR                             ' + TransForm( _vIRind , '@E  9,999,999.99'))	,oFont13)
		Endif
		nLinha += 50
		
		oPrint:Box( nLinha - 30 , 400, nLinha + 30	, 1300)
		oPrint:Say( nLinha		, 450, OemToAnsi('VALOR LIQUIDO COMISSÃO               ' + TransForm( _nVlrCom - _nVlrIR , '@E 9,999,999.99')),oFont13)
		If _sTpInd ='S'
			oPrint:Box( nLinha - 30 , 1600, nLinha + 30	, 2500)
			oPrint:Say( nLinha		, 1650, OemToAnsi('VALOR LIQUIDO                        ' + TransForm( _nIndeniz - _vIRind, '@E 9,999,999.99')),oFont13)
		Endif
		nLinha += 50
		
		oPrint:Box( nLinha - 30 , 400, nLinha + 30	, 1300)
		If _sTpInd ='S'
			oPrint:Box( nLinha - 30 , 1600, nLinha + 30	, 2500)
		Endif
		nLinha += 50
		
		oPrint:Box( nLinha - 30, 400, nLinha + 30 , 1300)
		If _sTpInd ='S'
			oPrint:Box( nLinha - 30, 1600, nLinha + 30 , 2500)
		Endif

		oPrint:Say(nLinha, 450,OemToAnsi('DADOS DO PAGAMENTO'  ),oFont13)
		If _sTpInd ='S'
			oPrint:Say(nLinha, 1650,OemToAnsi('DADOS DO PAGAMENTO'  ),oFont13)
		Endif
		nLinha += 50
		
		oPrint:Box( nLinha - 30,  400, nLinha + 30 , 1300)
		oPrint:Say(nLinha, 450, OemToAnsi('DATA                               '  + dtoc( _dDtaPgto) + '  *' ),oFont13)
		If _sTpInd ='S'
			oPrint:Box( nLinha - 30,  1600, nLinha + 30 , 2500)
			oPrint:Say(nLinha, 1650,OemToAnsi('DATA                               '  + dtoc(_dDtaPgto) + '  *' ),oFont13)
		Endif
		nLinha += 50
		
		oPrint:Box( nLinha - 30,  400, nLinha + 30 , 1300)
		oPrint:Say(nLinha, 450,OemToAnsi('BANCO                ' + alltrim(_sBanco) + " - " + alltrim(_sNomeBanco)),oFont13)
		If _sTpInd ='S'
			oPrint:Box( nLinha - 30,  1600, nLinha + 30 , 2500)
			oPrint:Say(nLinha, 1650,OemToAnsi('BANCO            ' + alltrim(_sBanco) + " - " + alltrim(_sNomeBanco)),oFont13)
		Endif
		nLinha += 50
		
		oPrint:Box( nLinha - 30,  400, nLinha + 30 , 1300)
		oPrint:Say(nLinha, 450,OemToAnsi('AGENCIA                                ' + _nAgencia),oFont13)
		If _sTpInd ='S'
			oPrint:Box( nLinha - 30,  1600, nLinha + 30 , 2500)
			oPrint:Say(nLinha, 1650,OemToAnsi('AGENCIA                                ' + _nAgencia),oFont13)
		Endif
		nLinha += 50
		
		oPrint:Box( nLinha - 30,  400, nLinha + 30 , 1300)
		oPrint:Say(nLinha, 450,OemToAnsi('CONTA                                  ' + _nConta),oFont13)
		If _sTpInd ='S'
			oPrint:Box( nLinha - 30,  1600, nLinha + 30 , 2500)
			oPrint:Say(nLinha, 1650,OemToAnsi('CONTA                                  ' + _nConta ),oFont13)
		Endif
		nLinha += 50
		
		nLinha += 50 
		oPrint:Say(nLinha, 300,OemToAnsi('* Pagamento via depósito, mediante recebimento da NF por email.'),oFont13)
		If _sTpInd ='S'
			oPrint:Say(nLinha, 1650,OemToAnsi('* Pagamento via depósito.'),oFont13)
		Endif
		nLinha += 50
		
		oPrint:Say(nLinha, 300,OemToAnsi('  Email para envio da NF: andressa.brugnera@novaaliança.coop.br'),oFont13)
		nLinha += 50
		//
		// ----------------------------------------------------------------------------------------------------------
		// Monta o recibo se for indenizacao paga no mes
			
		If _sTpInd ='S'
			_oCour14N  := TFont():New("Courier New",,14,,.T.,,,,,.F.)
			_oCour16   := TFont():New("Courier New",,16,,.F.,,,,,.F.)
			_oCour16N  := TFont():New("Courier New",,16,,.T.,,,,,.F.)
			_oCour20N  := TFont():New("Courier New",,20,,.T.,,,,,.F.)
			
			_oArial10  := TFont():New("Arial",,10,,.F.,,,,,.F.)
			_oArial16  := TFont():New("Arial",,16,,.F.,,,,,.F.)
			_oArial32N := TFont():New("Arial",,32,,.T.,,,,,.F.)
			_oArial48N := TFont():New("Arial",,48,,.T.,,,,,.F.)
			
			_nMargSup  := 250
			_nMargInf  := 260
			_nMargEsq  := 400
			_nAltPag   := 1500
			_nLargPag  := 2800
			
			// salta a pagina
			oPrint:StartPage()
			nlinha := 600
			// variaveis do recibo
			_wvlrrecibo = _nIndeniz - _vIRind
			_wcidade    = alltrim(fbuscacpo ("SA3", 1, xfilial ("SA3") + _sVend, "A3_MUN"))
			_west       =         fbuscacpo ("SA3", 1, xfilial ("SA3") + _sVend , "A3_EST")
			_wnomeraz   =         fbuscacpo ("SA3", 1, xfilial ("SA3") + _sVend , "A3_NOME")
			_wcnpj      =         fbuscacpo ("SA3", 1, xfilial ("SA3") + _sVend, "A3_CGC")
			_wdatapg    = substr(dtos(_dDtaPgto),7,2) + '/' + substr(dtos(_dDtaPgto),5,2)  + '/' + substr(dtos(_dDtaPgto),1,4)
			
			oPrint:Box(_nMargSup + 20, _nMargEsq + 20, _nMargSup + _nAltPag, _nLargPag - _nMargEsq)
			
			//_mvsim1:= GetMv ("MV_SIMB1") 
			oPrint:Say(_nMargSup + 170,  _nMargEsq + 40, "R E C I B O", _oArial32N, 100)
			oPrint:Say(_nMargSup + 170,  _nMargEsq + 1500,"R$ " + alltrim (transform (_wvlrrecibo, "@E 999,999,999.99")) , _oArial32N, 100)
			oPrint:Say(_nMargSup + 288,  _nMargEsq + 50, "Recebi de ", _oCour16, 100)
			oPrint:Say(_nMargSup + 288,  _nMargEsq + 300, "COOPERATIVA AGROINDUSTRIAL NOVA ALIANCA LTDA", _oCour20N, 100)
			_sExtenso = Extenso (_wvlrrecibo)
			oPrint:Say(_nMargSup + 388,  _nMargEsq + 50, "A importancia de ", _oCour16, 100)
			oPrint:Say(_nMargSup + 370,  _nMargEsq + 500, left (_sExtenso, 49), _oCour20N, 100)
			_wnlinha :=0
			if len(alltrim(_sExtenso)) > 50
				oPrint:Say(_nMargSup + 470,  _nMargEsq + 50,  substr (_sExtenso, 50, 109), _oCour20N, 100)
				_wnlinha += 1
			endif
			if len(alltrim(_sExtenso)) > 109				
				oPrint:Say(_nMargSup + 570,  _nMargEsq + 50,  substr (_sExtenso, 109, 169), _oCour20N, 100)
				_wnlinha += 1
			endif				
			oPrint:Say(_nMargSup + 670  - (_wnlinha*100), _nMargEsq + 50, "Correspondente a ", _oCour16, 100)
			oPrint:Say(_nMargSup + 670  - (_wnlinha*100), _nMargEsq + 450, "PAGAMENTO 1/12 (um doze avos) DE INDENIZAÇÃO.", _oCour20N, 100)
			oPrint:Say(_nMargSup + 770  - (_wnlinha*100), _nMargEsq + 50, _wcidade + " - " + _west + ", " + _wdatapg, _oCour16 ,100)
			oPrint:Say(_nMargSup + 900  - (_wnlinha*100), _nMargEsq + 900, "_____________________________________", _oCour20N, 100)
			oPrint:Say(_nMargSup + 1000 - (_wnlinha*100), _nMargEsq + 900, "             Assinatura",  _oCour16, 100)
			oPrint:Say(_nMargSup + 1100 - (_wnlinha*100), _nMargEsq + 900, _wnomeraz,  _oCour16, 100)
			oPrint:Say(_nMargSup + 1150 - (_wnlinha*100), _nMargEsq + 900, "CNPJ" + Transform(_wcnpj, '@R 99.999.999/9999-99') ,  _oCour16, 100)
			
		Endif	
		//
		// ----------------------------------------------------------------------------------------------------------
		// FINALIZA IMPRESSÃO
		
		oPrint:EndPage()
		oPrint:Preview() //abre o PDF na tela
		
		// gera o arquivo em PDF
		CpyT2S(_cPathPDF +_cFile+ ".PDF", cDestino)
		_sCtaMail  := "envio.comissoes"

		u_log(cDestino + _cFile + ".PDF")

		//u_help("TESTE")
		//_sMailDest := 'claudia.lionco@novaalianca.coop.br'
		//U_SendMail (_sMailDest, "Relatorio de Comissões - Envio automatico", "", {cDestino + _cFile + ".PDF"}, _sCtaMail)

		_sMailDest := 'andressa.brugnera@novaalianca.coop.br'
		U_SendMail (_sMailDest, "Relatorio de Comissões - Envio automatico", "", {cDestino + _cFile + ".PDF"}, _sCtaMail)
	
		_sMailDest := 'envio.comissoes@novaalianca.coop.br'
		U_SendMail (_sMailDest, "Relatorio de Comissões - Envio automatico", "", {cDestino + _cFile + ".PDF"}, _sCtaMail)

		// envia email para o represenante
		_sMailDest := (_sAliasVend) -> EMAIL
		U_SendMail (_sMailDest, "Relatorio de Comissões - Envio automatico", "", {cDestino + _cFile + ".PDF"}, _sCtaMail)
		
		
		// le o proximo vendedor
		(_sAliasVend) -> (dbskip())
	Enddo
	
Return
// -----------------------------------------------------------------------------
// Imprime cabeçalho Master
Static Function xCabec(_wvendedor, _wnomevend)

	oPrint:StartPage()
	oPrint:SayBitmap(150,100,'logo.jpg',720,170)
	oPrint:Say(0300,1000,OemToAnsi('Relatorio de Comissões'),oFont22)
	oPrint:Say(00270,2175,OemToAnsi('Recebimentos   : ' + dtoc(mv_par01) + ' até ' + dtoc(mv_par02) ),oFont13)
	oPrint:Say(00300,2175,OemToAnsi('Emissao        : ' + dtoc(date()) + '     Pagina: ' + strzero(_wpag,2) ),oFont13)
	oPrint:Say(00330,2175,OemToAnsi('Empresa/Filial : ' + alltrim(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_CODFIL')) + ' - ' + alltrim(RetField('SM0',1,cEmpAnt+cFilAnt,'M0_FILIAL')) ),oFont13)
	oPrint:Line(0400,00045,0400,2850)
	oPrint:Say(0430,0045,OemToAnsi('NUMERO PARCELA           CLIENTE                            TOTAL NOTA   BASE COM.   DATA        VALOR      DESCONTOS       VALOR  BASE COMISSAO   % MEDIO      VALOR'),oFont13)
    oPrint:Say(0460,0045,OemToAnsi('TITULO                                                                   PREV.NOTA   PAGTO       TITULO   FINANCEIROS    RECEBIDO   * LIBERADA *             COMISSAO'),oFont13)
    oPrint:Line(0500,00045,0500,2850)
    oPrint:Say(0550,0045,OemToAnsi('VENDEDOR: ' + _wvendedor + ' - '+ _wnomevend),oFont13)
    
Return
// --------------------------------------------------------------------------
// Imprime cabeçalho entre folhas
Static Function _ImprimeCabec(_sVend, _sNomeVend, _wpag, nlinha)
	
	If (nLinha/50) > 46
	   _wpag += 1	
	   xCabec(_sVend, _sNomeVend)
	   nlinha := 600
	Endif
Return
//
// --------------------------------------------------------------------------
// Quantidade de parcelas do titulo
Static Function MontaParcelas(_sFilial,_sNota,_sSerie,_sCliente,_sLoja,_sParcela)
	local _aParc   := {}
	local _qtdParc := 1
	local _sRet    := ""
	local _sP      := ""
	
	_sQuery := ""
	_sQuery += " SELECT COUNT (*) "
	_sQuery += " FROM " +  RetSQLName ("SE1") + " AS SE1 "
	_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
	_sQuery += " AND E1_FILIAL  = '" + _sFilial  + "'"
	_sQuery += " AND E1_NUM     = '" + _sNota    + "'"
	_sQuery += " AND E1_PREFIXO = '" + _sSerie   + "'"
	_sQuery += " AND E1_CLIENTE = '" + _sCliente + "'"
	_sQuery += " AND E1_LOJA   	= '" + _sLoja    + "'"
	_aParc := U_Qry2Array(_sQuery)
	
	If Len(_aParc) > 0
		_qtdParc := _aParc[1,1]
	Else
		_qtdParc := 1
	EndIf
	
	// Transforma parcelas em numeros
	
	Do case
		Case alltrim(_sParcela) == ''
			_sP := '1'
		Case alltrim(_sParcela) == 'A'
			_sP := '1'
		Case alltrim(_sParcela) == 'B'
			_sP := '2'
		Case alltrim(_sParcela) == 'C'
			_sP := '3'
		Case alltrim(_sParcela) == 'D'
			_sP := '4'
		Case alltrim(_sParcela) == 'E'
			_sP := '5'
		Case alltrim(_sParcela) == 'F'
			_sP := '6'
		Case alltrim(_sParcela) == 'G'
			_sP := '7'
		Case alltrim(_sParcela) == 'H'
			_sP := '8'
		Case alltrim(_sParcela) == 'I'
			_sP := '9'
		Case alltrim(_sParcela) == 'J'
			_sP := '10'
		Case alltrim(_sParcela) == 'K'
			_sP := '11'
		Case alltrim(_sParcela) == 'L'
			_sP := '12'
		Case alltrim(_sParcela) == 'M'
			_sP := '13'
		Case alltrim(_sParcela) == 'N'
			_sP := '14'
		Case alltrim(_sParcela) == 'O'
			_sP := '15'
		Case alltrim(_sParcela) == 'P'
			_sP := '16'
		Case alltrim(_sParcela) == 'Q'
			_sP := '17'
		Case alltrim(_sParcela) == 'R'
			_sP := '18'
		Case alltrim(_sParcela) == 'S'
			_sP := '19'
		Case alltrim(_sParcela) == 'T'
			_sP := '20'
		Case alltrim(_sParcela) == 'U'
			_sP := '21'
		Case alltrim(_sParcela) == 'V'
			_sP := '22'
		Case alltrim(_sParcela) == 'X'
			_sP := '23'
		Case alltrim(_sParcela) == 'Z'
			_sP := '24'
	EndCase
	
	_sRet := _sParcela + ' ' + _sP +'/'+ alltrim(str(_qtdParc))
Return _sRet
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Base de                 ?", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data Base ate                ?", "D", 8, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {03, "Representante de             ?", "C", 3, 0,  "",   "SA3", {},                        		 "Representante Inicial"})
    aadd (_aRegsPerg, {04, "Representante ate            ?", "C", 3, 0,  "",   "SA3", {},                        		 "Represenante Final"})
    aadd (_aRegsPerg, {05, "Lista Comissoes              ?", "N", 1,  0,  "",   "   ", {"Liberadas","Pagas"},   		 ""})
    aadd (_aRegsPerg, {06, "Lista no Cliente             ?", "N", 1,  0,  "",   "   ", {"Razão Social","Nome Reduzido"}, ""})
    aadd (_aRegsPerg, {07, "Opção                        ?", "N", 1,  0,  "",   "   ", {"Email"}						,""})
    aadd (_aRegsPerg, {08, "Lista comissao por item      ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   				 ""})
    aadd (_aRegsPerg, {09, "Considera bloqueados         ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   				 ""})
    aadd (_aRegsPerg, {10, "Lista verbas/comissões       ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   				 ""})
    aadd (_aRegsPerg, {11, "Ajustes de comissões         ?", "N", 1,  0,  "",   "   ", {"Ambas","Pagas","Em Aberto"},    ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
