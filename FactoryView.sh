#!/bin/bash

#########################
#### Help Menu Here ####
#########################
while getopts ":hd" opt; do
   case ${opt} in
      h) 
         echo "Usage: FactoryView [options]"
			echo "Usage: FactoryView -d  (To run debug mode)"
         echo "Usage: FactoryView -h  (To get this help menu)"
         exit 0
         ;;
		d)
			debug="yes"
			;;
      \?) echo "Invalid Option: -$OPTARG"
         exit 1
         ;;
   esac
done
shift $((OPTIND -1))

#########################

function Variable_Initialization {
	if [ "${debug}" != "yes" ];then
		debug="no"
	fi
	#############################
	# Source file and grid size #
	#############################
	FVfilename="/home/brcre/Documents/Factory_View/FactoryView_Project.csv"  ;#Location of source data
	declare -i FVrows=0                                                      ;#The Number of Rows
	declare -i FVcols=1                                                      ;#The Number of Columns
	declare -a FVcsv=()																		 ;#Empty array to load source file into
		
	##########################
	# These are counters for #
	# the number of items in #
	# priority groups        #
	##########################
	declare -i twodigit=0
	declare -i threedigit=0
	declare -i onethousands=0
	declare -i twothousands=0
	declare -i threethousands=0
	declare -i gtr4thousands=0
	declare -i temptwodigit=0
	declare -i tempthreedigit=0
	declare -i temponethousands=0
	declare -i temptwothousands=0
	declare -i tempthreethousands=0
	declare -i tempgtr4thousands=0

   declare -a temparray=()
	declare -i TempInt=0

	declare -i Npri=0

	Sort_By_Area="Inspection"                                                ;#Output will only contain product in this area
	#Sort_By_Area="All"
}

function ReadFile {
	let "twodigit=0"
	let "threedigit=0"
	let "onethousands=0"
	let "twothousands=0"
	let "threethousands=0"
	let "gtr4thousands=0"
   temparray=()
	FVcsv=()

	#Read source file into an array
   while read -r line
   do
     FVcsv+=("$line")
   done <"${FVfilename}"

   FVrows=${#FVcsv[@]}                     											;#The number of arrays is the row count
   FVcols+=`echo ${FVcsv[0]} | grep -c ","`											;#The number of commas plus one is the column count
	printf "%s\n" "${FVcsv[@]}"

	#Count the priority categories
   for ((rows=0;rows<${FVrows};rows++)); do
		TempInt=$(echo ${FVcsv[${rows}]} | awk -F, '{print $11}' | sed 's/\ //g')	;#In current line grab value from column 11 and delete white space
 
 		case ${debug} in
			yes)
				echo "ReadFile TempInit is "${TempInt}
				echo -n "The value should be "
				echo ${FVcsv[${rows}]} | awk -F, '{print $11}' | sed 's/\ //g'
		esac
		if [ ${TempInt} -le 100 ];then
				let "twodigit+=1"
		elif [ ${TempInt} -le 1000 ];then
				let "threedigit+=1"
		elif [ ${TempInt} -le 2000 ];then
				let "onethousands+=1"
		elif [ ${TempInt} -le 3000 ];then
				let "twothousands+=1"
		elif [ ${TempInt} -le 4000 ];then
				let "threethousands+=1"
		else
				let "gtr4thousands+=1"
		fi
	done

	case ${debug} in
		yes)
   		echo "The number or rows is: "${FVrows}
	   	echo "The number of cols is: "${FVcols}
			echo "twodigit       "${twodigit}
			echo "threedigit     "${threedigit}
			echo "onethousands   "${onethousands}
			echo "threethousands "${threethousands}
			echo "twothousands   "${twothousands}
			echo "gtr4thousands  "${gtr4thousands}
			;;	
	esac
}

function CalcTimeAtStep {
	let "temptwodigit=${FVrows}"												;#Number of rows in dataset
	let "tempthreedigit=${FVrows}-${twodigit}"							;#Number of rows in dataset
	let "temponethousands=${tempthreedigit}-${threedigit}"			;#Number of rows in dataset minus rows with 3 digit priorities
	let "tempthreethousands=${temponethousands}-${onethousands}"	;#Number of rows in dataset minus rows with priorities between 1 and 1999
	let "temptwothousands=${tempthreethousands}-${threethousands}"	;#Number of rows in dataset minus rows with priorities between [1-1999] && [3000-3999]
	let "tempgtr4thousands=${temptwothousands}-${twothousands}"		;#Number of rows in dataset that remain from all the above
	let "TempInt=0"
   temparray=()
	
	case ${debug} in
		yes)
			echo "temptwodigit       "${temptwodigit}
			echo "tempthreedigit     "${tempthreedigit}
			echo "temponethousands   "${temponethousands}
			echo "tempthreethousands "${tempthreethousands}
			echo "temptwothousands   "${temptwothousands}
			echo "tempgtr4thousands  "${tempgtr4thousands}
			echo "TempInt            "${TempInt}
	esac

   while read -r line
   do
     temparray+=("$line")
   done < <(printf "%s\n" "${FVcsv[@]}" | sort -t"," -rg -k10)

	case ${debug} in
		yes)
			printf "%s\n" "${temparray[@]}" > ./test\.csv
			;;
	esac

   for ((rows=0;rows<${FVrows};rows++)); do
		TempInt=$(echo ${temparray[${rows}]}	| awk -F, '{print $11}' | sed 's/\ //g')
		if [ ${TempInt} -le 100 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${temptwodigit}`
				let "temptwodigit-=1"
		elif [ ${TempInt} -le 1000 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${tempthreedigit}`
				let "tempthreedigit-=1"
		elif [ ${TempInt} -le 2000 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${temponethousands}`
				let "temponethousands-=1"
		elif [ ${TempInt} -le 3000 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${temptwothousands}`
				let "temptwothousands-=1"
		elif [ ${TempInt} -le 4000 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${tempthreethousands}`
				let "tempthreethousands-=1"
		else
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${tempgtr4thousands}`
				let "tempgtr4thousands-=1"
		fi
	done

	case ${debug} in
		no)
			#printf "%s\n" "${FVcsv[@]}"
			printf "%s\n" "${FVcsv[@]}" > ./test\.csv
			;;
	esac
}

function CalcShipDate {
	let "temptwodigit=${FVrows}"												;#Number of rows in dataset
	let "tempthreedigit=${FVrows}-${twodigit}"							;#Number of rows in dataset
	let "temponethousands=${tempthreedigit}-${threedigit}"			;#Number of rows in dataset minus rows with 3 digit priorities
	let "tempthreethousands=${temponethousands}-${onethousands}"	;#Number of rows in dataset minus rows with priorities between 1 and 1999
	let "temptwothousands=${tempthreethousands}-${threethousands}"	;#Number of rows in dataset minus rows with priorities between [1-1999] && [3000-3999]
	let "tempgtr4thousands=${temptwothousands}-${twothousands}"		;#Number of rows in dataset that remain from all the above
	let "TempInt=0"
   temparray=()

	case ${debug} in
		yes)
			echo "temptwodigit       "${temptwodigit}
			echo "tempthreedigit     "${tempthreedigit}
			echo "temponethousands   "${temponethousands}
			echo "tempthreethousands "${tempthreethousands}
			echo "temptwothousands   "${temptwothousands}
			echo "tempgtr4thousands  "${tempgtr4thousands}
			echo "TempInt            "${TempInt}
	esac

   while read -r line
   do
     temparray+=("$line")
   done < <(printf "%s\n" "${FVcsv[@]}" | sort -t"," -g -k13)

	case ${debug} in
		yes)
			#printf "%s\n" "${temparray[@]}" > ./test.csv
			printf "%s\n" "${FVcsv[@]}" > ./test\.csv
			;;
	esac

   for ((rows=0;rows<${FVrows};rows++)); do
		TempInt=$(echo ${temparray[${rows}]}	| awk -F, '{print $11}' | sed 's/\ //g')
		if [ ${TempInt} -le 100 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${temptwodigit}`
				let "temptwodigit-=1"
		elif [ ${TempInt} -le 1000 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${tempthreedigit}`
				let "tempthreedigit-=1"
		elif [ ${TempInt} -le 2000 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${temponethousands}`
				let "temponethousands-=1"
		elif [ ${TempInt} -le 3000 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${temptwothousands}`
				let "temptwothousands-=1"
		elif [ ${TempInt} -le 4000 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${tempthreethousands}`
				let "tempthreethousands-=1"
		else
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${tempgtr4thousands}`
				let "tempgtr4thousands-=1"
		fi
	done

	case ${debug} in
		yes)
			#printf "%s\n" "${FVcsv[@]}"
			printf "%s\n" "${FVcsv[@]}" > ./test\.csv
			;;
	esac
}

function WeightedPriority {
	let "TempInt=${FVrows}"
   temparray=()

	case ${debug} in
		yes)
			echo "TempInt            "${TempInt}
	esac

   while read -r line
   do
     temparray+=("$line")
   done < <(printf "%s\n" "${FVcsv[@]}" | sort -t"," -g -k11)

	case ${debug} in
		yes)
			#printf "%s\n" "${temparray[@]}" > ./test\.csv
			printf "%s\n" "${FVcsv[@]}" > ./test\.csv
			;;
	esac

   for ((rows=0;rows<${FVrows};rows++)); do
		FVcsv[${rows}]=`echo ${temparray[${rows}]}","${TempInt}`
		if [ ${TempInt} -le 100 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${TempInt}`
		elif [ ${TempInt} -le 1000 ];then
				FVcsv[${rows}]=`echo ${temparray[${rows}]}","${TempInt}`
		else
				#Per procedure Priority over 1000 are not based on Priority
				FVcsv[${rows}]=`echo ${temparray[${rows}]}",0"`
		fi
		let "TempInt-=1"
	done

	case ${debug} in
		yes)
			#printf "%s\n" "${FVcsv[@]}"
			printf "%s\n" "${FVcsv[@]}" > ./test\.csv
			;;
	esac
}

function NewPriority {
	#(ExpeditePlate) + (CalcTimeAtStep) + (CalcShipDate) + (PriorityNumber) = NewPriority
	let "TempInt=0"	
	temparray=()

   for ((rows=0;rows<${FVrows};rows++)); do
		let "TempInt+=`echo ${FVcsv[${rows}]} | awk -F, '{print $15"+"$16"+"$17"+"$18}'`"
		FVcsv[${rows}]+=`echo ","${TempInt}`
		let "TempInt=0"	
	done

   while read -r line
   do
     temparray+=("$line")
   done < <(printf "%s\n" "${FVcsv[@]}" | sort -t"," -rg -k19)

	FVcsv=() 
   while read -r line
   do
     FVcsv+=("$line")
   done < <(printf "%s\n" "${temparray[@]}")

	case ${debug} in
		yes)
			#printf "%s\n" "${temparray[@]}" > ./test\.csv
			printf "%s\n" "${temparray[@]}"
			echo -e "\n\n\n"
			printf "%s\n" "${FVcsv[@]}"
			;;
	esac
}

function WriteOutput {
   case ${Sort_By_Area} in
      All)
			temparray=()

			#The point here is to get the array variables
			#into sync so that after exiting the case 
			#statement the code can continue on in unity
  			while read -r line
  			do
  				temparray+=("$line")
  			done < <(printf "%s\n" "${FVcsv[@]}")
         ;;
      *)
			let "TempInt=0"
			temparray=()

			#Cycle through the arrays and pull out the ones matching Step
         for ((rows=0;rows<${FVrows};rows++)); do
				let "TempInt=`echo ${FVcsv[${rows}]} | awk -F, '{print $7}' | grep -c -m1 ${Sort_By_Area}`"
				if [ ${TempInt} -eq 1 ]; then
					temparray[${rows}]=`echo ${FVcsv[${rows}]}`					;#Create new arrays with only the values wanted
				fi
			done
         ;;
   esac
	FVcsv=()
  	while read -r line
  	do
  		FVcsv+=("$line")
  	done < <(printf "%s\n" "${temparray[@]}" | sort -t"," -k14,14 -k19,19)

	printf "%s\n" "${FVcsv[@]}" | awk -F, '{print $1","$2","$3","$4","$5","$6","$7","$8","$9","$14}' > ./test\.csv
	case ${debug} in
		no)
			printf "%s\n" "${FVcsv[@]}" | awk -F, '{print $1","$2","$3","$4","$5","$6","$7","$8","$9","$14}'
	esac
}

function Main {

	Variable_Initialization
	ReadFile
	CalcTimeAtStep
	CalcShipDate
	WeightedPriority
	NewPriority
	WriteOutput
	
   case ${debug} in
		yes)
   		echo "Factory View has ran"
			;;
   esac

   exit 0
}

Main							;#This has to be the last line in the program






##
#Resources
#Help Menu 
#https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f
#https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
#https://stackoverflow.com/questions/16483119/an-example-of-how-to-use-getopts-in-bash
##

function WriteFile {
	#sort by assigned area
	#sort by assigned tool
	echo ""
}


function ExpeditePlate {
	#Add a number to bump its priority to expedite a plate.
	#For now this will be a static value.
	echo ""
}


function AssignTool {
	#For now this will be a static value.
	echo ""
}
