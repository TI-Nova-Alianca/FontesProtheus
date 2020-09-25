// Programa.:  BatPreEnt
// Autor....:  Catia Cardoso       
// Data.....:  20/08/2014     
// Descricao:  Verificacoes diarias -  
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
//
// 11/09/2014 - Catia   - Desconsidera pedidos que foram eliminado residuos
//                        Trata quantidade saldo, quantidade - quantidade ja entregue
// 13/10/2014 - Catia   - Passar a enviar email dos pedidos com previsao de entrega EM ATRASO
// 07/05/2015 - Catia   - Email de previsão de peças e itens de manutenção
// 07/11/2015 - Catia   - Incluidas as colunas de telefone do fornecedor e contato do pedido  
// 12/07/2016 - Catia   - incluido setor de compras no email das peças que vai pra manutenção
// 28/11/2016 - Robert  - Envia e-mail para compras@... e nao mais para o grupo 017.
// 25/01/2018 - Catia   - Envia e-mail para compras@... e nao mais para o grupo 017. 
//                      - tinham ficado fora 2 emails que continuavam sendo enviados para o ZZU - 017
// 14/02/2018 - Catia   - chamdo 3586 - Alexandre - Incluir tipo: MA - MB - ME - PS - PP 
// 26/04/2018 - Catia   - tirado email do Coleoni e Catia que recebiam copia dos emaisl
// 15/03/2019 - Catia   - incluido rotina de recebimento de emails das previsoes de entrega para a portaria - ZZU - 031
// 13/05/2020 - Sandra  - Retirado e-mail de compras@... Para não receber mais e-mail conforme chamado GLPI 7867.
// 28/07/2020 - Cláudia - Adicionado email conforme GLPI: 8189

// --------------------------------------------------------------------------
user function BatPreEnt (_sQueFazer)
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _oSQL     := NIL
	local _sMsg     := ""
	local _sDest    := ""
	local _aCols    := {}
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	_sArqLog := U_NomeLog (.t., .f.)
	u_logIni ()

   if alltrim (upper (_sQueFazer)) == "OC"
	   _aCols = {}
	   aadd (_aCols, {'Filial'      ,    'left' ,  ''})
	   aadd (_aCols, {'Dt.Entrega'  ,    'left' ,  ''})
	   aadd (_aCols, {'Cod.Forn'    ,    'left' ,  ''})
	   aadd (_aCols, {'Fornecedor'  ,    'left' ,  ''})
	   aadd (_aCols, {'Fone'        ,    'left' ,  ''})
	   aadd (_aCols, {'Contato'     ,    'left' ,  ''})
	   aadd (_aCols, {'Ordem Compra',    'left' ,  ''})
	   aadd (_aCols, {'Produto'     ,    'left' ,  ''})
	   aadd (_aCols, {'Descrição'   ,    'left' ,  ''})
	   aadd (_aCols, {'UN'          ,    'left' ,  ''})
	   aadd (_aCols, {'Quantidade'  ,    'right',  ''})
	
	   // Somente os pedidos que tem previsao de entrega nos proximos 5 dias
	    _oSQL := ClsSQL():New ()
	    _oSQL:_sQuery := ""
	    _oSQL:_sQuery += "SELECT C7_FILIAL, C7_DATPRF, C7_FORNECE, A2_NOME"
	    _oSQL:_sQuery += "     , A2_TEL, C7_CONTATO"
        _oSQL:_sQuery += "     , C7_NUM, C7_PRODUTO, C7_DESCRI, C7_UM"
        _oSQL:_sQuery += "     , dbo.FormataValor (SC7.C7_QUANT -SC7.C7_QUJE, 4, 15) AS QUANT"
        _oSQL:_sQuery += "  FROM " + RetSQLName ("SC7") + " SC7, "
        _oSQL:_sQuery +=             RetSQLName ("SA2") + " SA2, "
        _oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
        _oSQL:_sQuery += " WHERE SA2.A2_COD = SC7.C7_FORNECE"
        _oSQL:_sQuery += "   AND SB1.B1_COD = SC7.C7_PRODUTO"
        _oSQL:_sQuery += "   AND SC7.D_E_L_E_T_ = ''"
        _oSQL:_sQuery += "   AND SB1.B1_TIPO IN ('ME','MA','MB','PS','PP')
        _oSQL:_sQuery += "   AND SC7.C7_RESIDUO = ' '"
        _oSQL:_sQuery += "   AND SC7.C7_QUANT - SC7.C7_QUJE > 0"
        _oSQL:_sQuery += "   AND SC7.C7_DATPRF BETWEEN '" + dtos (date ()) + "' AND '" + dtos (date()+10) + "'"
        _oSQL:_sQuery += "ORDER BY SC7.C7_DATPRF, SC7.C7_FORNECE, SC7.C7_NUM"
   	
	   u_log (_oSQL:_sQuery)
	   if len (_oSQL:Qry2Array (.T., .F.)) > 0
	   
			_sMsg = _oSQL:Qry2HTM ("Pedidos de Compra com previsão de entrega nos próximos 10 dias", _aCols, "", .F.)
			_sDest := "qualidade@novaalianca.coop.br;"
			_sDest += "leandro.kist@novaalianca.coop.br;"
			
			//U_SendMail ('compras@novaalianca.coop.br', "Previsões de Entrega", _sMsg, {})
			U_SendMail (_sDest, "Previsões de Entrega", _sMsg, {})
			U_ZZUNU ({'031'}, "Previsões de Entrega", _sMsg, .F., cEmpAnt, cFilAnt, "") // Portaria
		 	
	   endif
	   
	   // Somente os pedidos com previsao de entrega EM ATRASO
        _oSQL := ClsSQL():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += "SELECT C7_FILIAL, C7_DATPRF, C7_FORNECE, A2_NOME"
        _oSQL:_sQuery += "     , A2_TEL, C7_CONTATO"
        _oSQL:_sQuery += "     , C7_NUM, C7_PRODUTO, C7_DESCRI, C7_UM"
        _oSQL:_sQuery += "     , dbo.FormataValor (SC7.C7_QUANT -SC7.C7_QUJE, 4, 15) AS QUANT"
        _oSQL:_sQuery += "  FROM " + RetSQLName ("SC7") + " SC7, "
        _oSQL:_sQuery +=             RetSQLName ("SA2") + " SA2, "
        _oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
        _oSQL:_sQuery += " WHERE SA2.A2_COD = SC7.C7_FORNECE"
        _oSQL:_sQuery += "   AND SB1.B1_COD = SC7.C7_PRODUTO"
        _oSQL:_sQuery += "   AND SC7.D_E_L_E_T_ = ''"
        _oSQL:_sQuery += "   AND SB1.B1_TIPO = 'ME'"
        _oSQL:_sQuery += "   AND SC7.C7_RESIDUO = ' '"
        _oSQL:_sQuery += "   AND SC7.C7_QUANT - SC7.C7_QUJE > 0"
        _oSQL:_sQuery += "   AND SC7.C7_FILIAL = '01'"
        _oSQL:_sQuery += "   AND SC7.C7_DATPRF > '20170101'"
        _oSQL:_sQuery += "   AND SC7.C7_DATPRF < '" + dtos (date ()) + "'"
        _oSQL:_sQuery += "ORDER BY SC7.C7_DATPRF, SC7.C7_FORNECE, SC7.C7_NUM"
    
       u_log (_oSQL:_sQuery)
       if len (_oSQL:Qry2Array (.T., .F.)) > 0
       
         	_sMsg = _oSQL:Qry2HTM ("Pedidos de Compra com previsão EM ATRASO", _aCols, "", .F.)
          	
            U_ZZUNU ({'031'}, "Previsões de Entrega", _sMsg, .F., cEmpAnt, cFilAnt, "") // Portaria
          	//U_SendMail ('compras@novaalianca.coop.br', "Previsões de Entrega", _sMsg, {})
       endif
       
       // Somente os pedidos que tem previsao de entrega nos proximos 10 dias - PEÇAS
	    _oSQL := ClsSQL():New ()
	    _oSQL:_sQuery := ""
	    _oSQL:_sQuery += "SELECT C7_FILIAL, C7_DATPRF, C7_FORNECE, A2_NOME"
	    _oSQL:_sQuery += "     , A2_TEL, C7_CONTATO"
        _oSQL:_sQuery += "     , C7_NUM, C7_PRODUTO, C7_DESCRI, C7_UM"
        _oSQL:_sQuery += "     , dbo.FormataValor (SC7.C7_QUANT -SC7.C7_QUJE, 4, 15) AS QUANT"
        _oSQL:_sQuery += "  FROM " + RetSQLName ("SC7") + " SC7, "
        _oSQL:_sQuery +=             RetSQLName ("SA2") + " SA2, "
        _oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
        _oSQL:_sQuery += " WHERE SA2.A2_COD = SC7.C7_FORNECE"
        _oSQL:_sQuery += "   AND SB1.B1_COD = SC7.C7_PRODUTO"
        _oSQL:_sQuery += "   AND SC7.D_E_L_E_T_ = ''"
        _oSQL:_sQuery += "   AND SC7.C7_RESIDUO = ' '"
        _oSQL:_sQuery += "   AND SC7.C7_QUANT - SC7.C7_QUJE > 0"
        _oSQL:_sQuery += "   AND SC7.C7_DATPRF BETWEEN '" + dtos (date ()) + "' AND '" + dtos (date()+10) + "'"
        _oSQL:_sQuery += "   AND SC7.C7_PRODUTO IN ('7117','7017')"
        _oSQL:_sQuery += "ORDER BY SC7.C7_DATPRF, SC7.C7_FORNECE, SC7.C7_NUM"
   	
   		//u_showmemo(_oSQL:_sQuery)
	   u_log (_oSQL:_sQuery)
	   if len (_oSQL:Qry2Array (.T., .F.)) > 0
	   
	     	_sMsg = _oSQL:Qry2HTM ("Previsao de entrega de PEÇAS/Itens Manutencao nos próximos 10 dias", _aCols, "", .F.)
		  	
		  	U_ZZUNU ({'042'}, "Previsao de Entrega - PECAS/Itens Manutencao", _sMsg, .F., cEmpAnt, cFilAnt, "") // Setor de Manutenção
		  	//U_SendMail ('compras@novaalianca.coop.br', "Previsões de Entrega", _sMsg, {})
		  	U_ZZUNU ({'031'}, "Previsões de Entrega", _sMsg, .F., cEmpAnt, cFilAnt, "") // Portaria
	   endif
       
	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
	_sArqLog = _sArqLog2
return .T.