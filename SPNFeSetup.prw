// Programa:  SPNfeSetup
// Autor:     Robert Koch
// Data:      29/01/2021
// Descricao: Ponto de entrada na tela de configuracao de impressao de DANFe

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Ponto de entrada na tela de configuracao de impressao de DANFe
// #PalavasChave      #auxiliar #uso_generico #impressao #configuracao
// #TabelasPrincipais 
// #Modulos           #FAT #COOP

// Historico de alteracoes:
// 03/02/2021 - Robert - Para saber se estava gerando contranota de safra, testava rotina U_VA_RUS. Passa a testar U_VA_RUSN.
//

#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch" 

// --------------------------------------------------------------------------
user function SPNFESETUP ()
	local _aImpres := {}
	local _nImpres := 0

	U_Log2 ('info', 'Iniciando ' + procname ())
	// u_log2 ('debug', 'dados que seriam usados no DANFEII:')
	// U_Log2 ('debug', GetPrinterSession())
	// U_Log2 ('debug', Paramixb[2]:aOptions[PD_VALUETYPE])
	// U_Log2 ('debug', Paramixb[2]:aOptions)

	// https://tdn.totvs.com/display/framework/FwPrinterSetup
	// https://tdn.totvs.com/display/tec/GetImpWindows
	Paramixb[2]:SetProperty(PD_DESTINATION , 2)  // Propriedade 1 = destino: 1=server;2=local
	Paramixb[2]:SetProperty(PD_PRINTTYPE, 2)     // Propriedade 2 = tipo de impressao: 2=spool;6=PDF
	Paramixb[2]:SetProperty(PD_ORIENTATION, 1)   // Propriedade 3 = orientacao: 1=retrato;2=paisagem

	// Leitura das impressoras disponiveis no Windows da estacao
	_aImpres := aclone (GetImpWindows (.F.))  // Indica se, verdadeiro (.T.), retorna as impressoras do Application Server; caso contrário, falso (.F.), do Smart Client.
//	U_Log2 ('debug', _aImpres)

	// Se estou na tela de contranotas de safra, tento usar uma impressora especifica
	// para isso, que jah deve ter configuracao de impressao de 3 copias.
	if IsInCallStack ("U_VA_RUSN")
//		U_Log2 ('debug', 'Estou gerando contranota de safra')
		_nImpres = ascan (_aImpres, {|_aVal| 'CONTRANOTA' $ upper (_aVal)})
//		U_Log2 ('debug', 'achei impresora de contranotas na pos ' + cvaltochar (_nImpres))
	else
 		// Assume a primeira impressora (default do Windows)
		if len (_aImpres) >= 1
//			u_log2 ('debug', 'Nao tem impressora preferencial (provavelmente nao estava na tela de safra, ou nao tem impressora de contranotas na estacao)')
			_nImpres = 1
		endif
	endif
	if _nImpres > 0
		U_Log2 ('info', '[' + procname () + '] Definindo impressora para DANFe: ' + _aImpres [_nImpres])
		Paramixb[2]:SetProperty(PD_VALUETYPE, _nImpres)  // Propriedade 6 = numero da impressora do windows (como saber?)
		Paramixb[2]:aOptions[PD_VALUETYPE] = _aImpres [_nImpres]  // Array lida posteriormente pelo DANFEII.prw
	endif
	
	// u_log2 ('debug', 'propriedade 1: ' + cvaltochar (Paramixb[2]:GetProperty (1)))
	// u_log2 ('debug', 'propriedade 2: ' + cvaltochar (Paramixb[2]:GetProperty (2)))
	// u_log2 ('debug', 'propriedade 3: ' + cvaltochar (Paramixb[2]:GetProperty (3)))
	// u_log2 ('debug', 'propriedade 4: ' + cvaltochar (Paramixb[2]:GetProperty (4)))
	// u_log2 ('debug', 'propriedade 5: ' + cvaltochar (Paramixb[2]:GetProperty (5)))
	// u_log2 ('debug', 'propriedade 6: ' + cvaltochar (Paramixb[2]:GetProperty (6)))
	// u_log2 ('debug', 'propriedade 7: ' + cvaltochar (Paramixb[2]:GetProperty (7)))
	// U_Log2 ('debug', 'PD_VALUETYPE:')
	// U_Log2 ('debug', Paramixb[2]:aOptions[PD_VALUETYPE])
return
