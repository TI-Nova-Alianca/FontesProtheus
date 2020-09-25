// Programa..: ML_CNPJBASE.PRX
// Autor.....: Catia Cardoso
// Data......: 24/10/2014
// Nota......: Relação de Titulos por CNPJ Base - Emissoes e Pagamentos

// Historico de alteracoes:
// 12/11/2014 - não estava buscando corretamente o valor dos descontos
// 13/02/2015 - estava considerando os deletados ao buscar os registros no SE5010
//			  - buscar do SE5010 o valor pago
//			  - tirar a data de pagamento
//			  - incluir coluna saldo titulo
// 02/03/2015 - campos de totais estavam aparecendo **** - 
//            - alterado para que não considere as NCC neste relatorio

#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function ML_CNPJBASE()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)

    cString := "SE1"
    cDesc1  := "Relatorio de emissoes e pagamentos por cliente"
    cDesc2  := "agrupando pelo CNPJ base"
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_POSICAO_BASE"
    titulo  := "Relação de Titulos - Emissoes e Pagamentos p/ CNPJ Base"
    wnrel   := "ML_CNPJBASE"
    nTipo   := 0

    _ValidPerg()
    Pergunte(cPerg,.F.)

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

Static Function RptDetail()

    SetRegua(LastRec())

    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    cabec1 := "Codigo Nome do Cliente          Tipo    Titulo       Emissao    Vencto    Valor do Titulo     Desconto        Juros            Valor Pago      Compensações        Saldo Titulo"
    cabec2 := "                                                                                                                                                                                        "
    _sQuery := " "
    _sQuery += "   SELECT SE1.E1_PREFIXO AS PREFIXO"
    _sQuery += "        , SE1.E1_NUM     AS NUMERO"
    _sQuery += "        , SE1.E1_PARCELA AS PARCELA"
    _sQuery += "        , SE1.E1_TIPO    AS TIPTIT"
    _sQuery += "        , SE1.E1_CLIENTE AS CLIENTE"
    _sQuery += "        , SE1.E1_LOJA    AS LOJA"
    _sQuery += "        , SE1.E1_NOMCLI  AS NOMCLI"
    _sQuery += "        , SE1.E1_EMISSAO AS DATA"
    _sQuery += "        , SE1.E1_VENCTO  AS VENCTO"
    _sQuery += "        , SE1.E1_VALOR   AS VALOR"
    _sQuery += "        , ISNULL ((SELECT SUM(SE5.E5_VALOR)" 
    _sQuery += "                     FROM SE5010 SE5"
    _sQuery += "                    WHERE SE5.E5_RECPAG = 'R'"
    _sQuery += "                      AND D_E_L_E_T_ != '*'"
    _sQuery += "                      AND SE5.E5_NUMERO  = SE1.E1_NUM"
    _sQuery += "                      AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
    _sQuery += "                      AND SE5.E5_PARCELA = SE1.E1_PARCELA"
    _sQuery += "                      AND SE5.E5_CLIFOR  = SE1.E1_CLIENTE"
    _sQuery += "                      AND SE5.E5_LOJA    = SE1.E1_LOJA"
    _sQuery += "                      AND SE5.E5_TIPODOC = 'DC'"
    _sQuery += "                      AND SE5.E5_DATA BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
    _sQuery += "                   GROUP BY SE5.E5_NUMERO, SE5.E5_TIPODOC),0) AS DESCONTO"
    _sQuery += "        , ISNULL ((SELECT SUM(SE5.E5_VALOR)" 
    _sQuery += "                     FROM SE5010 SE5"
    _sQuery += "                    WHERE SE5.E5_RECPAG = 'R'"
    _sQuery += "                      AND D_E_L_E_T_ != '*'"
    _sQuery += "                      AND SE5.E5_NUMERO  = SE1.E1_NUM"
    _sQuery += "                      AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
    _sQuery += "                      AND SE5.E5_PARCELA = SE1.E1_PARCELA"
    _sQuery += "                      AND SE5.E5_CLIFOR  = SE1.E1_CLIENTE"
    _sQuery += "                      AND SE5.E5_LOJA    = SE1.E1_LOJA"
    _sQuery += "                      AND SE5.E5_TIPODOC = 'JR'"
    _sQuery += "                      AND SE5.E5_DATA BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
    _sQuery += "                   GROUP BY SE5.E5_NUMERO, SE5.E5_TIPODOC),0) AS JUROS"
    _sQuery += "        , ISNULL ((SELECT SUM(SE5.E5_VALOR)" 
    _sQuery += "                     FROM SE5010 SE5"
    _sQuery += "                    WHERE SE5.E5_RECPAG = 'R'"
    _sQuery += "                      AND D_E_L_E_T_ != '*'"
    _sQuery += "                      AND SE5.E5_NUMERO  = SE1.E1_NUM"
    _sQuery += "                      AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
    _sQuery += "                      AND SE5.E5_PARCELA = SE1.E1_PARCELA"
    _sQuery += "                      AND SE5.E5_CLIFOR  = SE1.E1_CLIENTE"
    _sQuery += "                      AND SE5.E5_LOJA    = SE1.E1_LOJA"
    _sQuery += "                      AND SE5.E5_TIPODOC = 'CP'"
    _sQuery += "                      AND SE5.E5_DATA BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
    _sQuery += "                   GROUP BY SE5.E5_NUMERO, SE5.E5_TIPODOC),0) AS VLR_COMP"
    _sQuery += "        , ISNULL ((SELECT SUM(SE5.E5_VALOR)" 
    _sQuery += "                    FROM SE5010 SE5"
    _sQuery += "                   WHERE SE5.E5_RECPAG = 'R'"
    _sQuery += "                     AND D_E_L_E_T_ != '*'"
    _sQuery += "                     AND SE5.E5_NUMERO  = SE1.E1_NUM"
    _sQuery += "                     AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
    _sQuery += "                     AND SE5.E5_PARCELA = SE1.E1_PARCELA"
    _sQuery += "                     AND SE5.E5_CLIFOR  = SE1.E1_CLIENTE"
    _sQuery += "                     AND SE5.E5_LOJA    = SE1.E1_LOJA"
    _sQuery += "                     AND SE5.E5_TIPODOC = 'VL'"
    _sQuery += "                     AND SE5.E5_DATA BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
    _sQuery += "                  GROUP BY SE5.E5_NUMERO, SE5.E5_TIPODOC),0) AS RECEBIDO"
    _sQuery += "        , SE1.E1_SALDO   AS SALDO"
    _sQuery += "     FROM " + RetSQLName ("SE1") + " AS SE1 "
    _sQuery += "   INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
    _sQuery += "              ON (SA1.D_E_L_E_T_ = ''" 
    _sQuery += "                  AND SA1.A1_FILIAL      = '" + xfilial ("SA1") + "'"
    _sQuery += "                  AND SA1.A1_COD         = SE1.E1_CLIENTE"
    _sQuery += "                  AND SA1.A1_LOJA        = SE1.E1_LOJA"
    _sQuery += "                  AND LEFT(SA1.A1_CGC,8) = '" +mv_par05 + "')"  
    _sQuery += "   WHERE SE1.D_E_L_E_T_ = ' '"  
    _sQuery += "      AND SE1.E1_FILIAL      = '" + xfilial ("SE1") + "'"
    _sQuery += "      AND SE1.E1_TIPO        != 'NCC'"
    _sQuery += "      AND SE1.E1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sQuery += "      AND SE1.E1_PREFIXO NOT LIKE '%CL%'"
    
    //u_log(_sQuery)
    
    u_log (_sQuery)
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTot = {0,0,0,0,0,0}
    
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
           If li>58
                cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           Endif
          		
	       @ li, 000 PSAY (_sAliasQ) -> CLIENTE
	       @ li, 007 PSAY LEFT((_sAliasQ) -> NOMCLI,28)
	       @ li, 033 PSAY (_sAliasQ) -> TIPTIT
	       @ li, 040 PSAY (_sAliasQ) -> NUMERO+"-"+(_sAliasQ) -> PARCELA
	       @ li, 053 PSAY stod((_sAliasQ) -> DATA)
	       @ li, 064 PSAY stod((_sAliasQ) -> VENCTO)
	       @ li, 075 PSAY (_sAliasQ) -> VALOR      Picture "@E 999,999,999.99"
	       @ li, 094 PSAY (_sAliasQ) -> DESCONTO   Picture "@E 999,999.99"
	       @ li, 107 PSAY (_sAliasQ) -> JUROS      Picture "@E 999,999.99"
	       @ li, 125 PSAY (_sAliasQ) -> RECEBIDO   Picture "@E 999,999,999.99"
	       @ li, 143 PSAY (_sAliasQ) -> VLR_COMP   Picture "@E 999,999,999.99"
	       @ li, 160 PSAY (_sAliasQ) -> SALDO      Picture "@E 999,999,999.99"
           li ++
           // acumula total
           _aTot[1] += (_sAliasQ) -> VALOR
           _aTot[2] += (_sAliasQ) -> DESCONTO
           _aTot[3] += (_sAliasQ) -> JUROS
           _aTot[4] += (_sAliasQ) -> RECEBIDO
           _aTot[5] += (_sAliasQ) -> VLR_COMP
           _aTot[6] += (_sAliasQ) -> SALDO
            (_sAliasQ) -> (dbskip())
     enddo
     
     li ++      
     If li>58
        cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif        
     // imprime totais das emissoes
     @ li, 007 PSAY "TOTAIS: 
     @ li, 075 PSAY _aTot[1] Picture "@E 999,999,999.99"
     @ li, 091 PSAY _aTot[2] Picture "@E 99,999,999.99"
     @ li, 104 PSAY _aTot[3] Picture "@E 99,999,999.99"
     @ li, 125 PSAY _aTot[4] Picture "@E 999,999,999.99"
     @ li, 143 PSAY _aTot[5] Picture "@E 999,999,999.99"
     @ li, 160 PSAY _aTot[6] Picture "@E 999,999,999.99"
     li ++
     
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
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Emissao de                   ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {02, "Emissao ate                  ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {03, "Pagamento de                 ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {04, "Pagamento ate                ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {05, "CNPJ Base                    ?", "C",  8, 0,  "",   "   ", {},                         ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return