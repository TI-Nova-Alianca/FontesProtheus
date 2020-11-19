User Function LeCOM ()
	local _sLeitura  := ""
	local _nHdl      := 2
	u_help ("Iniciando programa " + procname ())

	if MsOpenPort (_nHdl, "COM1:4800,n,8,1", .F.)
		u_help ("Conseguiu abrir a porta")
		MSRead (_nHdl, @_sLeitura)
		mscloseport (_nHdl)
		u_help (_sLeitura)
	else
		u_help ("Nao conseguiu abrir a porta")
	endif
return
