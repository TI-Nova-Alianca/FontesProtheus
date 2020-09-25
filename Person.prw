// Programa:  Person
// Autor:     Robert Koch
// Data:      24/09/2015
// Descricao: Aplica algumas personalizacoes automaticamente.
//            Cansei de baixar UPDs, atualizar versao, etc. e perder pastas/campos de cadastros, por exemplo...
//
// Historico de alteracoes:
//
// 20/06/2016 - Catia   - personalização do DA0 e DA1 - so altera quem estiver cadastrado na rotina 016
// 24/06/2016 - Catia   - personalizacao do A1_VAMUDOU - permissao so para rotina 036 - financeiro
// 05/07/2016 - Robert  - Campo X3_WHEN tabelas DA0 e DA1
//                      - Melhorias para quando nao tiver 'folder' definido.
// 12/07/2016 - Catia   - tratamento para inicializador padrao
// 12/07/2016 - Catia   - excluir dados da tabela SX5 que vem como padrao
// 18/07/2016 - Catia   - erro no inicializador padrao do SG1
// 21/07/2016 - Catia   - erro no inicializador padrao do SD3
// 22/07/2016 - Catia   - erro no inicializador padrao do SC6
// 02/08/2016 - Robert  - Inicializadores DA4 e DAU.
// 31/08/2016 - Robert  - Passa a fazer alteracoes no SXB e nao apenas inclusoes.
// 14/11/2016 - Catia   - validação E4_CODIGO  
// 12/12/2016 - Robert  - Atualizacoes campos tabela SBE.
// 08/02/2017 - Robert  - Validacao C5_TABELA.
// 14/02/2017 - Robert  - Validacao E4_MSBLQL.
// 24/02/2017 - Robert  - Validacoes e F3 para o campo A1_VAMARCM.
// 06/03/2017 - Robert  - Apenas grupo 069 (custos) altera cadastro de grupos de produtos.
// 29/05/2017 - Catia   - Tratar campo A1_VAOC e A1_VAREGE - colocar nas abas corretas
// 12/06/2017 - Catia   - Tratar campo A1_VABARAP e tirar o A1_TXRAPEL
// 08/04/2019 - Andre   - Alterada tabela SX5 '98' para ZX5 '50'.
// 23/05/2019 - Robert  - Habilitado para Sandra.
// 04/07/2019 - Catia   - Alterada pasta campo B1_SITUACA p/a pasta impostos
// 26/07/2019 - Robert  - Desabilitados B1_VAEANUN e B1_VADUNCX (vamos usar campos padrao do sistema) - GLPI 6335.
// 30/07/2019 - Robert  - Cria filtro de bancos não bloqueados na consulta SA6 do SXB
// 30/08/2019 - Claudia - Alterado campo b1_p_brt para b1_pesbru.
// 05/09/2019 - Sandra  - Excluido campo B1_VAGRWWC
// 28/02/2020 - Robert  - Desabilitada geracao do SXB (inconformidade para migracao para release 25)
//

// --------------------------------------------------------------------------------------------------
user function Person ()
	if ! alltrim(upper(cusername)) $ 'ROBERT.KOCH/ADMINISTRADOR/CATIA.CARDOSO/ANDRE.ALVES/SANDRA.SUGARI'
		msgalert ('Nao te conheco, nao gosto de ti e nao vou te deixar continuar. Vai pra casa.', procname ())
		return
	endif
	u_logIni ()
	u_logId ()
	processa ({|| _AndaLogo ()})
	u_logFim ()
return


// --------------------------------------------------------------------------
static function _AndaLogo ()

	// Cria pastas/folders nos cadastros e move os campos para as respectivas pastas.
	_Pastas ()

	// Cria / altera consultas padrao (F3)
//	_SXB ()

	// Cria validacoes para restringir quem altera qual campo nos cadastros.
	_X3When ()
return


// --------------------------------------------------------------------------
static function _Pastas ()
	local _aSXA     := {}
	local _nSXA     := 0
	local _sFolder  := ''
	local _sUltFold := ''
	procregua (10)

	// Atualiza algumas configuracoes do SX3. Informar NIL para deixar como estah.
	//
	//            Arq    Pasta                 	Campo         	X3_WHEN F3        VldUser									Inicializador Padrao
	aadd (_aSXA, {"DA4", NIL,                   "DA4_COD",      '',  	NIL,      NIL,										'GETSXENUM ("DA4", "DA4_COD")'})

	aadd (_aSXA, {"DAU", NIL,                   "DAU_COD",      '',  	NIL,      NIL,										'GETSXENUM ("DAU", "DAU_COD")'})

	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VACORIG", 	'',  	NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VASTATC", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAMDANF", 	'',     NIL,      'Vazio().or.U_VA_VCpo()',					NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_OBSALI",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_PVCOND",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_MICRO",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_MESO",    	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAOREMB", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAEAN",   	'',     NIL,      'u_va_vcpo ()',							NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAUSER",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAREGMA", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VADTINC", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VABOLST", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAUEXPO", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAEDING", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAMEI",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VACPEDI", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAEANLE", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VACBASE", 	'altera', 'SA1',    'vazio () .or. existcpo ("SA1", m->a1_vacbase)',			NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VALBASE", 	'altera', NIL,      'vazio () .or. existcpo ("SA1", m->a1_vacbase + m->a1_valbase)',NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VERBA",   	'',     NIL,      'Pertence("12")',							NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VARAPNE", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAJST",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Especificos",        	"A1_VAEBOL",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Fiscais",        	    "A1_VAREGE",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Cadastrais",     	    "A1_VAOC",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", "Adm/Fin.",        	"A1_VABARAP", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA1", NIL,		   			"A1_MSBLQL",  	'',	 	NIL,      NIL,										"'1'"})
	aadd (_aSXA, {"SA1", NIL,		   			"A1_LOJA",    	'',	 	NIL,      NIL,										"'01'"})
	aadd (_aSXA, {"SA1", NIL,         			"A1_TIPO",    	'',	 	NIL,      NIL,										"'R'"})
	aadd (_aSXA, {"SA1", NIL,            		"A1_NATUREZ", 	'',	 	NIL,      NIL,										"'0001'"})
	aadd (_aSXA, {"SA1", NIL,         			"A1_PAIS",   	'',	 	NIL,      NIL,										"'105'"})
	aadd (_aSXA, {"SA1", NIL,         			"A1_CODPAIS", 	'',	 	NIL,      NIL,										"'01058'"})
	aadd (_aSXA, {"SA1", NIL,         			"A1_TRIBFAV", 	'',	 	NIL,      NIL,										"'2'"})
	aadd (_aSXA, {"SA1", NIL,         			"A1_GRPVEN",  	'',	 	NIL,      NIL,										"'000001'"})
	aadd (_aSXA, {"SA1", NIL,         			"A1_RISCO",  	'',	 	NIL,      NIL,										"'E'"})     
	aadd (_aSXA, {"SA1", NIL, 		   			"A1_INOVAUT", 	'',	 	NIL,      NIL,										"'2'"})		
	
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAOBRA",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VACORIG", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAREGMA", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAMATRI", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VADTNAS", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VADTFAL", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VARG",    	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VACONJU", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VACPFCO", 	'',     NIL,      'VldCgcCpf(M->A2_Tipo,M->A2_VACPFCO)',	NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAAPDAP", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAMNDAP", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VANRDAP", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAENDAP", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAEMDAP", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAVLDAP", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAQBDAP", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VASTDAP", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VACBASE", 	'',     'SA2',    'vazio () .or. U_VA_VCpo ()',				NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VALBASE", 	'',     NIL,      'vazio () .or. U_VA_VCpo ()',				NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VASEXO",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAECIV",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VANPES",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAAREA",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAPOSSE", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VAOBS",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VALATIT",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA2", "Especificos",        	"A2_VALONGI",  	'',     NIL,      NIL,										NIL})
	
	aadd (_aSXA, {"SA2", NIL, 		   			"A2_COD", 		'',	 	NIL,      NIL,										'GETSX8NUM("SA2")'})
	aadd (_aSXA, {"SA2", NIL, 		   			"A2_LOJA", 		'',	 	NIL,      NIL,										"'01'"})
	aadd (_aSXA, {"SA2", NIL, 		   			"A2_PAIS", 		'',	 	NIL,      NIL,										"'105'"})
	aadd (_aSXA, {"SA2", NIL, 		   			"A2_ID_REPR", 	'',	 	NIL,      NIL,										"'N'"})
	aadd (_aSXA, {"SA2", NIL, 		   			"A2_IMPIP",		'',	 	NIL,      NIL,										"'3'"})
	aadd (_aSXA, {"SA2", NIL, 		   			"A2_CODPAIS",	'',	 	NIL,      NIL,										"'01058'"})
	aadd (_aSXA, {"SA2", NIL, 		   			"A2_TRIBFAV",	'',	 	NIL,      NIL,										"'2'"})
	
	aadd (_aSXA, {"SA3", NIL, 		   			"A3_COD", 		'',	 	NIL,      NIL,										'GETSX8NUM("SA3")'})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_VATPCOM",	'',	 	NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_ICMSRET",	'',	 	NIL,      NIL,										"'N'"})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_COMIS",	'',	 	NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_FRETE",	'',	 	NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_ICM",		'',	 	NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_IPI",		'',	 	NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_ALBAIXA",	'',	 	NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_ALEMISS",	'',	 	NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_ACREFIN",	'',	 	NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_ISS",		'',	 	NIL,      NIL,										NIL})
	aadd (_aSXA, {"SA3", "Pagamento de Comissão","A3_GRPCOM",	'',	 	NIL,      NIL,										NIL})
	
	aadd (_aSXA, {"SA4", NIL, 		   			"A4_COD", 		'',	 	NIL,      NIL,										'GETSXENUM("SA4","A4_COD")'})
	
	aadd (_aSXA, {"SA6", NIL, 		   			"A6_COD", 		'',	 	NIL,      NIL,										'iif(type("_SZI_Bco")=="C",_SZI_Bco,"")'})
	aadd (_aSXA, {"SA6", NIL, 		   			"A6_AGENCIA",	'',	 	NIL,      NIL,										'iif(type("_SZI_Age")=="C",_SZI_Age,"")'})
	aadd (_aSXA, {"SA6", NIL, 		   			"A6_NUMCON",	'',	 	NIL,      NIL,										'iif(type("_SZI_Cta")=="C",_SZI_Cta,"")'})
	
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_GRPEMB",  	'',     'ZX550', 'vazio ().or.U_existZX5("50",m->b1_grpemb)',		NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_VADSEMB", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_CODLIN",  	'',     'ZX539', 'vazio ().or.U_existZX5("39",m->b1_codlin)',		NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_LINHA",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_QTEMB",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_UENS",    	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_UENPROD", 	'',     'Z5',     NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_CODPAI",  	'',     'SB1',    'U_VA_VCpo ()',							NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_QTDEMB",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_VAGRLP",  	'',     'ZX538',  'vazio ().or.U_existZX5("38",m->b1_vagrlp)',NIL})
//	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_VAEANUN", 	'',     NIL,      'u_va_vcpo ()',							NIL})
//	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_VADUNCX", 	'',     NIL,      'u_va_vcpo ()',							NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_VAFORAL", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_VAMARCM", 	'',     'ZX540',  'vazio ().or.U_existZX5("40",m->b1_vamarcm)',NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_ADMIN",   	'',     'PGA',    NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_GARANT",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_PERGART", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_VAMIX",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Garantia Estendida", 	"B1_CLINF",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Uvas/Vinhos",        	"B1_LITROS",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Uvas/Vinhos",        	"B1_VARUVA",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Uvas/Vinhos",        	"B1_VARMAAL", 	'',     'ZX508',  'vazio().or.U_VA_VCpo()',NIL})
	aadd (_aSXA, {"SB1", "Uvas/Vinhos",        	"B1_VAORGAN", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Uvas/Vinhos",        	"B1_VAFCUVA", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Uvas/Vinhos",        	"B1_VAUVAES", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Uvas/Vinhos",        	"B1_VACOR",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Uvas/Vinhos",        	"B1_VATTR",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_UPRC",    	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_UCOM",    	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_UCALSTD", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_DATREF",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_CUSTD",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_MCUSTD",  	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_AGREGCU", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_VACUSEM", 	'',     NIL,      NIL,										NIL})
//	aadd (_aSXA, {"SB1", "Custos",             	"B1_VAGRWWC", 	'',     'ZZ',     'vazio () .or. (existcpo ("SX5", "ZZ" + m->b1_vagrwwc) .and. len (alltrim (m->b1_vagrwwc)) == 3)',NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_VARATEI", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_GCCUSTO", 	'',     'CTR',    NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_CCCUSTO", 	'',     'CTT',    NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_CC",      	'',     'CTT',    NIL,										NIL})
	aadd (_aSXA, {"SB1", "Custos",             	"B1_CONTA",   	'',     'CT1',    NIL,										NIL})
	aadd (_aSXA, {"SB1", "MRP / Suprimentos",  	"B1_VAOBSOP", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "MRP / Suprimentos",  	"B1_VALINEN", 	'',     'SH1',    'VAZIO () .OR. EXISTCPO ("SH1")',			NIL})
	aadd (_aSXA, {"SB1", "MRP / Suprimentos",  	"B1_VACODFA", 	'',     'ZW',     NIL,										NIL})
	aadd (_aSXA, {"SB1", "MRP / Suprimentos",  	"B1_VANOMEF", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "MRP / Suprimentos",  	"B1_VACAPDI", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "MRP / Suprimentos",  	"B1_VAFULLW", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "MRP / Suprimentos",  	"B1_REVATU", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "MRP / Suprimentos",  	"B1_RASTRO", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "MRP / Suprimentos",  	"B1_LOCALIZ", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "MRP / Suprimentos",  	"B1_CELCOD", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "C.Q.",               	"B1_PRVALID", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "C.Q.",               	"B1_VAPLLAS", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "C.Q.",               	"B1_VAPLCAM", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "C.Q.",               	"B1_PESBRU",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "C.Q.",               	"B1_PESO",    	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Impostos",           	"B1_TE",      	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Impostos",           	"B1_TS",      	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Impostos",           	"B1_SEGUM",   	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Impostos",           	"B1_CONV",    	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Impostos",           	"B1_TIPCONV", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Impostos",           	"B1_TESBONI", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Impostos",           	"B1_VAATO", 	'',     NIL,      NIL,										NIL})
	aadd (_aSXA, {"SB1", "Impostos",           	"B1_SITUACA", 	'',     NIL,      NIL,										NIL})
	
	//            Arq    Pasta                 	Campo         	X3_WHEN F3        VldUser									Inicializador Padrao
	aadd (_aSXA, {"SB1", NIL, 		   			"B1_MRP", 		'',	 	NIL,      NIL,										'"N"'})
	aadd (_aSXA, {"SB1", NIL, 		   			"B1_REGESIM",	'',	 	NIL,      NIL,										'"1"'})
	aadd (_aSXA, {"SB1", NIL, 		   			"B1_TPDP",		'',	 	NIL,      NIL,										'"2"'})
	aadd (_aSXA, {"SB1", NIL, 		   			"B1_GRPTIDC",	'',	 	NIL,      NIL,										'IIF(!INCLUI,Posicione("SX5",1,xFilial("SX5")+"ZV"+SB1->B1_GRPTI,"X5_DESCRI"),"")'})
	
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACSD01", 	'',     'ZX512',  'vazio() .or. U_ExistZX5 ("12", m->B5_VACSD01)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACSD03", 	'',     'ZX524',  'vazio() .or. U_ExistZX5 ("24", m->B5_VACSD03)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACSD05", 	'',     'ZX525',  'vazio() .or. U_ExistZX5 ("25", m->B5_VACSD05)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACSD06", 	'',     'ZX526',  'vazio() .or. U_ExistZX5 ("26", m->B5_VACSD06)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACSD07", 	'',     'ZX527',  'vazio() .or. U_ExistZX5 ("27", m->B5_VACSD07)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACSD09", 	'',     'ZX528',  'vazio() .or. U_ExistZX5 ("28", m->B5_VACSD09)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACSD10", 	'',     'ZX529',  'vazio() .or. U_ExistZX5 ("29", m->B5_VACSD10)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACSD11", 	'',     'ZX530',  'vazio() .or. U_ExistZX5 ("30", m->B5_VACSD11)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACSD12", 	'',     'ZX531',  'vazio() .or. U_ExistZX5 ("31", m->B5_VACSD12)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACSD13", 	'',     'ZX523',  'vazio() .or. U_ExistZX5 ("23", m->B5_VACSD13)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VATPSIS", 	'',     'ZX534',  'vazio() .or. U_ExistZX5 ("34", m->B5_VATPSIS)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VACPSIS", 	'',     'ZX532',  'vazio() .or. U_ExistZX5 ("32", m->B5_VACPSIS)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VAEPSIS", 	'',     'ZX533',  'vazio() .or. U_ExistZX5 ("33", m->B5_VAEPSIS)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VAEMSIS", 	'',     'ZX535',  'vazio() .or. U_ExistZX5 ("35", m->b5_vaemsis)',NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VAPPSIS", 	'',     ''     ,  '',										NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VASISDE", 	'',     ''     ,  '',										NIL})
	aadd (_aSXA, {"SB5", "Sisdeclara",         	"B5_VAVPSIS", 	'',     'SZ6'  ,  'vazio () .or. existcpo ("SZ6")',			NIL})
		
	aadd (_aSXA, {"SBE", 'Cadastrais',			"BE_VATANQ", 	'inclui',				NIL,      NIL,	NIL})
	aadd (_aSXA, {"SBE", NIL, 		   			"BE_LOCALIZ", 	'!empty(m->be_vatanq)',	NIL,      'U_VA_VCpo()',	NIL})

	aadd (_aSXA, {"SC1", NIL, 		   			"C1_FILENT", 	'',	 	NIL,      NIL,										'xFilial("SC7")'})
	
	aadd (_aSXA, {"SC2", NIL, 		   			"C2_NUM", 		'',	 	NIL,      NIL,										'GETSX8NUM("SC2","C2_NUM")'})
	aadd (_aSXA, {"SC2", NIL, 		   			"C2_DATPRI", 	'',	 	NIL,      NIL,										'ddatabase'})
	aadd (_aSXA, {"SC2", NIL, 		   			"C2_DATPRF", 	'',	 	NIL,      NIL,										'ddatabase'})
	aadd (_aSXA, {"SC2", NIL, 		   			"C2_EMISSAO", 	'',	 	NIL,      NIL,										'ddatabase'})
	
	//            Arq    Pasta                 	Campo         	X3_WHEN F3        VldUser									Inicializador Padrao
	aadd (_aSXA, {"SC5", NIL, 		   			"C5_NUM", 		'',	 	NIL,      NIL,										'U_VA_IniPD("C5_NUM",.F.)'})  // 'GetSX8Num("SC5", "C5_NUM")'})
	aadd (_aSXA, {"SC5", NIL, 		   			"C5_VEND1", 	'',	 	NIL,      NIL,										'U_VA_IniPD ("C5_VEND1", .F.)'})
	aadd (_aSXA, {"SC5", NIL, 		   			"C5_ESPECI1", 	'',	 	NIL,      NIL,										'"VOLUME(S)"'})
	aadd (_aSXA, {"SC5", NIL, 		   			"C5_TPCARGA", 	'',	 	NIL,      NIL,										'IIF(CEMPANT+CFILANT=="0101","1","2")'})
	aadd (_aSXA, {"SC5", NIL, 		   			"C5_GERAWMS", 	'',	 	NIL,      NIL,										'"2"'})
	
	aadd (_aSXA, {"SC6", NIL, 		   			"C6_PEDCLI", 	'',	 	NIL,      NIL,										'iif(type("M->C5_PEDCLI")=="C",m->c5_pedcli,"")'})
	
	aadd (_aSXA, {"SC8", NIL, 		   			"C8_TXMOEDA", 	'',	 	NIL,      NIL,										'1'})
	
	aadd (_aSXA, {"SD3", NIL, 		   			"D3_TM", 		'',	 	NIL,      NIL,										'IIF(ISINCALLSTACK("MATA250"),"010","")'})
	aadd (_aSXA, {"SD3", NIL, 		   			"D3_DOC", 		'',	 	NIL,      NIL,										'U_NxtD3Doc()'})
	aadd (_aSXA, {"SD3", NIL, 		   			"D3_USUARIO",	'',	 	NIL,      NIL,										'cusername'})
	
	aadd (_aSXA, {"SD5", NIL, 		   			"D5_DATA", 		'',	 	NIL,      NIL,										'DDATABASE'})
	aadd (_aSXA, {"SD5", NIL, 		   			"D5_LOTECTL",	'',	 	NIL,      NIL,										'"0000000001"'})
	aadd (_aSXA, {"SD5", NIL, 		   			"D5_DTVALID", 	'',	 	NIL,      NIL,										'DDATABASE'})
	
	aadd (_aSXA, {"SE1", NIL, 		   			"E1_BAIXA", 	'',	 	NIL,      NIL,										'SE1->E1_VENCREA'})
	aadd (_aSXA, {"SE1", NIL, 		   			"E1_OCORREN", 	'',	 	NIL,      NIL,										'"01"'})
	aadd (_aSXA, {"SE1", NIL, 		   			"E1_CODORCA", 	'',	 	NIL,      NIL,										'GETNEWPAR("MV_PLAPAD","PADRAOPR")'})
	
	aadd (_aSXA, {"SE2", NIL, 		   			"E2_BAIXA", 	'',	 	NIL,      NIL,										'SE2->E2_VENCREA'})
	aadd (_aSXA, {"SE2", NIL, 		   			"E2_CODORCA", 	'',	 	NIL,      NIL,										'GETNEWPAR("MV_PLAPAD","PADRAOPR")'})
	
	aadd (_aSXA, {"SE3", NIL, 		   			"E3_BAIEMI", 	'',	 	NIL,      NIL,										'"E"'})
	aadd (_aSXA, {"SE3", NIL, 		   			"E3_ORIGEM", 	'',	 	NIL,      NIL,										'"E"'})
	
	aadd (_aSXA, {"SE4", NIL, 		   			"E4_CODIGO", 	'',	 	NIL,      'u_va_vcpo ()',							NIL})
	aadd (_aSXA, {"SE4", NIL, 		   			"E4_MSBLQL", 	'',	 	NIL,      'u_va_vcpo ()',							NIL})
	aadd (_aSXA, {"SE4", NIL, 		   			"E4_IPI", 		'',	 	NIL,      NIL,										'"J"'})
	aadd (_aSXA, {"SE4", NIL, 		   			"E4_SOLID", 	'',	 	NIL,      NIL,										'"J"'})
		
	aadd (_aSXA, {"SE5", NIL, 		   			"E5_HISTOR", 	'',	 	NIL,      NIL,										'iif(type("_SZI_Hist")=="C",_SZI_Hist,"" )'})
	aadd (_aSXA, {"SE5", NIL, 		   			"E5_TIPOLAN", 	'',	 	NIL,      NIL,										'"X"'})
	
	aadd (_aSXA, {"SE8", NIL, 		   			"E8_MOEDA", 	'',	 	NIL,      NIL,										'"1"'})
	
	aadd (_aSXA, {"SED", NIL, 		   			"ED_JURSPD", 	'',	 	NIL,      NIL,										'"2"'})
	
	aadd (_aSXA, {"SF1", NIL, 		   			"F1_CHVNFE", 	'',	 	NIL,      NIL,										'iif(type("_F1CHVNFE")=="C",_F1CHVNFE,"")'})
	
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_OBSICM", 	'',	 	NIL,      NIL,										'"2"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_OBSSOL", 	'',	 	NIL,      NIL,										'"2"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_MKPSOL", 	'',	 	NIL,      NIL,										'"3"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_TPREG", 	'',	 	NIL,      NIL,										'"1"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_COMPONE", 	'',	 	NIL,      NIL,										'"2"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_CONSIND", 	'',	 	NIL,      NIL,										'"2"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_DEVPARC", 	'',	 	NIL,      NIL,										'"1"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_OPERGAR", 	'',	 	NIL,      NIL,										'"2"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_INDDET", 	'',	 	NIL,      NIL,										'"2"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_CV139", 	'',	 	NIL,      NIL,										'"2"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_RDBSICM", 	'',	 	NIL,      NIL,										'"1"'})
	aadd (_aSXA, {"SF4", NIL, 		   			"F4_CUSENTR", 	'',	 	NIL,      NIL,										'"2"'})
	
	aadd (_aSXA, {"SF7", NIL, 		   			"F7_UFBUSCA", 	'',	 	NIL,      NIL,										'"1"'})
	
	aadd (_aSXA, {"SF9", NIL, 		   			"F9_CODIGO", 	'',	 	NIL,      NIL,										'GetSx8Num("SF9","F9_CODIGO")'})
	aadd (_aSXA, {"SF9", NIL, 		   			"F9_BAIXAPR", 	'',	 	NIL,      NIL,										'"0"'})
	
	aadd (_aSXA, {"SFA", NIL, 		   			"FA_BAIXAPR", 	'',	 	NIL,      NIL,										'"0"'})
	
	aadd (_aSXA, {"SG2", NIL, 		   			"G2_OPERAC", 	'',	 	NIL,      NIL,										'Soma1(aCols[n-1,nPosOper],2)'})
	
	aadd (_aSXA, {"SL1", NIL, 		   			"L1_NUM", 		'',	 	NIL,      NIL,										'GetSx8Num("SL1")'})
	
	aadd (_aSXA, {"SL2", NIL, 		   			"L2_LOCAL",		'',	 	NIL,      NIL,										'"10"'})
	aadd (_aSXA, {"SL2", NIL, 		   			"L2_TES",		'',	 	NIL,      NIL,										'"526"'})
	
	//Ativos > Industrial
	//             Arq    Pasta         Campo        X3_WHEN    F3        VldUser     Inicializador Padrao
	aadd (_aSXA, {"SN1", "Industrial", "N1_VAZX541", '',        "ZX541",  'Vazio() .Or. U_ExistZX5("41",M->N1_VAZX541)',         NIL})
	aadd (_aSXA, {"SN1", "Industrial", "N1_VAZX542", '',        "ZX542",  'Vazio() .Or. U_ExistZX5("41",M->N1_VAZX542)',         NIL})
	aadd (_aSXA, {"SN1", "Industrial", "N1_VAZX543", '',        "ZX543",  'Vazio() .Or. U_ExistZX5("41",M->N1_VAZX543)',         NIL})
	aadd (_aSXA, {"SN1", "Industrial", "N1_VAZX544", '',        "ZX544",  'Vazio() .Or. U_ExistZX5("41",M->N1_VAZX544)',         NIL})
	
	aadd (_aSXA, {"SU7", NIL, 		   			"U7_COD", 		'',	 	NIL,      NIL,										'IIF(INCLUI,GETSX8NUM("SU7","U7_COD"),"")'})
	
	aadd (_aSXA, {"SU9", NIL, 		   			"U9_CODIGO",	'',	 	NIL,      NIL,										'GetSx8Num("SU9","U9_CODIGO")'})
	aadd (_aSXA, {"SU9", NIL, 		   			"U9_VALIDO",	'',	 	NIL,      NIL,										'"1"'})
	aadd (_aSXA, {"SU9", NIL, 		   			"U9_DESCASS",	'',	 	NIL,      NIL,										'If(!INCLUI,Posicione("SX5",1,xFilial("SX5")+ "T1" + SU9->U9_ASSUNTO,"X5_DESCRI"),"")'})
	
	aadd (_aSXA, {"DA0", NIL,                   "DA0_CODTAB", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_DESCRI", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_DATDE ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_HORADE", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_DATATE", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_HORATE", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_CONDPG", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_ATIVO ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_TPHORA", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_PVCOND", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_DESC  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_FATOR ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_ICMS  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_COMIS ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_FRETE ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_CUSTFX", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_LUCRO ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_RAPEL ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_OUTROS", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_VACMEM", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_VAUF  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_VATPFR", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_FILPUB", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_CODPUB", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA0", NIL,                   "DA0_VACME2", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})

	aadd (_aSXA, {"DA1", NIL,                   "DA1_FILIAL ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_ITEM   ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_CODTAB ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_CODPRO ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_CUSPRO ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_CUSPR  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_PRCVEN ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_PVMINI ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_PVUNIT ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_CUSTFX ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_PVCONC ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_PVUNI2 ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_ICMS   ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_IPI    ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_COMIS  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_COMMIN ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_FRETE2 ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_LUCRO  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_RAPEL  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_OUTROS ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_PVMERC ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_LINHA  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_PVCOND ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_DESCON ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_VLRDES ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_PERDES ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_ATIVO  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_FRETE  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_ESTADO ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_TPOPER ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_QTDLOT ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_INDLOT ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_MOEDA  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_DATVIG ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_DESCR2 ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_GRUPO  ", "U_ZZUVL ('016', __CUSERID, .F.)", 'SBM', '',				NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_REFGRD ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_PRCMAX ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_VAST   ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_ITEMGR ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_DOC    ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_SERIE  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_EMISS  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_CLIENT ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_LOJA   ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_NOMCLI ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_PEREAJ ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_CANAL  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_SEGATI ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_VALNF  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_DTUMOV ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_HRUMOV ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_USERGI ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_USERGA ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_MSEXP  ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})
	aadd (_aSXA, {"DA1", NIL,                   "DA1_HREXPO ", "U_ZZUVL ('016', __CUSERID, .F.)", '', '',					NIL})

	//            Arq    Pasta                  Campo         X3_WHEN                            F3     VldUser				Inicializador Padrao
	aadd (_aSXA, {"NNR", NIL,                   "NNR_CODIGO", "U_ZZUVL ('069', __CUSERID, .F.)", '',    '',					NIL})
	aadd (_aSXA, {"NNR", NIL,                   "NNR_DESCRI", "U_ZZUVL ('069', __CUSERID, .F.)", '',    '',					NIL})
	aadd (_aSXA, {"NNR", NIL,                   "NNR_CTRAB ", "U_ZZUVL ('069', __CUSERID, .F.)", '',    '',					NIL})
	aadd (_aSXA, {"NNR", NIL,                   "NNR_INTP  ", "U_ZZUVL ('069', __CUSERID, .F.)", '',    '',					NIL})
	aadd (_aSXA, {"NNR", NIL,                   "NNR_TIPO  ", "U_ZZUVL ('069', __CUSERID, .F.)", '',    '',					NIL})
	aadd (_aSXA, {"NNR", NIL,                   "NNR_MRP   ", "U_ZZUVL ('069', __CUSERID, .F.)", '',    '',					NIL})
	aadd (_aSXA, {"SGQ", NIL,                   "GQ_USER   ", "U_ZZUVL ('069', __CUSERID, .F.)", 'USR', '',					NIL})
	aadd (_aSXA, {"SGQ", NIL,                   "GQ_GRPUSER", "U_ZZUVL ('069', __CUSERID, .F.)", 'GRP', '',					NIL})
	aadd (_aSXA, {"SGQ", NIL,                   "GQ_PRODUTO", "U_ZZUVL ('069', __CUSERID, .F.)", 'SB1', '',					NIL})
	aadd (_aSXA, {"SGQ", NIL,                   "GQ_GRPPROD", "U_ZZUVL ('069', __CUSERID, .F.)", 'SBM', '',					NIL})

	sxa -> (dbsetorder (1))
	for _nSXA = 1 to len (_aSXA)

		// Varre o SXA por que nao tem indice pelo nome da pasta.
		_sFolder = ''
		if ! empty (_aSXA [_nSXA, 2])
			_sUltFold = '0'
			sxa -> (dbseek (_aSXA [_nSXA, 1], .T.))
			do while ! sxa -> (eof ()) .and. sxa -> xa_alias == _aSXA [_nSXA, 1]
				if upper (alltrim (sxa -> xa_descric)) == upper (alltrim (_aSXA [_nSXA, 2]))
					_sFolder = sxa -> xa_ordem
					exit
				endif
				_sUltFold = sxa -> xa_ordem
				sxa -> (dbskip ())
			enddo
			if empty (_sFolder)
				u_log ('Criando SXA para:', _aSXA [_nSXA, 1], _aSXA [_nSXA, 2])
				reclock ("SXA", .T.)
				sxa -> xa_alias   = _aSXA [_nSXA, 1]
				sxa -> xa_ordem   = soma1 (_sUltFold)
				sxa -> xa_descric = _aSXA [_nSXA, 2]
				sxa -> xa_descspa = _aSXA [_nSXA, 2]
				sxa -> xa_desceng = _aSXA [_nSXA, 2]
				sxa -> xa_propri  = 'U'
				msunlock ()
				_sFolder = sxa -> xa_ordem
			endif
		endif
		
		
		// Agora tenho o folder onde o campo vai ficar.
		//u_log ('folder:', _sFolder)
		sx3 -> (dbsetorder (2))
		_aSXA [_nSXA, 3] = U_TamFixo (_aSXA [_nSXA, 3], 10, ' ')
		if sx3 -> (dbseek (_aSXA [_nSXA, 3], .F.))
			if sx3 -> x3_arquivo != _aSXA [_nSXA, 1]
				u_help ('Inconsistencia na array de campos: alias ' + _aSXA [_nSXA, 1] + ' incompativel com campo ' + _aSXA [_nSXA, 3])
			else
				if alltrim (sx3 -> x3_folder) != alltrim (_sFolder) .and. _aSXA [_nSXA, 2] != NIL
					u_log ('Alterando folder do campo', sx3 -> x3_campo, 'de', sx3 -> x3_folder, 'para', _sFolder)
					reclock ("SX3", .F.)
					sx3 -> x3_folder = _sFolder
					msunlock ()
				endif
				if valtype (_aSXA [_nSXA, 5]) != 'U' .and. alltrim (sx3 -> x3_f3) != alltrim (_aSXA [_nSXA, 5])
					U_GrvAviso ('A', 'grpTI', 'Alterando F3 do campo ' + sx3 -> x3_campo + ' de ' + sx3 -> x3_f3 + ' para ' + _aSXA [_nSXA, 5])
					reclock ("SX3", .F.)
					sx3 -> x3_f3 = _aSXA [_nSXA, 5]
					msunlock ()
				endif
				if valtype (_aSXA [_nSXA, 6]) != 'U' .and. alltrim (sx3 -> x3_vlduser) != alltrim (_aSXA [_nSXA, 6])
					U_GrvAviso ('A', 'grpTI', 'Alterando F3_VLDUSER do campo ' + sx3 -> x3_campo + ' de ' + alltrim (sx3 -> x3_vlduser) + ' para ' + _aSXA [_nSXA, 6])
					reclock ("SX3", .F.)
					sx3 -> x3_vlduser = _aSXA [_nSXA, 6]
					msunlock ()
				endif
				// altera inicializador padrao
				if valtype (_aSXA [_nSXA, 7]) != 'U' .and. alltrim (sx3 -> x3_relacao) != alltrim (_aSXA [_nSXA, 7])
					U_GrvAviso ('A', 'grpTI', 'Alterando F3_RELACAO do campo ' + sx3 -> x3_campo + ' de ' + alltrim (sx3 -> x3_relacao) + ' para ' + _aSXA [_nSXA, 7])
					reclock ("SX3", .F.)
					sx3 -> x3_relacao = _aSXA [_nSXA, 7]
					msunlock ()
				endif
			endif
		else
			u_help ('Nao encontrei o campo no SX3:' + _aSXA [_nSXA, 3])
		endif
	next
return


/*
// --------------------------------------------------------------------------
// Cria / altera consultas no SXB
static function _SXB ()
	local _aSXB := {}
	local _nSXB := 0

	// Chamadas de customizacoes
	//            Nome     Descricao               XB_CONTEM, ExecBlock                                                             Retorno
	aadd (_aSXB, {'ZX525', 'Cod.Sisdeclara F.05 ', 'ZX5',     'U_F3ZX5 ("25")',                                                     'zx5 -> zx5_25cod'})
	aadd (_aSXB, {'ZX526', 'Cod.Sisdeclara F.06 ', 'ZX5',     'U_F3ZX5 ("26")',                                                     'zx5 -> zx5_26cod'})
	aadd (_aSXB, {'ZX527', 'Cod.Sisdeclara F.07 ', 'ZX5',     'U_F3ZX5 ("27")',                                                     'zx5 -> zx5_27cod'})
	aadd (_aSXB, {'ZX528', 'Cod.Sisdeclara F.09 ', 'ZX5',     'U_F3ZX5 ("28")',                                                     'zx5 -> zx5_28cod'})
	aadd (_aSXB, {'ZX529', 'Cod.Sisdeclara F.10 ', 'ZX5',     'U_F3ZX5 ("29")',                                                     'zx5 -> zx5_29cod'})
	aadd (_aSXB, {'ZX530', 'Cod.Sisdeclara F.11 ', 'ZX5',     'U_F3ZX5 ("30")',                                                     'zx5 -> zx5_30cod'})
	aadd (_aSXB, {'ZX531', 'Cod.Sisdeclara F.12 ', 'ZX5',     'U_F3ZX5 ("31")',                                          'zx5 -> zx5_31cod'})
	aadd (_aSXB, {'ZX532', 'Classes Sisdeclara  ', 'ZX5',     'U_F3ZX5 ("32")',                                          'zx5 -> zx5_32cod'})
	aadd (_aSXB, {'ZX533', 'Especies Sisdeclara ', 'ZX5',     'U_F3ZX5 ("33")',                                          'zx5 -> zx5_33cod'})
	aadd (_aSXB, {'ZX534', 'Tipos prd.Sisdeclara', 'ZX5',     'U_F3ZX5 ("34")',                                          'zx5 -> zx5_34cod'})
	aadd (_aSXB, {'ZX535', 'Embalag. Sisdeclara ', 'ZX5',     'U_F3ZX5 ("35")',                                          'zx5 -> zx5_35cod'})
//	aadd (_aSXB, {'ZX536', 'Subnucleos de assoc.', 'ZX5',     'U_F3ZX5 ("36","left(ZX5_36COD,2)=='"+M->ZAN_NUCLEO+"'")', 'zx5 -> zx5_36cod'})
	aadd (_aSXB, {'ZX537', 'Cod.Sisdeclara F.08 ', 'ZX5',     'U_F3ZX5 ("37")',                                                     'zx5 -> zx5_37cod'})
	aadd (_aSXB, {'ZX538', 'Grupos lista preco  ', 'ZX5',     'U_F3ZX5 ("38")',                                                     'zx5 -> zx5_38cod'})
	aadd (_aSXB, {'ZX539', 'Linhas comerciais   ', 'ZX5',     'U_F3ZX5 ("39")',                                                     'zx5 -> zx5_39cod'})
	aadd (_aSXB, {'ZX540', 'Marcas comerciais   ', 'ZX5',     'U_F3ZX5 ("40")',                                                     'zx5 -> zx5_40cod'})
	aadd (_aSXB, {'ZX541', 'Class. de Maquinas  ', 'ZX5',     'U_F3ZX5 ("41")',                                                     'zx5 -> zx5_41cod'})
	aadd (_aSXB, {'ZX542', 'Tipos de Máquinas   ', 'ZX5',     'U_F3ZX5 ("42")',                                                     'zx5 -> zx5_42cod'})
	aadd (_aSXB, {'ZX543', 'Categorias Máquinas ', 'ZX5',     'U_F3ZX5 ("43")',                                                     'zx5 -> zx5_43cod'})
	aadd (_aSXB, {'ZX544', 'Grupos de Máquinas  ', 'ZX5',     'U_F3ZX5 ("44")',                                                     'zx5 -> zx5_44cod'})
	aadd (_aSXB, {'ZX549', 'Impressoras etiq.   ', 'ZX5',     'U_F3ZX5 ("49")',                                                     'zx5 -> zx5_49cod'})
	aadd (_aSXB, {'ZX550', 'Grupo Embalagens.   ', 'ZX5',     'U_F3ZX5 ("50")',                                                     'zx5 -> zx5_50cod'})

	// Ajusta tamanho da chave para que o dbseek encontre o registro.
	for _nSXB = 1 to len (_aSXB)
		_aSXB [_nSXB, 1] = left (alltrim (_aSXB [_nSXB, 1]) + '      ', 6)
	next

	sxb -> (dbsetorder (1))  // xb_alias + xb_tipo + xb_seq + xb_coluna
	for _nSXB = 1 to len (_aSXB)
		u_Log ('Verificando SXB para alias ' + _aSXB [_nSXB, 1])
		reclock ("SXB", ! sxb -> (dbseek (_aSXB [_nSXB, 1] + '1', .F.)))
		sxb -> xb_alias   = _aSXB [_nSXB, 1]
		sxb -> xb_tipo    = '1'
		sxb -> xb_seq     = '01'
		sxb -> xb_coluna  = 'RE'
		sxb -> xb_descri  = _aSXB [_nSXB, 2]
		sxb -> xb_descspa = _aSXB [_nSXB, 2]
		sxb -> xb_desceng = _aSXB [_nSXB, 2]
		sxb -> xb_contem  = _aSXB [_nSXB, 3]
		msunlock ()
		reclock ("SXB", ! sxb -> (dbseek (_aSXB [_nSXB, 1] + '2', .F.)))
		sxb -> xb_alias  = _aSXB [_nSXB, 1]
		sxb -> xb_tipo   = '2'
		sxb -> xb_seq    = '01'
		sxb -> xb_coluna = '01'
		sxb -> xb_contem = _aSXB [_nSXB, 4]
		msunlock ()
		reclock ("SXB", ! sxb -> (dbseek (_aSXB [_nSXB, 1] + '5', .F.)))
		sxb -> xb_alias  = _aSXB [_nSXB, 1]
		sxb -> xb_tipo   = '5'
		sxb -> xb_seq    = '01'
		sxb -> xb_contem = _aSXB [_nSXB, 5]
		msunlock ()
	next

	// Setor financeiro solicita que a consulta de bancos filtre os bloueados.
	sxb -> (dbsetorder (1))  // xb_alias + xb_tipo + xb_seq + xb_coluna
	if ! sxb -> (dbseek ("SA6   601", .F.)) .or. alltrim (upper (sxb -> xb_contem)) != 'SA6->A6_BLOCKED <> "1"'
		u_log ('Filtrando bancos bloqueados na consulta SA6')
		reclock ("SXB", .t.)
		sxb -> xb_alias   = 'SA6'
		sxb -> xb_tipo    = '6'
		sxb -> xb_seq     = '01'
		sxb -> xb_contem  = 'SA6->A6_BLOCKED <> "1"'
		msunlock ()
	endif

	// Chamadas de consultas que nao usam customizacoes.
	//            Nome     Descricao               XB_CONTEM, ExecBlock                                                             Retorno
//	aadd (_aSXB, {'SBFZAG', 'Tanques com saldo',   'ZX5',     'U_F3ZX5 ("25")',                                                     'zx5 -> zx5_25cod'})
return
*/


// --------------------------------------------------------------------------
static function _X3When ()
	local _aCampos   := {}
	local _nCampo    := 0
	local _sNovoWhen := ""

	aadd (_aCampos, {"A3_COD    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_NOME   ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_ATIVO  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_END    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_MUN    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_CEP    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_EST    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_BCO1   ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_REGIAO ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_GERASE2", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_COMIS  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_TELEX  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_INSCRM ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_INSCR  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_SALDO  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_FRETE  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_ICM    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_IPI    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_ALBAIXA", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_ACREFIN", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_TIPO   ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_ALEMISS", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_GEREN  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_PERDESC", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_EMAIL  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_HPAGE  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_SUPER  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_DIA    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_DDD    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_CLIFIM ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_CLIINI ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_LOCARQ ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_MENS1  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_MENS2  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_PEDFIM ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_PEDINI ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_PROXCLI", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_PROXPED", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_SENHA  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_GRPREP ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_ISS    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_GRPCOM ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_FAT_RH ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_GRUPSAN", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_DEPEND ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_PEN_ALI", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_TIPVEND", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_OK     ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_DDDTEL ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_VAGEREN", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_VACLOUT", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_VAEXTAB", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_TIPSUP ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_UNIDAD ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_HAND   ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_QTCONTA", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_REGSLA ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_CARGO  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_URLEXG ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_PAIS   ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_DDI    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_CEL    ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_ADMISS ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_VAUSER ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_NVLSTR ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_NIVEL  ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	aadd (_aCampos, {"A3_INDENIZ", "U_ZZUVL ('046', __CUSERID, .F.)"})
	
	// cadastro de clientes
	aadd (_aCampos, {"A3_VAMUDOU", "U_ZZUVL ('036', __CUSERID, .F.)"})

	//aadd (_aCampos, {"B1_UM",      "inclui"})
	aadd (_aCampos, {"BE_VATANQ",  "inclui"})

	// Libera alteracao de campos cfe. abas.
	sx3 -> (dbsetorder (1))
	sx3 -> (dbseek ("SB1", .T.))
	do while ! sx3 -> (eof ()) .and. sx3 -> x3_arquivo == 'SB1'
		aadd (_aCampos, {sx3 -> x3_campo, "'" + sx3 -> x3_campo + "'$_sCposAlt"})  // Nao usar alltrim no nome do campo, pois nomes curtos cujo inicio eh igual a outros campos seriam considerados erroneamente.
		sx3 -> (dbskip ())
	enddo
	
	// Permissoes para alteracao da tabela de preço
	sx3 -> (dbsetorder (1))
	sx3 -> (dbseek ("DA0", .T.))
	do while ! sx3 -> (eof ()) .and. sx3 -> x3_arquivo == 'DA0'
		aadd (_aCampos, {sx3 -> x3_campo, "U_ZZUVL ('016', __CUSERID, .F.)"}) 
		sx3 -> (dbskip ())
	enddo
	
	sx3 -> (dbsetorder (1))
	sx3 -> (dbseek ("DA1", .T.))
	do while ! sx3 -> (eof ()) .and. sx3 -> x3_arquivo == 'DA1'
		aadd (_aCampos, {sx3 -> x3_campo, "U_ZZUVL ('016', __CUSERID, .F.)"}) 
		sx3 -> (dbskip ())
	enddo
	
	// Atualiza SX3.
	sx3 -> (dbsetorder (2))
	for _nCampo = 1 to len (_aCampos)
		if sx3 -> (dbseek (_aCampos [_nCampo, 1], .F.))
			if ! alltrim (_aCampos [_nCampo, 2]) $ sx3 -> x3_when
				if empty (sx3 -> x3_when)
					_sNovoWhen = _aCampos [_nCampo, 2]
				else
					_sNovoWhen = alltrim (sx3 -> x3_when) + ".and." + _aCampos [_nCampo, 2]
				endif
				if len (_sNovoWhen) > len (sx3 -> x3_when)
					u_help ("Novo conteudo (" + _sNovoWhen + ") nao cabe no campo X3_WHEN do campo '" + sx3 -> x3_campo + "'")
				else
					u_log ('Alterando x3_when do campo', sx3 -> x3_campo, 'de', sx3 -> x3_when, 'para', _sNovoWhen)
					reclock ("SX3", .F.)
					sx3 -> x3_when = _sNovoWhen
					msunlock ()
				endif
			endif
		endif
	next
	
	// exclui registro da SX5 tabela T3 - registro que vem como padrão, mas que a gente não usa
	  
   	_sSQL := ""
   	_sSQL += " UPDATE SX5010"
   	_sSQL += "    SET D_E_L_E_T_ = '*'"    
   	_sSQL += "  WHERE D_E_L_E_T_ = ''"
   	_sSQL += "    AND X5_TABELA  = 'T3'"
   	_sSQL += "    AND X5_CHAVE NOT LIKE '%.%'"
	if TCSQLExec (_sSQL) < 0
		u_showmemo(_sSQL)
		return
	endif
	
return
