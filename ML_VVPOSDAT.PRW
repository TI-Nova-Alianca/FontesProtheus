//  Programa...: ML_VVPOSDAT
//  Autor......: Catia Cardoso
//  Data.......: 23/08/2017
//  Descricao..: Vencidos e a Vencer - Posicao na data 
// 
//  Historico de alterações
//  
//  08/02/2019 - Catia - alterado o programa para otimizar a geracao das informações
//
#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User function ML_VVPOSDAT()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)
	
	cString := "SE1"
    cDesc1  := "Vencidos e a Vencer"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    titulo  := "Vencidos e a Vencer"
    cPerg   := "ML_VVPOSDAT"
    wnrel   := "ML_VVPOSDAT"
    nTipo   := 0
    
    _ValidPerg()
    if Pergunte(cPerg,.T.)
    	titulo := "Vencidos e a Vencer - Carteira: " + iif(mv_par02 == 1, "RECEBER", "PAGAR") + " - Posição na data de: " + dtoc(mv_par01)
		wnrel  := SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	
	    If nLastKey == 27
		   Return
	    Endif
	    SetDefault(aReturn,cString)
	    If nLastKey == 27
		   Return
	    Endif
	
	    RptStatus({|| RptDetail()})
	endif
			    	
Return

Static Function RptDetail()
	local i	:= 0
	
    SetRegua(LastRec())
    nTipo  := IIF(aReturn[4]==1,15,18)
    li     := 80
    m_pag  := 1
    
    cabec1 :="FL   PRE    NUMERO      TIPO       EMISSAO    CLIFOR LJ   RAZAO SOCIAL                                                     VALOR       VENCIMENTO              SALDO"
    cabec2 :=""
    
	tcsqlexec ('DROP TABLE TMP_POSDATA')
	if mv_par02 == 1
		// -- PRIMEIRA PARTE BUSCA TUDO O QUE ESTIVER EM ABERTO
		_sSQL = ""
		_sSQL += "WITH C AS (
		_sSQL += "	SELECT SE1.E1_FILIAL   AS FILIAL"
	    _sSQL += "       , SE1.E1_PREFIXO  AS PREFIXO"
		_sSQL += "  	 , SE1.E1_NUM      AS NUMERO"
		_sSQL += "  	 , SE1.E1_PARCELA  AS PARCELA"
	 	_sSQL += "  	 , SE1.E1_TIPO     AS TIPO"
	 	_sSQL += "  	 , SE1.E1_CLIENTE  AS CLIFOR"
		_sSQL += "  	 , SE1.E1_LOJA     AS LOJA"
		_sSQL += "  	 , SA1.A1_NOME     AS NOME"
		_sSQL += "  	 , SE1.E1_EMISSAO  AS EMISSAO"
	 	_sSQL += "  	 , SE1.E1_VALOR    AS VALOR"
	 	_sSQL += "  	 , SE1.E1_VENCREA  AS VENCREA"
		_sSQL += "  	 , SE1.E1_SALDO    AS SALDO"
		_sSQL += "  	 , SPACE(40)       AS FAIXA"
		_sSQL += "	     , ROW_NUMBER() OVER(ORDER BY SE1.E1_FILIAL,SE1.E1_PREFIXO,SE1.E1_NUM,SE1.E1_PARCELA) AS RECNO"
		_sSQL += "  	 , ISNULL(DATEDIFF(day, cast (SE1.E1_VENCREA as DATETIME), cast('" + dtos(mv_par01) + "' as DATETIME)),1) AS QDIAS"
		_sSQL += "  	 , 0 AS ORDEM"
		_sSQL += "  FROM SE1010 AS SE1"
		_sSQL += " 		INNER JOIN SA1010 AS SA1"
		_sSQL += " 			ON (SA1.D_E_L_E_T_  = ''"
		_sSQL += " 				AND SA1.A1_COD  = SE1.E1_CLIENTE"
		_sSQL += " 				AND SA1.A1_LOJA = SE1.E1_LOJA)"
	 	_sSQL += " WHERE SE1.D_E_L_E_T_ = ''"
	   	_sSQL += "   AND SE1.E1_FILIAL  BETWEEN '" + mv_par04 + "' and '" + mv_par05 + "'"
	   	_sSQL += "   AND SE1.E1_TIPO   != 'NCC'"
	   	_sSQL += "   AND SE1.E1_TIPO   != 'RA'"
	   	_sSQL += "   AND SE1.E1_SALDO > 0
	   	_sSQL += "   AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos (mv_par01) + "'" // essa data inicial pode mudar conforme os titulos em aberto
	   	_sSQL += " UNION ALL
	   	_sSQL += "	SELECT SE1.E1_FILIAL   AS FILIAL"
	    _sSQL += "       , SE1.E1_PREFIXO  AS PREFIXO"
		_sSQL += "  	 , SE1.E1_NUM      AS NUMERO"
		_sSQL += "  	 , SE1.E1_PARCELA  AS PARCELA"
	 	_sSQL += "  	 , SE1.E1_TIPO     AS TIPO"
	 	_sSQL += "  	 , SE1.E1_CLIENTE  AS CLIFOR"
		_sSQL += "  	 , SE1.E1_LOJA     AS LOJA"
		_sSQL += "  	 , SA1.A1_NOME     AS NOME"
		_sSQL += "  	 , SE1.E1_EMISSAO  AS EMISSAO"
	 	_sSQL += "  	 , SE1.E1_VALOR    AS VALOR"
	 	_sSQL += "  	 , SE1.E1_VENCREA  AS VENCREA"
		_sSQL += "  	 , SE1.E1_SALDO    AS SALDO"
		_sSQL += "  	 , SPACE(40)       AS FAIXA"
		_sSQL += "	     , (100000 + ROW_NUMBER() OVER(ORDER BY SE1.E1_FILIAL,SE1.E1_PREFIXO,SE1.E1_NUM,SE1.E1_PARCELA)) AS RECNO"
		_sSQL += "  	 , ISNULL(DATEDIFF(day, cast (SE1.E1_VENCREA as DATETIME), cast('" + dtos(mv_par01) + "' as DATETIME)),1) AS QDIAS"
		_sSQL += "  	 , 0 AS ORDEM"
		_sSQL += "  FROM SE1010 AS SE1"
		_sSQL += " 		INNER JOIN SA1010 AS SA1"
		_sSQL += " 			ON (SA1.D_E_L_E_T_  = ''"
		_sSQL += " 				AND SA1.A1_COD  = SE1.E1_CLIENTE"
		_sSQL += " 				AND SA1.A1_LOJA = SE1.E1_LOJA)"
	 	_sSQL += " WHERE SE1.D_E_L_E_T_ = ''"
	   	_sSQL += "   AND SE1.E1_FILIAL  BETWEEN '" + mv_par04 + "' and '" + mv_par05 + "'"
	   	_sSQL += "   AND SE1.E1_TIPO   != 'NCC'"
	   	_sSQL += "   AND SE1.E1_TIPO   != 'RA'"
	   	_sSQL += "   AND SE1.E1_SALDO   = 0
	   	_sSQL += "   AND SE1.E1_BAIXA   > '" + dtos (mv_par01) + "'"
	   	_sSQL += "   AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos (mv_par01) + "'" // essa data inicial pode mudar conforme os titulos em aberto
	   	_sSQL += "   )"
	   	_sSQL += " SELECT *"
	   	_sSQL += "  INTO TMP_POSDATA"
	   	_sSQL += "   FROM C"
	   	//u_showmemo(_sSQL)
	   	TCSQLExec (_sSQL) < 0
	else
		// -- PRIMEIRA PARTE BUSCA TUDO O QUE ESTIVER EM ABERTO
		_sSQL = ""
		_sSQL += "WITH C AS (
		_sSQL += "	SELECT SE2.E2_FILIAL   AS FILIAL"
	    _sSQL += "       , SE2.E2_PREFIXO  AS PREFIXO"
		_sSQL += "  	 , SE2.E2_NUM      AS NUMERO"
		_sSQL += "  	 , SE2.E2_PARCELA  AS PARCELA"
	 	_sSQL += "  	 , SE2.E2_TIPO     AS TIPO"
	 	_sSQL += "  	 , SE2.E2_FORNECE  AS CLIFOR"
		_sSQL += "  	 , SE2.E2_LOJA     AS LOJA"
		_sSQL += "  	 , SA2.A2_NOME     AS NOME"
		_sSQL += "  	 , SE2.E2_EMISSAO  AS EMISSAO"
	 	_sSQL += "  	 , SE2.E2_VALOR    AS VALOR"
	 	_sSQL += "  	 , SE2.E2_VENCREA  AS VENCREA"
		_sSQL += "  	 , SE2.E2_SALDO    AS SALDO"
		_sSQL += "  	 , SPACE(40)       AS FAIXA"
		_sSQL += "	     , ROW_NUMBER() OVER(ORDER BY SE2.E2_FILIAL,SE2.E2_PREFIXO,SE2.E2_NUM,SE2.E2_PARCELA) AS RECNO"
		_sSQL += "  	 , DATEDIFF(day, cast (SE2.E2_VENCREA as DATETIME), cast('" + dtos(mv_par01) + "' as DATETIME)) AS QDIAS"
		_sSQL += "  	 , 0 AS ORDEM"
		_sSQL += "  FROM SE2010 AS SE2"
		_sSQL += " 		INNER JOIN SA2010 AS SA2"
		_sSQL += " 			ON (SA2.D_E_L_E_T_  = ''"
		_sSQL += " 				AND SA2.A2_COD  = SE2.E2_FORNECE"
		_sSQL += " 				AND SA2.A2_LOJA = SE2.E2_LOJA)"
	 	_sSQL += " WHERE SE2.D_E_L_E_T_ = ''"
	   	_sSQL += "   AND SE2.E2_FILIAL  BETWEEN '" + mv_par04 + "' and '" + mv_par05 + "'"
	   	_sSQL += "   AND SE2.E2_TIPO   != 'NDF'"
   		_sSQL += "   AND SE2.E2_TIPO   != 'PA'"
   		_sSQL += "   AND SE2.E2_TIPO   != 'PR'"
   		_sSQL += "   AND SE2.E2_TIPO   != 'PRI'"
   		_sSQL += "   AND SE2.E2_SALDO   > 0"
	   	_sSQL += "   AND SE2.E2_EMISSAO BETWEEN '20000101' AND '" + dtos (mv_par01) + "'" // essa data inicial pode mudar conforme os titulos em aberto
	   	// -- SEGUNDA PARTE BUSCA TUDO O QUE FOI PAGO DEPOIS DA DATA
	   	_sSQL += " UNION ALL"
	   	_sSQL += "	SELECT SE2.E2_FILIAL   AS FILIAL"
	    _sSQL += "       , SE2.E2_PREFIXO  AS PREFIXO"
		_sSQL += "  	 , SE2.E2_NUM      AS NUMERO"
		_sSQL += "  	 , SE2.E2_PARCELA  AS PARCELA"
	 	_sSQL += "  	 , SE2.E2_TIPO     AS TIPO"
	 	_sSQL += "  	 , SE2.E2_FORNECE  AS CLIFOR"
		_sSQL += "  	 , SE2.E2_LOJA     AS LOJA"
		_sSQL += "  	 , SA2.A2_NOME     AS NOME"
		_sSQL += "  	 , SE2.E2_EMISSAO  AS EMISSAO"
	 	_sSQL += "  	 , SE2.E2_VALOR    AS VALOR"
	 	_sSQL += "  	 , SE2.E2_VENCREA  AS VENCREA"
		_sSQL += "  	 , SE2.E2_SALDO    AS SALDO"
		_sSQL += "  	 , SPACE(40)       AS FAIXA"
		_sSQL += "	     , (100000 + ROW_NUMBER() OVER(ORDER BY SE2.E2_FILIAL,SE2.E2_PREFIXO,SE2.E2_NUM,SE2.E2_PARCELA)) AS RECNO"
		_sSQL += "  	 , DATEDIFF(day, cast (SE2.E2_VENCREA as DATETIME), cast('" + dtos(mv_par01) + "' as DATETIME)) AS QDIAS"
		_sSQL += "  	 , 0 AS ORDEM"
		_sSQL += "  FROM SE2010 AS SE2"
		_sSQL += " 		INNER JOIN SA2010 AS SA2"
		_sSQL += " 			ON (SA2.D_E_L_E_T_  = ''"
		_sSQL += " 				AND SA2.A2_COD  = SE2.E2_FORNECE"
		_sSQL += " 				AND SA2.A2_LOJA = SE2.E2_LOJA)"
	 	_sSQL += " WHERE SE2.D_E_L_E_T_ = ''"
	   	_sSQL += "   AND SE2.E2_FILIAL  BETWEEN '" + mv_par04 + "' and '" + mv_par05 + "'"
	   	_sSQL += "   AND SE2.E2_TIPO   != 'NDF'"
   		_sSQL += "   AND SE2.E2_TIPO   != 'PA'"
   		_sSQL += "   AND SE2.E2_TIPO   != 'PR'"
   		_sSQL += "   AND SE2.E2_TIPO   != 'PRI'"
   		_sSQL += "   AND SE2.E2_SALDO  = 0"
   		_sSQL += "   AND SE2.E2_BAIXA  > '" + dtos (mv_par01) + "'"
	   	_sSQL += "   AND SE2.E2_EMISSAO BETWEEN '20000101' AND '" + dtos (mv_par01) + "'" // essa data inicial pode mudar conforme os titulos em aberto
	   	_sSQL += "   )"
	   	_sSQL += " SELECT *"
	   	_sSQL += "  INTO TMP_POSDATA"
	   	_sSQL += "   FROM C"
	   	//u_showmemo(_sSQL)
	   	TCSQLExec (_sSQL) < 0
	endif	
	// verifica se tem quantidade de dias com zero e passa para 1 - considera como vencido a 1 dia - cai na primeira faixa
	_sSQL = ""
   	_sSQL += " UPDATE TMP_POSDATA"
   	_sSQL += "    SET QDIAS = 1"
   	_sSQL += "  WHERE QDIAS = 0"
   	TCSQLExec (_sSQL) < 0
    // calcula saldo na data
    _sQuery = ""
   	_sQuery += " SELECT *"
   	_sQuery += "   FROM TMP_POSDATA"
   	_aDados := U_Qry2Array(_sQuery)
	if len(_aDados) > 0
		for i = 1 to len(_aDados)
			_wdiasvenc = _aDados[i,15]
			_wrecno    = _aDados[i,14]
			if _wdiasvenc > 0
				do case
   					case _wdiasvenc > 181
   						_wfaixa = ' 7#VENCIDOS: MAIS  DE 181DD'
   						_wordem = '17'
   					case _wdiasvenc > 151
   						_wfaixa = ' 6#VENCIDOS: DE 151 A 180DD'
   						_wordem = '16'
   					case _wdiasvenc > 121
   						_wfaixa = ' 5#VENCIDOS: DE 121 A 150DD'
   						_wordem = '15'
   					case _wdiasvenc > 91
   						_wfaixa = ' 4#VENCIDOS: DE 91  A 120DD'
   						_wordem = '14'
   					case _wdiasvenc > 61
   						_wfaixa = ' 3#VENCIDOS: DE 61  A 90DD'
   						_wordem = '13'
   					case _wdiasvenc > 31
   						_wfaixa = ' 2#VENCIDOS: DE 31  A 60DD'
   						_wordem = '12'
					OtherWise
						_wfaixa = ' 1#VENCIDOS: ATE 30DD'
						_wordem = '11'									   						
   				endcase
			else
				_wdiasvenc = _wdiasvenc * -1
				do case
   					case _wdiasvenc > 181
   						_wfaixa = ' 7#A VENCER: MAIS  DE 181DD'
   						_wordem = '27'
   					case _wdiasvenc > 151
   						_wfaixa = ' 6#A VENCER: DE 151 A 180DD'
   						_wordem = '26'
   					case _wdiasvenc > 121
   						_wfaixa = ' 5#A VENCER: DE 121 A 150DD'
   						_wordem = '25'
   					case _wdiasvenc > 91
   						_wfaixa = ' 4#A VENCER: DE 91  A 120DD'
   						_wordem = '24'
   					case _wdiasvenc > 61
   						_wfaixa = ' 3#A VENCER: DE 61  A 90DD'
   						_wordem = '23'
   					case _wdiasvenc > 31
   						_wfaixa = ' 2#A VENCER: DE 31  A 60DD'
   						_wordem = '22'
					OtherWise
						_wfaixa = ' 1#A VENCER: ATE 30DD'
						_wordem = '21'									   						
   				endcase
			endif
			_sSQL = ""	
			_sSQL += " UPDATE TMP_POSDATA"
			_sSQL += "	  SET SALDO     = [dbo].[VA_SLDTIT] ('" + _aDados[i,2] + "','"
			_sSQL +=  _aDados[i,3] + "','" 
			_sSQL +=  _aDados[i,4] + "','" 
			if mv_par02 == 1
				_sSQL +=  _aDados[i,5] + "','R','"
			else
				_sSQL +=  _aDados[i,5] + "','P','"
			endif	 
			_sSQL +=  _aDados[i,6] + "','" 
			_sSQL +=  _aDados[i,7] + "','" 
			_sSQL +=  dtos (mv_par01) + "','" 
			_sSQL +=  _aDados[i,1] + "'," 
			_sSQL +=  TRANSF(_aDados[i,10], "@ 999,999,999.99") + ")"
			_sSQL += "	    , FAIXA     = '" + _wfaixa + "'"
			_sSQL += "	    , ORDEM     = '" + _wordem + "'"
		 	_sSQL += "  WHERE RECNO     = "  + TRANSF(_wrecno, "@ 9999999")
			TCSQLExec (_sSQL)
		next
	endif
	_sSQL  = ""			
	_sSQL += " SELECT *"
	_sSQL += "   	, SUM(SALDO) OVER (PARTITION BY FAIXA) AS TOTFAIXA"
	_sSQL += "   FROM TMP_POSDATA"
  	_sSQL += "  WHERE SALDO > 0"
  	_sSQL += "    AND FAIXA IS NOT NULL"
  	_sSQL += "  ORDER BY ORDEM, FAIXA, EMISSAO"
  	
  	_sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sSQL), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _wfaixa   = ''
    _wtotger := 0
    // le e imprime arquivo de trabalho
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
	    If li>65
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif
		
		if _wfaixa = '' .or. _wfaixa !=  (_sAliasQ) -> FAIXA
	        // imprime total da faixa
	        if _wfaixa != ''
	        	li++
	        endif
	        @ li, 001 PSAY "TOTAL " + SUBSTR((_sAliasQ) -> FAIXA,4,40)
	        @ li, 146 PSAY (_sAliasQ) -> TOTFAIXA Picture "@E 999,999,999,999.99"
	        _wfaixa = (_sAliasQ) -> FAIXA
	        _wtotger += (_sAliasQ) -> TOTFAIXA
	        li++
		endif		
        // imprime detalhe
        if mv_par03 == 2
			@ li, 001 PSAY (_sAliasQ) -> FILIAL 
			@ li, 006 PSAY (_sAliasQ) -> PREFIXO
			@ li, 012 PSAY (_sAliasQ) -> NUMERO 
			@ li, 023 PSAY (_sAliasQ) -> PARCELA 
			@ li, 026 PSAY (_sAliasQ) -> TIPO 
			@ li, 032 PSAY STOD((_sAliasQ) -> EMISSAO)
			@ li, 046 PSAY (_sAliasQ) -> CLIFOR
			@ li, 053 PSAY (_sAliasQ) -> LOJA
			@ li, 058 PSAY (_sAliasQ) -> NOME
			@ li, 114 PSAY (_sAliasQ) -> VALOR Picture "@E 999,999,999.99"
			@ li, 135 PSAY STOD((_sAliasQ) -> VENCREA)			 
			@ li, 150 PSAY (_sAliasQ) -> SALDO Picture "@E 999,999,999.99"
			li ++
		endif
		(_sAliasQ) -> (dbskip ())
	 enddo
	 // imprime geral
	 li++
	 @ li, 001 PSAY "TOTAL GERAL"
	 @ li, 146 PSAY _wtotger Picture "@E 999,999,999,999.99"
	 li++		

	 U_ImpParam (60)
	 
	 Set Device To Screen
	 
     If aReturn[5]==1
     	Set Printer TO
        dbcommitAll()
        ourspool(wnrel)
     Endif

     MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)
return   

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	aadd (_aRegsPerg, {01, "Posição na Data de  ?", "D", 8,  0,  "",   "   ", {}                          , ""})
	aadd (_aRegsPerg, {02, "Carteira            ?", "N", 1,  0,  "",   "   ", {"Receber", "Pagar"}	      , ""})			
	aadd (_aRegsPerg, {03, "Tipo                ?", "N", 1,  0,  "",   "   ", {"Sintético", "Analitico"}  , ""})
	aadd (_aRegsPerg, {04, "Filial de           ?", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {05, "Filial até          ?", "C", 2,  0,  "",   "SM0", {},                         ""})
    	
    U_ValPerg (cPerg, _aRegsPerg)
Return