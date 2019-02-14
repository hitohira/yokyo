test:
	xvlog -sv ftest.sv ../fdiv.v fdiv_old.v
	xelab ftest -s ftest_sim
	xsim ftest_sim --runall

clean:
	rm *.log *.pb *.jou *.dir/ -r
