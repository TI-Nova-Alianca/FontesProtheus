// Programa...: VA_RUSCV
// Autor......: Robert Koch
// Data.......: 06/01/2021
// Descricao..: Gera array com dados do cadastro viticola, para uso nas rotinas de safra.

// Historico de alteracoes:
// 08/01/2021 - Robert - Preenche o cad.viticola com zeros a esquerda (tipo numerico no NaWeb)
//

#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
User Function va_rusCV (_sFornCV, _sLojaCV)
	local _oSQL        := NIL
	local _aRetCV      := {}
	local _aAreaAnt := U_ML_SRArea ()

	u_Log2 ('info', 'Iniciando ' + procname ())
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery += "SELECT GX0001_VITICOLA_CODIGO cadvit, GX0001_GRUPO_CODIGO grpfam, GX0001_GRUPO_DESCRICAO descgrp"
	_oSQL:_sQuery +=      ", GX0001_PRODUTO_CODIGO produto, GX0001_PRODUTO_DESCRICAO descprod, GX0001_TIPO_ORGANICO tipo_organ"
	_oSQL:_sQuery +=      ", GX0001_VITICOLA_RECADASTRO safravit, GX0001_FINA_COMUM varuva"
	_oSQL:_sQuery +=      ", GX0001_VITICOLA_FISICO fis_vitic, GX0001_SISTEMA_CONDUCAO conduc, GX0001_SIVIBE_CODIGO sivibe"
	_oSQL:_sQuery +=  " FROM GX0001_AGENDA_SAFRA"
	_oSQL:_sQuery += " WHERE GX0001_ASSOCIADO_CODIGO = '" + _sFornCV + "'"
	_oSQL:_sQuery +=   " AND GX0001_ASSOCIADO_LOJA   = '" + _sLojaCV + "'"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	_aRetCV = {}
	do while ! (_sAliasQ) -> (eof ())
		aadd (_aRetCV, array (.CadVitQtColunas))
		_aRetCV [len (_aRetCV), .CadVitCodigo]      = alltrim ((_sAliasQ) -> cadvit)
		_aRetCV [len (_aRetCV), .CadVitCodGrpFam]   = (_sAliasQ) -> grpfam
		_aRetCV [len (_aRetCV), .CadVitNomeGrpFam]  = alltrim ((_sAliasQ) -> descgrp)
		_aRetCV [len (_aRetCV), .CadVitProduto]     = (_sAliasQ) -> produto
		_aRetCV [len (_aRetCV), .CadVitDescPro]     = alltrim ((_sAliasQ) -> descprod)
		_aRetCV [len (_aRetCV), .CadVitOrganico]    = (_sAliasQ) -> tipo_organ
		_aRetCV [len (_aRetCV), .CadVitSafrVit]     = (_sAliasQ) -> safravit
		_aRetCV [len (_aRetCV), .CadVitVarUva]      = (_sAliasQ) -> varuva
		_aRetCV [len (_aRetCV), .CadVitRecebFisico] = (_sAliasQ) -> fis_vitic
		_aRetCV [len (_aRetCV), .CadVitSistCond]    = (_sAliasQ) -> conduc
		_aRetCV [len (_aRetCV), .CadVitSivibe]      = (_sAliasQ) -> sivibe
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())

	u_log2 ('debug', 'Array de cadastro viticola gerada:')
	u_log2 ('debug', _aRetCV)

	U_ML_SRArea (_aAreaAnt)
return _aRetCV
