User Function LeCOM ()
	local _sLeitura  := ""
	local _nHdl      := 2
	msgalert ("Iniciando programa " + procname ())

	if MsOpenPort (_nHdl, "COM1:4800,n,8,1", .F.)
		msgalert ("Conseguiu abrir a porta")
		MSRead (_nHdl, @_sLeitura)
		mscloseport (_nHdl)
		msgalert (_sLeitura)
	else
		msgalert ("Nao conseguiu abrir a porta")
	endif
return
