// Programa..: REVALXML.PRX
// Autor.....: Catia Cardoso
// Data......: 21/02/2015
// Nota......: Revalida XML

// Historico de alteracoes:
// 27/02/2015 - Catia  - estava revalidando registros antigos e não precisava
//                       se foi feito algum ajuste manual nao revalida
// 30/03/2015 - Catia  - aumentado o nro de registros lidos de 50 para 100
// 05/07/2022 - Robert - Melhoria logs (GLPI 12312)
//                     - Passa a revalidar somente chaves importadas nos ultimos 30 dias
//

#include "rwmake.ch"
#include "VA_INCLU.prw"

user function RevalXML ()
//	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
//	delete file (_sArqLog)
//	u_logId ()
	processa ({|| _Inicio ()})
return .t.

// --------------------------------------------------------------------------
static function _Inicio ()
	processa ({|| _Revalida_XML()})
return


static function _Revalida_XML()
	local _nRecno := 0
    /// REVALIDA CTe
    _oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT TOP 500 R_E_C_N_O_"
	_oSQL:_sQuery += "   FROM " + RetSQLName ("ZZX") + " ZZX "
	_oSQL:_sQuery += "  WHERE D_E_L_E_T_ != '*'"
	_oSQL:_sQuery += "    AND ZZX_AJMAN   = ''"					// se foi feito algum ajuste manual nao revalida
	_oSQL:_sQuery += "    AND ZZX_CHAVE  != ''"
//	_oSQL:_sQuery += "    AND ZZX_DTIMP > '20161001'"  				//  revalidar so os de 2015 pra frente
	_oSQL:_sQuery += "    AND ZZX_DTIMP >= '" + dtos (date () - 30) + "'"
	_oSQL:_sQuery += "    AND ZZX_LAYOUT = 'procNFe'"
	_oSQL:_sQuery += "    AND ZZX_DUCC   !=   '" + dtos (date ()) + "'" 	//  ja revalidou no dia, nao revalida novamente
	_oSQL:Log ('[' + procname () + ']')

	_aRecnos = aclone (_oSQL:Qry2Array ())
//	u_log (_aRecnos)
	for _nRecno = 1 to len (_aRecnos)
		zzx -> (dbgoto (_aRecnos [_nRecno, 1]))
		U_Log2 ('info', '[' + procname () + ']Vou revalidar chave ' + zzx -> zzx_chave + ' importada em ' + dtoc (zzx -> zzx_dtimp))
		u_zzxr()
	next

return
