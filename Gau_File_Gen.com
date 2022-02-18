#! /bin/bash
$SGE_O_WORKDIR

echo ' 


      /$$$$$$   /$$$$$$  /$$   /$$  /$$$$$$   /$$$$$$  /$$$$$$  /$$$$$$  /$$   /$$           
     /$$__  $$ /$$__  $$| $$  | $$ /$$__  $$ /$$__  $$|_  $$_/ /$$__  $$| $$$ | $$           
    | $$  \__/| $$  \ $$| $$  | $$| $$  \__/| $$  \__/  | $$  | $$  \ $$| $$$$| $$           
    | $$ /$$$$| $$$$$$$$| $$  | $$|  $$$$$$ |  $$$$$$   | $$  | $$$$$$$$| $$ $$ $$           
    | $$|_  $$| $$__  $$| $$  | $$ \____  $$ \____  $$  | $$  | $$__  $$| $$  $$$$           
    | $$  \ $$| $$  | $$| $$  | $$ /$$  \ $$ /$$  \ $$  | $$  | $$  | $$| $$\  $$$           
    |  $$$$$$/| $$  | $$|  $$$$$$/|  $$$$$$/|  $$$$$$/ /$$$$$$| $$  | $$| $$ \  $$           
     \______/ |__/  |__/ \______/  \______/  \______/ |______/|__/  |__/|__/  \__/           
                                                                                         
                                                                                         
                                                                                         
    		       /$$$$$$$$ /$$$$$$ /$$       /$$$$$$$$                                                   
		      | $$_____/|_  $$_/| $$      | $$_____/                                                   
		      | $$        | $$  | $$      | $$                                                         
		      | $$$$$     | $$  | $$      | $$$$$                                                      
		      | $$__/     | $$  | $$      | $$__/                                                      
		      | $$        | $$  | $$      | $$                                                         
		      | $$       /$$$$$$| $$$$$$$$| $$$$$$$$                                                   
		      |__/      |______/|________/|________/                                                   
                                                                                         
                                                                                         
                                                                                         
  /$$$$$$  /$$$$$$$$ /$$   /$$ /$$$$$$$$ /$$$$$$$   /$$$$$$  /$$$$$$$$ /$$$$$$  /$$$$$$$ 
 /$$__  $$| $$_____/| $$$ | $$| $$_____/| $$__  $$ /$$__  $$|__  $$__//$$__  $$| $$__  $$
| $$  \__/| $$      | $$$$| $$| $$      | $$  \ $$| $$  \ $$   | $$  | $$  \ $$| $$  \ $$
| $$ /$$$$| $$$$$   | $$ $$ $$| $$$$$   | $$$$$$$/| $$$$$$$$   | $$  | $$  | $$| $$$$$$$/
| $$|_  $$| $$__/   | $$  $$$$| $$__/   | $$__  $$| $$__  $$   | $$  | $$  | $$| $$__  $$
| $$  \ $$| $$      | $$\  $$$| $$      | $$  \ $$| $$  | $$   | $$  | $$  | $$| $$  \ $$
|  $$$$$$/| $$$$$$$$| $$ \  $$| $$$$$$$$| $$  | $$| $$  | $$   | $$  |  $$$$$$/| $$  | $$
 \______/ |________/|__/  \__/|________/|__/  |__/|__/  |__/   |__/   \______/ |__/  |__/


			Created by Jesús Antonio Luque Urrutia
			     ORCID: 0000-0002-4695-5676
      WEBPAGE: https://portalrecerca.uab.cat/en/persons/jesús-antonio-luque-urrutia

				       VER: 1.0
'
###################################################################################################

# Author notes: In order to use this program, we need the files "INPUT_Gaussian", "LINKFILE", "FREQFILE" and "CCSDT_SP" in the same directory as this program file. I recommend to see them before using the program to ensure that it is according to your expectations.

###################################################################################################

############ THIS SECTION REFERS TO THE USER INPUTS ############

echo 'Welcome, please state the following:
	[All the file names you want to prepare]'

read -a molecules

echo 'Now, all the methods you want to use [b3lyp/bhlyp/m062x/mpwb1k/pw6b95/wb97x]'

read -a methods 

echo 'Type the basis sets you want to use [Use the specific keyword/aug-cc-PVTZ for SP CCSD(T)]'

read -a basis

echo 'Enter charge and multiplicity. [C M]'

read mult

echo 'Do you want to optimize only, opt + frequencies, TS optimization, or frequencioes only? [opt/optfreq/ts/freq]?'

read optimization

if [[ "$optimization" == optfreq || "$optimization" == opt || "$optimization" == ts ]];then
	echo 'If you want CCSD(T) single point calculation [aug-cc-PVTZ required], state the method, else type "n" [method//n]'
	read -a ccsdt
fi

if [[ "$optimization" == optfreq || "$optimization" == freq || "$optimization" == ts ]];then
	echo 'Do you want to choose the temperature and pressure of the frequency calculation? [y/n]'
	read prestemp
	
	if [[ "$prestemp" == y ]];then
		echo 'Select the temperature in K:'
		read TEMP
		echo 'Select the pressure in atm:'
		read PRES
	fi
fi

echo 'Do you want to include dispersion?(y/n)'

read dispersion

echo 'How many processors do you want to use?'

read processor

###################################################################################################
###################################################################################################

#### Internal variables. You may change them to adapt the outcome of the program ####
	
	#Directory where the main files are located.
		MAINPATH=/home/jaluque/Utilities

	#This sets up the memory of the program according to the Nº of cores. Change at will.
		memory=$(($processor*4-3))

###################################################################################################
###################################################################################################

#### This section is dedicated for the general functions of the program. Check them in case you want to add dispersion or functionals to the program. Beware to include them in the loop of the program #####

	#Generated files format. Please use the variables "mol", "method" and "base" as you see fit.
	function FILENAME (){
		FILEINPUT="${mol}_${method}.${base}"
	}

	#This function makes the required changes for the files.
	function SED_FUNCTION () {
		sed -i 's/PROCESSOR/'${processor}'/g' ${FILEINPUT}
		sed -i 's/MEMORY/'${memory}'/g' ${FILEINPUT}
		sed -i 's/NAME/'${mol}'/g' ${FILEINPUT}
		sed -i "s/MULTIPLICITY/${mult}/g" ${FILEINPUT}
		sed -i "s/TITLE/Optimization of ${mol} in ${method}/g" ${FILEINPUT}
		sed -i "s/TITULO/Single Point of ${mol} in CCSD(T)/g" ${FILEINPUT}
		sed -i "s/BASIS/${basisset}/g" ${FILEINPUT}
		sed -i "s/FILE/${mol}_${method}.${base}/g" ${FILEINPUT}
		sed -i "s/METHOD/${functional}/g" ${FILEINPUT}
	}

	#This converts the filename that includes parenthesis and other symbols into a readable filename. It transforms "basiset" from the user input into the variable "base".
	function BASIS_NAME () {
		if [[ "$basisset" == '6-311++G(d,p)' ]];then
			base=6-311G
		
		elif [[ "$basisset" == 'aug-cc-PVTZ' ]];then
			base=augccPVTZ
		
		else
			base=${basisset}
		
		fi
	}

	#This checks for ccsdt request and applies it
	function CCSDT () {
		for ccsd in ${ccsdt[@]}; do
			if [[ "$method" == "$ccsd" ]];then
				if [[ "$base" == augccPVTZ ]];then
					cat ${MAINPATH}/CCSDT_SP >> ${FILEINPUT}
					SED_FUNCTION
				fi
			fi
		done
	}

	#This function defines both the pressure and the temperature for the frequency calculation
	function TEMPPRES () {
		if [[ "$prestemp" == y ]];then
			sed -i "s/TEMP/Temperature=${TEMP}/g" ${FILEINPUT}
			sed -i "s/PRESS/Pressure=${PRES}/g" ${FILEINPUT}
		
		else 
			sed -i "s/PRESS TEMP//g" ${FILEINPUT}
		
		fi
	}

	#This function begins the loop of the optimization process
	function OPTIMIZATION () {
		if [[ "$optimization" == opt ]];then
			sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${FILEINPUT}
			SED_FUNCTION
	
		elif [[ "$optimization" == optfreq ]];then
			sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${FILEINPUT}
			cat ${MAINPATH}/LINKFILE >> ${FILEINPUT}
			SED_FUNCTION
			TEMPPRES

		elif [[ "$optimization" == ts ]];then
			sed -i "s/OPTIMIZATION/opt\=(ts,calcfc,noeigentest,addredundant) int\=ultrafine/g" ${FILEINPUT}
			cat ${MAINPATH}/LINKFILE >> ${FILEINPUT}
			SED_FUNCTION
			TEMPPRES

		elif [[ "$optimization" == freq ]];then
			cp ${MAINPATH}/FREQFILE ${FILEINPUT}
			SED_FUNCTION
			TEMPPRES
	
		fi
	}

	#This function includes the dispersion of each functional
	function DISPERSION () {
		if [[ "$dispersion" == y ]];then
			if [[ "${functional}" == BHandHLYP ]];then
				sed -i "s/DISPERSION/IOp(3\/124\=40) IOp(3\/174\=1000000, 3\/175\=1035400, 3\/177\=279300, 3\/178\=4961500)/g" ${FILEINPUT}

			elif [[ "${functional}" == M062X ]];then
				sed -i "s/DISPERSION/IOp(3\/124\=30) IOp(3\/174\=1000000, 3\/175\=0000000, 3\/176\=1619000)/g" ${FILEINPUT}
	
			elif [[ "${functional}" == mPWB95 ]];then
				sed -i "s/DISPERSION/IOp(3\/124\=40) IOp(3\/76\=0560004400, 3\/174\=1000000, 3\/175\=949900, 3\/177\=147400, 3\/178\=6622300)/g" ${FILEINPUT}
	
			elif [[ "${functional}" == PW6B95 ]];then
				sed -i "s/DISPERSION/IOp(3\/124\=40) IOp(3\/174\=1000000, 3\/175\=725700, 3\/177\=207600, 3\/178\=6375000)/g" ${FILEINPUT}

			elif [[ "${functional}" == wB97X ]];then
				sed -i "s/DISPERSION/IOp(3\/124\=30) IOp(3\/174\=1000000, 3\/175\=1000000, 3\/176\=1281000)/g" ${FILEINPUT}
			
			elif [[ "${functional}" == B3LYP ]];then
				sed -i "s/DISPERSION/Empiricaldispersion=GD3BJ/g" ${FILEINPUT}
		
			fi

		else
			sed -i "s/DISPERSION//g" ${FILEINPUT}
		
		fi
	}

	# This function is the main loop of the program
	function RUNPROGRAM () {
		OPTIMIZATION
                CCSDT
                DISPERSION
                dos2unix ${FILEINPUT}
	}


########################################################################################################
########################################################################################################
########################################################################################################

############ CORE OF THE PROGRAM  ############

for mol in ${molecules[@]}; do
	for method in ${methods[@]}; do
		for basisset in ${basis[@]}; do
				BASIS_NAME
				FILENAME
				cp ${MAINPATH}/INPUT_Gaussian ${FILEINPUT}
	
				if [[ "$method" == bhlyp ]];then
					functional=BHandHLYP			
					RUNPROGRAM	
				elif [[ "$method" == m062x ]];then
					functional=M062X
					RUNPROGRAM
				elif [[ "$method" == mpwb1k ]];then
					functional=mPWB95	
					RUNPROGRAM
				elif [[ "$method" == pw6b95 ]];then
					functional=PW6B95
					RUNPROGRAM
				elif [[ "$method" == wb97x ]];then
					functional=wB97X
					RUNPROGRAM
				elif [[ "$method" == b3lyp ]];then
					functional=B3LYP
					RUNPROGRAM
				else		
					echo "Sorry, the method ${method} is not supported"
					continue
				fi
			rm -rf ${mol}
		done
	done
done


########################################################################################################
########################################################################################################
########################################################################################################


########This section is for PICARD only. It has not been revised accordingly to the changes of the main program. Review before enabling it #########

#echo 'Do you have the xyz files ready?(y/n)'
#read input

#if [[ "$input" == y ]];then
#	echo 'Do you want to send all files to queue?(y/n)'
#	read answer
#	if [[ "$answer" == y ]];then
#		echo 'Select borg [1-4]'
#		read borg
#		if [[ "$borg" == 1 ]];then
#			for mol in ${molecules[@]}; do
#				for method in ${methods[@]}; do
#					g16.py -q borg1 -n "${processor}" -c "${mol}_${method}" "${mol}_${method}".log
#				done
#			done
#		elif [[ "$borg" == 2 ]];then
#                       for mol in ${molecules[@]}; do
#				for method in ${methods[@]}; do
#                                	g16.py -q borg2 -n "${processor}" -c "${mol}_${method}" "${mol}_${method}".log
#				done
#			done
#		elif [[ "$borg" == 3 ]];then
#                        for mol in ${molecules[@]}; do
#				for method in ${methods[@]}; do
#                        	        g16.py -q borg3 -n "${processor}" -c "${mol}_${method}" "${mol}_${method}".log
#				done
# 			done
# 		elif [[ "$borg" == 4 ]];then
#                        for mol in ${molecules[@]}; do
#				for method in ${methods[@]}; do
#                                	g16.py -q borg4 -n "${processor}" -c "${mol}_${method}" "${mol}_${method}".log
#				done
#			done
#		else
#			echo 'Sorry, that queue is not supported'
#		fi
#	else
#		echo 'Files not sent'
#	fi
#else
	echo 'Ending the program...'
#fi

echo 'Your files are ready!'
