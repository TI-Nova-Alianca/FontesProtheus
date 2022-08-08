// Programa:   BatMercM
// Autor:      Robert Koch
// Data:       31/10/2017
// Descricao:  Gera tabela MER_PERCOMP para posterior leitura pelo sistema Mercanet.
//             Criado para ser executado via batch.
//             Criado com base no Atl_PerComp.prw (03/02/2017) de Catia Cardoso.
//
// Historico de alteracoes:
// 08/08/2022 - Robert - Inseridos alguns comentarios para registro e removido do projeto.
//
/*
(08:09) Robert Koch: Bom dia, César. Temos um esquema de formação de preços no Mercanet que foi montado lá no início do projeto, pegando o custo e aplicando despesas até chegar ao preço de venda (contrário do que o Mercanet faz, que é pegar o preço cheio e dar descontos).
Tenho no Protheus uma rotina que exporta isso apenas para poucos clientes:
A1_COD	A1_LOJA	A1_NOME	A1_MUN
000219	01	IMPORTADORA COELHO CP COELHO ME                   	BOA VISTA           
009830	01	CONDOR SUPER CENTER LTDA                          	CURITIBA            
009991	01	A E S COMERCIO E DISTRIBUICAO DE ALIMENTOS LTDA   	BRASILIA            
020561	01	SUPERMERCADO BAHAMAS S/A                          	JUIZ DE FORA        

Já no Mercanet, pelo que vejo, a importação está desabilitada.
(08:09) Robert Koch: Acho que, se não foi usada até agora, posso remover essa 'exportação de tabelas' do Protheus também, certo?
(08:23) Cesar Luis Chinato: Bom Dia, 
(08:23) Cesar Luis Chinato: pode remover sim
(08:23) Cesar Luis Chinato: troquei uma ideia com o Fernando tbm e ele me falou que nunca funcionou 
(08:25) Robert Koch: blz!
*/

/*
Este programa gerava a tabela MER_PERCOMP, que era posteriormente importada pelo Mercanet
executando o seguinte comando: 
EXECUTE [dbo].[MERCP_FORMACAO_PRECOS]
... que ficava agendado nos jobs do SQL Server, mas jah estava desabilitado em 08/08/2022
*/

// --------------------------------------------------------------------------
user function BatMercM ()
	local _sArqLog2  := iif (type ("_sArqLog") == "C", _sArqLog, "")
	local _oSQL      := NIL
	local _nLock     := 0
	local _lContinua := .T.
	_sArqLog := procname () + "_" + dtos (date ()) + ".log"
	u_logIni ()
	u_logDH ()

	_oBatch:Retorno = 'N'

	// Controla acesso via semaforo para evitar executar quando a execucao anterior ainda nao terminou.
	if _lContinua
		_nLock := U_Semaforo (procname (1) + procname ())
		if _nLock == 0
			u_log ("Bloqueio de semaforo.")
			_oBatch:Mensagens += "Bloqueio de semaforo."
			_lContinua = .F.
		endif
	endif
	
	u_help("INICIO")

	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "DELETE MER_PERCOMP"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			u_help ("Erro ao deletar dados anteriores")
			_oBatch:Mensagens += "Erro ao deletar dados anteriores: " + _oSQL:_sQuery
			_lContinua = .F.
		endif
	endif

	u_help("DELETOU A TABELA")
	
	if _lContinua
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "WITH C AS (SELECT SA1.A1_VEND AS CODVEN,"
		_oSQL:_sQuery += "    			     SA1.A1_COD		AS CODCLI,"
		_oSQL:_sQuery += "    			     B1_COD AS CODPRO," 
		_oSQL:_sQuery += "    			     B1_CUSTD AS CUSTOPRO," 
		_oSQL:_sQuery += "    			     ZX5.ZX5_39PERC	AS MARGEM,"  // %MARKUP
		_oSQL:_sQuery += "                   dbo.VA_FRAPELPADRAO (SA1.A1_COD, SA1.A1_LOJA, SB1.B1_COD) AS RAPEL,"
		_oSQL:_sQuery += "    			     SA3.A3_COMIS AS COMIS," 
		_oSQL:_sQuery += "    					   CASE WHEN SA1.A1_EST = 'RS' THEN 18" 
		_oSQL:_sQuery += "    					  	 WHEN SA1.A1_EST IN ('MG','PR','RJ','SC','SE','SP') THEN 12" 
		_oSQL:_sQuery += "    					     WHEN SA1.A1_EST IN ('AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MS','MT','PA','PB','PE','PI','SE','RN','RO','RR','TO') THEN 7" 
		_oSQL:_sQuery += "    					   END AS ICMS," 	  
		_oSQL:_sQuery += "    					   3.2 AS PISCOF,"
		_oSQL:_sQuery += "    					   SA1.A1_VAPFRE AS PFRETE,"
		_oSQL:_sQuery += "    				       1.5 AS FINAN"
		//_oSQL:_sQuery += "    			   0 AS PR_PRATICADO"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SA1") + " SA1, "
		_oSQL:_sQuery +=            RetSQLName ("SB1") + " SB1, "
		_oSQL:_sQuery +=            RetSQLName ("SA3") + " SA3, "
		_oSQL:_sQuery +=            RetSQLName ("ZX5") + " ZX5 "
		_oSQL:_sQuery += " WHERE SA1.D_E_L_E_T_ = ''""
		_oSQL:_sQuery += " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_oSQL:_sQuery += " AND SA1.A1_MSBLQL != '1'"
		_oSQL:_sQuery += " AND SA3.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SA3.A3_FILIAL  = '" + xfilial ("SA3") + "'"
		_oSQL:_sQuery += " AND SA3.A3_COD     = SA1.A1_VEND"
		_oSQL:_sQuery += " AND SA3.A3_ATIVO   = 'S'"

		// durante testes iniciais, vamos integrar apenas pouco(s) repres. e clientes
		//_oSQL:_sQuery += " AND SA3.A3_VAUSAME = 'S'"
		_oSQL:_sQuery += " AND A1_COD IN ('009991','009830','000219','020561')"  // A E S COMERCIO E DISTRIBUICAO DE ALIMENTOS LTDA   

		_oSQL:_sQuery += " AND SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery += " AND SB1.B1_CUSTD   > 0"  		
		_oSQL:_sQuery += " AND SB1.B1_TIPO    = 'PA'"  		
		_oSQL:_sQuery += " AND SB1.B1_COD     NOT LIKE '8%'"  // ignora produtos da loja (unitarios)  		
		_oSQL:_sQuery += " AND SB1.B1_MSBLQL != '1'"  		
		_oSQL:_sQuery += " AND ZX5.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery += " AND ZX5.ZX5_TABELA = '39'"
		_oSQL:_sQuery += " AND ZX5.ZX5_39COD  = SB1.B1_CODLIN"
		_oSQL:_sQuery += ")"

		// Campos nao lidos pela Mercanet: COMIS, ICMS, PISCOF, FINAN, COMPOSICAO, PR_PRATICADO, margem_atual

		_oSQL:_sQuery += "  INSERT INTO MER_PERCOMP (CODVEN, CODCLI, CODPRO, CUSTOPRO, MARGEM, RAPEL, PFRETE, PERTOT, MARGEM_BLQ)"
		_oSQL:_sQuery += " SELECT C.CODVEN, C.CODCLI, C.CODPRO, C.CUSTOPRO, C.MARGEM, C.RAPEL, C.PFRETE,"       
	  	_oSQL:_sQuery += "       (C.MARGEM + C.RAPEL + C.COMIS + C.ICMS + C.PISCOF + C.PFRETE + C.FINAN) AS PERTOT,"       
	  	
	  	//_oSQL:_sQuery += " 	     CASE WHEN C.PR_PRATICADO > 0 THEN ROUND((C.PR_PRATICADO - C.CUSTOPRO - (C.PR_PRATICADO * (C.RAPEL + C.COMIS + C.ICMS + C.PISCOF + C.PFRETE + C.FINAN)/100))*100/C.PR_PRATICADO,2)" 
	    //_oSQL:_sQuery += "      	 ELSE C.MARGEM" 
		//_oSQL:_sQuery += " 		 END AS MARGEM_ATUAL,"

//	  	_oSQL:_sQuery += " 	     CASE WHEN C.PR_PRATICADO > 0 AND C.PR_PRATICADO < (ROUND((C.CUSTOPRO / (100 - (C.MARGEM + C.RAPEL + C.COMIS + C.ICMS + C.PISCOF + C.PFRETE + C.FINAN))*100),2)) THEN ROUND((C.PR_PRATICADO - C.CUSTOPRO - (C.PR_PRATICADO * (C.RAPEL + C.COMIS + C.ICMS + C.PISCOF + C.PFRETE + C.FINAN)/100))*100/C.PR_PRATICADO,2)" 
//	    _oSQL:_sQuery += " 		 ELSE C.MARGEM"
//		_oSQL:_sQuery += " 	 	 END AS MARGEM_BLQ"  // Abaixo desta margem, gera bloqueio do pedido no Mercanet

		_oSQL:_sQuery += " 	 	 C.MARGEM AS MARGEM_BLQ"  // Abaixo desta margem, gera bloqueio do pedido no Mercanet
		_oSQL:_sQuery += "    FROM C"
		
		u_showmemo(_oSQL:_sQuery)
		if _oSQL:Exec ()
			_oBatch:Retorno = 'S'
		endif
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	u_logFim ()
	_sArqLog = _sArqLog2
return .T.
