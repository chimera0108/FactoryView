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
   FVfilename="${HOME}/.git/FactoryView/FactoryView_Project.csv"           ;#Location of source data
   declare -i FVrows=0                                                     ;#The Number of Rows
   declare -i FVcols=1                                                     ;#The Number of Columns
   declare -a FVcsv=()                                                     ;#Empty array to load source file into

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

   FVrows=${#FVcsv[@]}                                                     ;#The number of arrays is the row count
   FVcols+=`echo ${FVcsv[0]} | grep -c ","`                                ;#The number of commas plus one is the column count
   printf "%s\n" "${FVcsv[@]}"

   #Count the priority categories
   for ((rows=0;rows<${FVrows};rows++)); do
      TempInt=$(echo ${FVcsv[${rows}]} | awk -F, '{print $11}' | sed 's/\ //g')  ;#In current line grab value from column 11 and delete white space

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

function FixPriority {
   let "temponethousands=1000"         ;#Number of rows in dataset minus rows with 3 digit priorities
   let "temptwothousands=${tempthreethousands}-${threethousands}" ;#Number of rows in dataset minus rows with priorities between [1-1999] && [3000-3999]
   let "tempthreethousands=0"
   let "tempgtr4thousands=0"
   let "TempInt=0"
   temparray=()

   case ${debug} in
      yes)
         echo "temponethousands   "${temponethousands}
         echo "temptwothousands   "${temptwothousands}
         echo "TempInt            "${TempInt}
   esac

   #Read in the array and sort by the Due Date Epoch column
   while read -r line
   do
     temparray+=("$line")
   done < <(printf "%s\n" "${FVcsv[@]}" | sort -t"," -g -k14)

   case ${debug} in
      yes)
         #printf "%s\n" "${temparray[@]}" > ./test.csv
         printf "%s\n" "${FVcsv[@]}" > ./test\.csv
         ;;
   esac

   #Assign new Priorities as needed based on Due Date
   for ((rows=0;rows<${FVrows};rows++)); do
      TempInt=$(echo ${temparray[${rows}]}   | awk -F, '{print $11}' | sed 's/\ //g')
      if [ ${TempInt} -le 1000 ];then
         FVcsv[${rows}]=`echo ${temparray[${rows}]}","${TempInt}`
      elif [ ${TempInt} -le 2000 ];then
         FVcsv[${rows}]=`echo ${temparray[${rows}]}","${temponethousands}`
         let "temponethousands+=1"
      elif [ ${TempInt} -le 3000 ];then
         let "temptwothousands=${TempInit}+11000"
         FVcsv[${rows}]=`echo ${temparray[${rows}]}","${temptwothousands}`
      elif [ ${TempInt} -le 4000 ];then
         let "tempthreethousands=${TempInit}+9000"
         FVcsv[${rows}]=`echo ${temparray[${rows}]}","${tempthreethousands}`
      else
         let "tempgtr4thousands=${TempInit}+10000"
         FVcsv[${rows}]=`echo ${temparray[${rows}]}","${tempgtr4thousands}`
      fi
   done

   #Update the Priority to the new value
   for ((rows=0;rows<${FVrows};rows++)); do
      FVcsv[${rows}]=`printf "%s\n" "${FVcsv[${rows}]}" | awk -F, '{print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10","$15","$12","$13","$14}'`
   done

   case ${debug} in
      yes)
         #printf "%s\n" "${FVcsv[@]}"
         printf "%s\n" "${FVcsv[@]}" > ./test\.csv
         ;;
   esac

}

function WriteOutput {
   case ${Sort_By_Area} in
      All)
         temparray=()

         #The point here is to get the array variables
         #into sync regardless of which case statement is used
         #so that after exiting the case 
         #statement the code can continue on in unity
         while read -r line
         do
            temparray+=("$line")
         done < <(printf "%s\n" "${FVcsv[@]}")
         ;;
      *)
         let "TempInt=0"
         temparray=()

         #Only print Primary Source Key (In this case the area "Inspection")(refer to graphic)
         for ((rows=0;rows<${FVrows};rows++)); do
            #awk $7 is the step its at
            #variable ${Sort_By_Area} is a stand in for the drop down list of areas and has a static value assigned in Variable_Initialization
            let "TempInt=`echo ${FVcsv[${rows}]} | awk -F, '{print $7}' | grep -c -m1 ${Sort_By_Area}`"
            if [ ${TempInt} -eq 1 ]; then
               temparray[${rows}]=`echo ${FVcsv[${rows}]}`              ;#Create new arrays with only the values wanted
            fi
         done
         ;;
   esac
   
   #Now sort the array by the tool assigned and then by the priority
   FVcsv=()
   while read -r line
   do
      FVcsv+=("$line")
   done < <(printf "%s\n" "${temparray[@]}" | sort -t"," -k13,13 -k11,11)

   printf "%s\n" "${FVcsv[@]}" > ./test\.csv
   case ${debug} in
      no)
         printf "%s\n" "${FVcsv[@]}" 
   esac
}


function Main {

   Variable_Initialization
   ReadFile
   FixPriority
   WriteOutput

   case ${debug} in
      yes)
         echo "Factory View has ran"
         ;;
   esac

   exit 0
}

Main                    ;#This has to be the last line in the program

