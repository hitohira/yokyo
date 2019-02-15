test:
	xvlog -sv ftest.sv ../fadd.v fadd_old.v
	xelab ftest -s ftest_sim
	xsim ftest_sim --runall

div:
	xvlog -sv divtest.sv ../div.v
	xelab divtest -s divtest_sim
	xsim divtest_sim --runall

clean:
	rm *.log *.pb *.jou *.dir/ -r
