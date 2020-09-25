// Programa:  BatCpySX
// Autor:     Robert Koch
// Data:      28/07/2019
// Descricao: Batch para copiar o conteudo de algumas tabelas (inicialmente SX6) de modo a manter historico.
//
// Historico de alteracoes:
// 10/02/2020 - Robert - Indice do VA_SX6 passa a ser criado como 'clustered', pare permitir reorganizacao via job do SQL.
//

#Include "TbiConn.ch"

// ------------------------------------------------------------------------------------
User Function BatCpySX ()
	local _oSQL      := NIL
	local _lContinua := .T.
	local _sX6Cont   := ''

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
		//_oSQL:Log ()
		_lContinua = _oSQL:Exec ()
		if _lContinua
			_oSQL:_sQuery := "IF NOT EXISTS (SELECT * FROM sysindexes WHERE name = 'VA_SX6_IDX1')"
			_oSQL:_sQuery += " CREATE clustered INDEX VA_SX6_IDX1 ON VA_SX6 ([X6_FIL],[X6_VAR],[X6_CONTEUD])"
			_lContinua = _oSQL:Exec ()
		endif
	endif

	if _lContinua
		_oSQL := ClsSQL ():New ()
		sx6 -> (dbsetorder (1))
		sx6 -> (dbgotop ())
		do while _lContinua .and. ! sx6 -> (eof ())
			_sX6Cont = alltrim (strtran (sx6 -> x6_conteud, "'", "''"))

			// Insere somente se o conteudo anterior for diferente
			_oSQL:_sQuery := "IF (SELECT count (*)"
			_oSQL:_sQuery +=  " FROM VA_SX6"
			_oSQL:_sQuery += " WHERE X6_FIL     = '" + sx6 -> x6_fil + "'"
			_oSQL:_sQuery +=   " AND X6_VAR     = '" + sx6 -> x6_var + "'"
			_oSQL:_sQuery +=   " AND X6_CONTEUD = '" + _sX6Cont + "'"
			_oSQL:_sQuery +=   " AND HORARIO = (SELECT MAX (HORARIO) FROM VA_SX6 ULTIMA"
			_oSQL:_sQuery +=                   " WHERE ULTIMA.X6_FIL = VA_SX6.X6_FIL"
			_oSQL:_sQuery +=                     " AND ULTIMA.X6_VAR = VA_SX6.X6_VAR)"
			_oSQL:_sQuery +=   ") = 0"
			_oSQL:_sQuery += " INSERT INTO VA_SX6 (X6_FIL,X6_VAR,X6_TIPO,X6_DESCRIC,X6_DESC1,X6_DESC2,X6_CONTEUD,X6_PROPRI,X6_DEFPOR)"
			_oSQL:_sQuery += " VALUES ('" + sx6 -> x6_fil + "'"
			_oSQL:_sQuery +=         ",'" + sx6 -> x6_var + "'"
			_oSQL:_sQuery +=         ",'" + sx6 -> x6_tipo + "'"
			_oSQL:_sQuery +=         ",'" + alltrim (strtran (sx6 -> x6_descric, "'", "''")) + "'"
			_oSQL:_sQuery +=         ",'" + alltrim (strtran (sx6 -> x6_desc1, "'", "''")) + "'"
			_oSQL:_sQuery +=         ",'" + alltrim (strtran (sx6 -> x6_desc2, "'", "''")) + "'"
			_oSQL:_sQuery +=         ",'" + _sX6Cont + "'"
			_oSQL:_sQuery +=         ",'" + sx6 -> x6_propri + "'"
			_oSQL:_sQuery +=         ",'" + alltrim (strtran (sx6 -> x6_defpor, "'", "''")) + "')"
//			_oSQL:Log ()
			_lContinua = _oSQL:Exec ()
			if ! _lContinua
				_oBatch:Mensagens += "Erro inserindo " + sx6 -> x6_var + ';'
			endif
			sx6 -> (dbskip ())
		enddo
		_oBatch:Mensagens += 'SX6 finalizado;'
	endif
	u_logFim ()
return _lContinua
