// Programa..: BatCpySX
// Autor.....: Robert Koch
// Data......: 28/07/2019
// Descricao.: Batch para copiar o conteudo de algumas tabelas (inicialmente SX6) de modo a manter historico.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Batch para copiar o conteudo de algumas tabelas (inicialmente SX6) de modo a manter historico
// #PalavasChave      #copia_SX6
// #TabelasPrincipais #SX6
// #Modulos           #todos
//
// Historico de alteracoes:
// 10/02/2020 - Robert  - Indice do VA_SX6 passa a ser criado como 'clustered', pare permitir reorganizacao via job do SQL.
// 12/05/2021 - Claudia - Ajustada leitura da tabela SX6 conforme R27. GLPI 8825
//
// ------------------------------------------------------------------------------------------------------------------------

#Include "TbiConn.ch"

User Function BatCpySX ()
	local _oSQL      := NIL
	local _lContinua := .T.
	local _sX6Cont   := ''
	local _x         := 0

	u_logIni ()
	u_logdh ()
	
	// Cria tabela caso ainda nao exista.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "IF OBJECT_ID ('dbo.VA_SX6') IS NULL"
		_oSQL:_sQuery += " CREATE TABLE VA_SX6"
		_oSQL:_sQuery += " (HORARIO    DATETIME NOT NULL DEFAULT GETDATE ()"
		_oSQL:_sQuery += " ,X6_FIL     VARCHAR (2) NOT NULL DEFAULT ''"
		_oSQL:_sQuery += " ,X6_VAR     VARCHAR (10) NOT NULL DEFAULT ''"
		_oSQL:_sQuery += " ,X6_TIPO    VARCHAR (1) NOT NULL DEFAULT ''"
		_oSQL:_sQuery += " ,X6_DESCRIC VARCHAR (50) NOT NULL DEFAULT ''"
		_oSQL:_sQuery += " ,X6_DESC1   VARCHAR (50) NOT NULL DEFAULT ''"
		_oSQL:_sQuery += " ,X6_DESC2   VARCHAR (50) NOT NULL DEFAULT ''"
		_oSQL:_sQuery += " ,X6_CONTEUD VARCHAR (250) NOT NULL DEFAULT ''"
		_oSQL:_sQuery += " ,X6_PROPRI  VARCHAR (1) NOT NULL DEFAULT ''"
		_oSQL:_sQuery += " ,X6_DEFPOR  VARCHAR (250) NOT NULL DEFAULT ''"
		_oSQL:_sQuery += ")"
		_lContinua = _oSQL:Exec ()

		if _lContinua
			_oSQL:_sQuery := "IF NOT EXISTS (SELECT * FROM sysindexes WHERE name = 'VA_SX6_IDX1')"
			_oSQL:_sQuery += " CREATE clustered INDEX VA_SX6_IDX1 ON VA_SX6 ([X6_FIL],[X6_VAR],[X6_CONTEUD])"
			_lContinua = _oSQL:Exec ()
		endif
	endif

	if _lContinua

		_oSQL  := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += " 		 X6_FIL"
		_oSQL:_sQuery += "    	,X6_VAR"
		_oSQL:_sQuery += "    	,X6_DESCRIC"
		_oSQL:_sQuery += "    	,X6_DESC1"
		_oSQL:_sQuery += "   	,X6_DESC2"
		_oSQL:_sQuery += "    	,X6_PROPRI"
		_oSQL:_sQuery += "    	,X6_DEFPOR"
		_oSQL:_sQuery += "    	,X6_TIPO"
		_oSQL:_sQuery += "    	,X6_CONTEUD"
		_oSQL:_sQuery += " FROM SX6010"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_aSX6 := aclone (_oSQL:Qry2Array ())

		For _x:= 1 to Len(_aSX6)
			_sX6_FIL 	:= _aSX6[_x, 1]
			_sX6_VAR	:= _aSX6[_x, 2]
			_sX6_DESCRIC:= _aSX6[_x, 3]
			_sX6_DESC1	:= _aSX6[_x, 4]
			_sX6_DESC2	:= _aSX6[_x, 5]
			_sX6_PROPRI	:= _aSX6[_x, 6]
			_sX6_DEFPOR	:= _aSX6[_x, 7]
			_sX6_TIPO	:= _aSX6[_x, 8]
			_sX6_CONTEUD:= _aSX6[_x, 9]
			_sX6Cont    := alltrim (strtran (_sX6_CONTEUD, "'", "''"))

			// Insere somente se o conteudo anterior for diferente
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "IF (SELECT count (*)"
			_oSQL:_sQuery +=  " FROM VA_SX6"
			_oSQL:_sQuery += " WHERE X6_FIL     = '" + _sX6_FIL + "'"
			_oSQL:_sQuery +=   " AND X6_VAR     = '" + _sX6_VAR + "'"
			_oSQL:_sQuery +=   " AND X6_CONTEUD = '" + _sX6Cont + "'"
			_oSQL:_sQuery +=   " AND HORARIO = (SELECT MAX (HORARIO) FROM VA_SX6 ULTIMA"
			_oSQL:_sQuery +=                   " WHERE ULTIMA.X6_FIL = VA_SX6.X6_FIL"
			_oSQL:_sQuery +=                     " AND ULTIMA.X6_VAR = VA_SX6.X6_VAR)"
			_oSQL:_sQuery +=   ") = 0"
			_oSQL:_sQuery += " INSERT INTO VA_SX6 (X6_FIL,X6_VAR,X6_TIPO,X6_DESCRIC,X6_DESC1,X6_DESC2,X6_CONTEUD,X6_PROPRI,X6_DEFPOR)"
			_oSQL:_sQuery += " VALUES ('" + _sX6_FIL  + "'"
			_oSQL:_sQuery +=         ",'" + _sX6_VAR  + "'"
			_oSQL:_sQuery +=         ",'" + _sX6_TIPO + "'"
			_oSQL:_sQuery +=         ",'" + alltrim(strtran (_sX6_DESCRIC, "'", "''")) + "'"
			_oSQL:_sQuery +=         ",'" + alltrim(strtran (_sX6_DESC1  , "'", "''")) + "'"
			_oSQL:_sQuery +=         ",'" + alltrim(strtran (_sX6_DESC2  , "'", "''")) + "'"
			_oSQL:_sQuery +=         ",'" + _sX6Cont    + "'"
			_oSQL:_sQuery +=         ",'" + _sX6_PROPRI + "'"
			_oSQL:_sQuery +=         ",'" + alltrim(strtran (_sX6_DEFPOR, "'", "''")) + "')"

			_lContinua = _oSQL:Exec ()
			if ! _lContinua
				_oBatch:Mensagens += "Erro inserindo " + _sX6_VAR + ';'
			endif
		Next

		_oBatch:Mensagens += 'SX6 finalizado;'
	EndIf
	u_logFim ()

return _lContinua
