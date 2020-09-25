// Programa....: VA_SERASA
// Autor.......: Cláudia Lionço
// Data........: 24/04/2020
// Descricao...: Relato simplificado SERASA - Arquivo de remessa normal
//
// Historico de alteracoes:
// 11/11/2019 - Cláudia - Alterada a formula de Estoque médio. 
// 						  O retorno será em dias e não meses, conforme código comentado.
// 04/12/2019 - Cláudia - Incluído parâmetro de grupo de produto.
//
// --------------------------------------------------------------------------------------- 
/* LAYOUT DO ARQUIVO SERASA

HEADER
Seq Iní Fim Tam Form 	Descrição
01 	01 	02 	02 	N 		Identificação Registro Header = 00
02 	03 	22 	20 	C 		Constante = ‘RELATO COMP NEGOCIOS’ Ajuste à esquerda com brancos à direta
03 	23 	36 	14 	N 		CNPJ Empresa Conveniada – informar:(Nr base 8 dígitos numéricos + matriz/filial 4 dígitos numéricos + dígito de controle 2 numéricos).
04 	37 	44 	08 	D/C 	Para remessa Normal Informar: Data Início do Período Informado : AAAAMMDD
						Para remessa de Conciliação Informar:Constante = ‘CONCILIA’
05 	45 	52 	08	D 		Data Final do Período Informado : AAAAMMDD
06 	53 	53 	01 	C 		Periodicidade da remessa. Indicar a constante conforme a periodicidade D=Diário S=Semanal
07 	54 	68 	15 	C 		Reservado Serasa
08 	69 	71 	03 	C 		Número identificador do Grupo Relato Segmento ou brancos.
09 	72 	100 29 	C 		Brancos.
12 101 	102 02 	C 		Identificação da Versão do Layout => Fixo = “V.”
13 103 	104 02 	N 		Número da Versão do Layout => Fixo = “01”.
14 105 	130 26 	C 		Brancos.

DETALHE - TEMPO DE RELACIONAMENTO (DEVERÁ SER FORMATADO SOMENTE PARA REMESSA NORMAL)
Seq Ini Fim Tam Form 	Descrição
01 	01 	02 	02 	N 		Identificação do Registro de Dados = 01
02 	03 	16 	14 	N 		Sacado Pessoa jurídica: CNPJ Empresa Cliente (Sacado) - informar:
						(Nr base 8 dígitos numéricos + matriz/filial 4 dígitos numéricos + dígito de controle 2 numéricos).
03 	17 	18 	02 	N 		Tipo de Dados= 01 (Tempo de Relacionamento para Sacado Pessoa Jurídica)
04 	19 	26 	08 	D 		Cliente Desde: AAAAMMDD
05 	27 	27 	01 	N 		Tipo de Cliente: 1 = Antigo; 2 = Menos de um ano; 3= Inativo
06 	28 	65 	38 	C 		Brancos
07 	66 	99 	34 	C 		Brancos
08 100 100 	01 	C 		Brancos
09 101 130 	30 	C 		Brancos

DETALHE - TÍTULOS
Seq Ini Fim Tam Form 	Descrição
01 	01 	02 	02 	N 		Identificação do Registro de Dados = 01
02 	03 	16 	14 	N 		Sacado Pessoa jurídica: CNPJ Empresa Cliente (Sacado) - informar:
						(Nr base 8 dígitos numéricos + matriz/filial 4 dígitos numéricos + dígito de controle 2 numéricos).
03 	17 	18 	02 	N 		Tipo de Dados = 05 (Títulos – Para Sacado Pessoa Jurídica)
04 	19 	28 	10 	C 		Número do Título com até 10 posições
05 	29 	36 	08 	D 		Data da Emissão do título: AAAAMMDD
06 	37 	49 	13 	N 		Valor do Título, com 2 casas decimais. Ajuste à direita com zeros à esquerda. Formatar 9999999999999 para exclusão do título.
07 	50 	57 	08 	D 		Data de Vencimento: AAAAMMDD
08 	58 	65 	08 	D 		Data de Pagamento: AAAAMMDD ou Brancos. 
						No arquivo de Conciliação enviado pela Serasa esta informação estará com o conteúdo 99999999.
						No arquivo de Conciliação a ser enviado para a Serasa esta informação deverá ser formatada com a 
						Data de Pagamento do título OU com Brancos, se o título não foi pago.
09 	66	99	34	C		Número do Título com mais de 10 posições:
09  66	67	02			#D : indica número do título. Obs.: O "#D" pode ser utilizado quando o número do título for maior que dez
						posições. Se for informado "#D" nas posições 66 e 67, o sistema desprezará o conteúdo das posições 19 a 28 
09	68	99	32			(Número do título), e considerará como número do título o número informado nas posições 68 a 99.
10 100 100 	01 	C 		Brancos.
11 101 124 	24 	C 		Reservado Serasa
12 125 126 	02 	C 		Reservado Serasa
13 127 127 	01 	C 		Reservado Serasa
14 128 128 	01 	C 		Reservado Serasa
15 129 130 	02 	C 		Reservado Serasa

TRAILLER
Seq Ini Fim Tam Form 	Descrição
01 	01 	02 	02 	N 		Identificação do Registro Trailler = 99
02 	03 	13 	11 	N 		Quantidade de Registros 01–Tempo de Relacionamento PJ. Ajuste à direita com zeros à esquerda
						Para remessa de Conciliação formatar zeros.
03 	14 	57 	44 	C 		Brancos
04 	58 	68 	11 	N 		Quantidade de Registros 05 – Títulos PJ. Ajuste à direita com zeros à esquerda
05 	69 	79 	11 	C 		Reservado Serasa
06 	80 	90 	11 	C 		Reservado Serasa
07 	91 100 	10 	C 		Reservado Serasa
08 101 130 	30 	C 		Brancos.

*/ 
#include 'protheus.ch'
#include 'parmtype.ch'

User function VA_SERASA()
	Local _sVazio 	:= ""
	Local _aCliente	:= {}
	Local _aTitulo  := {}
	Local _oSQL 	:= NIL
	Local _x		:= 0
	cPerg         	:= "VA_SERASA"
	
	_ValidPerg()
	Pergunte(cPerg,.T.)
	
	If empty(mv_par03)
		u_help("Informar caminho do arquivo. Ex: C:\Temp\")
	Else
		_sLocal := alltrim(mv_par03) + "serasa_simplificado.txt"
		nHandle := FCreate(_sLocal)
		
		// carrega Header
		_sHeader01 := '00'						// 001-002 Tam.002
		_sHeader02 := 'RELATO COMP NEGOCIOS'    // 003-022 Tam.020
		_sHeader03 := PADL(SM0 -> M0_CGC,14,'0')// 023-036 Tam.014
		_sHeader04 := DTOS(mv_par01)			// 037-044 Tam.008
		_sHeader05 := DTOS(mv_par02)			// 045-052 Tam.008
		_sHeader06 := 'S'						// 053-053 Tam.001
		_sHeader07 := PADR(_sVazio,15,' ')      // 054-068 Tam.015
		_sHeader08 := PADR(_sVazio,3,' ')       // 069-071 Tam.003
		_sHeader09 := PADR(_sVazio,29,' ')      // 072-100 Tam.029
		_sHeader12 := 'V.'						// 101-102 Tam.002
		_sHeader13 := '01'						// 103-104 Tam.002
		
		_sLinha := _sHeader01 + _sHeader02 + _sHeader03 + _sHeader04 + _sHeader05 + _sHeader06 + _sHeader07 + _sHeader08 
		_sLinha += _sHeader09 + _sHeader12 + _sHeader13 + chr (13) + chr (10)
		FWrite(nHandle,_sLinha )
		//
	    // -----------------------------------------------------------------------------------------------------------------
		// carrega detalhe - Tempo de relacionamento
		//
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT A1_CGC, A1_PRICOM, A1_ULTCOM, A1_MSBLQL, A1_COD"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SA1")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND A1_PESSOA = 'J' "										// Apenas juridicos
		_oSQL:_sQuery += " AND A1_COD <> '000000' " 									// retira consumidor final
		_oSQL:_sQuery += " AND A1_PRICOM <> '' " 										// retira clientes sem data de primeira compra
		_oSQL:_sQuery += " AND A1_EST <> 'EX'" 											// Não leva clientes exterior
		_oSQL:_sQuery += " AND A1_PRICOM <= '" + DTOS(mv_par02) +"'"					// Data do cliente menor que a primeira compra
		_oSQL:_sQuery += " AND A1_MSBLQL = '2'" 										// so ativos
		_oSQL:_sQuery += " AND A1_CGC not like '8861248600%'"							// retira filiais
		_aCliente := aclone (_oSQL:Qry2Array ())
		 
		 (!Empty(SA1->A1_ULTCOM).And.(MV_PAR01-SA1->A1_ULTCOM)>365,3,1)
		_nQntCli := 0
	 	For _x:=1 to len(_aCliente)
	 		_sDetRel01 := '01'									// 001-002 Tam.002
			_sDetRel02 := PADL(alltrim(_aCliente[_x,1]),14,'0')	// 003-016 Tam.014
			_sDetRel03 := '01'									// 017-018 Tam.002
			_sDetRel04 := DTOS(_aCliente[_x,2])					// 019-026 Tam.008
			
			// verifica pela dt primeira compra se é cliente novo ou antigo
			If !empty(_aCliente[_x,2])
				_nDias := DateDiffDay(_aCliente[_x,2],mv_par01)
				
				If _nDias < 365 // menos de um ano
					_sDetRel05 := '2'
				Else
					_sDetRel05 := '1'
				EndIf	
			EndIf
			// verifica pela dt da ultima compra se é um cliente ativo ou inativo
			If !empty(_aCliente[_x,3])
				_nDias := DateDiffDay(_aCliente[_x,3],mv_par01)
				
				If _nDias > 365 // mais de um ano que nao compra - inativo
					_sDetRel05 := '3'
				Else
					_sDetRel05 := '1'
				EndIf	
			EndIf
			
			_nQntCli += 1
			
			_sLinha := _sDetRel01 + _sDetRel02 + _sDetRel03 + _sDetRel04 + _sDetRel05 + chr (13) + chr (10)
	 		FWrite(nHandle,_sLinha )
	 	Next	
	 	//
	    // -----------------------------------------------------------------------------------------------------------------
		// carrega detalhe - Títulos
		//	
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT"
		_oSQL:_sQuery += "	 	A1_CGC"
		_oSQL:_sQuery += " 		,E1_EMISSAO"
		_oSQL:_sQuery += "		,(E1_VALOR * 100)"
		_oSQL:_sQuery += "		,E1_VENCREA"
		_oSQL:_sQuery += "		,E1_BAIXA"
		_oSQL:_sQuery += "		,E1_SALDO"
		_oSQL:_sQuery += "		,E1_PREFIXO"
		_oSQL:_sQuery += "		,E1_NUM "
		_oSQL:_sQuery += "		,E1_PARCELA"
		_oSQL:_sQuery += "	FROM " + RetSQLName ("SE1") + " SE1"
		_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SA1") + " SA1"
		_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "		AND SA1.A1_COD = SE1.E1_CLIENTE"
		_oSQL:_sQuery += "		AND SA1.A1_LOJA = SE1.E1_LOJA"
		_oSQL:_sQuery += "		AND SA1.A1_PESSOA = 'J'"
		_oSQL:_sQuery += " 		AND SA1.A1_COD <> '000000' " 									
		_oSQL:_sQuery += " 		AND SA1.A1_PRICOM <> '' " 										
		_oSQL:_sQuery += " 		AND SA1.A1_EST <> 'EX'" 											
		_oSQL:_sQuery += " 		AND SA1.A1_PRICOM <= '" + DTOS(mv_par02) +"'"					
		_oSQL:_sQuery += " 		AND SA1.A1_MSBLQL = '2')"
		_oSQL:_sQuery += "  WHERE SE1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "	AND SE1.E1_FILIAL = '" + xfilial ("SE1")  + "'"
		_oSQL:_sQuery += "	AND ((SE1.E1_EMISSAO BETWEEN '" + DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) + "'"
		_oSQL:_sQuery += "	AND E1_VALOR = E1_SALDO)"
		_oSQL:_sQuery += "	OR (SE1.E1_BAIXA BETWEEN '" + DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) + "'))"
		_oSQL:_sQuery += "	AND SE1.E1_TIPO IN ('NF', 'DP')"
		_oSQL:_sQuery += "	ORDER BY E1_EMISSAO, E1_NUM"
		_aTitulo := aclone (_oSQL:Qry2Array ())
		
		_nQntTit := 0
		For _x:= 1 to len(_aTitulo)
			_sDetTit01 := '01' 																// 001-002 Tam.002
			_sDetTit02 := PADR(_aTitulo[_x,1],14,' ')										// 003-016 Tam.014
			_sDetTit03 := '05'																// 017-018 Tam.002
			_sDetTit04 := PADR(_sVazio,10,' ') 												// 019-028 Tam.010
			_sDetTit05 := DTOS(_aTitulo[_x,2])												// 029-036 Tam.008
			_sDetTit06 := PADL(_aTitulo[_x,3],13,'0') 										// 037-049 Tam.013
			_sDetTit07 := DTOS(_aTitulo[_x,4])												// 050-057 Tam.008
			_sDetTit08 := IIF(empty(_aTitulo[_x,5]),PADR(_sVazio,8,' '),DTOS(_aTitulo[_x,5]))// 058-065 Tam.008
			_sDetTit09 := '#D' +  _aTitulo[_x,7] + _aTitulo[_x,8] + _aTitulo[_x,9]   		// 066-099 Tam.034 sendo que  
																							// 066-067 Tam.002 para #D (numero de titulos maiores que 10 posições)  
																							// 068-099 Tam.032 para número de titulos com mais de 10 posições
			_nQntTit += 1
			
			_sLinha := _sDetTit01 + _sDetTit02 + _sDetTit03 + _sDetTit04 + _sDetTit05 
			_sLinha += _sDetTit06 + _sDetTit07 + _sDetTit08 + _sDetTit09 + chr (13) + chr (10)
	 		FWrite(nHandle,_sLinha )
		Next										
		//
	    // -----------------------------------------------------------------------------------------------------------------
		// Trailler
		//	
		_sTra01 := '99' 									// 001-002 Tam.002
		_sTra02 := PADL(alltrim(str(_nQntCli)),11,'0')  	// 003-013 Tam.011
		_sTra03 := PADR(_sVazio,44,' ')						// 014-057 Tam.044
		_sTra04 := PADL(alltrim(str(_nQntTit)),11,'0')		// 058-068 Tam.011
		
		_sLinha := _sTra01 + _sTra02 + _sTra03 + _sTra04
		FWrite(nHandle,_sLinha )
		
		u_help(" Arquivo gerado em " + _sLocal)
		FClose(nHandle)
	EndIf
Return
//-------------------------------------------------
// perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Data Inicial	", "D",  8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Data Final		", "D",  8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Caminho arquivo ", "C", 30, 0,  "",  "   ", {},                         					""})
     U_ValPerg (cPerg, _aRegsPerg)
Return
