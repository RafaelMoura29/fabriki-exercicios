
PROFILE_WILDFLY_MANAGED="-P wildfly-managed"

mkdir -p src/test/java/
mkdir -p src/main/resources/
mkdir -p src/main/webapp/WEB-INF/lib/

executarEComparar() {
	echo Entrada $2
	java -cp ./target/classes/ $1 < $1_entrada_$2.txt > saida.txt
	diff saida.txt $1_saida_$2.txt
	return $? 
}

executarTestesEntradaESaida() {
	mvn -e -V compile -Dmaven.test.skip=true -Dmaven.javadoc.skip=true;
	if [ "$?" -ne 0 ]; then
		RESULTADO_TESTES=2
		return $RESULTADO_TESTES
	fi
	ARRAY=()
	for ENTRADA in $(ls | grep entrada | cut -d '_' -f 3 | cut -d '.' -f 1)
	do
		executarEComparar $1 $ENTRADA;
		RESULTADO=$?
		if [ $RESULTADO -eq 0 ]; then
			echo CORRETO.
			ARRAY+=($RESULTADO)
		else 
			echo INCORRETO.
		fi
		CONTADOR_EXERCICIOS=$(($CONTADOR_EXERCICIOS+1))
	done
	EXERCICIOS_CORRETOS=${#ARRAY[@]}
}

executarTestesIntegracao() {
	wget https://github.com/mozilla/geckodriver/releases/download/v0.20.1/geckodriver-v0.20.1-linux64.tar.gz;
	tar -xzf geckodriver-v0.20.1-linux64.tar.gz -C .;
	export PATH=$PATH:.;
	xvfb-run mvn clean install verify $PROFILE_WILDFLY_MANAGED;
}

executarTestesUnitarios() {
	mvn compile
	if [ "$?" -ne 0 ]; then
		RESULTADO_TESTES=2
		return $RESULTADO_TESTES
	fi
	mvn test 1> log.txt
	RESULTADO_TESTES=$?
	cat log.txt
	TESTS_RUN=`grep "Tests run" log.txt | tail -1 | cut -d ' ' -f 3,5,7 | sed 's/,//g'`
	ARRAY=($TESTS_RUN)
	CONTADOR_EXERCICIOS=${ARRAY[0]}
	TEST_FAILURES=${ARRAY[1]}
	TEST_ERRORS=${ARRAY[2]}
	EXERCICIOS_CORRETOS=$(($CONTADOR_EXERCICIOS-($TEST_FAILURES+$TEST_ERRORS)))
	return $RESULTADO_TESTES
}
