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
'

echo 'Welcome, please state the following:
	[All the file names you want to prepare]'

read -a molecules

echo 'Now, all the methods you want to use [b3lyp/bhlyp/m062x/mpwb1k/pw6b95/wb97x]'

read -a methods 

echo 'Type the basis sets you want to use [Use the specific keyword]'

read -a basis

echo 'Enter charge and multiplicity. [C M]'

read mult

echo 'If you want CCSD(T) single point calculation, state the method, else type "n" [method//n]'

read -a ccsdt

echo 'Do you want to optimize only, or add frequencies? [opt/optfreq/ts]?'

read optimization

echo 'Do you want to include dispersion?(y/n)'

read dispersion

echo 'How many processors do you want to use?'

read processor

#This function makes the required changes for the files
function SED_FUNCTION () {
	sed -i 's/PROCESSOR/'${processor}'/g' ${mol}_${method}.${base}
	sed -i 's/MEMORY/'${memory}'/g' ${mol}_${method}.${base}
	sed -i 's/NAME/'${mol}'/g' ${mol}_${method}.${base}
	sed -i "s/MULTIPLICITY/${mult}/g" ${mol}_${method}.${base}
	sed -i "s/TITLE/Optimization of ${mol} in ${method}/g" ${mol}_${method}.${base}
	sed -i "s/TITULO/Single Point of ${mol} in CCSD(T)/g" ${mol}_${method}.${base}
	sed -i "s/BASIS/${basisset}/g" ${mol}_${method}.${base}
	sed -i "s/FILE/${mol}_${method}.${base}/g" ${mol}_${method}.${base}
}

#This converts the filename that includes parenthesis into a readable filename
function BASIS_NAME () {
	if [[ "$basisset" == '6-311++G(d,p)' ]];then
		base=6311G
	elif [[ "$basisset" == 'aug-cc-PVTZ' ]];then
		base=augccPVTZ
	else
		base=${basisset}
	fi
}

memory=$(($processor*4-3))

#Core of the program
for mol in ${molecules[@]}; do
	for method in ${methods[@]}; do
		for basisset in ${basis[@]}; do
			for ccsd in ${ccsdt[@]}; do
				BASIS_NAME
				cp /home/jaluque/Utilities/INPUT_Gaussian ${mol}_${method}.${base}
	
				if [[ "$method" == bhlyp ]];then
					if [[ "$optimization" == opt ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${mol}_${method}.${base}
						SED_FUNCTION
						
					elif [[ "$optimization" == optfreq ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/BHandHLYP/g" ${mol}_${method}.${base}
						
					elif [[ "$optimization" == ts ]];then
						sed -i "s/OPTIMIZATION/opt\=(ts,calcfc,noeigentest,addredundant) int\=ultrafine/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/BHandHLYP/g" ${mol}_${method}.${base}
					fi
					
					if [[ "$method" == "$ccsd" ]];then
						cat /home/jaluque/Utilities/CCSDT_SP >> ${mol}_${method}.${base}
						SED_FUNCTION
					fi
					
					if [[ "$dispersion" == y ]];then
						sed -i "s/DISPERSION/IOp(3\/124\=40) IOp(3\/174\=1000000, 3\/175\=1035400, 3\/177\=279300, 3\/178\=4961500)/g" ${mol}_${method}.${base}
					else
						sed -i "s/DISPERSION//g" ${mol}_${method}.${base}
					fi
					dos2unix ${mol}_${method}.${base}
		
				elif [[ "$method" == m062x ]];then
					if [[ "$optimization" == opt ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${mol}_${method}.${base}
						SED_FUNCTION
						
					elif [[ "$optimization" == optfreq ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/M062X/g" ${mol}_${method}.${base}
		
					elif [[ "$optimization" == ts ]];then
						sed -i "s/OPTIMIZATION/opt\=(ts,calcfc,noeigentest,addredundant) int\=ultrafine/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/M062X/g" ${mol}_${method}.${base}
					fi
					
					if [[ "$method" == "$ccsd" ]];then
						cat /home/jaluque/Utilities/CCSDT_SP >> ${mol}_${method}.${base}
						SED_FUNCTION
					fi
					
					if [[ "$dispersion" == y ]];then
								sed -i "s/DISPERSION/IOp(3\/124\=30) IOp(3\/174\=1000000, 3\/175\=0000000, 3\/176\=1619000)/g" ${mol}_${method}.${base}
					else
						sed -i "s/DISPERSION//g" ${mol}_${method}.${base}
					fi
					dos2unix ${mol}_${method}.${base}
					
				elif [[ "$method" == mpwb1k ]];then
					if [[ "$optimization" == opt ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine IOp(3\/76\=0560004400)/g" ${mol}_${method}.${base}
						SED_FUNCTION
						
					elif [[ "$optimization" == optfreq ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine IOp(3\/76\=0560004400)/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/mPWB95/g" ${mol}_${method}.${base}
		
					elif [[ "$optimization" == ts ]];then
						sed -i "s/OPTIMIZATION/opt\=(ts,calcfc,noeigentest,addredundant) int\=ultrafine IOp(3\/76\=0560004400)/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/mPWB95/g" ${mol}_${method}.${base}
					fi
					
					if [[ "$method" == "$ccsd" ]];then
						cat /home/jaluque/Utilities/CCSDT_SP >> ${mol}_${method}.${base}
						SED_FUNCTION
					fi	
					
					if [[ "$dispersion" == y ]];then
						sed -i "s/DISPERSION/IOp(3\/124\=40) IOp(3\/76\=0560004400, 3\/174\=1000000, 3\/175\=949900, 3\/177\=147400, 3\/178\=6622300)/g" ${mol}_${method}.${base}
					else
						sed -i "s/DISPERSION//g" ${mol}_${method}.${base}
					fi
					dos2unix ${mol}_${method}.${base}
	
				elif [[ "$method" == pw6b95 ]];then
					if [[ "$optimization" == opt ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${mol}_${method}.${base}
						SED_FUNCTION
						
					elif [[ "$optimization" == optfreq ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/PW6B95/g" ${mol}_${method}.${base}
						
					elif [[ "$optimization" == ts ]];then
						sed -i "s/OPTIMIZATION/opt\=(ts,calcfc,noeigentest,addredundant) int\=ultrafine freq\=noraman/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/PW6B95/g" ${mol}_${method}.${base}
					fi
					
					if [[ "$method" == "$ccsd" ]];then
						cat /home/jaluque/Utilities/CCSDT_SP >> ${mol}_${method}.${base}
						SED_FUNCTION
					fi
					
					if [[ "$dispersion" == y ]];then
								sed -i "s/DISPERSION/IOp(3\/124\=40) IOp(3\/174\=1000000, 3\/175\=725700, 3\/177\=207600, 3\/178\=6375000)/g" ${mol}_${method}.${base}
					else
						sed -i "s/DISPERSION//g" ${mol}_${method}.${base}
					fi
					dos2unix ${mol}_${method}.${base}
	
				elif [[ "$method" == wb97x ]];then
					if [[ "$optimization" == opt ]];then
						SED_FUNCTION
						sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${mol}_${method}.${base}
	
					elif [[ "$optimization" == optfreq ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/wB97X/g" ${mol}_${method}.${base}

					elif [[ "$optimization" == ts ]];then
						sed -i "s/OPTIMIZATION/opt\=(ts,calcfc,noeigentest,addredundant) int\=ultrafine/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/wB97X/g" ${mol}_${method}.${base}					
					fi
					
					if [[ "$method" == "$ccsd" ]];then
						cat /home/jaluque/Utilities/CCSDT_SP >> ${mol}_${method}.${base}
						SED_FUNCTION
					fi
					
					if [[ "$dispersion" == y ]];then
								sed -i "s/DISPERSION/IOp(3\/124\=30) IOp(3\/174\=1000000, 3\/175\=1000000, 3\/176\=1281000)/g" ${mol}_${method}.${base}
					else
						sed -i "s/DISPERSION//g" ${mol}_${method}.${base}
					fi
					dos2unix ${mol}_${method}.${base}
					
				elif [[ "$method" == b3lyp ]];then
					if [[ "$optimization" == opt ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${mol}_${method}.${base}
						SED_FUNCTION
						
					elif [[ "$optimization" == optfreq ]];then
						sed -i "s/OPTIMIZATION/opt int\=ultrafine/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/B3LYP/g" ${mol}_${method}.${base}
		
					elif [[ "$optimization" == ts ]];then
						sed -i "s/OPTIMIZATION/opt\=(ts,calcfc,noeigentest,addredundant) int\=ultrafine/g" ${mol}_${method}.${base}
						cat /home/jaluque/Utilities/LINKFILE >> ${mol}_${method}.${base}
						SED_FUNCTION
						sed -i "s/METHOD/B3LYP/g" ${mol}_${method}.${base}
					fi
					
					if [[ "$method" == "$ccsd" ]];then
						cat /home/jaluque/Utilities/CCSDT_SP >> ${mol}_${method}.${base}
						SED_FUNCTION
					fi
					
					if [[ "$dispersion" == y ]];then
						sed -i "s/DISPERSION/Empiricaldispersion=GD3BJ/g" ${mol}_${method}.${base}
					else
						sed -i "s/DISPERSION//g" ${mol}_${method}.${base}
					fi
					dos2unix ${mol}_${method}.${base}
					
				else		
					echo "Sorry, the method ${method} is not supported"
					continue
				fi
			rm -rf ${mol}
			done
		done
	done
done

########This section is for PICARD only#########

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
