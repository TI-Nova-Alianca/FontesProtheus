// Programa..: ML_RESFAT.PRX
// Autor.....: Catia Cardoso
// Data......: 02/07/2015
// Nota......: Resumo Faturamento BRUTO
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Relatorio de resumo de faturamento, formatado para apresentacao em reunioes de conselho.
// #PalavasChave      #resumo #faturamento #formatado #formato_grafico
// #TabelasPrincipais #SD2 #SF3 #SF4
// #Modulos           #FAT #CTB
//
// Historico de alteracoes:
// 12/11/2019 - Robert - Alterados cargos (administrador / contador) para os nomes das pessoas (Alceu/Carlos)
// 06/10/2020 - Sandra - Alterado nome do contador de Carlos para Liane
// 07/10/2020 - Robert - Chamadas da funcao msgalert() trocadas para u_help ()
//                     - Adicionadas tags para catalogo de fontes.
// 09/11/2020 - Robert - Alterado nome do contador de Liane para Sara
// 10/11/2020 - Robert - Faltou ajustar o numero do CRC.
// 03/02/2023 - Claudia - Ajuste de valor de faturamento. GLPI: 12857
// 08/02/2023 - Claudia - Tratamento para icms st de guias MG. GLPI: 13161
//
// ------------------------------------------------------------------------------------------------------------------ 
#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function ML_RESFAT()
	
	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)
	
	cString := "SD2"
    cDesc1  := "Relação Faturamento"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_RESFAT"
    titulo  := "Relação Faturamento"
    wnrel   := "ML_RESFAT"
    nTipo   := 0

    _ValidPerg()
    Pergunte(cPerg,.T.)
    
   	if mv_par05 = 1 /// maximo de 30 meses
   		//_o := ClsDUtil():New()
		//_nMeses := _o:DifMeses (mv_par01, mv_par02)
		_nMeses = 30
		// falta terminar de testar a quantidade de meses
   		if _nMeses > 30
			u_help ("Intervalo informado maior que o maximo permitido. Informar máximo de 30 meses.",, .t.)
			return
		endif
	else // maximo de 31 dias
		if mv_par02 - mv_par01 > 31
			u_help ("Intervalo informado maior que o maximo permitido. Informar máximo de 31 dias.",, .t.)
			return
		endif
	endif
    
	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	
    If nLastKey == 27
	   Return
    Endif
    SetDefault(aReturn,cString)
    If nLastKey == 27
	   Return
    Endif

    RptStatus({|| RptDetail()})
Return
//
// ----------------------------------------------------------------------------------------
// Imprimir relatorio
Static Function RptDetail()
	Local _sQuery := " "

    SetRegua(LastRec())
    
	// monta query
    _sQuery := " "
    _sQuery += " WITH C AS (SELECT SD2.D2_EMISSAO  AS DATA"
    _sQuery += "                 , ROUND(SUM(D2_PRCVEN*D2_QUANT),2)                               AS VLR_PROD"
  	_sQuery += " 	             , SUM(SD2.D2_VALBRUT)                                            AS VLR_BRT"
	_sQuery += "                 ,SUM(SD2.D2_VALBRUT) - SUM(SD2.D2_VALIPI) - CASE WHEN SF4.F4_CREDST = '4' THEN 0 ELSE SUM(SD2.D2_ICMSRET) END AS VLR_TOTAL "
  	_sQuery += "              FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	          		INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
  	_sQuery += "						ON (SF2.D_E_L_E_T_ = ''"
  	_sQuery += "							AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
  	_sQuery += "							AND SF2.F2_DOC     = SD2.D2_DOC"
  	_sQuery += "							AND SF2.F2_SERIE   = SD2.D2_SERIE"
  	_sQuery += "							AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
  	_sQuery += "							AND SF2.F2_LOJA    = SD2.D2_LOJA"
  	_sQuery += "							AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "					INNER JOIN SF4010 AS SF4"
	_sQuery += "						ON (SF4.D_E_L_E_T_ = ''"
  	_sQuery += "							AND SF4.F4_CODIGO  = SD2.D2_TES"
  	_sQuery += "							AND SF4.F4_MARGEM = '1')"
    _sQuery += " 			WHERE SD2.D_E_L_E_T_ = ''"
    _sQuery += "   			  AND SD2.D2_FILIAL    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
    _sQuery += "   			  AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += " 			GROUP BY SD2.D2_EMISSAO,SF4.F4_CREDST "
 	_sQuery += " )"
 	if mv_par05 = 1
 		_sQuery += " SELECT SUBSTRING(DATA,1,4) + SUBSTRING(DATA,5,2) AS DATA"
 	else
 		_sQuery += " SELECT DATA          AS DATA"
	endif 	
 	_sQuery += "      ,SUM(VLR_BRT)       AS TOTAL"
	_sQuery += "      ,SUM(VLR_TOTAL)     AS TOTAL_NF "
 	_sQuery += "   FROM C"
 	if mv_par05 = 1
 		_sQuery += "  GROUP BY SUBSTRING(DATA,1,4) + SUBSTRING(DATA,5,2)"
 		_sQuery += "  ORDER BY SUBSTRING(DATA,1,4) + SUBSTRING(DATA,5,2)"	
 	else
		_sQuery += "  GROUP BY DATA"
		_sQuery += "  ORDER BY DATA"
	endif		
    u_log (_sQuery)

    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)

    // gera excel
    if mv_par06 = 2
    	(_sAliasQ) -> (DBGoTop ())
    	 processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
     	(_sAliasQ) -> (dbclosearea ())
     	return
	endif     	
    
    // imprime relatorio
    // Objetos para impressao
	_oPrn:=TAVPrinter():New("ML_RESFAT")
	_oPrn:Setup()           // Tela para usuario selecionar a impressora
	_oPrn:SetPortrait()     // ou SetLanscape()

	::_oPrn      := _oPrn
	::_nPagAtual := 1  		// Contador de paginas
	::_nLinAtual := 0
	::_nAltLin   := 50  	// Altura de cada linha em pontos (para trabalhar de forma semelhante a impressao caracter)
	::_nMargSup  := 40  	// Margem superior da pagina
	::_nMargInf  := 50  	// Margem inferior da pagina
	::_nMargEsq  := 40   	// Margem esquerda da pagina
	::_nAltPag   := 3100  	// Altura maxima da pagina
	::_nLargPag  := 2350  	// Largura maxima da pagina
	::_oTimes8  := TFont():New("Times New Roman",,8,,.T.,,,,,.F.)
	::_oTimes16 := TFont():New("Times New Roman",,16,,.T.,,,,,.F.)

	// Objetos para tamanho e tipo das fontes
	_oCour18N := TFont():New("Courier New",,18,,.T.,,,,,.F.)
	_oCour16N := TFont():New("Courier New",,16,,.T.,,,,,.F.)
	_oCour12N := TFont():New("Courier New",,12,,.T.,,,,,.F.)
	_oCour10N := TFont():New("Courier New",,10,,.T.,,,,,.F.)
	_oCour8N  := TFont():New("Courier New",,8 ,,.T.,,,,,.F.)
    
    // impressao
    _aTotal  = 0
    (_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
    	if ::_nLinAtual = 0 .or. ::_nLinAtual > 2500
    		// Reinicia contagem de paginas e gera cabecalho automaticamente.
			_Cabec (.T., 0, .T.)
			
			::_nLinAtual += ::_nAltLin * 3
			_sLinhaImp := "              RELAÇÃO DE FATURAMENTO "
			::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 400, _sLinhaImp, _oCour12N, 100)
			::_nLinAtual += ::_nAltLin * 1
			::_nLinAtual += ::_nAltLin * 3					
			
			::_oPrn:Box(::_nMargsup + ::_nLinAtual				, ; // Linha sup
	               ::_nMargEsq + 400							, ; // Coluna esq
	               ::_nMargsup + ::_nLinAtual + ::_nAltLin * 2	, ; // Linha inf
	               ::_nMargEsq + 1800							  ) // Coluna dir
			
			if mv_par05 = 1
				_sLinhaImp := "MES/ANO                               VALOR"
			else
				_sLinhaImp := "DATA                                  VALOR"
			endif
			::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 655, _sLinhaImp, _oCour10N, 100)
			::_nLinAtual += ::_nAltLin * 1
		endif
		
		if mv_par05 = 1
			_sLinhaImp := SUBSTR(mesextenso( SUBSTRING( (_sAliasQ) -> DATA,5,2) ),1,3) + ' / ' + SUBSTRING((_sAliasQ) -> DATA,1,4)  + "                 "
		else
			_sLinhaImp := SUBSTRING((_sAliasQ) -> DATA,7,2) + '/' + SUBSTRING((_sAliasQ) -> DATA,5,2) + '/' + SUBSTRING((_sAliasQ) -> DATA,1,4)  + "                 "
		endif
			
		::_oPrn:Box(::_nMargsup + ::_nLinAtual					, ; // Linha sup
	                ::_nMargEsq + 400							, ; // Coluna esq
	                ::_nMargsup + ::_nLinAtual + ::_nAltLin * 2	, ; // Linha inf
	                ::_nMargEsq + 1800							  ) // Coluna dir
					
		u_log((_sAliasQ) -> DATA)
		If (_sAliasQ) -> DATA <= '20221231'
			_sLinhaImp += transform ( (_sAliasQ) -> TOTAL    , "@E 9,999,999,999.99") + " "
		else
			_sLinhaImp += transform ( (_sAliasQ) -> TOTAL_NF , "@E 9,999,999,999.99") + " "
		EndIf
		::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 650, _sLinhaImp, _oCour10N, 100)
		::_nLinAtual += ::_nAltLin * 1					
		
		// acumula total
		If (_sAliasQ) -> DATA <= '20221231'
			_aTotal += (_sAliasQ) -> TOTAL 		
		else
			_aTotal += (_sAliasQ) -> TOTAL_NF 	
		EndIf					
	 	(_sAliasQ) -> (dbskip())
     enddo
     
	// imprime total
	_sLinhaImp := "     TOTAL"  + "                 "
	_sLinhaImp += transform ( _aTotal , "@E 9,999,999,999.99") + " "
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 655, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1					

	// imprime local e data
	::_nLinAtual += ::_nAltLin * 5
	_sLinhaImp := alltrim (sm0 -> m0_CidCob) + ", " + SUBSTR(dtos(dDatabase),7,2) + " de " + MesExtenso( val(SUBStr(dtos(dDatabase),5,2) )) + " de " + SUBSTR(dtos(dDatabase),1,4)
	::_oPrn:Say (::_nMargsup + ::_nLinAtual , ::_nMargEsq + 950, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1

	// imprime assinaturas
	::_nLinAtual += ::_nAltLin * 4
	_sLinhaImp := "_______________________________" + "    " + "_______________________________ "
	::_oPrn:Say (::_nMargsup + ::_nLinAtual , ::_nMargEsq + 400, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1					

	_sLinhaImp := "      ALCEU DALLE MOLLE                        SARA CETOLIN"
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 400, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1					

	_sLinhaImp := "     CPF: 431.760.700-04                     CRC: 76.578 / RS"
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 400, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1					
			
	// Visualiza antes de imprimir
	_oPrn:Preview()
	_oPrn:End()
return
//
// ----------------------------------------------------------------------------------------
// Imprime cabeçalho
static function _Cabec(_lObrig, _nMinimo, _lZeraPag)

	_sLinhaImp := ""
	_nMinimo   := iif (_nMinimo == NIL, 0, _nMinimo)
	_lZeraPag  := iif (_lZeraPag == NIL, .F., _lZeraPag)

	if ::_nLinAtual >= ::_nAltPag - (::_nMargInf + _nMinimo) .or. _lObrig
		if ::_nPagAtual > 1
			::_oPrn:EndPage ()    // Encerra pagina
		endif
		::_oPrn:StartPage ()  // Inicia uma nova pagina
		
		if _lZeraPag
			::_nPagAtual = 1
		endif

		// Moldura em torno da pagina
		::_oPrn:Box(10				, ; // Linha sup
	               10				, ; // Coluna esq
	               ::_nAltPag - 10	, ; // Linha inf
	               ::_nLargPag - 10   ) // Coluna dir

		// Moldura em torno do cabecalho
		::_oPrn:Box(30				, ; // Linha sup
	               30				, ; // Coluna esq
	               200				, ; // Linha inf
	               ::_nLargPag - 40   ) // Coluna dir

		// Monta cabecalho padrao
		::_nLinAtual = ::_nMargSup
		::_oPrn:Say (::_nLinAtual, ::_nLargPag - 200, _sLinhaImp, ::_oTimes8, 100)
		::_oPrn:SayBitmap(::_nLinAtual	, ;  // Linha
		                  ::_nMargEsq	, ;  // Coluna
		                  "Logo9.jpg"	, ;  // Arquivo
		                  400			, ;  // Largura
		                  107			  )  // Altura

		_sLinhaImp := alltrim (sm0 -> m0_nomecom)
		::_oPrn:Say (::_nLinAtual, 500, _sLinhaImp, ::_oTimes16, 100)
		::_nLinAtual += 60

		_sLinhaImp := alltrim (sm0 -> m0_endcob) + " - "
		_sLinhaImp += "Bairro " + alltrim (sm0 -> m0_BairCob) + " - "
		_sLinhaImp += "CEP " + alltrim (transform (sm0 -> m0_CEPCob, "@R 99.999-999")) + " - "
		_sLinhaImp += alltrim (sm0 -> m0_CidCob) + " - " + sm0 -> m0_EstCob
		
		::_oPrn:Say (::_nLinAtual, 500, _sLinhaImp, ::_oTimes8, 100)
		::_nLinAtual += 40

		_sLinhaImp := "CNPJ: 88.612.486/0001-60"
		_sLinhaImp += " -  Fone/fax: " + alltrim( sm0 -> m0_tel)
		_sLinhaImp += " -  E-mail: novaalianca@novaalianca.coop.br"
		::_oPrn:Say (::_nLinAtual, 500, _sLinhaImp, ::_oTimes8, 100)
		::_nLinAtual = 200

		::_nPagAtual ++
	endif
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Emissao de                   ?", "D", 8,  0,  "",   "   ", {},                         	""})
	aadd (_aRegsPerg, {02, "Emissao ate                  ?", "D", 8,  0,  "",   "   ", {},                         	""})
	aadd (_aRegsPerg, {03, "Filial  de                   ?", "C", 2,  0,  "",   "SM0", {},                         	""})
	aadd (_aRegsPerg, {04, "Filial até                   ?", "C", 2,  0,  "",   "SM0", {},                         	""})
    aadd (_aRegsPerg, {05, "Gerar                        ?", "N", 1,  0,  "",   "   ", {"Mensal","Diario"},   		""})
    aadd (_aRegsPerg, {06, "Listar                       ?", "N", 1,  0,  "",   "   ", {"Relatório","Planilia"},   	""})
    
   	U_ValPerg (cPerg, _aRegsPerg)
Return
