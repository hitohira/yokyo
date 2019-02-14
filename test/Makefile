test_mul:
	xvlog -sv ftest.sv fadd.v fadd_old.v
	xelab ftest -s ftest_sim
	xsim ftest_sim --runall

clean:
	rm *.log *.pb *.jou *.dir/ -r
